// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/diary_state.dart';
import '../global/constants.dart';
import 'ddl_diary.dart';

class DBDiaryHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBDiaryHelper _dbDiaryHelper = DBDiaryHelper._createInstance();
  // 构造函数，返回单例
  factory DBDiaryHelper() => _dbDiaryHelper;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var diaryDbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBDiaryHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取Android和iOS存储数据库的目录路径(用户看不到，在Android/data/……里看不到)。
    // Directory directory = await getApplicationDocumentsDirectory();
    // String path = "${directory.path}/${DiaryDdl.databaseName}";

    // IOS不支持这个方法，所以可能取不到这个地址
    Directory? directory2 = await getExternalStorageDirectory();
    String path = "${directory2?.path}/${DiaryDdl.databaseName}";

    print("初始化 DIARY sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var diaryDb = await openDatabase(path, version: 1, onCreate: _createDb);
    diaryDbFilePath = path;
    return diaryDb;
  }

  // 创建训练数据库相关表
  void _createDb(Database db, int newVersion) async {
    print("开始创建表 _createDb……");

    await db.transaction((txn) async {
      txn.execute(DiaryDdl.ddlForDiary);
    });
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("Diary db.isOpen ${db.isOpen}");
    await db.close();
    print("Diary db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    print("开始删除內嵌的 sqlite Diary db文件，db文件地址：$diaryDbFilePath");

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(diaryDbFilePath);

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://stackoverflow.com/questions/60848752/delete-database-when-log-out-and-create-again-after-log-in-dart
    _database = null;
  }

  // 显示db中已有的table，默认的和自建立的
  void showTableNameList() async {
    Database db = await database;
    var tableNames = (await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    ))
        .map((row) => row['name'] as String)
        .toList(growable: false);

    print("Diary DB中拥有的表名:------------");
    print(tableNames);
  }

  // 导出所有数据
  Future<void> exportDatabase() async {
    // 获取应用文档目录路径
    Directory appDocDir = await getApplicationDocumentsDirectory();
    // 创建或检索 db_export 文件夹
    var tempDir = await Directory(p.join(appDocDir.path, "db_export")).create();

    // 打开数据库
    Database db = await database;

    // 获取所有表名
    List<Map<String, dynamic>> tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

    // 遍历所有表
    for (Map<String, dynamic> table in tables) {
      String tableName = table['name'];

      // 不是自建的表，不导出
      if (!tableName.startsWith("ff_")) {
        continue;
      }

      String tempFilePath = p.join(tempDir.path, '$tableName.json');

      // 查询表中所有数据
      List<Map<String, dynamic>> result = await db.query(tableName);

      // 将结果转换为JSON字符串
      String jsonStr = jsonEncode(result);

      // 创建临时导出文件
      File tempFile = File(tempFilePath);

      // 将JSON字符串写入临时文件
      await tempFile.writeAsString(jsonStr);

      // print('表 $tableName 已成功导出到：$tempFilePath');
    }
  }

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// diary 的相关操作
  ///
  ///
  // 插入单条数据(返回 diary_id)
  Future<int> insertDiary(Diary diary) async =>
      (await database).insert(DiaryDdl.tableNameOfDiary, diary.toMap());

  Future<List<Object?>> insertDiaryList(List<Diary> diarys) async {
    var batch = (await database).batch();
    for (var item in diarys) {
      batch.insert(DiaryDdl.tableNameOfDiary, item.toMap());
    }
    return batch.commit();
  }

  // 修改单条数据
  Future<int> updateDiary(Diary diary) async =>
      (await database).update(DiaryDdl.tableNameOfDiary, diary.toMap(),
          where: 'diary_id = ?', whereArgs: [diary.diaryId]);

  // 删除单条数据
  Future<int> deleteDiaryById(int id) async =>
      (await database).delete(DiaryDdl.tableNameOfDiary,
          where: 'diary_id = ?', whereArgs: [id]);

  // 关键字模糊查询基础活动
  Future<CusDataResult> queryDiaryByKeyword({
    required int userId,
    required String keyword,
    required int pageSize, // 一次查询条数显示
    required int page, // 一次查询的偏移量，用于分页
  }) async {
    Database db = await database;
    // 根据页数和页面获得偏移量
    var offset = (page - 1) * pageSize;

    try {
      // 查询指定关键字当前页的数据
      List<Map<String, dynamic>> maps = await db.query(
        DiaryDdl.tableNameOfDiary,
        where:
            '(title LIKE ? OR content LIKE ?) AND user_id = ? LIMIT ? OFFSET ?',
        whereArgs: ['%$keyword%', '%$keyword%', userId, pageSize, offset],
      );
      final list = maps.map((row) => Diary.fromMap(row)).toList();

      // 获取满足查询条件的数据总量
      int? totalCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${DiaryDdl.tableNameOfDiary} '
          'WHERE (title LIKE ? OR content LIKE ?) AND user_id = ?',
          ['%$keyword%', '%$keyword%', userId],
        ),
      );

      // 查询每页指定数量的数据，但带上总条数
      return CusDataResult(data: list, total: totalCount ?? 0);
    } catch (e) {
      print('Error at queryDiaryByKeyword: $e');
      // ？？？抛出异常来触发回滚的方式是 sqflite 中常用的做法
      rethrow;
    }
  }

  // 按日期范围查询(查询某一天也要起止为同一个即可)，查询所有
  Future<List<Diary>> queryDiaryByDateRange(
    int userId, {
    String? startDate,
    String? endDate,
  }) async {
    Database db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    where.add('user_id = ?');
    whereArgs.add(userId);

    if (startDate != null) {
      where.add('date >= ?');
      whereArgs.add(startDate);
    }

    if (endDate != null) {
      where.add('date <= ?');
      whereArgs.add(endDate);
    }

    try {
      // 查询指定关键字当前页的数据
      List<Map<String, dynamic>> maps = await db.query(
        DiaryDdl.tableNameOfDiary,
        where: where.isNotEmpty ? where.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      );
      final list = maps.map((row) => Diary.fromMap(row)).toList();

      // 查询每页指定数量的数据，但带上总条数
      return list;
    } catch (e) {
      print('Error at queryDiaryByDateRange: $e');
      // ？？？抛出异常来触发回滚的方式是 sqflite 中常用的做法
      rethrow;
    }
  }

  // 按指定编号查询
  Future<List<Diary>> queryDiaryById(int id) async =>
      (await (await database).query(
        DiaryDdl.tableNameOfDiary,
        where: "diary_id = ? ",
        whereArgs: [id],
      ))
          .map((row) => Diary.fromMap(row))
          .toList();
}

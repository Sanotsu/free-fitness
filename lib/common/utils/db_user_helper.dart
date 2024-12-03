// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/user_state.dart';

import 'ddl_user.dart';

class DBUserHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBUserHelper _dbHelper = DBUserHelper._createInstance();
  // 构造函数，返回单例
  factory DBUserHelper() => _dbHelper;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var userDbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBUserHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取Android和iOS存储数据库的目录路径(用户看不到，在Android/data/……里看不到)。
    // Directory directory = await getApplicationDocumentsDirectory();
    // String path = "${directory.path}/${UserDdl.databaseName}";

    // IOS不支持这个方法，所以可能取不到这个地址
    Directory? directory2 = await getExternalStorageDirectory();
    String path = "${directory2?.path}/${UserDdl.databaseName}";

    print("初始化 User sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var userDb = await openDatabase(path, version: 1, onCreate: _createDb);
    userDbFilePath = path;
    return userDb;
  }

  // 创建训练数据库相关表
  void _createDb(Database db, int newVersion) async {
    print("开始创建表 _createDb……");

    await db.transaction((txn) async {
      txn.execute(UserDdl.ddlForUser);
      txn.execute(UserDdl.ddlForIntakeDailyGoal);
      txn.execute(UserDdl.ddlForWeightTrend);
    });
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("User db.isOpen ${db.isOpen}");
    await db.close();
    print("User db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    print("开始删除內嵌的 sqlite User db文件，db文件地址：$userDbFilePath");

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(userDbFilePath);

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

    print("User DB中拥有的表名:------------");
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
  /// user 的相关操作
  ///

  // 查询用户
  // ？？？现在就是显示登录用户信息，用户密码登录成功之后记住信息？(缓存还不太懂，这里就账号密码id查询)
  Future<User?> queryUser({
    int? userId,
    String? userName,
    String? password,
  }) async {
    Database db = await database;

    var where = [];
    var whereArgs = [];

    if (userId != null) {
      where.add(" user_id = ? ");
      whereArgs.add(userId);
    }
    if (userName != null) {
      where.add(" user_name = ? ");
      whereArgs.add(userName);
    }
    if (password != null) {
      where.add(" password = ? ");
      whereArgs.add(password);
    }

    final userRows = await db.query(
      UserDdl.tableNameOfUser,
      where: where.isNotEmpty ? where.join(" AND ") : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    final userlist = userRows.map((row) => User.fromMap(row)).toList();

    return userlist.isNotEmpty ? userlist[0] : null;
  }

  // 查询用户列表
  Future<List<User>?> queryUserList({String? userName}) async {
    Database db = await database;

    var where = [];
    var whereArgs = [];

    if (userName != null) {
      where.add(" user_name like ? ");
      whereArgs.add("%$userName%");
    }

    final userRows = await db.query(
      UserDdl.tableNameOfUser,
      where: where.isNotEmpty ? where.join(" AND ") : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return userRows.map((row) => User.fromMap(row)).toList();
  }

  // 批量插入用户(有单条的，也放到list)
  Future<List<Object?>> insertUserList(
    List<User> userList,
  ) async {
    var batch = (await database).batch();

    for (var item in userList) {
      batch.insert(UserDdl.tableNameOfUser, item.toMap());
    }

    return batch.commit();
  }

  // 修改单条 user
  Future<int> updateUser(User user) async => (await database).update(
        UserDdl.tableNameOfUser,
        user.toMap(),
        where: 'user_id = ?',
        whereArgs: [user.userId],
      );

  // 删除单条 user
  Future<int> deleteUser(int userId) async => (await database).delete(
        UserDdl.tableNameOfUser,
        where: "user_id = ?",
        whereArgs: [userId],
      );

  Future<List<Object?>> insertIntakeDailyGoalList(
    List<IntakeDailyGoal> goals,
  ) async {
    var batch = (await database).batch();

    for (var item in goals) {
      batch.insert(UserDdl.tableNameOfIntakeDailyGoal, item.toMap());
    }

    return batch.commit();
  }

  // 查询用户带上每周具体摄入目标
  // ？？？现在就是显示登录用户信息，用户密码登录成功之后记住信息？(缓存还不太懂，这里就账号密码id查询)
  // 这里查询的都是当前app的唯一用户，就一个用户
  Future<UserWithIntakeDailyGoal> queryUserWithIntakeDailyGoal({
    int? userId,
    String? userName,
    String? password,
  }) async {
    Database db = await database;

    var where = [];
    var whereArgs = [];

    if (userId != null) {
      where.add(" user_id = ? ");
      whereArgs.add(userId);
    }
    if (userName != null) {
      where.add(" user_name = ? ");
      whereArgs.add(userName);
    }
    if (password != null) {
      where.add(" password = ? ");
      whereArgs.add(password);
    }

    // 这里查询的都是唯一用户，就一个用户
    final user = User.fromMap((await db.query(UserDdl.tableNameOfUser,
            where: where.isNotEmpty ? where.join(" AND ") : null,
            whereArgs: whereArgs.isNotEmpty ? whereArgs : null))
        .first);

    final intakeGoalRows = await db.query(
      UserDdl.tableNameOfIntakeDailyGoal,
      where: "user_id = ? ",
      whereArgs: [user.userId],
    );

    List<IntakeDailyGoal> goals =
        intakeGoalRows.map((row) => IntakeDailyGoal.fromMap(row)).toList();

    return UserWithIntakeDailyGoal(intakeGoals: goals, user: user);
  }

  // 修改用户的周摄入宏量素目标
  Future<int> updateIntakeDailyGoalByUser(List<IntakeDailyGoal> goals) async {
    Database db = await database;

    try {
      int rst = 0;

      await db.transaction((txn) async {
        for (var goal in goals) {
          List<Map<String, dynamic>> result = await txn.query(
            UserDdl.tableNameOfIntakeDailyGoal,
            where: 'user_id = ? and day_of_week = ?',
            whereArgs: [goal.userId, goal.dayOfWeek],
          );
          // 如果已存在，指定用户指定周几的目标值只有1条数据才对
          if (result.isNotEmpty) {
            var existed = IntakeDailyGoal.fromMap(result[0]);
            goal.intakeDailyGoalId = existed.intakeDailyGoalId;

            rst = await txn.update(
              UserDdl.tableNameOfIntakeDailyGoal,
              goal.toMap(),
              where: 'user_id = ? and day_of_week = ?',
              whereArgs: [goal.userId, goal.dayOfWeek],
            );
          } else {
            // 如果该用户指定weekeday没有数据，则新增
            rst = await txn.insert(
              UserDdl.tableNameOfIntakeDailyGoal,
              goal.toMap(),
            );
          }
        }
      });

      return rst;
    } catch (e) {
      // Handle the error
      // 抛出异常来触发回滚的方式是 sqflite 中常用的做法
      rethrow;
    }
  }

  ///***********************************************/
  /// weight_trent 的相关操作
  ///

  // 批量插入体重趋势数据(有单条的，也放到list)
  Future<List<Object?>> insertWeightTrendList(
    List<WeightTrend> weightTrendList,
  ) async {
    var batch = (await database).batch();

    for (var item in weightTrendList) {
      batch.insert(UserDdl.tableNameWeightTrend, item.toMap());
    }

    return batch.commit();
  }

  // 批量删除体重趋势数据(有单条的，也放到list)
  Future<List<Object?>> deleteWeightTrendList(
    List<WeightTrend> weightTrendList,
  ) async {
    var batch = (await database).batch();

    for (var item in weightTrendList) {
      batch.delete(
        UserDdl.tableNameWeightTrend,
        where: "weight_trend_id = ? ",
        whereArgs: [item.weightTrendId],
      );
    }

    return batch.commit();
  }

  // 查询用户体重数据，查不到是空数组
  Future<List<WeightTrend>> queryWeightTrendByUser({
    int? userId,
    String? startDate,
    String? endDate,
    String? gmtCreateSort = "ASC", // 按创建时间升序或者降序排序
  }) async {
    Database db = await database;

    var where = [];
    var whereArgs = [];

    if (userId != null) {
      where.add(" user_id = ? ");
      whereArgs.add(userId);
    }
    if (startDate != null) {
      where.add(" gmt_create >= ? ");
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      where.add(" gmt_create <= ? ");
      whereArgs.add(endDate);
    }

    // 如果有传入创建时间排序，不是传的降序一律升序
    var sort = gmtCreateSort?.toLowerCase() == 'desc' ? 'DESC' : 'ASC';

    final userRows = await db.query(
      UserDdl.tableNameWeightTrend,
      where: where.isNotEmpty ? where.join(" AND ") : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'gmt_create $sort',
    );

    return userRows.map((row) => WeightTrend.fromMap(row)).toList();
  }
}

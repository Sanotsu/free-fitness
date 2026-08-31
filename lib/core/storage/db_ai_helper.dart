// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/ai/ai_conversation.dart';
import '../../models/ai/ai_custom_role.dart';
import '../../models/ai/ai_message.dart';
import 'ddl_ai.dart';

/// 2026-08-27 AI 助手模块的 sqlite 单例 helper
/// (照抄 DBDiaryHelper 的范式：单例/外部存储目录/全量导出json/删库重建)
class DBAiHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBAiHelper _dbAiHelper = DBAiHelper._createInstance();
  // 构造函数，返回单例
  factory DBAiHelper() => _dbAiHelper;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var aiDbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBAiHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 与其他四库一致，放在应用外部存储私有目录
    Directory? directory2 = await getExternalStorageDirectory();
    String path = "${directory2?.path}/${AiDdl.databaseName}";

    print("初始化 AI sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var aiDb = await openDatabase(path, version: 1, onCreate: _createDb);
    aiDbFilePath = path;
    return aiDb;
  }

  // 创建AI模块相关表
  void _createDb(Database db, int newVersion) async {
    print("开始创建AI模块表 _createDb……");

    await db.transaction((txn) async {
      await txn.execute(AiDdl.ddlForAiConversation);
      await txn.execute(AiDdl.ddlForAiMessage);
      await txn.execute(AiDdl.ddlForAiRole);
    });
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("AI db.isOpen ${db.isOpen}");
    await db.close();
    print("AI db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    _database = null;

    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    print("开始删除內嵌的 sqlite AI db文件，db文件地址：$aiDbFilePath");

    await deleteDatabase(aiDbFilePath);

    _database = null;
  }

  /// 导出所有数据(每张 ff_ 表导成一个 ff_xxx.json，供全量备份 zip 打包)
  Future<void> exportDatabase() async {
    // 获取应用文档目录路径
    Directory appDocDir = await getApplicationDocumentsDirectory();
    // 创建或检索 db_export 文件夹
    var tempDir = await Directory(p.join(appDocDir.path, "db_export")).create();

    // 打开数据库
    Database db = await database;

    // 获取所有表名
    List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );

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
    }
  }

  ///
  /// Helper 的相关方法
  ///

  ///***********************************************/
  /// ai_conversation 的相关操作
  ///

  // 插入会话(返回 conversation_id)
  Future<int> insertConversation(AiConversation conv) async =>
      (await database).insert(
        AiDdl.tableNameOfAiConversation,
        conv.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<List<Object?>> insertConversationList(
    List<AiConversation> convs,
  ) async {
    var batch = (await database).batch();
    for (var item in convs) {
      batch.insert(
        AiDdl.tableNameOfAiConversation,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return batch.commit();
  }

  // 修改会话
  Future<int> updateConversation(AiConversation conv) async =>
      (await database).update(
        AiDdl.tableNameOfAiConversation,
        conv.toMap(),
        where: 'conversation_id = ?',
        whereArgs: [conv.conversationId],
      );

  // 删除会话(消息由调用方级联删除)
  Future<int> deleteConversationById(int id) async => (await database).delete(
    AiDdl.tableNameOfAiConversation,
    where: 'conversation_id = ?',
    whereArgs: [id],
  );

  // 查询全部会话(侧边栏列表，按最后修改时间倒序)
  Future<List<AiConversation>> queryConversationList() async =>
      (await (await database).query(
        AiDdl.tableNameOfAiConversation,
        orderBy: 'gmt_modified DESC',
      )).map((row) => AiConversation.fromMap(row)).toList();

  // 按指定编号查询
  Future<AiConversation?> queryConversationById(int id) async {
    var list = (await (await database).query(
      AiDdl.tableNameOfAiConversation,
      where: "conversation_id = ? ",
      whereArgs: [id],
    )).map((row) => AiConversation.fromMap(row)).toList();
    return list.isNotEmpty ? list.first : null;
  }

  // 按业务场景+对象键查询会话(同一业务对象复用同一会话；取最近一条兜底)
  Future<AiConversation?> queryConversationByBiz(
    String bizType,
    String bizKey,
  ) async {
    var list = (await (await database).query(
      AiDdl.tableNameOfAiConversation,
      where: "biz_type = ? AND biz_key = ?",
      whereArgs: [bizType, bizKey],
      orderBy: 'conversation_id DESC',
      limit: 1,
    )).map((row) => AiConversation.fromMap(row)).toList();
    return list.isNotEmpty ? list.first : null;
  }

  ///***********************************************/
  /// ai_message 的相关操作
  ///

  // 插入消息(返回 message_id)
  Future<int> insertMessage(AiMessage msg) async => (await database).insert(
    AiDdl.tableNameOfAiMessage,
    msg.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<List<Object?>> insertMessageList(List<AiMessage> msgs) async {
    var batch = (await database).batch();
    for (var item in msgs) {
      batch.insert(
        AiDdl.tableNameOfAiMessage,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return batch.commit();
  }

  // 删除单条消息
  Future<int> deleteMessageById(int id) async => (await database).delete(
    AiDdl.tableNameOfAiMessage,
    where: 'message_id = ?',
    whereArgs: [id],
  );

  // 删除指定会话的全部消息(删除会话时级联调用；清空会话也复用)
  Future<int> deleteMessagesByConversation(int conversationId) async =>
      (await database).delete(
        AiDdl.tableNameOfAiMessage,
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
      );

  // 查询指定会话的全部消息(按插入顺序升序，即对话时间顺序)
  Future<List<AiMessage>> queryMessagesByConversation(
    int conversationId,
  ) async => (await (await database).query(
    AiDdl.tableNameOfAiMessage,
    where: 'conversation_id = ?',
    whereArgs: [conversationId],
    orderBy: 'message_id ASC',
  )).map((row) => AiMessage.fromMap(row)).toList();

  ///***********************************************/
  /// ai_role(自定义角色) 的相关操作
  ///

  // 插入自定义角色(返回 role_id)
  Future<int> insertCustomRole(AiCustomRole role) async =>
      (await database).insert(
        AiDdl.tableNameOfAiRole,
        role.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<List<Object?>> insertCustomRoleList(List<AiCustomRole> roles) async {
    var batch = (await database).batch();
    for (var item in roles) {
      batch.insert(
        AiDdl.tableNameOfAiRole,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return batch.commit();
  }

  // 修改自定义角色
  Future<int> updateCustomRole(AiCustomRole role) async =>
      (await database).update(
        AiDdl.tableNameOfAiRole,
        role.toMap(),
        where: 'role_id = ?',
        whereArgs: [role.roleId],
      );

  // 删除自定义角色(不级联修改历史会话，旧会话按兜底角色显示)
  Future<int> deleteCustomRoleById(int id) async => (await database).delete(
    AiDdl.tableNameOfAiRole,
    where: 'role_id = ?',
    whereArgs: [id],
  );

  // 查询全部自定义角色
  Future<List<AiCustomRole>> queryCustomRoles() async =>
      (await (await database).query(
        AiDdl.tableNameOfAiRole,
        orderBy: 'role_id ASC',
      )).map((row) => AiCustomRole.fromMap(row)).toList();
}

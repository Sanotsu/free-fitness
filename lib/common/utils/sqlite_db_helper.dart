// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/dietary_state.dart';
import '../../models/training_state.dart';
import '../global/constants.dart';
import 'ddl_dietary.dart';
import 'ddl_training.dart';

class DBTrainHelper {
  static final DBTrainHelper _dbHelper = DBTrainHelper._createInstance();
  static Database? _database;
  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  var log = Logger();

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBTrainHelper._createInstance();

  factory DBTrainHelper() => _dbHelper;

  Future<Database> get database async =>
      _database ??= await initializeDatabase();

  // 初始化数据库
  Future<Database> initializeDatabase() async {
    // 获取Android和iOS存储数据库的目录路径。
    // Directory directory = await getApplicationDocumentsDirectory();
    // String path = "${directory.path}/${TrainingDdl.databaseName}";

    Directory? directory = await getExternalStorageDirectory();
    String path = "${directory?.path}/${DietaryDdl.databaseName}";

    print("初始化 TRAIN sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var notesDatabase =
        await openDatabase(path, version: 1, onCreate: _createDb);

    dbFilePath = path;

    return notesDatabase;
  }

  // 创建训练数据库相关表
  void _createDb(Database db, int newVersion) async {
    await db.execute(TrainingDdl.ddlForExercise);
    await db.execute(TrainingDdl.ddlForAction);
    await db.execute(TrainingDdl.ddlForGroup);
    await db.execute(TrainingDdl.ddlForPlan);
    await db.execute(TrainingDdl.ddlForPlanHasGroup);
    await db.execute(TrainingDdl.ddlForUser);
    await db.execute(TrainingDdl.ddlForTrainedLog);
    await db.execute(TrainingDdl.ddlForWeightTrend);
  }

  // 关闭数据库
  Future<bool> closeDatabase() async {
    Database db = await database;

    print("db.isOpen ${db.isOpen}");
    await db.close();
    print("db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    if (!db.isOpen) {
      return true;
    } else {
      return false;
    }
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  void deleteDb() async {
    print("开始删除內嵌的sqlite db文件，db文件地址：$dbFilePath");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://stackoverflow.com/questions/60848752/delete-database-when-log-out-and-create-again-after-log-in-dart
    _database = null;

    await deleteDatabase(dbFilePath);
  }

// 显示db中已有的table，默认的和自建立的
  void showTableNameList() async {
    Database db = await database;
    var tableNames = (await db
            .query('sqlite_master', where: 'type = ?', whereArgs: ['table']))
        .map((row) => row['name'] as String)
        .toList(growable: false);

    // for (var row
    //     in (await db.query('sqlite_master', columns: ['type', 'name']))) {
    //   print(row.values);
    // }

    print("------------1111");
    print(tableNames);
    print("------------1111");
  }

  ///
  /// 动作库基础表exercise的相关操作
  ///
  ///
  // 插入单条数据
  Future<int> insertExercise(Exercise exercise) async {
    Database db = await database;
    var result = await db.insert(
      TrainingDdl.tableNameOfExercise,
      exercise.toMap(),
    );
    return result;
  }

  // 修改单条数据
  Future<int> updateExercise(Exercise exercise) async {
    Database db = await database;
    var result = await db.update(
      TrainingDdl.tableNameOfExercise,
      exercise.toMap(),
      // 确保Id存在.
      where: 'exercise_id = ?',
      // 传递 pdfState 的id作为whereArg，以防止SQL注入。
      whereArgs: [exercise.exerciseId],
    );
    return result;
  }

  // 删除单条数据
  Future<int> deleteExercise(int id) async {
    Database db = await database;
    var result = await db.delete(
      TrainingDdl.tableNameOfExercise,
      where: "exercise_id=?",
      whereArgs: [id],
    );
    return result;
  }

// 关键字模糊查询基础活动
  Future<CusDataResult> queryExerciseByKeyword({
    required String keyword,
    required int pageSize, // 一次查询条数显示
    required int page, // 一次查询的偏移量，用于分页
  }) async {
    Database db = await database;

    // 查询每页指定数量的数据，但带上总条数
    var temp = CusDataResult(data: [], total: 0);

    try {
      List<Map<String, dynamic>> maps = await db.query(
          TrainingDdl.tableNameOfExercise,
          where:
              'exercise_code LIKE ? OR exercise_name LIKE ? LIMIT ? OFFSET ?',
          whereArgs: [
            '%$keyword%',
            '%$keyword%',
            pageSize,
            (page - 1) * pageSize
          ]);

      final list = maps.map((row) => Exercise.fromMap(row)).toList();
      print(
          "queryExerciseByKeyword---keyword $keyword-pageSize $pageSize-page $page-");
      print("----$list");

      // 获取满足查询条件的数据总量
      int? totalCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${TrainingDdl.tableNameOfExercise} '
          'WHERE exercise_code LIKE ? OR exercise_name LIKE ?',
          ['%$keyword%', '%$keyword%'],
        ),
      );

      temp.data = list;
      temp.total = totalCount ?? 0;
    } catch (e) {
      // Handle the error
      print('Error inserting food with serving info: $e');
      // 抛出异常来触发回滚的方式是 sqflite 中常用的做法
      rethrow;
    }

    return temp;
  }

  // 指定栏位查询
  Future<List<Exercise>> queryExercise({
    int? exerciseId,
    String? exerciseCode,
    String? exerciseName,
    String? force,
    String? level,
    String? mechanic,
    String? equipment,
    String? category,
    String? primaryMuscle, // 都只有单个
    required int pageSize, // 一次查询条数显示
    required int page, // 一次查询的偏移量，用于分页
  }) async {
    Database db = await database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    final conditions = {
      'exercise_id': exerciseId,
      'exercise_code': exerciseCode,
      'exercise_name': exerciseName,
      'force': force,
      'level': level,
      'mechanic': mechanic,
      'equipment': equipment,
      'category': category,
    };

    conditions.forEach((key, value) {
      if (value != null) {
        whereClauses.add('$key = ?');
        whereArgs.add(value);
      }
    });

    if (primaryMuscle != null) {
      whereClauses.add('primary_muscles LIKE ?');
      whereArgs.add('%$primaryMuscle%');
    }

    final whereClause =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    var sql = 'SELECT * FROM ${TrainingDdl.tableNameOfExercise} $whereClause';

    sql += ' LIMIT $pageSize';
    sql += ' OFFSET ${(page - 1) * pageSize}';

    print("exercise条件查询的sql语句：$sql");

    List<Map<String, dynamic>> maps = await db.rawQuery(sql, whereArgs);

    print(maps);

    final list = maps.map((row) => Exercise.fromMap(row)).toList();

    print(list);

    return list;
  }

  ///----------------------- group and action

  // 插入单条训练
  // 因为新增group没有给主键，而主键是自增的，所以这里返回的row id就是新增主键的group_id
  Future<int> insertTrainingGroup(TrainingGroup group) async {
    Database db = await database;
    var result = await db.insert(
      TrainingDdl.tableNameOfGroup,
      group.toMap(),
    );
    return result;
  }

  // 查询指定训练以及其所有动作
  // 训练支持条件查询，估计训练的数量不会多，就暂时不分页；同事关联的动作就全部带出。
  Future<List<GroupWithActions>> searchGroupWithActions({
    int? groupId,
    String? groupName, // 模糊查询
    String? groupCategory, // 分类和级别最好是下拉选择的结果，用精确查询
    String? groupLevel,
  }) async {
    final db = await database;

    var where = [];
    var whereArgs = [];

    if (groupId != null) {
      where.add("group_id =? ");
      whereArgs.add(groupId);
    }
    if (groupName != null) {
      where.add("group_name  like ? ");
      whereArgs.add("%$groupName%");
    }
    if (groupCategory != null) {
      where.add("group_category =? ");
      whereArgs.add(groupCategory);
    }
    if (groupLevel != null) {
      where.add("group_level =? ");
      whereArgs.add(groupLevel);
    }

    List<Map<String, Object?>> groupRows;

    if (where.isEmpty) {
      groupRows = await db.query(TrainingDdl.tableNameOfGroup);
    } else {
      groupRows = await db.query(
        TrainingDdl.tableNameOfGroup,
        where: where.join(" AND "),
        whereArgs: whereArgs,
      );
    }

    final list = <GroupWithActions>[];

    for (final row in groupRows) {
      final group = TrainingGroup.fromMap(row);
      final actionRows = await db.query(
        TrainingDdl.tableNameOfAction,
        where: 'group_id = ?',
        whereArgs: [group.groupId],
      );

      final adList = <ActionDetail>[];

      for (final r in actionRows) {
        final action = TrainingAction.fromMap(r);
        final exerciseRows = await db.query(
          TrainingDdl.tableNameOfExercise,
          where: 'exercise_id = ?',
          whereArgs: [action.exerciseId],
        );

        // ？？？理论上这里只有查到1个exercise，且不应该差不多(暂不考虑异常情况)
        var ad = ActionDetail(
          action: action,
          exercise: Exercise.fromMap(exerciseRows[0]),
        );

        adList.add(ad);
      }
      final gas = GroupWithActions(group: group, actionDetailList: adList);

      list.add(gas);
    }

    log.d("searchAllGroupWithActions---$list");
    return list;
  }

  // 插入动作组（单条也当数组插入）
  Future<List<Object?>> insertTrainingActionList(
    List<TrainingAction> actionList,
  ) async {
    Database db = await database;

    var batch = db.batch();
    for (var item in actionList) {
      batch.insert(TrainingDdl.tableNameOfAction, item.toMap());
    }

    var results = await batch.commit();

    return results;
  }

  // 更新指定训练的所有动作(删除所有已有的，新增传入的)
  Future<List<Object?>> renewGroupWithActionsList(
    int groupId,
    List<TrainingAction> actionList,
  ) async {
    Database db = await database;

    List<Object?> rst = [];

    await db.transaction((txn) async {
      await txn.delete(
        TrainingDdl.tableNameOfAction,
        where: "group_id =? ",
        whereArgs: [groupId],
      );

      var batch = txn.batch();
      for (var item in actionList) {
        batch.insert(TrainingDdl.tableNameOfAction, item.toMap());
      }

      rst = await batch.commit();
    });

    return rst;
  }

  Future<List<GroupWithActions>> searchAllGroupWithActions2({
    int? groupId,
    String? groupName,
    String? groupCategory,
    String? groupLevel,
  }) async {
    final db = await database;

    final whereList = <String>[];
    final whereArgs = <dynamic>[];

    if (groupId != null) {
      whereList.add("group_id = ?");
      whereArgs.add(groupId);
    }
    if (groupName != null) {
      whereList.add("group_name  like ?");
      whereArgs.add("%$groupName%");
    }
    if (groupCategory != null) {
      whereList.add("group_category = ?");
      whereArgs.add(groupCategory);
    }
    if (groupLevel != null) {
      whereList.add("group_level = ?");
      whereArgs.add(groupLevel);
    }

    final whereClause = whereList.isEmpty ? null : whereList.join(" AND ");

    final groupRows = await db.query(
      TrainingDdl.ddlForGroup,
      where: whereClause,
      whereArgs: whereClause == null ? null : whereArgs,
    );

    final list = <GroupWithActions>[];

    await Future.forEach(groupRows, (row) async {
      final group = TrainingGroup.fromMap(row);
      final actionRows = await db.query(
        TrainingDdl.tableNameOfAction,
        where: 'group_id = ?',
        whereArgs: [group.groupId],
      );

      final adList = <ActionDetail>[];

      await Future.forEach(actionRows, (r) async {
        final action = TrainingAction.fromMap(r);
        final exerciseRow = await db.query(
          TrainingDdl.tableNameOfExercise,
          where: 'exercise_id = ?',
          whereArgs: [action.exerciseId],
        );
        var ad = ActionDetail(
          action: action,
          exercise: Exercise.fromMap(exerciseRow[0]),
        );
        adList.add(ad);
      });

      final gas = GroupWithActions(group: group, actionDetailList: adList);
      list.add(gas);
    });

    return list;
  }

  ///----------------------- plan and group
  /// 插入单个计划基本信息
  Future<int> insertTrainingPlan(TrainingPlan plan) async {
    Database db = await database;
    var result = await db.insert(
      TrainingDdl.tableNameOfPlan,
      plan.toMap(),
    );
    return result;
  }

  /// 插入计划的每天的训练数据(插入plan has group 表)
  Future<List<Object?>> insertTrainingGroupList(
    List<PlanHasGroup> phgList,
  ) async {
    Database db = await database;

    var batch = db.batch();
    for (var item in phgList) {
      batch.insert(TrainingDdl.tableNameOfPlanHasGroup, item.toMap());
    }

    var results = await batch.commit();

    return results;
  }

  // 插入动作组（单条也当数组插入）
  Future<List<Object?>> insertPlanHasGroupList(
    List<PlanHasGroup> phgList,
  ) async {
    Database db = await database;

    var batch = db.batch();
    for (var item in phgList) {
      batch.insert(TrainingDdl.tableNameOfPlanHasGroup, item.toMap());
    }

    var results = await batch.commit();

    return results;
  }

  /// ？？？查询指定计划以及其所有训练（3层嵌套，看怎么优化）
  // 计划支持条件查询，估计计划的数量不会多，就暂时不分页；同时关联的训练就全部带出。
  Future<List<PlanWithGroups>> searchPlanWithGroups({
    int? planId,
    String? planName, // 模糊查询
    String? planCode, // 模糊查询
    String? planCategory, // 分类和级别最好是下拉选择的结果，用精确查询
    String? planLevel,
  }) async {
    final db = await database;

    var where = [];
    var whereArgs = [];

    if (planId != null) {
      where.add("plan_id =? ");
      whereArgs.add(planId);
    }
    if (planName != null) {
      where.add("plan_ame like ? ");
      whereArgs.add("%$planName%");
    }
    if (planCategory != null) {
      where.add("plan_category =? ");
      whereArgs.add(planCategory);
    }
    if (planLevel != null) {
      where.add("plan_level = ? ");
      whereArgs.add(planLevel);
    }

    List<Map<String, Object?>> planRows;

    if (where.isEmpty) {
      planRows = await db.query(TrainingDdl.tableNameOfPlan);
    } else {
      planRows = await db.query(
        TrainingDdl.tableNameOfPlan,
        where: where.join(" AND "),
        whereArgs: whereArgs,
      );
    }

    final pwgList = <PlanWithGroups>[];

    for (final row in planRows) {
      // 计划有了
      final plan = TrainingPlan.fromMap(row);

      final planHasGroupRows = await db.query(
        TrainingDdl.tableNameOfPlanHasGroup,
        where: 'plan_id = ?',
        whereArgs: [plan.planId],
      );

      final gwaList = <GroupWithActions>[];

      // 构建groupWithActions实例
      for (final phg in planHasGroupRows) {
        print("----------gggggggggg$phg");

        // 先通过id查到指定group，再巩固group查询包含的action

        final planHasGroup = PlanHasGroup.fromMap(phg);

        // ？？？理论上是有且只有1个，不会为空
        var tempGroupRows = await db.query(
          TrainingDdl.tableNameOfGroup,
          where: 'group_id = ?',
          whereArgs: [planHasGroup.groupId],
        );
        final group = TrainingGroup.fromMap(tempGroupRows[0]);

        final actionRows = await db.query(
          TrainingDdl.tableNameOfAction,
          where: 'group_id = ?',
          whereArgs: [group.groupId],
        );

        final adList = <ActionDetail>[];
        // 构建actionDetail 实例
        for (final a in actionRows) {
          final action = TrainingAction.fromMap(a);
          final exerciseRows = await db.query(
            TrainingDdl.tableNameOfExercise,
            where: 'exercise_id = ?',
            whereArgs: [action.exerciseId],
          );

          // ？？？理论上这里只有查到1个exercise，且不应该差不多(暂不考虑异常情况)
          var ad = ActionDetail(
            action: action,
            exercise: Exercise.fromMap(exerciseRows[0]),
          );

          adList.add(ad);
        }

        var ga = GroupWithActions(
          group: group,
          actionDetailList: adList,
        );
        gwaList.add(ga);
      }

      final gas = PlanWithGroups(plan: plan, groupDetailList: gwaList);

      pwgList.add(gas);
    }

    log.d("searchPlanWithGroups---$pwgList");
    return pwgList;
  }

  // 更新指定训练的所有动作(删除所有已有的，新增传入的)
  Future<List<Object?>> renewPlanWithGroupList(
    int planId,
    List<PlanHasGroup> phgList,
  ) async {
    Database db = await database;

    List<Object?> rst = [];

    await db.transaction((txn) async {
      await txn.delete(
        TrainingDdl.tableNameOfPlanHasGroup,
        where: "plan_id = ? ",
        whereArgs: [planId],
      );

      var batch = txn.batch();
      for (var item in phgList) {
        batch.insert(TrainingDdl.tableNameOfPlanHasGroup, item.toMap());
      }

      rst = await batch.commit();
    });

    return rst;
  }
}

class DBDietaryHelper {
  static final DBDietaryHelper _dbHelper = DBDietaryHelper._createInstance();
  static Database? _database;
  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dietaryDbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBDietaryHelper._createInstance();

  factory DBDietaryHelper() => _dbHelper;

  Future<Database> get database async =>
      _database ??= await initializeDatabase();

  // 初始化数据库
  Future<Database> initializeDatabase() async {
    // 获取Android和iOS存储数据库的目录路径。
    Directory? directory = await getExternalStorageDirectory();
    String path = "${directory?.path}/${DietaryDdl.databaseName}";

    print("初始化 DIETARY sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var db = await openDatabase(path, version: 1, onCreate: _createDb);

    dietaryDbFilePath = path;

    return db;
  }

  // 创建训练数据库相关表
  void _createDb(Database db, int newVersion) async {
    print("开始创建表 _createDb……");
    await db.execute(DietaryDdl.ddlForFood);
    await db.execute(DietaryDdl.ddlForServingInfo);
    await db.execute(DietaryDdl.ddlForDailyFoodItem);
    await db.execute(DietaryDdl.ddlForDietaryUser);
    await db.execute(DietaryDdl.ddlForIntakeDailyGoal);
  }

  // 关闭数据库
  Future<bool> closeDatabase() async {
    Database db = await database;

    print("Dietary db.isOpen ${db.isOpen}");
    await db.close();
    print("Dietary db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    if (!db.isOpen) {
      return true;
    } else {
      return false;
    }
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  void deleteDb() async {
    var tempPath =
        "/storage/emulated/0/Android/data/com.example.free_fitness/files/embedded_dietary.db";

    // ？？？这里删除dietaryDbFilePath 没效果？？？
    print("开始删除內嵌的 sqlite Dietary db文件，db文件地址：$tempPath");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://stackoverflow.com/questions/60848752/delete-database-when-log-out-and-create-again-after-log-in-dart
    _database = null;

    await deleteDatabase(tempPath);
  }

// 显示db中已有的table，默认的和自建立的
  void showTableNameList() async {
    Database db = await database;
    var tableNames = (await db
            .query('sqlite_master', where: 'type = ?', whereArgs: ['table']))
        .map((row) => row['name'] as String)
        .toList(growable: false);

    // for (var row
    //     in (await db.query('sqlite_master', columns: ['type', 'name']))) {
    //   print(row.values);
    // }

    print("------------Dietary");
    print(tableNames);
    print("------------Dietary");
  }

  ///
  /// 食物基本表的相关操作
  ///  实际使用时，新增食物一定会级联带上新增单份食物营养素信息
  ///  insertFoodWithServingInfo
  ///  updateFoodWithServingInfo
  /// selectFoodBasic  一般是查看拥有的食物，通过品牌或产品类型的关键字查询时
  /// selectFoodDetail 会带上详情，一般查看food详情时用

  ///
  ///
  // 插入单条食物
  // 如果食物为空，servinginfo不为空，说明是给以存在的食物添加单份营养素
  // 如果食物不为空，servinginfo为空，说明是单独新增食物（正常业务应该不会，新增食物一定会带一份营养素）
  // 如果食物不为空，servinginfo不为空，说明是正常的新增食物带一份营养素
  // 如果都为空，则报错
  // ？？？ 2023-10-30 应该支持1个食物带多份营养素信息（ServingInfo? -> List<ServingInfo>?即可）
  Future<int> insertFoodWithServingInfoList({
    Food? food,
    List<ServingInfo>? servingInfoList,
  }) async {
    final db = await database;
    int foodId = 0;
    try {
      await db.transaction((txn) async {
        // 如果有传入的食物信息，说明是在新增食物时一并新增其营养素
        if (food != null &&
            (servingInfoList != null && servingInfoList.isNotEmpty)) {
          // 由于food_id列被设置为自增属性的主键，因此在调用insert方法时，返回值应该是新插入行的food_id值。
          // 如果不是自增主键，则返回的是行号row 的id。
          foodId = await txn.insert(DietaryDdl.tableNameOfFood, food.toMap());

          // 多个单个营养素的食物都是同一个
          for (var e in servingInfoList) {
            e.foodId = foodId;
            await txn.insert(DietaryDdl.tableNameOfServingInfo, e.toMap());
          }
        } else if (food != null && servingInfoList == null) {
          // 如果只有食物，则是新增食物
          foodId = await txn.insert(DietaryDdl.tableNameOfFood, food.toMap());
        } else if (food == null && servingInfoList != null) {
          //如果没有传食物，是已存在的食物编号，则直接新增serving info即可

          // 多个单个营养素的批量插入
          for (var e in servingInfoList) {
            txn.insert(DietaryDdl.tableNameOfServingInfo, e.toMap());
          }
        } else {
          throw Exception("没有传入food id或serving info");
        }
      });
    } catch (e) {
      // Handle the error
      print('Error inserting food with serving info: $e');
      // 抛出异常来触发回滚的方式是 sqflite 中常用的做法
      rethrow;
    }

    return foodId; // 返回成功插入的食品信息 ID
  }

  Future<void> updateFoodWithServingInfo(
      Food food, ServingInfo servingInfo) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        // Update food info
        await txn.update(
          DietaryDdl.tableNameOfFood,
          food.toMap(),
          where: 'food_id = ?',
          whereArgs: [food.foodId],
        );

        // Update serving info associated with the food
        await txn.update(
          DietaryDdl.tableNameOfServingInfo,
          servingInfo.toMap(),
          where: 'food_id = ?',
          whereArgs: [food.foodId],
        );
      });
    } catch (e) {
      // Handle the error
      print('Error updating food with serving info: $e');
      rethrow;
    }
  }

  // 删除单条数据
  Future<void> deleteFoodWithServingInfo(int foodId) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        // Delete serving info associated with the food
        await txn.delete(
          DietaryDdl.tableNameOfServingInfo,
          where: 'food_id = ?',
          whereArgs: [foodId],
        );

        // Delete the food
        await txn.delete(
          DietaryDdl.tableNameOfFood,
          where: 'food_id = ?',
          whereArgs: [foodId],
        );
      });
    } catch (e) {
      // Handle the error
      print('Error deleting food with serving info: $e');
      rethrow;
    }
  }

  // 关键字查询食物及其不同单份食物营养素
  Future<List<FoodAndServingInfo>> searchFoodWithServingInfoWithPagination(
    String keyword,
    int page,
    int pageSize,
  ) async {
    print("进入了searchFoodWithServingInfoWithPagination……");

    final db = await database;
    final offset = (page - 1) * pageSize;

    final foodRows = await db.query(
      DietaryDdl.tableNameOfFood,
      where: 'brand LIKE ? OR product LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      limit: pageSize,
      offset: offset,
    );

    final foods = <FoodAndServingInfo>[];

    for (final row in foodRows) {
      final food = Food.fromMap(row);
      final servingInfoRows = await db.query(
        DietaryDdl.tableNameOfServingInfo,
        where: 'food_id = ?',
        whereArgs: [food.foodId],
      );

      print("--------------servingInfoRows:");
      print(servingInfoRows);

      final servingInfoList =
          servingInfoRows.map((row) => ServingInfo.fromMap(row)).toList();
      final foodAndServingInfo =
          FoodAndServingInfo(food: food, servingInfoList: servingInfoList);
      foods.add(foodAndServingInfo);
    }
    return foods;
  }

  // 像在daily log首页等地方可能需要只是单条的food id查询食物和营养素信息
  Future<FoodAndServingInfo?> searchFoodWithServingInfoByFoodId(
    int foodId,
  ) async {
    print("进入了 searchFoodWithServingInfoByFoodId ……");

    final db = await database;

    // 正常来讲，通过food id要么查到一条，要么查不到，所以只返回一个
    final foodRows = await db.query(
      DietaryDdl.tableNameOfFood,
      where: 'food_id = ?',
      whereArgs: [foodId],
    );

    if (foodRows.isEmpty) {
      return null;
    } else {
      final food = Food.fromMap(foodRows[0]);

      final servingInfoRows = await db.query(
        DietaryDdl.tableNameOfServingInfo,
        where: 'food_id = ?',
        whereArgs: [food.foodId],
      );

      final servingInfoList = servingInfoRows
          .map(
            (row) => ServingInfo.fromMap(row),
          )
          .toList();

      final foodAndServingInfo = FoodAndServingInfo(
        food: food,
        servingInfoList: servingInfoList,
      );
      return foodAndServingInfo;
    }
  }

  Future<Food> queryFoodById(Database db, int foodId) async {
    final foodRows = await db.query(
      DietaryDdl.tableNameOfFood,
      where: 'food_id = ?',
      whereArgs: [foodId],
    );

    final foodList = foodRows.map((row) => Food.fromMap(row)).toList();

    return foodList[0];
  }

  Future<ServingInfo> queryServingInfoById(
      Database db, int servingInfoId) async {
    final servingInfoRows = await db.query(
      DietaryDdl.tableNameOfServingInfo,
      where: 'serving_info_id = ?',
      whereArgs: [servingInfoId],
    );

    final servingInfoList =
        servingInfoRows.map((row) => ServingInfo.fromMap(row)).toList();

    return servingInfoList[0];
  }

  // 插入饮食日记条目( daily_food_item 一般一次性插入多条，有单条的，也放到list)
  Future<List<Object?>> insertDailyFoodItemList(
    List<DailyFoodItem> dfiList,
  ) async {
    Database db = await database;

    var batch = db.batch();
    for (var item in dfiList) {
      batch.insert(DietaryDdl.tableNameOfDailyFoodItem, item.toMap());
    }

    var results = await batch.commit();

    return results;
  }

  // 修改单条 daily_food_item
  Future<int> updateDailyFoodItem(DailyFoodItem dailyFoodItem) async {
    Database db = await database;

    var result = await db.update(
      DietaryDdl.tableNameOfDailyFoodItem,
      dailyFoodItem.toMap(),
      where: 'daily_food_item_id = ?',
      whereArgs: [dailyFoodItem.dailyFoodItemId],
    );

    print("updateDailyFoodItem--------的返回 $result $dailyFoodItem");
    return result;
  }

  // 删除单条 daily_food_item
  Future<int> deleteDailyFoodItem(int dailyFoodItemId) async {
    Database db = await database;
    var result = await db.delete(
      DietaryDdl.tableNameOfDailyFoodItem,
      where: "daily_food_item_id=?",
      whereArgs: [dailyFoodItemId],
    );
    return result;
  }

  // 条件查询日记条目 daily_food_item
  // 支持日期区间，当日的起止都是同一个，使用字符串比较，所以字符串传入的格式要都一致（YYYY-MM-DD）
  // 不需要分页，后续即便是导出月度、年度数据，都是一次性所有，然后再格式化展示
  Future<List<DailyFoodItem>> queryDailyFoodItemList({
    int? dailyFoodItemId,
    String? startDate,
    String? endDate,
    String? mealCategory,
  }) async {
    Database db = await database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (dailyFoodItemId != null) {
      whereClauses.add('daily_food_item_id = ?');
      whereArgs.add(dailyFoodItemId);
    }

    if (mealCategory != null) {
      whereClauses.add('meal_category = ?');
      whereArgs.add(mealCategory);
    }

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate);
    }

    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate);
    }

    final whereClause =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : '';

    final List<Map<String, dynamic>> maps = await db.query(
      DietaryDdl.tableNameOfDailyFoodItem,
      where: whereClause,
      whereArgs: whereArgs,
    );

    final List<DailyFoodItem> list =
        maps.map((row) => DailyFoodItem.fromMap(row)).toList();

    return list;
  }

// 条件查询日记条目，但food和serving info 详情
// 查询结果展示时，会更多用到对应的food和serving info的具体数值
  Future<List<DailyFoodItemWithFoodServing>> queryDailyFoodItemListWithDetail({
    int? dailyFoodItemId,
    String? startDate,
    String? endDate,
    String? mealCategory,
  }) async {
    Database db = await database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (dailyFoodItemId != null) {
      whereClauses.add('daily_food_item_id = ?');
      whereArgs.add(dailyFoodItemId);
    }

    if (mealCategory != null) {
      whereClauses.add('meal_category = ?');
      whereArgs.add(mealCategory);
    }

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate);
    }

    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate);
    }

    final whereClause =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : '';

    final dfiRows = await db.query(
      DietaryDdl.tableNameOfDailyFoodItem,
      where: whereClause,
      whereArgs: whereArgs,
    );

    // 如果有查询到日记条目，查询对应的食物和营养素详情
    final List<DailyFoodItem> list =
        dfiRows.map((row) => DailyFoodItem.fromMap(row)).toList();

    // 用来存要放回的饮食日记条目详情
    final dfiwfsList = <DailyFoodItemWithFoodServing>[];

    if (list.isEmpty) {
      return [];
    } else {
      for (var dailyFoodItem in list) {
        // ？？？当天日记条目的食物和营养素通过id查询都应该只有一条，数据正确的话也不会为空，所以不做检查
        final foodRows = await db.query(
          DietaryDdl.tableNameOfFood,
          where: 'food_id = ?',
          whereArgs: [dailyFoodItem.foodId],
        );
        final food = Food.fromMap(foodRows[0]);

        final servingInfoRows = await db.query(
          DietaryDdl.tableNameOfServingInfo,
          where: 'serving_info_id = ?',
          whereArgs: [dailyFoodItem.servingInfoId],
        );
        final servingInfo = ServingInfo.fromMap(servingInfoRows[0]);

        final dfiwfs = DailyFoodItemWithFoodServing(
          dailyFoodItem: dailyFoodItem,
          food: food,
          servingInfo: servingInfo,
        );

        dfiwfsList.add(dfiwfs);
      }
    }

    return dfiwfsList;
  }

  // 查询用户
  // ？？？现在就是显示登录用户信息，用户密码登录成功之后记住信息？(缓存还不太懂，这里就账号密码id查询)
  Future<DietaryUser> queryDietaryUser({
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
      DietaryDdl.tableNameOfDietaryUser,
      where: where.isNotEmpty ? where.join(" AND ") : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    final userlist = userRows.map((row) => DietaryUser.fromMap(row)).toList();

    return userlist[0];
  }

  // 批量插入用户(有单条的，也放到list)
  Future<List<Object?>> insertDietaryUserList(
    List<DietaryUser> userList,
  ) async {
    Database db = await database;

    var batch = db.batch();
    for (var item in userList) {
      batch.insert(DietaryDdl.tableNameOfDietaryUser, item.toMap());
    }

    var results = await batch.commit();

    return results;
  }

  // 修改单条 dietaryUser
  Future<int> updateDietaryUser(DietaryUser user) async {
    Database db = await database;

    var result = await db.update(
      DietaryDdl.tableNameOfDietaryUser,
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );

    print("updateDietaryUser--------的返回 $result $user");
    return result;
  }

  // 删除单条 dietaryUser
  Future<int> deleteDietaryUser(int userId) async {
    Database db = await database;
    var result = await db.delete(
      DietaryDdl.tableNameOfDietaryUser,
      where: "user_id = ?",
      whereArgs: [userId],
    );
    return result;
  }

  // 查询用户带上每周具体摄入目标
  // ？？？现在就是显示登录用户信息，用户密码登录成功之后记住信息？(缓存还不太懂，这里就账号密码id查询)
  Future<DietaryUserWithIntakeDailyGoal> queryDietaryUserWithIntakeGoal({
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
      DietaryDdl.tableNameOfDietaryUser,
      where: where.isNotEmpty ? where.join(" AND ") : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    final userlist = userRows.map((row) => DietaryUser.fromMap(row)).toList();

    final intakeGoalRows = await db.query(
      DietaryDdl.tableNameOfIntakeDailyGoal,
      where: "user_id = ? ",
      whereArgs: [userlist[0].userId],
    );

    List<IntakeDailyGoal> goals =
        intakeGoalRows.map((row) => IntakeDailyGoal.fromMap(row)).toList();

    DietaryUserWithIntakeDailyGoal temp =
        DietaryUserWithIntakeDailyGoal(goals: goals, user: userlist[0]);

    return temp;
  }

  // 修改用户的周摄入宏量素目标
  Future<int> updateUserIntakeDailyGoal(List<IntakeDailyGoal> goals) async {
    Database db = await database;

    int rst = 0;

    try {
      await db.transaction((txn) async {
        for (var goal in goals) {
          List<Map<String, dynamic>> result = await txn.query(
            DietaryDdl.tableNameOfIntakeDailyGoal,
            where: 'user_id = ? and day_of_week = ?',
            whereArgs: [goal.userId, goal.dayOfWeek],
          );
          // 如果已存在，指定用户指定周几的目标值只有1条数据才对
          if (result.isNotEmpty) {
            print(
                "updateUserIntakeDailyGoal-------$result 修改已存在 ${goal.toMap()}");

            var existed = IntakeDailyGoal.fromMap(result[0]);
            goal.intakeDailyGoalId = existed.intakeDailyGoalId;

            rst = await txn.update(
              DietaryDdl.tableNameOfIntakeDailyGoal,
              goal.toMap(),
              where: 'user_id = ? and day_of_week = ?',
              whereArgs: [goal.userId, goal.dayOfWeek],
            );
          } else {
            print("updateUserIntakeDailyGoal-------新增不存在");
            rst = await txn.insert(
              DietaryDdl.tableNameOfIntakeDailyGoal,
              goal.toMap(),
            );
          }
        }
      });
    } catch (e) {
      // Handle the error
      print('Error inserting food with serving info: $e');
      // 抛出异常来触发回滚的方式是 sqflite 中常用的做法
      rethrow;
    }
    return rst;
  }
}

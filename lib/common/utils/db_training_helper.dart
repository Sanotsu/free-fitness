// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/training_state.dart';
import '../global/constants.dart';
import 'ddl_training.dart';

class DBTrainingHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBTrainingHelper _dbHelper = DBTrainingHelper._createInstance();
  // 构造函数，返回单例
  factory DBTrainingHelper() => _dbHelper;

  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 过长的字符串无法打印显示完，默认的developer库的log有时候没效果
  var log = Logger();

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBTrainingHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取Android和iOS存储数据库的目录路径(用户看不到，在Android/data/……里看不到)。
    // Directory directory = await getApplicationDocumentsDirectory();
    // String path = "${directory.path}/${TrainingDdl.databaseName}";

    // IOS不支持这个方法，所以可能取不到这个地址
    Directory? directory2 = await getExternalStorageDirectory();
    String path = "${directory2?.path}/${TrainingDdl.databaseName}";

    print("初始化 TRAINING sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var trainingDb = await openDatabase(path, version: 1, onCreate: createDB);
    dbFilePath = path;
    return trainingDb;
  }

  // 创建训练数据库相关表
  void createDB(Database db, int newVersion) async {
    await db.transaction((txn) async {
      txn.execute(TrainingDdl.ddlForExercise);
      txn.execute(TrainingDdl.ddlForAction);
      txn.execute(TrainingDdl.ddlForGroup);
      txn.execute(TrainingDdl.ddlForPlan);
      txn.execute(TrainingDdl.ddlForPlanHasGroup);
      txn.execute(TrainingDdl.ddlForTrainedDetailLog);
    });
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("training db isOpen ${db.isOpen}");
    await db.close();
    print("training db isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  Future<void> deleteDB() async {
    print("开始删除內嵌的sqlite db文件，db文件地址：$dbFilePath");

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(dbFilePath);

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

    print("TrainingDB中拥有的表名:------------");
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
  /// 动作库基础表 exercise 的相关操作
  ///

  // 插入单条数据(返回exercise_id)
  Future<int> insertExercise(Exercise exercise) async =>
      (await database).insert(
        TrainingDdl.tableNameOfExercise,
        exercise.toMap(),
      );

  Future<int> insertExerciseThrowError(Exercise exercise) async {
    final db = await database;
    try {
      return await db.insert(
        TrainingDdl.tableNameOfExercise,
        exercise.toMap(),
      );
    } on DatabaseException catch (e) {
      // 唯一值重复
      if (e.isUniqueConstraintError()) {
        // 抛出自定义异常并携带错误信息
        throw Exception(
          '该动作代号或名称已存在:\n ${exercise.exerciseCode} - ${exercise.exerciseName}',
        );
      } else if (e.isDuplicateColumnError()) {
        // 抛出自定义异常并携带错误信息
        throw Exception(
          '该动作重复:\n ${exercise.exerciseId}-${exercise.exerciseCode} - ${exercise.exerciseName}',
        );
      } else {
        // 其他错误(抛出异常来触发回滚的方式是 sqflite 中常用的做法)
        rethrow;
      }
    }
  }

  Future<List<Object?>> insertExerciseList(List<Exercise> exercises) async {
    var batch = (await database).batch();

    for (var item in exercises) {
      batch.insert(TrainingDdl.tableNameOfExercise, item.toMap());
    }

    return batch.commit();
  }

  // 修改单条数据
  Future<int> updateExercise(Exercise exercise) async =>
      (await database).update(
        TrainingDdl.tableNameOfExercise,
        exercise.toMap(),
        where: 'exercise_id = ?',
        whereArgs: [exercise.exerciseId],
      );

  // 删除单条数据
  Future<int> deleteExerciseById(int id) async =>
      (await database).delete(TrainingDdl.tableNameOfExercise,
          where: "exercise_id=?", whereArgs: [id]);

  // 通过编号查询单条数据(返回exercise_id)
  Future<Exercise> queryExerciseById(int id) async =>
      Exercise.fromMap((await (await database).query(
        TrainingDdl.tableNameOfExercise,
        where: 'exercise_id = ? ',
        whereArgs: [id],
      ))
          .first);

  // 关键字模糊查询基础活动
  Future<CusDataResult> queryExerciseByKeyword({
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
        TrainingDdl.tableNameOfExercise,
        where: 'exercise_code LIKE ? OR exercise_name LIKE ? LIMIT ? OFFSET ?',
        whereArgs: ['%$keyword%', '%$keyword%', pageSize, offset],
      );
      final list = maps.map((row) => Exercise.fromMap(row)).toList();

      // 获取满足查询条件的数据总量
      int? totalCount = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${TrainingDdl.tableNameOfExercise} '
          'WHERE exercise_code LIKE ? OR exercise_name LIKE ?',
          ['%$keyword%', '%$keyword%'],
        ),
      );

      // 查询每页指定数量的数据，但带上总条数
      return CusDataResult(data: list, total: totalCount ?? 0);
    } catch (e) {
      print('Error at queryExerciseByKeyword: $e');
      // 抛出异常来触发回滚的方式是 sqflite 中常用的做法
      rethrow;
    }
  }

  // 指定栏位查询基础运动
  Future<CusDataResult> queryExercise({
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
    required int page, // 页码，用于分页
  }) async {
    Database db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    // 这些条件是准确查询
    final conditions = {
      'exercise_id': exerciseId,
      // 'exercise_code': exerciseCode,
      // 'exercise_name': exerciseName,
      'force': force,
      'level': level,
      'mechanic': mechanic,
      'equipment': equipment,
      'category': category,
    };

    // 一般的条件是精确查询
    conditions.forEach((key, value) {
      if (value != null) {
        where.add('$key = ?');
        whereArgs.add(value);
      }
    });

    // 代号、名称、肌肉都是模糊查询
    if (exerciseCode != null) {
      where.add('exercise_code LIKE ? OR exercise_name LIKE ? ');
      whereArgs.add('%$exerciseCode%');
      whereArgs.add('%$exerciseCode%');
    }

    if (exerciseName != null) {
      where.add('exercise_code LIKE ? OR exercise_name LIKE ? ');
      whereArgs.add('%$exerciseName%');
      whereArgs.add('%$exerciseName%');
    }

    if (primaryMuscle != null) {
      where.add('primary_muscles LIKE ?');
      whereArgs.add('%$primaryMuscle%');
    }

    List<Map<String, dynamic>> maps = await db.query(
      TrainingDdl.tableNameOfExercise,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: pageSize,
      offset: (page - 1) * pageSize,
    );

    // 数据是分页查询的，但这里带上满足条件的一共多少条
    String sql = 'SELECT COUNT(*) FROM ${TrainingDdl.tableNameOfExercise}';
    if (where.isNotEmpty) {
      sql += ' WHERE ${where.join(' AND ')}';
    }

    print(sql);
    print("whereArgs $whereArgs");

    int totalCount =
        Sqflite.firstIntValue(await db.rawQuery(sql, whereArgs)) ?? 0;

    print('Total count: $totalCount');

    final list = maps.map((row) => Exercise.fromMap(row)).toList();

    // 返回时数据列表(使用时先转型)和总数
    return CusDataResult(data: list, total: totalCount);
  }

  ///***********************************************/
  ///   group and action 的相关操作
  ///

  // 插入单条训练
  // 因为新增group没有给主键，而主键是自增的，所以这里返回的row id就是新增主键的group_id
  Future<int> insertTrainingGroup(TrainingGroup group) async =>
      (await database).insert(TrainingDdl.tableNameOfGroup, group.toMap());

  Future<List<Object?>> insertTrainingGroupList(
    List<TrainingGroup> tgList,
  ) async {
    var batch = (await database).batch();
    for (var item in tgList) {
      batch.insert(TrainingDdl.tableNameOfGroup, item.toMap());
    }
    return batch.commit();
  }

// 修改指定训练基本信息（指定id修改）
  Future<int> updateTrainingGroup(int groupId, TrainingGroup group) async =>
      (await database).update(
        TrainingDdl.tableNameOfGroup,
        group.toMap(),
        where: "group_id = ? ",
        whereArgs: [groupId],
      );

  // 删除单条训练(同时需要删除其所有的action)
  Future<dynamic> deleteGroupById(int groupId) async {
    final db = await database;

    try {
      return await db.transaction((txn) async {
        await txn.delete(
          TrainingDdl.tableNameOfGroup,
          where: 'group_id = ?',
          whereArgs: [groupId],
        );

        await txn.delete(
          TrainingDdl.tableNameOfAction,
          where: 'group_id = ?',
          whereArgs: [groupId],
        );
      });
    } catch (e) {
      throw Exception("删除指定训练及其动作失败: $e");
    }
  }

  // 删除单条训练(同时需要删除其所有的plan has group 关系。group有复用，不会删除)
  Future<dynamic> deletePlanById(int planId) async {
    final db = await database;

    try {
      return await db.transaction((txn) async {
        await txn.delete(
          TrainingDdl.tableNameOfPlan,
          where: 'plan_id = ?',
          whereArgs: [planId],
        );

        await txn.delete(
          TrainingDdl.tableNameOfPlanHasGroup,
          where: 'plan_id = ?',
          whereArgs: [planId],
        );
      });
    } catch (e) {
      throw Exception("删除指定计划及其训练组失败: $e");
    }
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
      where.add("group_name LIKE ? ");
      whereArgs.add("%$groupName%");
    }
    if (groupCategory != null) {
      where.add("group_category = ? ");
      whereArgs.add(groupCategory);
    }
    if (groupLevel != null) {
      where.add("group_level = ? ");
      whereArgs.add(groupLevel);
    }

    final List<Map<String, dynamic>> groupRows = where.isEmpty
        ? await db.query(TrainingDdl.tableNameOfGroup)
        : await db.query(
            TrainingDdl.tableNameOfGroup,
            where: where.join(' AND '),
            whereArgs: whereArgs,
          );

    final list = <GroupWithActions>[];

    for (final row in groupRows) {
      final group = TrainingGroup.fromMap(row);
      final actionRows = await db.query(
        TrainingDdl.tableNameOfAction,
        where: 'group_id = ?',
        whereArgs: [group.groupId],
      );

      // 上面是异步的，说是性能要好些
      final adList = <ActionDetail>[];
      for (final r in actionRows) {
        final action = TrainingAction.fromMap(r);
        final exerciseRows = await db.query(
          TrainingDdl.tableNameOfExercise,
          where: 'exercise_id = ?',
          whereArgs: [action.exerciseId],
        );

        // print("exerciseRows----${exerciseRows.length}");
        // ？？？理论上这里只有查到1个exercise，且不应该差不多(暂不考虑异常情况)
        if (exerciseRows.isNotEmpty) {
          var ad = ActionDetail(
            action: action,
            exercise: Exercise.fromMap(exerciseRows[0]),
          );
          adList.add(ad);
        }
      }

      list.add(GroupWithActions(group: group, actionDetailList: adList));
    }

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

    return batch.commit();
  }

  // 更新指定训练的所有动作(删除所有已有的，新增传入的)
  Future<List<Object?>> renewGroupWithActionsList(
    int groupId,
    List<TrainingAction> actionList,
  ) async {
    Database db = await database;

    return await db.transaction((txn) async {
      await txn.delete(
        TrainingDdl.tableNameOfAction,
        where: "group_id =? ",
        whereArgs: [groupId],
      );

      var batch = txn.batch();
      for (var item in actionList) {
        batch.insert(TrainingDdl.tableNameOfAction, item.toMap());
      }

      return batch.commit();
    });
  }

  ///***********************************************/
  ///   plan and group 的相关操作
  ///

  /// 插入单个计划基本信息
  Future<int> insertTrainingPlan(TrainingPlan plan) async =>
      (await database).insert(TrainingDdl.tableNameOfPlan, plan.toMap());

  Future<List<Object?>> insertTrainingPlanList(
    List<TrainingPlan> tpList,
  ) async {
    var batch = (await database).batch();
    for (var item in tpList) {
      batch.insert(TrainingDdl.tableNameOfPlan, item.toMap());
    }
    return batch.commit();
  }

  // 插入动作组(插入plan has group 表，单条也当数组插入）
  Future<List<Object?>> insertPlanHasGroupList(
    List<PlanHasGroup> phgList,
  ) async {
    var batch = (await database).batch();
    for (var item in phgList) {
      batch.insert(TrainingDdl.tableNameOfPlanHasGroup, item.toMap());
    }
    return batch.commit();
  }

  // 修改指定计划基本信息（指定id修改）
  Future<int> updateTrainingPlanById(int planId, TrainingPlan plan) async =>
      (await database).update(
        TrainingDdl.tableNameOfPlan,
        plan.toMap(),
        where: "plan_id = ? ",
        whereArgs: [planId],
      );

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
      where.add("plan_name like ? ");
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

    /// 简单来说，就是级联的查询每个基础表，组合到一起：
    /// plan -> plan_has_group -> group -> action -> exercise
    /// 对应自定义类的包含关系(从大到细)
    ///  PlanWithGroups
    ///  -> plan + GroupWithActions
    ///  -> plan + (group + ActionDetail)
    ///  -> plan + (group + (action + exercise))

    // 1 查询计划基础表
    final planRows = where.isEmpty
        ? await db.query(TrainingDdl.tableNameOfPlan)
        : await db.query(
            TrainingDdl.tableNameOfPlan,
            where: where.join(" AND "),
            whereArgs: whereArgs,
          );

    // 2 通过计划基础表数据查询 计划训练关联表数据
    final pwgList = <PlanWithGroups>[];
    for (final row in planRows) {
      final plan = TrainingPlan.fromMap(row);

      final planHasGroupRows = await db.query(
        TrainingDdl.tableNameOfPlanHasGroup,
        where: 'plan_id = ?',
        whereArgs: [plan.planId],
      );

      // 3 通过计划训练关联表数据查询 训练基础表数据
      final gwaList = <GroupWithActions>[];
      // 构建groupWithActions实例
      for (final phg in planHasGroupRows) {
        // 先通过id查到指定group，再通过group查询包含的action
        final planHasGroup = PlanHasGroup.fromMap(phg);

        // ？？？主键查询数据，理论上是有且只有1个，不会为空
        var group = TrainingGroup.fromMap((await db.query(
                TrainingDdl.tableNameOfGroup,
                where: 'group_id = ?',
                whereArgs: [planHasGroup.groupId]))
            .first);

        // 4 通过训练基础表数据查询 动作基础表数据
        final actionRows = await db.query(
          TrainingDdl.tableNameOfAction,
          where: 'group_id = ?',
          whereArgs: [group.groupId],
        );

        // 5 通过 动作基础表数据查询管理的基础运动基础表数据
        final adList = <ActionDetail>[];
        // 构建actionDetail 实例
        for (final a in actionRows) {
          final action = TrainingAction.fromMap(a);
          // ？？？理论上这里1个动作只有查到1个基础运动，且不应该查不到(暂不考虑异常情况)

          var exerciseRows = await db.query(
            TrainingDdl.tableNameOfExercise,
            where: 'exercise_id = ?',
            whereArgs: [action.exerciseId],
          );

          if (exerciseRows.isNotEmpty) {
            final exercise = Exercise.fromMap(exerciseRows.first);

            adList.add(ActionDetail(
              action: action,
              exercise: exercise,
            ));
          }
        }

        gwaList.add(GroupWithActions(group: group, actionDetailList: adList));
      }

      pwgList.add(PlanWithGroups(plan: plan, groupDetailList: gwaList));
    }

    // log.d("searchPlanWithGroups---$pwgList");
    return pwgList;
  }

  // 更新指定训练的所有动作(删除所有已有的，新增传入的)
  Future<List<Object?>> renewPlanWithGroupList(
    int planId,
    List<PlanHasGroup> phgList,
  ) async {
    Database db = await database;

    return await db.transaction((txn) async {
      await txn.delete(
        TrainingDdl.tableNameOfPlanHasGroup,
        where: "plan_id = ? ",
        whereArgs: [planId],
      );

      var batch = txn.batch();
      for (var item in phgList) {
        batch.insert(TrainingDdl.tableNameOfPlanHasGroup, item.toMap());
      }

      return batch.commit();
    });
  }

  ///***********************************************/
  ///  training_detail_log 的相关操作
  ///

  /// 插入单个计划基本信息
  Future<int> insertTrainedDetailLog(TrainedDetailLog log) async =>
      (await database)
          .insert(TrainingDdl.tableNameOfTrainedDetailLog, log.toMap());

  // 批量插入训练日志(备份恢复时有用到)
  Future<List<Object?>> insertTrainingDetailLogList(
    List<TrainedDetailLog> tlList,
  ) async {
    var batch = (await database).batch();

    for (var item in tlList) {
      batch.insert(TrainingDdl.tableNameOfTrainedDetailLog, item.toMap());
    }

    return batch.commit();
  }

  // 2023-12-27 日志改为宽表，直接查出数据，不用关联查询
  Future<List<TrainedDetailLog>> queryTrainedDetailLog({
    int? userId,
    String? startDate,
    String? endDate,
    String? gmtCreateSort = "ASC", // 按创建时间升序或者降序排序
  }) async {
    final db = await database;

    var where = [];
    var whereArgs = [];

    if (userId != null) {
      where.add(" user_id = ? ");
      whereArgs.add(userId);
    }
    if (startDate != null) {
      where.add(" trained_date >= ? ");
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      where.add(" trained_date <= ? ");
      whereArgs.add(endDate);
    }

    // 如果有传入创建时间排序，不是传的降序一律升序
    var sort = gmtCreateSort?.toLowerCase() == 'desc' ? 'DESC' : 'ASC';

    final rows = await db.query(
      TrainingDdl.tableNameOfTrainedDetailLog,
      where: where.isNotEmpty ? where.join(" AND ") : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'trained_date $sort',
    );

    return rows.map((row) => TrainedDetailLog.fromMap(row)).toList();
  }

  /// 2023-12-27 查询训练计划中每一个训练日最近一次跟练的时间
  /// 因为group_name和plan_name是唯一的，而id是自增，可能删除之后万一新的又和旧的编号一样了
  /// 所以通过名称查询；而且这个名称也不会是用户手动输入，所以也不担心匹配不上。
  Future<Map<int, TrainedDetailLog?>> queryLastTrainingDetailLogByPlanName(
    TrainingPlan plan,
  ) async {
    final db = await database;

    // 对应计划的每个训练日编号作为key，该训练日的最新训练记录作为value。
    Map<int, TrainedDetailLog?> logMap = {};

    /// 只找最后一次的记录，那就创建时间倒序查询计划编号和对应训练日编号的最新数据
    for (var i = 0; i < plan.planPeriod; i++) {
      final logRows = await db.query(
        TrainingDdl.tableNameOfTrainedDetailLog,
        where: "plan_name = ? AND day_number = ? ",
        whereArgs: [plan.planName, i + 1],
        orderBy: 'trained_date DESC',
      );

      if (logRows.isEmpty) {
        logMap[i + 1] = null;
      } else {
        // 训练时间倒序排列的，所以选第一个即可
        logMap[i + 1] = TrainedDetailLog.fromMap(logRows.first);
      }
    }

    return logMap;
  }

  /// 2023-12-27 因为已经有了训练日志宽表，所以，即便有训练日志也可以删除；
  /// 因此判断是否被使用排除掉存在于日志表这一条；也就是说:
  ///   计划可以随便删；
  ///   训练没有被计划使用即可删除；
  ///   exercise没有对应action(没有被训练使用)即可删除
  Future<List<Map<String, Object?>>> isExerciseUsed(int exerciseId) async {
    Database db = await database;

    // 如果对应的exercise编号关联查询的结果不为空，则说明有被使用，不允许删除
    return await db.rawQuery(
      '''
      SELECT a.action_id,g.group_id,phg.plan_id
      FROM ${TrainingDdl.tableNameOfAction} a
      LEFT JOIN ${TrainingDdl.tableNameOfGroup}         g   ON g.group_id = a.group_id  
      LEFT JOIN ${TrainingDdl.tableNameOfPlanHasGroup}  phg ON phg.group_id = g.group_id
      WHERE a.exercise_id = $exerciseId;
      ''',
    );
  }

  // 这个训练有所属的计划
  Future<List<Map<String, Object?>>> isGroupUsed(int groupId) async =>
      await (await database).query(
        TrainingDdl.tableNameOfPlanHasGroup,
        where: 'group_id = ? ',
        whereArgs: [groupId],
      );
}

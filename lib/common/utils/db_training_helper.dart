// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
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
      txn.execute(TrainingDdl.ddlForUser);
      txn.execute(TrainingDdl.ddlForTrainedLog);
      txn.execute(TrainingDdl.ddlForWeightTrend);
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
  void deleteDB() async {
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

  // 修改单条数据
  Future<int> updateExercise(Exercise exercise) async =>
      (await database).update(
        TrainingDdl.tableNameOfExercise,
        exercise.toMap(),
        where: 'exercise_id = ?',
        whereArgs: [exercise.exerciseId],
      );

  // 删除单条数据
  Future<int> deleteExercise(int id) async =>
      (await database).delete(TrainingDdl.tableNameOfExercise,
          where: "exercise_id=?", whereArgs: [id]);

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

    // 一般的条件是精确查询，肌肉是模糊查询
    conditions.forEach((key, value) {
      if (value != null) {
        where.add('$key = ?');
        whereArgs.add(value);
      }
    });

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

      final adList = await Future.wait(actionRows.map((a) async {
        final action = TrainingAction.fromMap(a);
        // 理论上一个action一定能查到且仅查到一个exercise，不会为空
        final exercise = Exercise.fromMap((await db.query(
          TrainingDdl.tableNameOfExercise,
          where: 'exercise_id = ?',
          whereArgs: [action.exerciseId],
        ))
            .first);

        return ActionDetail(action: action, exercise: exercise);
      }));

      // 上面是异步的，说是性能要好些
      // final adList = <ActionDetail>[];
      // for (final r in actionRows) {
      //   final action = TrainingAction.fromMap(r);
      //   final exerciseRows = await db.query(
      //     TrainingDdl.tableNameOfExercise,
      //     where: 'exercise_id = ?',
      //     whereArgs: [action.exerciseId],
      //   );
      //   // ？？？理论上这里只有查到1个exercise，且不应该差不多(暂不考虑异常情况)
      //   var ad = ActionDetail(
      //     action: action,
      //     exercise: Exercise.fromMap(exerciseRows[0]),
      //   );
      //   adList.add(ad);
      // }

      list.add(GroupWithActions(group: group, actionDetailList: adList));
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
          final exercise = Exercise.fromMap((await db.query(
                  TrainingDdl.tableNameOfExercise,
                  where: 'exercise_id = ?',
                  whereArgs: [action.exerciseId]))
              .first);

          adList.add(ActionDetail(
            action: action,
            exercise: exercise,
          ));
        }

        gwaList.add(GroupWithActions(group: group, actionDetailList: adList));
      }

      pwgList.add(PlanWithGroups(plan: plan, groupDetailList: gwaList));
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
}

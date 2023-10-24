// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/dietary_state.dart';
import '../../models/training_state.dart';
import 'ddl_dietary.dart';
import 'ddl_training.dart';

class DBTrainHelper {
  static final DBTrainHelper _dbHelper = DBTrainHelper._createInstance();
  static Database? _database;
  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBTrainHelper._createInstance();

  factory DBTrainHelper() => _dbHelper;

  Future<Database> get database async =>
      _database ??= await initializeDatabase();

  // 初始化数据库
  Future<Database> initializeDatabase() async {
    // 获取Android和iOS存储数据库的目录路径。
    Directory directory = await getApplicationDocumentsDirectory();
    String path = "${directory.path}/${TrainingDdl.databaseName}";

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
    await db.execute(TrainingDdl.ddlForGroupHaAction);
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

    var list = List.generate(maps.length, (i) {
      return Exercise(
        exerciseId: maps[i]['exercise_id'],
        exerciseCode: maps[i]['exercise_code'],
        exerciseName: maps[i]['exercise_name'],
        force: maps[i]['force'],
        level: maps[i]['level'],
        mechanic: maps[i]['mechanic'],
        equipment: maps[i]['equipment'],
        // ？？？明明sql语句设置了默认值，但是不传还是null
        standardDuration: maps[i]['standard_duration'] ?? "1",
        instructions: maps[i]['instructions'],
        ttsNotes: maps[i]['tts_notes'],
        category: maps[i]['category'],
        primaryMuscles: maps[i]['primary_muscles'],
        secondaryMuscles: maps[i]['secondary_muscles'],
        images: maps[i]['images'],
        // ？？？明明sql语句设置了默认值，但是不传还是null
        isCustom: maps[i]['is_custom'] ?? '0',
        contributor: maps[i]['contributor'],
        gmtCreate: maps[i]['gmt_create'],
        gmtModified: maps[i]['gmt_modified'],
      );
    });

    print(list);

    return list;
  }
}

class DBDietaryHelper {
  static final DBDietaryHelper _dbHelper = DBDietaryHelper._createInstance();
  static Database? _database;
  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBDietaryHelper._createInstance();

  factory DBDietaryHelper() => _dbHelper;

  Future<Database> get database async =>
      _database ??= await initializeDatabase();

  // 初始化数据库
  Future<Database> initializeDatabase() async {
    // 获取Android和iOS存储数据库的目录路径。
    Directory directory = await getApplicationDocumentsDirectory();
    String path = "${directory.path}/${DietaryDdl.databaseName}";

    print("初始化 TRAIN sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var db = await openDatabase(path, version: 1, onCreate: _createDb);

    dbFilePath = path;

    return db;
  }

  // 创建训练数据库相关表
  void _createDb(Database db, int newVersion) async {
    await db.execute(DietaryDdl.ddlForFood);
    await db.execute(DietaryDdl.ddlForServingInfo);
    await db.execute(DietaryDdl.ddlForMeal);
    await db.execute(DietaryDdl.ddlForFoodDailyLog);
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
    print("开始删除內嵌的 sqlite Dietary db文件，db文件地址：$dbFilePath");

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
  Future<int> insertFoodWithServingInfo(
      Food food, ServingInfo servingInfo) async {
    final db = await database;
    int foodId = 0;
    try {
      await db.transaction((txn) async {
        // Insert food info
        // 由于food_id列被设置为自增属性的主键，因此在调用insert方法时，返回值应该是新插入行的food_id值。
        // 如果不是自增主键，则返回的是行号row 的id。
        foodId = await txn.insert(DietaryDdl.tableNameOfFood, food.toMap());

        // Insert serving info associated with the food
        servingInfo.foodId = foodId;
        await txn.insert(
            DietaryDdl.tableNameOfServingInfo, servingInfo.toMap());
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
}

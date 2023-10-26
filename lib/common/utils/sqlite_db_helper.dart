// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer';
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
    await db.execute(DietaryDdl.ddlForMealFoodItem);
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
  // 如果食物为空，servinginfo不为空，说明是给以存在的食物添加单份营养素
  // 如果食物不为空，servinginfo为空，说明是单独新增食物（正常业务应该不会，新增食物一定会带一份营养素）
  // 如果食物不为空，servinginfo不为空，说明是正常的新增食物带一份营养素
  // 如果都为空，则报错
  Future<int> insertFoodWithServingInfo({
    Food? food,
    ServingInfo? servingInfo,
  }) async {
    final db = await database;
    int foodId = 0;
    try {
      await db.transaction((txn) async {
        // 如果有传入的食物信息，说明是在新增食物时一并新增其营养素
        //是已存在的食物编号，则直接新增serving info即可
        if (food != null && servingInfo != null) {
          // 由于food_id列被设置为自增属性的主键，因此在调用insert方法时，返回值应该是新插入行的food_id值。
          // 如果不是自增主键，则返回的是行号row 的id。
          foodId = await txn.insert(DietaryDdl.tableNameOfFood, food.toMap());
          servingInfo.foodId = foodId;
          await txn.insert(
              DietaryDdl.tableNameOfServingInfo, servingInfo.toMap());
        } else if (food != null && servingInfo == null) {
          foodId = await txn.insert(DietaryDdl.tableNameOfFood, food.toMap());
        } else if (food == null && servingInfo != null) {
          await txn.insert(
              DietaryDdl.tableNameOfServingInfo, servingInfo.toMap());
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

  // 插入单条meal
  Future<int> insertMeal(Meal meal) async {
    Database db = await database;

    // 因为meal id作为主键且设为自增，所以这里返回的是新增的meal id
    var result = await db.insert(
      DietaryDdl.tableNameOfMeal,
      meal.toMap(),
    );
    return result;
  }

  Future<int> insertMealFoodItem(MealFoodItem mealFoodItem) async {
    Database db = await database;

    // 因为 meal_food_item_id 作为主键且设为自增，所以这里返回的是新增的 meal_food_item_id
    var result = await db.insert(
      DietaryDdl.tableNameOfMealFoodItem,
      mealFoodItem.toMap(),
    );
    return result;
  }

  Future<int> insertFoodDailyLogObly(FoodDailyLog foodDailyLog) async {
    Database db = await database;

    // 因为 foodDailyLogId 作为主键且设为自增，所以这里返回的是新增的 foodDailyLogId
    var result = await db.insert(
      DietaryDdl.tableNameOfFoodDailyLog,
      foodDailyLog.toMap(),
    );
    return result;
  }

  /// 插入每日饮食记录大体流程
  ///
  /// 1、查看当前日期有没有饮食记录
  ///    如果没有，直接新增；
  ///    如果已存在，查看需要新增的那个餐次(早中晚夜)编号是否为空
  ///      0、查询该日该餐次是否有绑定已存在的餐次记录（food daily log 指定 date 和 四餐的meal id）
  ///         如果为空：创建当日当餐次的基本信息（新增meal数据），获取新建的meal id
  ///         如果已有：获取已存在的meal id
  ///      1、新增该餐次食用食物的数据（新增 food intake item）， 加入上方得到的meal id绑定餐次
  ///      2、将绑定了 food intake item 的meal id 放到 food daily log的当天对应早中晚宵夜的meal栏位
  ///
  Future<int> insertFoodDailyLog(
    FoodDailyLog foodDailyLog,
    String mealBelong, // 插入的是哪一餐
    Meal meal,
    MealFoodItem mealFoodItem,
  ) async {
    Database db = await database;

    int resultFlag = 0;

    print("进入insertFoodDailyLog-----------");
    try {
      await db.transaction((txn) async {
        // 查询当前日期有没有记录
        final logRows = await txn.query(
          DietaryDdl.tableNameOfFoodDailyLog,
          where: 'date = ?',
          whereArgs: [foodDailyLog.date],
        );

        print("1111111111111111-----------");

        // 如果没有记录，全新的，所有内容都直接新增
        if (logRows.isEmpty) {
          var mealId = await txn.insert(
            DietaryDdl.tableNameOfMeal,
            meal.toMap(),
          );
          print("2222222222222222222-----------");

          mealFoodItem.mealId = mealId;
          await txn.insert(
            DietaryDdl.tableNameOfMealFoodItem,
            mealFoodItem.toMap(),
          );

          print("333333333333333333333-----------");

          switch (mealBelong) {
            case "breakfast":
              foodDailyLog.breakfastMealId = mealId;
              break;
            case "lunch":
              foodDailyLog.lunchMealId = mealId;
              break;
            case "dinner":
              foodDailyLog.dinnerMealId = mealId;
              break;
            case "other":
              foodDailyLog.otherMealId = mealId;
              break;
          }
          await txn.insert(
            DietaryDdl.tableNameOfFoodDailyLog,
            foodDailyLog.toMap(),
          );

          print("444444444444444444444-----------");
        } else {
          // 如果有记录，正常来讲，如果能查询到结果，每日只会有1条数据
          final log = FoodDailyLog.fromMap(logRows.first);
          int? targetMealId;
          switch (mealBelong) {
            case "breakfast":
              targetMealId = log.breakfastMealId;
              break;
            case "lunch":
              targetMealId = log.lunchMealId;
              break;
            case "dinner":
              targetMealId = log.dinnerMealId;
              break;
            case "other":
              targetMealId = log.otherMealId;
              break;
          }

          // final logList =
          //     logRows.map((row) => FoodDailyLog.fromMap(row)).toList();
          // if (mealBelong == "breakfast") {
          //   targetMealId = logList[0].breakfastMealId;
          // } else if (mealBelong == "lunch") {
          //   targetMealId = logList[0].lunchMealId;
          // } else if (mealBelong == "dinner") {
          //   targetMealId = logList[0].dinnerMealId;
          // } else if (mealBelong == "other") {
          //   targetMealId = logList[0].otherMealId;
          // }

          // 如果已存在log，且对应的target meal不为空，说明该日该餐次已有数据，直接新增meal food item 即可
          if (targetMealId != null) {
            mealFoodItem.mealId = targetMealId;
            await txn.insert(
              DietaryDdl.tableNameOfMealFoodItem,
              mealFoodItem.toMap(),
            );

            print("555555555555555555-----------");
          } else {
            // 如果该日该餐次没有数据，则需要先新增meal，再新增meal food item
            var mealId = await txn.insert(
              DietaryDdl.tableNameOfMeal,
              meal.toMap(),
            );
            mealFoodItem.mealId = mealId;
            await txn.insert(
              DietaryDdl.tableNameOfMealFoodItem,
              mealFoodItem.toMap(),
            );
            print("666666666666666666666666-----------");
          }
        }
      });

      // 正常执行完成，返回1
      resultFlag = 1;
    } catch (e) {
      // Handle the error
      print('Error deleting food with serving info: $e');
      resultFlag = 0;
      rethrow;
    }

    return resultFlag;
  }

  // 移除item
  // 传入food dialy log的id，对应的早中晚夜宵编号，找到对应的meal，找到对应的food intake item id，删除
  // 如果meal 没有任何food intake item，
  //    meal没有绑定到人和food daily log中，删除meal（这一步可以在food daily log中也同时清除原本绑定了这个meal id点栏位）

  Future<List<FoodDailyLog>> queryFoodDailyLog() async {
    Database db = await database;

    final rows = await db.query(DietaryDdl.tableNameOfFoodDailyLog);

    var list = rows.map((row) => FoodDailyLog.fromMap(row)).toList();

    print("queryFoodDailyLog--- $list");

    return list;
  }

// 查询所有饮食记录及相关信息
  Future<List<FoodIntakeRecord>> queryAllFoodIntakeRecords2() async {
    Database db = await database;

    List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT fdl.*, 
           m1.meal_id AS breakfast_meal_id, 
           m1.meal_name AS breakfast_meal_name, 
           m2.meal_id AS lunch_meal_id, 
           m2.meal_name AS lunch_meal_name, 
           m3.meal_id AS dinner_meal_id, 
           m3.meal_name AS dinner_meal_name, 
           m4.meal_id AS other_meal_id, 
           m4.meal_name AS other_meal_name,
           mfi1.meal_food_item_id AS breakfast_meal_food_item_id,
           mfi1.food_id AS breakfast_food_id,
           mfi1.serving_info_id AS breakfast_serving_info_id,
           mfi1.food_intake_size AS breakfast_food_intake_size,
           mfi2.meal_food_item_id AS lunch_meal_food_item_id,
           mfi2.food_id AS lunch_food_id,
           mfi2.serving_info_id AS lunch_serving_info_id,
           mfi2.food_intake_size AS lunch_food_intake_size,
           mfi3.meal_food_item_id AS dinner_meal_food_item_id,
           mfi3.food_id AS dinner_food_id,
           mfi3.serving_info_id AS dinner_serving_info_id,
           mfi3.food_intake_size AS dinner_food_intake_size,
           mfi4.meal_food_item_id AS other_meal_food_item_id,
           mfi4.food_id AS other_food_id,
           mfi4.serving_info_id AS other_serving_info_id,
           mfi4.food_intake_size AS other_food_intake_size
    FROM ff_food_daily_log AS fdl
    LEFT JOIN ff_meal AS m1 ON fdl.breakfast_meal_id = m1.meal_id
    LEFT JOIN ff_meal AS m2 ON fdl.lunch_meal_id = m2.meal_id
    LEFT JOIN ff_meal AS m3 ON fdl.dinner_meal_id = m3.meal_id
    LEFT JOIN ff_meal AS m4 ON fdl.other_meal_id = m4.meal_id
    LEFT JOIN ff_meal_food_item AS mfi1 ON fdl.breakfast_meal_id = mfi1.meal_id
    LEFT JOIN ff_meal_food_item AS mfi2 ON fdl.lunch_meal_id = mfi2.meal_id
    LEFT JOIN ff_meal_food_item AS mfi3 ON fdl.dinner_meal_id = mfi3.meal_id
    LEFT JOIN ff_meal_food_item AS mfi4 ON fdl.other_meal_id = mfi4.meal_id
  ''');

    log("queryAllFoodIntakeRecords  result---------------------$result");

/*
result be like：

[{food_daily_id: 1, date: 2023-10-24 16:32:15.617120, 
breakfast_meal_id: 1, lunch_meal_id: null, dinner_meal_id: null, other_meal_id: null, 
contributor: david, gmt_create: 2023-10-24 16:32:15.618412, gmt_modified: null, 
breakfast_meal_name: 20231024的早餐, lunch_meal_name: null, dinner_meal_name: null, other_meal_name: null, 
breakfast_meal_food_item_id: 1, breakfast_food_id: 1, breakfast_serving_info_id: 1, breakfast_food_intake_size: 100.0, 
lunch_meal_food_item_id: null, lunch_food_id: null, lunch_serving_info_id: null, lunch_food_intake_size: null, 
dinner_meal_food_item_id: null, dinner_food_id: null, dinner_serving_info_id: null, dinner_food_intake_size: null, 
other_meal_food_item_id: null, other_food_id: null, other_serving_info_id: null, other_food_intake_size: null}, 

{food_daily_id: 1, date: 2023-10-24 16:32:15.617120, 
breakfast_meal_id: 1, lunch_meal_id: null, dinner_meal_id: null, other_meal_id: null, 
contributor: david, gmt_create: 2023-10-24 16:32:15.618412, gmt_modified: null, 
breakfast_meal_name: 20231024的早餐, lunch_meal_name: null, dinner_meal_name: null, other_meal_name: null, 
breakfast_meal_food_item_id: 2, breakfast_food_id: 2, breakfast_serving_info_id: 1, breakfast_food_intake_size: 200.0, 
lunch_meal_food_item_id: null, lunch_food_id: null, lunch_serving_info_id: null, lunch_food_intake_size: null, 
dinner_meal_food_item_id: null, dinner_food_id: null, dinner_serving_info_id: null, dinner_food_intake_size: null, 
other_meal_food_item_id: null, other_food_id: null, other_serving_info_id: null, other_food_intake_size: null}]

*/

    List<FoodIntakeRecord> foodIntakeRecords = [];

    for (Map<String, dynamic> row in result) {
      int foodDailyId = row['food_daily_id'];
      String date = row['date'];
      String? contributor = row['contributor'];
      String? gmtCreate = row['gmt_create'];
      String? gmtModified = row['gmt_modified'];

      Meal? breakfastMeal;
      if (row['breakfast_meal_id'] != null) {
        breakfastMeal = Meal(
          mealId: row['breakfast_meal_id'],
          mealName: row['breakfast_meal_name']!,
          description: row['breakfast_description'],
          contributor: row['breakfast_contributor'],
          gmtCreate: row['breakfast_gmt_create'],
          gmtModified: row['breakfast_gmt_modified'],
        );
      }

      Meal? lunchMeal;
      if (row['lunch_meal_id'] != null) {
        lunchMeal = Meal(
          mealId: row['lunch_meal_id'],
          mealName: row['lunch_meal_name']!,
          description: row['lunch_description'],
          contributor: row['lunch_contributor'],
          gmtCreate: row['lunch_gmt_create'],
          gmtModified: row['lunch_gmt_modified'],
        );
      }

      Meal? dinnerMeal;
      if (row['dinner_meal_id'] != null) {
        dinnerMeal = Meal(
          mealId: row['dinner_meal_id'],
          mealName: row['dinner_meal_name']!,
          description: row['dinner_description'],
          contributor: row['dinner_contributor'],
          gmtCreate: row['dinner_gmt_create'],
          gmtModified: row['dinner_gmt_modified'],
        );
      }

      Meal? otherMeal;
      if (row['other_meal_id'] != null) {
        otherMeal = Meal(
          mealId: row['other_meal_id'],
          mealName: row['other_meal_name']!,
          description: row['other_description'],
          contributor: row['other_contributor'],
          gmtCreate: row['other_gmt_create'],
          gmtModified: row['other_gmt_modified'],
        );
      }

      List<MealFoodItem> breakfastMealFoodItems = [];
      if (row['breakfast_meal_food_item_id'] != null) {
        breakfastMealFoodItems.add(MealFoodItem(
          mealId: row['breakfast_meal_id'],
          mealFoodItemId: row['breakfast_meal_food_item_id'],
          foodId: row['breakfast_food_id'],
          servingInfoId: row['breakfast_serving_info_id'],
          foodIntakeSize: row['breakfast_food_intake_size'],
        ));
      }

      List<MealFoodItem> lunchMealFoodItems = [];
      if (row['lunch_meal_food_item_id'] != null) {
        lunchMealFoodItems.add(MealFoodItem(
          mealId: row['lunch_meal_id'],
          mealFoodItemId: row['lunch_meal_food_item_id'],
          foodId: row['lunch_food_id'],
          servingInfoId: row['lunch_serving_info_id'],
          foodIntakeSize: row['lunch_food_intake_size'],
        ));
      }

      List<MealFoodItem> dinnerMealFoodItems = [];
      if (row['dinner_meal_food_item_id'] != null) {
        dinnerMealFoodItems.add(MealFoodItem(
          mealId: row['dinner_meal_id'],
          mealFoodItemId: row['dinner_meal_food_item_id'],
          foodId: row['dinner_food_id'],
          servingInfoId: row['dinner_serving_info_id'],
          foodIntakeSize: row['dinner_food_intake_size'],
        ));
      }

      List<MealFoodItem> otherMealFoodItems = [];
      if (row['other_meal_food_item_id'] != null) {
        otherMealFoodItems.add(MealFoodItem(
          mealId: row['other_meal_id'],
          mealFoodItemId: row['other_meal_food_item_id'],
          foodId: row['other_food_id'],
          servingInfoId: row['other_serving_info_id'],
          foodIntakeSize: row['other_food_intake_size'],
        ));
      }

      FoodIntakeRecord foodIntakeRecord = FoodIntakeRecord(
        foodDailyId: foodDailyId,
        date: date,
        contributor: contributor,
        gmtCreate: gmtCreate,
        gmtModified: gmtModified,
        breakfastMeal: breakfastMeal,
        lunchMeal: lunchMeal,
        dinnerMeal: dinnerMeal,
        otherMeal: otherMeal,
        breakfastMealFoodItems: breakfastMealFoodItems,
        lunchMealFoodItems: lunchMealFoodItems,
        dinnerMealFoodItems: dinnerMealFoodItems,
        otherMealFoodItems: otherMealFoodItems,
      );

      foodIntakeRecords.add(foodIntakeRecord);
    }

    log("queryAllFoodIntakeRecords  foodIntakeRecords --- $foodIntakeRecords");

    return foodIntakeRecords;
  }

  Future<List<FoodIntakeRecord>> queryAllFoodIntakeRecords3() async {
    Database db = await database;

    List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT fdl.*, 
           m1.meal_id AS breakfast_meal_id, 
           m1.meal_name AS breakfast_meal_name, 
           m2.meal_id AS lunch_meal_id, 
           m2.meal_name AS lunch_meal_name, 
           m3.meal_id AS dinner_meal_id, 
           m3.meal_name AS dinner_meal_name, 
           m4.meal_id AS other_meal_id, 
           m4.meal_name AS other_meal_name,
           mfi1.meal_food_item_id AS breakfast_meal_food_item_id,
           mfi1.food_id AS breakfast_food_id,
           mfi1.serving_info_id AS breakfast_serving_info_id,
           mfi1.food_intake_size AS breakfast_food_intake_size,
           mfi2.meal_food_item_id AS lunch_meal_food_item_id,
           mfi2.food_id AS lunch_food_id,
           mfi2.serving_info_id AS lunch_serving_info_id,
           mfi2.food_intake_size AS lunch_food_intake_size,
           mfi3.meal_food_item_id AS dinner_meal_food_item_id,
           mfi3.food_id AS dinner_food_id,
           mfi3.serving_info_id AS dinner_serving_info_id,
           mfi3.food_intake_size AS dinner_food_intake_size,
           mfi4.meal_food_item_id AS other_meal_food_item_id,
           mfi4.food_id AS other_food_id,
           mfi4.serving_info_id AS other_serving_info_id,
           mfi4.food_intake_size AS other_food_intake_size
    FROM ff_food_daily_log AS fdl
    LEFT JOIN ff_meal AS m1 ON fdl.breakfast_meal_id = m1.meal_id
    LEFT JOIN ff_meal AS m2 ON fdl.lunch_meal_id = m2.meal_id
    LEFT JOIN ff_meal AS m3 ON fdl.dinner_meal_id = m3.meal_id
    LEFT JOIN ff_meal AS m4 ON fdl.other_meal_id = m4.meal_id
    LEFT JOIN ff_meal_food_item AS mfi1 ON fdl.breakfast_meal_id = mfi1.meal_id
    LEFT JOIN ff_meal_food_item AS mfi2 ON fdl.lunch_meal_id = mfi2.meal_id
    LEFT JOIN ff_meal_food_item AS mfi3 ON fdl.dinner_meal_id = mfi3.meal_id
    LEFT JOIN ff_meal_food_item AS mfi4 ON fdl.other_meal_id = mfi4.meal_id
  ''');

    log("queryAllFoodIntakeRecords1111  result---------------------$result");

    Map<int, FoodIntakeRecord> foodIntakeRecords = {};

    for (var row in result) {
      int foodDailyId = row['food_daily_id'];

      // 如果字典中已存在该foodDailyId的记录，则跳过当前行数据
      if (foodIntakeRecords.containsKey(foodDailyId)) {
        // 有当日记录的时候，添加对应值即可
        FoodIntakeRecord foodIntakeRecord = foodIntakeRecords[foodDailyId]!;

        if (row['breakfast_meal_id'] != null) {
          foodIntakeRecord.breakfastMeal = Meal(
            mealId: row['breakfast_meal_id'],
            mealName: row['breakfast_meal_name'] ?? "",
          );

          MealFoodItem mealFoodItem = MealFoodItem(
            mealId: row['breakfast_meal_id'],
            mealFoodItemId: row['breakfast_meal_food_item_id'],
            foodId: row['breakfast_food_id'],
            servingInfoId: row['breakfast_serving_info_id'],
            foodIntakeSize: row['breakfast_food_intake_size'],
          );

          foodIntakeRecord.breakfastMealFoodItems.add(mealFoodItem);
        }

        if (row['lunch_meal_id'] != null) {
          foodIntakeRecord.lunchMeal = Meal(
            mealId: row['lunch_meal_id'],
            mealName: row['lunch_meal_name'] ?? "",
          );

          MealFoodItem mealFoodItem = MealFoodItem(
            mealId: row['lunch_meal_id'],
            mealFoodItemId: row['lunch_meal_food_item_id'],
            foodId: row['lunch_food_id'],
            servingInfoId: row['lunch_serving_info_id'],
            foodIntakeSize: row['lunch_food_intake_size'],
          );

          foodIntakeRecord.lunchMealFoodItems.add(mealFoodItem);
        }

        if (row['dinner_meal_id'] != null) {
          foodIntakeRecord.dinnerMeal = Meal(
            mealId: row['dinner_meal_id'],
            mealName: row['dinner_meal_name'] ?? "",
          );

          MealFoodItem mealFoodItem = MealFoodItem(
            mealId: row['dinner_meal_id'],
            mealFoodItemId: row['dinner_meal_food_item_id'],
            foodId: row['dinner_food_id'],
            servingInfoId: row['dinner_serving_info_id'],
            foodIntakeSize: row['dinner_food_intake_size'],
          );

          foodIntakeRecord.dinnerMealFoodItems.add(mealFoodItem);
        }

        if (row['other_meal_id'] != null) {
          foodIntakeRecord.otherMeal = Meal(
            mealId: row['other_meal_id'],
            mealName: row['other_meal_name'] ?? "",
          );

          MealFoodItem mealFoodItem = MealFoodItem(
            mealId: row['other_meal_id'],
            mealFoodItemId: row['other_meal_food_item_id'],
            foodId: row['other_food_id'],
            servingInfoId: row['other_serving_info_id'],
            foodIntakeSize: row['other_food_intake_size'],
          );
          foodIntakeRecord.otherMealFoodItems.add(mealFoodItem);
        }
      } else {
        // 如果不存在，则创建新的 FoodIntakeRecord 并添加到字典中
        FoodIntakeRecord foodIntakeRecord = FoodIntakeRecord(
          foodDailyId: foodDailyId,
          date: row['date'],
          contributor: row['contributor'],
          gmtCreate: row['gmt_create'],
          gmtModified: row['gmt_modified'],
          breakfastMealFoodItems: [],
          lunchMealFoodItems: [],
          dinnerMealFoodItems: [],
          otherMealFoodItems: [],
        );

        if (row['breakfast_meal_id'] != null) {
          foodIntakeRecord.breakfastMeal = Meal(
            mealId: row['breakfast_meal_id'],
            mealName: row['breakfast_meal_name'] ?? "",
          );

          MealFoodItem mealFoodItem = MealFoodItem(
            mealId: row['breakfast_meal_id'],
            mealFoodItemId: row['breakfast_meal_food_item_id'],
            foodId: row['breakfast_food_id'],
            servingInfoId: row['breakfast_serving_info_id'],
            foodIntakeSize: row['breakfast_food_intake_size'],
          );

          foodIntakeRecord.breakfastMealFoodItems.add(mealFoodItem);
        }

        if (row['lunch_meal_id'] != null) {
          foodIntakeRecord.lunchMeal = Meal(
            mealId: row['lunch_meal_id'],
            mealName: row['lunch_meal_name'] ?? "",
          );

          MealFoodItem mealFoodItem = MealFoodItem(
            mealId: row['lunch_meal_id'],
            mealFoodItemId: row['lunch_meal_food_item_id'],
            foodId: row['lunch_food_id'],
            servingInfoId: row['lunch_serving_info_id'],
            foodIntakeSize: row['lunch_food_intake_size'],
          );

          foodIntakeRecord.lunchMealFoodItems.add(mealFoodItem);
        }

        if (row['dinner_meal_id'] != null) {
          foodIntakeRecord.dinnerMeal = Meal(
            mealId: row['dinner_meal_id'],
            mealName: row['dinner_meal_name'] ?? "",
          );

          MealFoodItem mealFoodItem = MealFoodItem(
            mealId: row['dinner_meal_id'],
            mealFoodItemId: row['dinner_meal_food_item_id'],
            foodId: row['dinner_food_id'],
            servingInfoId: row['dinner_serving_info_id'],
            foodIntakeSize: row['dinner_food_intake_size'],
          );

          foodIntakeRecord.dinnerMealFoodItems.add(mealFoodItem);
        }

        if (row['other_meal_id'] != null) {
          foodIntakeRecord.dinnerMeal = Meal(
            mealId: row['other_meal_id'],
            mealName: row['other_meal_name'] ?? "",
          );

          MealFoodItem mealFoodItem = MealFoodItem(
            mealId: row['other_meal_id'],
            mealFoodItemId: row['other_meal_food_item_id'],
            foodId: row['other_food_id'],
            servingInfoId: row['other_serving_info_id'],
            foodIntakeSize: row['other_food_intake_size'],
          );
          foodIntakeRecord.otherMealFoodItems.add(mealFoodItem);
        }

        // 没有当日记录的时候是新增
        foodIntakeRecords[foodDailyId] = foodIntakeRecord;
      }
    }

    List<FoodIntakeRecord> finalResult = foodIntakeRecords.values.toList();

    log("queryAllFoodIntakeRecords  finalResult1111 --- $finalResult");

    return finalResult;
  }

  /// 查询饮食记录都是看当天。如果是某一顿，也是知道是哪一天了，再加上对应mealId直接去查下meal 和 meal_food_item即可

  // 方案1,关联查询所有的数据，再按照指定格式进行转化
  Future<void> queryAllFoodIntakeRecords() async {
    Database db = await database;

    List<Map<String, dynamic>> result = await db.rawQuery("""
        SELECT fd.food_daily_id, fd.date,
              m1.meal_name AS breakfast_meal, m2.meal_name AS lunch_meal, 
              m3.meal_name AS dinner_meal, m4.meal_name AS other_meal,
              f1.brand, f1.product, f1.photos, f1.tags, f1.category,
              si.energy, si.protein, si.total_fat, si.saturated_fat, si.trans_fat,
              si.polyunsaturated_fat, si.monounsaturated_fat, si.cholesterol,
              si.total_carbohydrate, si.sugar, si.dietary_fiber, si.sodium, si.potassium,
              fd.contributor, fd.gmt_create, fd.gmt_modified
        FROM ff_food_daily_log fd
        LEFT JOIN ff_meal m1 ON fd.breakfast_meal_id = m1.meal_id
        LEFT JOIN ff_meal m2 ON fd.lunch_meal_id = m2.meal_id
        LEFT JOIN ff_meal m3 ON fd.dinner_meal_id = m3.meal_id
        LEFT JOIN ff_meal m4 ON fd.other_meal_id = m4.meal_id
        LEFT JOIN ff_meal_food_item mfi ON (fd.breakfast_meal_id = mfi.meal_id OR
                                            fd.lunch_meal_id = mfi.meal_id OR
                                            fd.dinner_meal_id = mfi.meal_id OR
                                            fd.other_meal_id = mfi.meal_id)
        LEFT JOIN ff_food f1 ON mfi.food_id = f1.food_id
        LEFT JOIN ff_serving_info si ON mfi.serving_info_id = si.serving_info_id;
      """);
    log("result----------$result");
  }

  // ======================
  // 方案2,嵌套查询，一层一层查，一层一层包装，也有新的类包装起来
  Future<List<FoodDailyLogRecord>> queryFoodDailyLogRecordOrgin(String date) async {
    final db = await database;

    // 查询log （注意：数据库中date栏位可用2023-10-24这个格式，时间戳的再说）
    // 1 查询指定天数的，date = '2023-10-24' 即可
    // 2 这里还可能查询几月份的，需要模糊查询date字符串的一部分 substr(date,1,7)='2023-10' 即可
    // 3 同理，查询年份直接 substr(date,1,4)='2023' 即可
    //
    final logRows = await db.query(
      DietaryDdl.tableNameOfFoodDailyLog,
      where: 'date = ?',
      whereArgs: ['date'],
    );

    final records = <FoodDailyLogRecord>[];

    for (final row in logRows) {
      final fdl = FoodDailyLog.fromMap(row);

      // 查询meal
      if (fdl.breakfastMealId != null) {
        final breakfastMealRows = await db.query(
          DietaryDdl.tableNameOfMeal,
          where: 'meal_id = ?',
          whereArgs: [fdl.breakfastMealId],
        );

        print("--------------breakfastMealRows:");
        print(breakfastMealRows);

        // 一切正常的话，早餐有数据，meal只有1条
        final breakfastMeal = Meal.fromMap(breakfastMealRows[0]);

        // 查询 meal food item
        final mealFoodItemRows = await db.query(
          DietaryDdl.tableNameOfMealFoodItem,
          where: 'meal_id = ?',
          whereArgs: [breakfastMeal.mealId],
        );

        print("--------------mealFoodItemRows:");
        print(mealFoodItemRows);

        final mealFoodItemList =
            mealFoodItemRows.map((row) => MealFoodItem.fromMap(row)).toList();

        List<MealFoodItemDetail> mealFoodItemDetailist = [];

        // 正常来讲到这里，一个item 里面也只有1个food 和 1个serving info
        for (var item in mealFoodItemList) {
          // 查询 meal food item
          final foodRows = await db.query(
            DietaryDdl.tableNameOfFood,
            where: 'food_id = ?',
            whereArgs: [item.foodId],
          );

          // 正常数据的话，长度为1
          final foodList = foodRows.map((row) => Food.fromMap(row)).toList();

          final servingInfoRows = await db.query(
            DietaryDdl.tableNameOfServingInfo,
            where: 'serving_info_id = ?',
            whereArgs: [item.servingInfoId],
          );

          // 正常数据的话，长度为1
          final servingInfoList =
              servingInfoRows.map((row) => ServingInfo.fromMap(row)).toList();

          final mealFoodItemDetail = MealFoodItemDetail(
            mealFoodItem: item,
            food: foodList[0],
            servingInfo: servingInfoList[0],
          );

          mealFoodItemDetailist.add(mealFoodItemDetail);
        }

        var mealAndMealFoodItemDetail = MealAndMealFoodItemDetail(
          meal: breakfastMeal,
          mealFoodItemDetailist: mealFoodItemDetailist,
        );

        final foodDailyLogRecord = FoodDailyLogRecord(
          foodDailyLog: fdl,
          breakfastMealFoodItems: mealAndMealFoodItemDetail,
        );
        records.add(foodDailyLogRecord);
      }
      if (fdl.lunchMealId != null) {
        final lunchMealRows = await db.query(
          DietaryDdl.tableNameOfMeal,
          where: 'meal_id = ?',
          whereArgs: [fdl.lunchMealId],
        );

        print("--------------lunchMealRows:");
        print(lunchMealRows);

        // 一切正常的话，早餐有数据，meal只有1条
        final lunchMeal = Meal.fromMap(lunchMealRows[0]);

        // 查询 meal food item
        final mealFoodItemRows = await db.query(
          DietaryDdl.tableNameOfMealFoodItem,
          where: 'meal_id = ?',
          whereArgs: [lunchMeal.mealId],
        );

        print("--------------mealFoodItemRows:");
        print(mealFoodItemRows);

        final mealFoodItemList =
            mealFoodItemRows.map((row) => MealFoodItem.fromMap(row)).toList();

        List<MealFoodItemDetail> mealFoodItemDetailist = [];

        // 正常来讲到这里，一个item 里面也只有1个food 和 1个serving info
        for (var item in mealFoodItemList) {
          // 查询 meal food item
          final foodRows = await db.query(
            DietaryDdl.tableNameOfFood,
            where: 'food_id = ?',
            whereArgs: [item.foodId],
          );

          // 正常数据的话，长度为1
          final foodList = foodRows.map((row) => Food.fromMap(row)).toList();

          final servingInfoRows = await db.query(
            DietaryDdl.tableNameOfServingInfo,
            where: 'serving_info_id = ?',
            whereArgs: [item.servingInfoId],
          );

          // 正常数据的话，长度为1
          final servingInfoList =
              servingInfoRows.map((row) => ServingInfo.fromMap(row)).toList();

          final mealFoodItemDetail = MealFoodItemDetail(
            mealFoodItem: item,
            food: foodList[0],
            servingInfo: servingInfoList[0],
          );

          mealFoodItemDetailist.add(mealFoodItemDetail);
        }

        var mealAndMealFoodItemDetail = MealAndMealFoodItemDetail(
          meal: lunchMeal,
          mealFoodItemDetailist: mealFoodItemDetailist,
        );

        final foodDailyLogRecord = FoodDailyLogRecord(
          foodDailyLog: fdl,
          lunchMealFoodItems: mealAndMealFoodItemDetail,
        );
        records.add(foodDailyLogRecord);
      }
    }
    return records;
  }

  // 以下是方案2优化之后的版本（前面这一堆是工具函数，也有可能其他地方可用）
  // 通过mealId查询meal，只返回一个meal
  Future<Meal> queryMealById(Database db, int mealId) async {
    final mealRows = await db.query(
      DietaryDdl.tableNameOfMeal,
      where: 'meal_id = ?',
      whereArgs: [mealId],
    );
    return Meal.fromMap(mealRows[0]);
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

  Future<List<MealFoodItemDetail>> queryMealFoodItemsByMealId(
      Database db, int mealId) async {
    final mealFoodItemRows = await db.query(
      DietaryDdl.tableNameOfMealFoodItem,
      where: 'meal_id = ?',
      whereArgs: [mealId],
    );

    final mealFoodItemList =
        mealFoodItemRows.map((row) => MealFoodItem.fromMap(row)).toList();

    final mealFoodItemDetailList = <MealFoodItemDetail>[];

    // 正常来讲到这里，一个item 里面也只有1个food 和 1个serving info
    for (var item in mealFoodItemList) {
      // 正常数据的话，长度为1
      final food = await queryFoodById(db, item.foodId);
      // 正常数据的话，长度为1
      final servingInfo = await queryServingInfoById(db, item.servingInfoId);
      final mealFoodItemDetail = MealFoodItemDetail(
        mealFoodItem: item,
        food: food,
        servingInfo: servingInfo,
      );
      mealFoodItemDetailList.add(mealFoodItemDetail);
    }

    return mealFoodItemDetailList;
  }

  Future<void> _processMeal(
    Database db,
    int? mealId,
    FoodDailyLog fdl,
    List<FoodDailyLogRecord> records,
  ) async {
    if (mealId != null) {
      final meal = await queryMealById(db, mealId);
      final mealFoodItemList =
          await queryMealFoodItemsByMealId(db, meal.mealId!);
      final mealAndMealFoodItemDetail = MealAndMealFoodItemDetail(
        meal: meal,
        mealFoodItemDetailist: mealFoodItemList,
      );
      final foodDailyLogRecord = FoodDailyLogRecord(
        foodDailyLog: fdl,
        breakfastMealFoodItems: mealAndMealFoodItemDetail,
      );
      records.add(foodDailyLogRecord);
    }
  }

  Future<List<FoodDailyLogRecord>> queryFoodDailyLogRecord(
      {String? date}) async {
    final db = await database;

    final logRows = await db.query(
      DietaryDdl.tableNameOfFoodDailyLog,
      // where: 'date = ?',
      // whereArgs: ['date'],
    );

    final records = <FoodDailyLogRecord>[];

    for (final row in logRows) {
      final fdl = FoodDailyLog.fromMap(row);

      await _processMeal(db, fdl.breakfastMealId, fdl, records);
      await _processMeal(db, fdl.lunchMealId, fdl, records);
      await _processMeal(db, fdl.dinnerMealId, fdl, records);
      await _processMeal(db, fdl.otherMealId, fdl, records);
    }

    log("records---------records---$records");

    return records;
  }
}

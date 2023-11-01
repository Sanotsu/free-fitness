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
    await db.execute(DietaryDdl.ddlForFood);
    await db.execute(DietaryDdl.ddlForServingInfo);
    await db.execute(DietaryDdl.ddlForDailyFoodItem);
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
}

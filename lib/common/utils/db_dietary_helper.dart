// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/dietary_state.dart';
import 'ddl_dietary.dart';

class DBDietaryHelper {
  ///
  /// 数据库初始化相关
  ///

  // 单例模式
  static final DBDietaryHelper _dbHelper = DBDietaryHelper._createInstance();
  // 构造函数，返回单例
  factory DBDietaryHelper() => _dbHelper;
  // 数据库实例
  static Database? _database;

  // 创建sqlite的db文件成功后，记录该地址，以便删除时使用。
  var dietaryDbFilePath = "";

  // 命名的构造函数用于创建DatabaseHelper的实例
  DBDietaryHelper._createInstance();

  // 获取数据库实例
  Future<Database> get database async => _database ??= await initializeDB();

  // 初始化数据库
  Future<Database> initializeDB() async {
    // 获取Android和iOS存储数据库的目录路径(用户看不到，在Android/data/……里看不到)。
    // Directory directory = await getApplicationDocumentsDirectory();
    // String path = "${directory.path}/${DietaryDdl.databaseName}";

    // IOS不支持这个方法，所以可能取不到这个地址
    Directory? directory2 = await getExternalStorageDirectory();
    String path = "${directory2?.path}/${DietaryDdl.databaseName}";

    print("初始化 DIETARY sqlite数据库存放的地址：$path");

    // 在给定路径上打开/创建数据库
    var dietaryDb = await openDatabase(path, version: 1, onCreate: _createDb);
    dietaryDbFilePath = path;
    return dietaryDb;
  }

  // 创建训练数据库相关表
  void _createDb(Database db, int newVersion) async {
    print("开始创建表 _createDb……");

    await db.transaction((txn) async {
      txn.execute(DietaryDdl.ddlForFood);
      txn.execute(DietaryDdl.ddlForServingInfo);
      txn.execute(DietaryDdl.ddlForDailyFoodItem);
      txn.execute(DietaryDdl.ddlForDietaryUser);
      txn.execute(DietaryDdl.ddlForIntakeDailyGoal);
    });
  }

  // 关闭数据库
  Future<bool> closeDB() async {
    Database db = await database;

    print("Dietary db.isOpen ${db.isOpen}");
    await db.close();
    print("Dietary db.isOpen ${db.isOpen}");

    // 删除db或者关闭db都需要重置db为null，
    // 否则后续会保留之前的连接，以致出现类似错误：Unhandled Exception: DatabaseException(database_closed 5)
    // https://github.com/tekartik/sqflite/issues/223
    _database = null;

    // 如果已经关闭了，返回ture
    return !db.isOpen;
  }

  // 删除sqlite的db文件（初始化数据库操作中那个path的值）
  void deleteDB() async {
    print("开始删除內嵌的 sqlite Dietary db文件，db文件地址：$dietaryDbFilePath");

    // 先删除，再重置，避免仍然存在其他线程在访问数据库，从而导致删除失败
    await deleteDatabase(dietaryDbFilePath);

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

    print("DietaryDB中拥有的表名:------------");
    print(tableNames);
  }

  ///
  ///  Helper 的相关方法
  ///

  ///***********************************************/
  /// food and serving_info 的相关操作
  ///

  ///
  // 插入单条食物(返回食物编号和营养素编号列表，0和空可能就没插入成功)
  // 如果食物为空，servinginfo不为空，说明是给以存在的食物添加单份营养素
  // 如果食物不为空，servinginfo为空，说明是单独新增食物（正常业务应该不会，新增食物一定会带一份营养素）
  // 如果食物不为空，servinginfo不为空，说明是正常的新增食物带一份营养素(支持1个食物带多份营养素信息)
  // 如果都为空，则报错
  Future<Map<String, Object>> insertFoodWithServingInfoList({
    Food? food,
    List<ServingInfo>? servingInfoList,
  }) async {
    final db = await database;

    late int foodId = 0;
    late List<int> servingIds = [];

    try {
      await db.transaction((txn) async {
        // 如果有传入食物
        if (food != null) {
          // 1 食物不为空
          // 由于food_id列被设置为自增属性的主键，因此在调用insert方法时，返回值应该是新插入行的food_id值。
          // 如果不是自增主键，则返回的是行号row 的id。
          foodId = await txn.insert(DietaryDdl.tableNameOfFood, food.toMap());
          // 2 食物不为空、营养素不为空
          if (servingInfoList != null && servingInfoList.isNotEmpty) {
            // 多个单个营养素的食物都是同一个
            for (var e in servingInfoList) {
              e.foodId = foodId;
              var servingId = await txn.insert(
                DietaryDdl.tableNameOfServingInfo,
                e.toMap(),
              );
              servingIds.add(servingId);
            }
          }
        } else if (servingInfoList != null && servingInfoList.isNotEmpty) {
          // 3 食物为空，营养素不为空
          // 多个单个营养素的批量插入，(营养素的foodId不传食物时一定要有)
          for (var e in servingInfoList) {
            var sId = await txn.insert(
              DietaryDdl.tableNameOfServingInfo,
              e.toMap(),
            );
            servingIds.add(sId);
          }
          foodId = servingInfoList.first.foodId;
        } else {
          // 4 都为空
          throw Exception("没有传入food id或serving info");
        }
      });
    } catch (e) {
      // Handle the error
      print('Error inserting food with serving info: $e');
      // 抛出异常来触发回滚的方式是 sqflite 中常用的做法
      rethrow;
    }
    // 返回成功插入的食品编号和营养素编号列表
    // ？？？这个map的key是魔法值
    return {
      "foodId": foodId,
      "servingIds": servingIds,
    };
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
        await txn.delete(
          DietaryDdl.tableNameOfServingInfo,
          where: 'food_id = ?',
          whereArgs: [foodId],
        );

        await txn.delete(
          DietaryDdl.tableNameOfFood,
          where: 'food_id = ?',
          whereArgs: [foodId],
        );
      });
    } catch (e) {
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

      final servingInfoList =
          servingInfoRows.map((row) => ServingInfo.fromMap(row)).toList();

      foods.add(FoodAndServingInfo(
        food: food,
        servingInfoList: servingInfoList,
      ));
    }
    return foods;
  }

  // 查询指定食物的单份营养素信息
  Future<FoodAndServingInfo?> searchFoodWithServingInfoByFoodId(
    int foodId,
  ) async {
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

      final servingInfoList =
          servingInfoRows.map((row) => ServingInfo.fromMap(row)).toList();

      final foodAndServingInfo = FoodAndServingInfo(
        food: food,
        servingInfoList: servingInfoList,
      );
      return foodAndServingInfo;
    }
  }

  ///***********************************************/
  /// daily_food_item 的相关操作
  ///

  // 批量插入饮食日记条目
  Future<List<Object?>> insertDailyFoodItemList(
    List<DailyFoodItem> dfiList,
  ) async {
    var batch = (await database).batch();

    for (var item in dfiList) {
      batch.insert(DietaryDdl.tableNameOfDailyFoodItem, item.toMap());
    }

    return batch.commit();
  }

  // 修改单条 daily_food_item
  Future<int> updateDailyFoodItem(DailyFoodItem dailyFoodItem) async =>
      (await database).update(
        DietaryDdl.tableNameOfDailyFoodItem,
        dailyFoodItem.toMap(),
        where: 'daily_food_item_id = ?',
        whereArgs: [dailyFoodItem.dailyFoodItemId],
      );

  // 删除单条 daily_food_item
  Future<int> deleteDailyFoodItem(int dailyFoodItemId) async =>
      (await database).delete(
        DietaryDdl.tableNameOfDailyFoodItem,
        where: "daily_food_item_id=?",
        whereArgs: [dailyFoodItemId],
      );

// 条件查询日记条目，可以带food和serving info 详情
  // 返回值动态类型，有查详情则是 List<DailyFoodItemWithFoodServing>，
  // 不查详情则是 List<DailyFoodItem>
  Future<List<dynamic>> queryDailyFoodItemListWithDetail({
    int? dailyFoodItemId,
    String? startDate,
    String? endDate,
    String? mealCategory,
    bool withDetail = false,
  }) async {
    Database db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (dailyFoodItemId != null) {
      where.add('daily_food_item_id = ?');
      whereArgs.add(dailyFoodItemId);
    }

    if (mealCategory != null) {
      where.add('meal_category = ?');
      whereArgs.add(mealCategory);
    }

    if (startDate != null) {
      where.add('date >= ?');
      whereArgs.add(startDate);
    }

    if (endDate != null) {
      where.add('date <= ?');
      whereArgs.add(endDate);
    }

    final dfiRows = await db.query(
      DietaryDdl.tableNameOfDailyFoodItem,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

// 如果需要查询详情，则继续查以下内容
    if (withDetail) {
      // 如果有查询到日记条目，查询对应的食物和营养素详情
      final List<DailyFoodItem> list =
          dfiRows.map((row) => DailyFoodItem.fromMap(row)).toList();

      // 用来存要放回的饮食日记条目详情
      final dfiwfsList = <DailyFoodItemWithFoodServing>[];

      for (var dailyFoodItem in list) {
        // ？？？当天日记条目的食物和营养素通过id查询都应该只有一条，数据正确的话也不会为空，所以不做检查
        final food = Food.fromMap((await db.query(
          DietaryDdl.tableNameOfFood,
          where: 'food_id = ?',
          whereArgs: [dailyFoodItem.foodId],
        ))
            .first);

        final servingInfo = ServingInfo.fromMap((await db.query(
                DietaryDdl.tableNameOfServingInfo,
                where: 'serving_info_id = ?',
                whereArgs: [dailyFoodItem.servingInfoId]))
            .first);

        dfiwfsList.add(DailyFoodItemWithFoodServing(
          dailyFoodItem: dailyFoodItem,
          food: food,
          servingInfo: servingInfo,
        ));
      }

      return dfiwfsList;
    } else {
      // 不查询详情就直接返回饮食日记条目列表
      return dfiRows.map((row) => DailyFoodItem.fromMap(row)).toList();
    }
  }

  ///***********************************************/
  /// dietary_user 的相关操作
  ///

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
    var batch = (await database).batch();

    for (var item in userList) {
      batch.insert(DietaryDdl.tableNameOfDietaryUser, item.toMap());
    }

    return batch.commit();
  }

  // 修改单条 dietaryUser
  Future<int> updateDietaryUser(DietaryUser user) async =>
      (await database).update(
        DietaryDdl.tableNameOfDietaryUser,
        user.toMap(),
        where: 'user_id = ?',
        whereArgs: [user.userId],
      );

  // 删除单条 dietaryUser
  Future<int> deleteDietaryUser(int userId) async => (await database).delete(
        DietaryDdl.tableNameOfDietaryUser,
        where: "user_id = ?",
        whereArgs: [userId],
      );

  // 查询用户带上每周具体摄入目标
  // ？？？现在就是显示登录用户信息，用户密码登录成功之后记住信息？(缓存还不太懂，这里就账号密码id查询)
  // 这里查询的都是当前app的唯一用户，就一个用户
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

    // 这里查询的都是唯一用户，就一个用户
    final user = DietaryUser.fromMap((await db.query(
            DietaryDdl.tableNameOfDietaryUser,
            where: where.isNotEmpty ? where.join(" AND ") : null,
            whereArgs: whereArgs.isNotEmpty ? whereArgs : null))
        .first);

    final intakeGoalRows = await db.query(
      DietaryDdl.tableNameOfIntakeDailyGoal,
      where: "user_id = ? ",
      whereArgs: [user.userId],
    );

    List<IntakeDailyGoal> goals =
        intakeGoalRows.map((row) => IntakeDailyGoal.fromMap(row)).toList();

    return DietaryUserWithIntakeDailyGoal(goals: goals, user: user);
  }

  // 修改用户的周摄入宏量素目标
  Future<int> updateUserIntakeDailyGoal(List<IntakeDailyGoal> goals) async {
    Database db = await database;

    try {
      int rst = 0;

      await db.transaction((txn) async {
        for (var goal in goals) {
          List<Map<String, dynamic>> result = await txn.query(
            DietaryDdl.tableNameOfIntakeDailyGoal,
            where: 'user_id = ? and day_of_week = ?',
            whereArgs: [goal.userId, goal.dayOfWeek],
          );
          // 如果已存在，指定用户指定周几的目标值只有1条数据才对
          if (result.isNotEmpty) {
            var existed = IntakeDailyGoal.fromMap(result[0]);
            goal.intakeDailyGoalId = existed.intakeDailyGoalId;

            rst = await txn.update(
              DietaryDdl.tableNameOfIntakeDailyGoal,
              goal.toMap(),
              where: 'user_id = ? and day_of_week = ?',
              whereArgs: [goal.userId, goal.dayOfWeek],
            );
          } else {
            // 如果该用户指定weekeday没有数据，则新增
            rst = await txn.insert(
              DietaryDdl.tableNameOfIntakeDailyGoal,
              goal.toMap(),
            );
          }
        }
      });

      return rst;
    } catch (e) {
      // Handle the error
      print('Error at updateUserIntakeDailyGoal: $e');
      // 抛出异常来触发回滚的方式是 sqflite 中常用的做法
      rethrow;
    }
  }
}

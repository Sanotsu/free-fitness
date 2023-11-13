/// sqlite中创建table的sql语句
/// 2023-10-23 训练模块相关db语句
class DietaryDdl {
  // db名称
  static String databaseName = "embedded_dietary.db";

  static const tableNameOfFood = 'ff_food';
  static const tableNameOfServingInfo = 'ff_serving_info';
  // 日记条目表（一天多餐多条目，空间换时间的设计）
  static const tableNameOfDailyFoodItem = 'ff_daily_food_item';
  // 用户基础表
  static const tableNameOfDietaryUser = 'ff_dietary_user';
  // 饮食摄入目标表
  static const tableNameOfIntakeDailyGoal = 'ff_intake_daily_goal';

  static const String ddlForFood = """
    CREATE TABLE IF NOT EXISTS $tableNameOfFood (
      food_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      brand TEXT NOT NULL,
      product TEXT NOT NULL,
      photos TEXT,
      tags TEXT,
      category TEXT,
      contributor TEXT,
      gmt_create TEXT,
      UNIQUE(brand,product)
    );
    """;

  static const String ddlForServingInfo = """
    CREATE TABLE IF NOT EXISTS $tableNameOfServingInfo (
      serving_info_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      food_id INTEGER NOT NULL,
      serving_size INTEGER NOT NULL,
      serving_unit TEXT NOT NULL,
      energy REAL NOT NULL,
      protein REAL NOT NULL,
      total_fat REAL NOT NULL,
      saturated_fat REAL,
      trans_fat REAL,
      polyunsaturated_fat REAL,
      monounsaturated_fat REAL,
      cholesterol REAL,
      total_carbohydrate REAL NOT NULL,
      sugar REAL,
      dietary_fiber REAL,
      sodium REAL NOT NULL,
      potassium REAL,
      contributor TEXT,
      gmt_create TEXT,
      update_user TEXT,
      gmt_modified TEXT
    );
    """;

  static const String ddlForDailyFoodItem = """
    CREATE TABLE IF NOT EXISTS $tableNameOfDailyFoodItem (
      daily_food_item_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      meal_category TEXT NOT NULL,
      food_id INTEGER NOT NULL,
      food_intake_size REAL NOT NULL,
      serving_info_id INTEGER NOT NULL,
      contributor TEXT,
      gmt_create TEXT,
      update_user TEXT,
      gmt_modified TEXT
    );
    """;

  static const String ddlForDietaryUser = """
    CREATE TABLE $tableNameOfDietaryUser (
      user_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_name TEXT NOT NULL,
      user_code TEXT,
      gender TEXT,
      password TEXT,
      description TEXT,
      date_of_birth TEXT,
      height REAL,
      current_weight REAL,
      target_weight REAL,
      rda_goal INTEGER,
      protein_goal REAL,
      fat_goal REAL,
      cho_goal REAL
    );
    """;

  static const String ddlForIntakeDailyGoal = """
    CREATE TABLE IF NOT EXISTS $tableNameOfIntakeDailyGoal (
      intake_daily_goal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      day_of_week TEXT NOT NULL,
      rda_daily_goal INTEGER NOT NULL,
      protein_daily_goal REAL NOT NULL,
      fat_daily_goal REAL NOT NULL,
      cho_daily_goal REAL NOT NULL
    );
    """;
}

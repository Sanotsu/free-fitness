/// sqlite中创建table的sql语句
/// 2023-10-23 训练模块相关db语句
class DietaryDdl {
  // db名称
  static String databaseName = "embedded_dietary.db";

  static const tableNameOfFood = 'ff_food';
  static const tableNameOfServingInfo = 'ff_serving_info';
  static const tableNameOfMeal = 'ff_meal';
  static const tableNameOfFoodDailyLog = 'ff_food_daily_log';

  static const String ddlForFood = """
    CREATE TABLE IF NOT EXISTS $tableNameOfFood (
      food_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      brand TEXT NOT NULL,
      product TEXT NOT NULL,
      photos TEXT,
      tags TEXT,
      category TEXT,
      contributor TEXT,
      gmt_create TEXT
    );
    """;

  static const String ddlForServingInfo = """
    CREATE TABLE IF NOT EXISTS $tableNameOfServingInfo (
      serving_info_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      food_id INTEGER NOT NULL,
      is_metric INTEGER,
      serving_size TEXT,
      metric_serving_size INTEGER,
      metric_serving_unit TEXT,
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
      upd_user_id TEXT,
      gmt_modified TEXT
    );
    """;

  static const String ddlForMeal = """
    CREATE TABLE IF NOT EXISTS $tableNameOfMeal (
      meal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      meal_name TEXT,
      food_id INTEGER NOT NULL,
      serving_info_id INTEGER NOT NULL,
      intake INTEGER NOT NULL,
      description TEXT,
      contributor TEXT,
      gmt_create TEXT,
      gmt_modified TEXT
    );
    """;

  static const String ddlForFoodDailyLog = """
    CREATE TABLE IF NOT EXISTS $tableNameOfFoodDailyLog (
      food_daily_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      date TEXT NOT NULL,
      breakfast_meal_id INTEGER,
      lunch_meal_id INTEGER,
      dinner_meal_id INTEGER,
      other_meal_id INTEGER,
      contributor TEXT,
      gmt_create TEXT,
      gmt_modified TEXT
    );
    """;
}

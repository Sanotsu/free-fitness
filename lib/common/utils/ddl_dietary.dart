/// sqlite中创建table的sql语句
/// 2023-10-23 训练模块相关db语句
class DietaryDdl {
  // db名称
  static String databaseName = "embedded_dietary.db";

  static const tableNameOfFood = 'ff_food';
  static const tableNameOfServingInfo = 'ff_serving_info';
  // 日记条目表（一天多餐多条目，空间换时间的设计）
  static const tableNameOfDailyFoodItem = 'ff_daily_food_item';
  // 餐次的食物照片表
  static const tableNameOfMealPhoto = 'ff_meal_photo';

  static const String ddlForFood = """
    CREATE TABLE IF NOT EXISTS $tableNameOfFood (
      food_id     INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      brand       TEXT      NOT NULL,
      product     TEXT      NOT NULL,
      description TEXT,
      photos      TEXT,
      tags        TEXT,
      category    TEXT,
      contributor TEXT,
      gmt_create  TEXT,
      is_deleted  INTEGER,
      UNIQUE(brand,product)
    );
    """;

  // 2023-12-06 新增唯一检查，同一个食物、同一个单位、同一个数量的联合值是唯一的
  static const String ddlForServingInfo = """
    CREATE TABLE IF NOT EXISTS $tableNameOfServingInfo (
      serving_info_id       INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      food_id               INTEGER   NOT NULL,
      serving_size          INTEGER   NOT NULL,
      serving_unit          TEXT      NOT NULL,
      energy                REAL      NOT NULL,
      protein               REAL      NOT NULL,
      total_fat             REAL      NOT NULL,
      saturated_fat         REAL,
      trans_fat             REAL,
      polyunsaturated_fat   REAL,
      monounsaturated_fat   REAL,
      cholesterol           REAL,
      total_carbohydrate    REAL NOT NULL,
      sugar                 REAL,
      dietary_fiber         REAL,
      sodium                REAL NOT NULL,
      potassium             REAL,
      contributor           TEXT,
      gmt_create            TEXT,
      update_user           TEXT,
      gmt_modified          TEXT,
      is_deleted            INTEGER,
      UNIQUE(food_id,serving_size,serving_unit)
    );
    """;

  static const String ddlForDailyFoodItem = """
    CREATE TABLE IF NOT EXISTS $tableNameOfDailyFoodItem (
      daily_food_item_id  INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_id             INTEGER   NOT NULL,
      date                TEXT      NOT NULL,
      meal_category       TEXT      NOT NULL,
      food_id             INTEGER   NOT NULL,
      food_intake_size    REAL      NOT NULL,
      serving_info_id     INTEGER   NOT NULL,
      gmt_create          TEXT,
      gmt_modified        TEXT
    );
    """;

  static const String ddlForMealPhoto = """
    CREATE TABLE IF NOT EXISTS $tableNameOfMealPhoto (
      meal_photo_id   INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_id         INTEGER   NOT NULL,
      date            TEXT      NOT NULL,
      meal_category   TEXT      NOT NULL,
      photos          TEXT      NOT NULL,
      gmt_create      TEXT      NOT NULL
    );
    """;
}

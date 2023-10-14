/// sqlite中创建table的sql语句
/// 2023-10-23 训练模块相关db语句
class SqliteSqlStatements {
  /// db name、table names
  // db名称
  static String databaseName = "embedded_train.db";
  // 动作基础表
  static const tableNameOfExercise = 'exercise';
  // 动作组基础表
  static const tableNameOfAction = 'action';
  // 训练计划基础表
  static const tableNameOfPlan = 'plan';
  // 用户基础表
  static const tableNameOfUser = 'user';
  // 训练日志记录表
  static const tableNameOfTrainingLog = 'training_log';
  // 体重趋势记录表
  static const tableNameOfWeightTrend = 'weight_trend';

  static const String ddlForExercise = """
    CREATE TABLE $tableNameOfExercise (
      exercise_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      exercise_code TEXT UNIQUE NOT NULL,
      exercise_name TEXT UNIQUE NOT NULL,
      force TEXT,
      level TEXT,
      mechanic TEXT,
      equipment TEXT,
      instructions TEXT,
      tts_notes TEXT,
      category TEXT NOT NULL,
      primary_muscles TEXT,
      secondary_muscles TEXT,
      images TEXT,
      is_custom INTEGER DEFAULT 0,
      contributor TEXT,
      gmt_create TEXT NOT NULL,
      gmt_modified TEXT 
    );
    """;

  static const String ddlForAction = """
    CREATE TABLE $tableNameOfAction (
      action_id INTEGER,
      action_code TEXT,
      action_name TEXT,
      action_category TEXT,
      exercise_id TEXT,
      sorted_number INTEGER,
      frequency INTEGER,
      duration  INTEGER,
      weight  REAL,
      contributor TEXT,
      gmt_create  TEXT,
      gmt_modified  TEXT,
      PRIMARY KEY (action_id,exercise_id,sorted_number)
    );
    """;

  static const String ddlForPlan = """
    CREATE TABLE $tableNameOfPlan (
      plan_id INTEGER,
      plan_code TEXT,
      plan_name TEXT,
      plan_category TEXT,
      day_number  INTEGER,
      action_id INTEGER,
      contributor TEXT,
      gmt_create  TEXT,
      gmt_modified  TEXT,
      PRIMARY KEY (plan_id,day_number)
    );
    """;

  static const String ddlForUser = """
    CREATE TABLE $tableNameOfUser (
      user_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      user_code TEXT,
      user_name TEXT,
      height  REAL,
      height_unit  TEXT
    );
    """;

  static const String ddlForTrainedLog = """
    CREATE TABLE $tableNameOfTrainingLog (
      trained_log_id  INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      user_id INTEGER,
      plan_id INTEGER,
      day_number  INTEGER,
      is_completed  INTEGER,
      sorted_number INTEGER,
      trained_date  TEXT,
      trained_duration  REAL
    );
    """;

  static const String ddlForWeightTrend = """
    CREATE TABLE $tableNameOfWeightTrend (
      weight_trend_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      user_id INTEGER,
      measured_date TEXT,
      weight  REAL,
      weight_unit TEXT,
      height  REAL,
      height_unit  TEXT,
      bmi_value REAL
    );
    """;
}

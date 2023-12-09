/// sqlite中创建table的sql语句
/// 2023-10-23 训练模块相关db语句
class UserDdl {
  // db名称
  static String databaseName = "embedded_user.db";

  // 用户基础表
  static const tableNameOfUser = 'ff_user';
  // 饮食摄入目标表
  static const tableNameOfIntakeDailyGoal = 'ff_intake_daily_goal';
  // 用户体重趋势表
  static const tableNameWeightTrend = 'ff_weight_trend';

  static const String ddlForUser = """
    CREATE TABLE $tableNameOfUser (
      user_id           INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_name         TEXT      NOT NULL,
      user_code         TEXT,
      gender            TEXT,
      avatar            TEXT,
      password          TEXT,
      description       TEXT,
      date_of_birth     TEXT,
      height            REAL,
      height_unit       TEXT,
      current_weight    REAL,
      target_weight     REAL,
      weight_unit       TEXT,
      rda_goal          INTEGER,
      protein_goal      REAL,
      fat_goal          REAL,
      cho_goal          REAL,
      action_rest_time  INTEGER,
      UNIQUE(user_name,user_code)
    );
    """;

  static const String ddlForIntakeDailyGoal = """
    CREATE TABLE IF NOT EXISTS $tableNameOfIntakeDailyGoal (
      intake_daily_goal_id    INTEGER     NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_id                 INTEGER     NOT NULL,
      day_of_week             TEXT        NOT NULL,
      rda_daily_goal          INTEGER     NOT NULL,
      protein_daily_goal      REAL        NOT NULL,
      fat_daily_goal          REAL        NOT NULL,
      cho_daily_goal          REAL        NOT NULL
    );
    """;

  static const String ddlForWeightTrend = """
    CREATE TABLE IF NOT EXISTS $tableNameWeightTrend (
      weight_trend_id   INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      user_id           INTEGER   NOT NULL,
      weight            REAL      NOT NULL,
      weight_unit       TEXT      NOT NULL,
      height            REAL      NOT NULL,
      height_unit       TEXT      NOT NULL,
      bmi               REAL      NOT NULL,
      gmt_create        TEXT      NOT NULL
    );
    """;
}

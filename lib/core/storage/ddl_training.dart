class TrainingDdl {
  /// sqlite中创建table的sql语句
  /// 2023-10-23 训练模块相关db语句
  ///
  /// /// 这个训练计划从小到大应该是：
  ///   1、一个基础活动（Exercise）就是最基础的活动的元数据，描述这个活动的一些信息。
  ///   2、一个动作（Action）是一个基础活动+对应配置。比如俯卧撑+30个，高抬腿+30秒。注意，一个动作只针对一个基础活动进行配置，当然一个基础活动可以有不同的配置，则变成不同的动作。
  ///   3、一个动作组（Group）有多个动作。注意，一个动作可以被多个不同的动作组使用，多对多的关系（group_has_action）。
  ///   4、一个训练计划（Plan）有多个训练日，一个训练日实际就是一组动作，即一个动作组。注意，一个动作组也可以被多个不同的训练计划使用，多对多的关系（plan_has_group）。
  ///

  // db名称
  static String databaseName = "embedded_workout.db";

  // 创建的表名加上项目前缀，避免出现关键字问题
  // 基础活动基础表
  static const tableNameOfExercise = 'ff_exercise';
  // 动作基础表
  static const tableNameOfAction = 'ff_action';
  // 动作组表
  static const tableNameOfGroup = 'ff_group';
  // 训练计划基础表
  static const tableNameOfPlan = 'ff_plan';
  // 训练计划-动作组关系表
  static const tableNameOfPlanHasGroup = 'ff_plan_has_group';

  // 2023-12-27 训练日志基础宽表，不再级联查询plan和group
  static const tableNameOfTrainedDetailLog = 'ff_trained_detail_log';

  static const String ddlForExercise = """
    CREATE TABLE $tableNameOfExercise (
      exercise_id         INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      exercise_code       TEXT      UNIQUE NOT NULL,
      exercise_name       TEXT      UNIQUE NOT NULL,
      force               TEXT,
      level               TEXT,
      mechanic            TEXT,
      equipment           TEXT,
      counting_mode       TEXT      NOT NULL,
      standard_duration   INTEGER   NOT NULL  DEFAULT 1,
      instructions        TEXT,
      tts_notes           TEXT,
      category            TEXT      NOT NULL,
      primary_muscles     TEXT,
      secondary_muscles   TEXT,
      images              TEXT,
      is_custom           INTEGER   DEFAULT 0,
      contributor         TEXT,
      gmt_create          TEXT,
      gmt_modified        TEXT 
    );
    """;

  static const String ddlForAction = """
    CREATE TABLE $tableNameOfAction (
      action_id         INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      group_id          INTEGER   NOT NULL,
      exercise_id       INTEGER   NOT NULL,
      frequency         INTEGER,
      duration          INTEGER,
      equipment_weight  REAL
    );
    """;

  static const String ddlForGroup = """
    CREATE TABLE $tableNameOfGroup (
      group_id        INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      group_name      TEXT      UNIQUE NOT NULL,
      group_category  TEXT      NOT NULL,
      group_level     TEXT      NOT NULL,
      consumption     INTEGER,
      time_spent      INTEGER,
      description     TEXT,
      contributor     TEXT,
      gmt_create      TEXT,
      gmt_modified    TEXT
    );
    """;

  static const String ddlForPlan = """
    CREATE TABLE $tableNameOfPlan (
      plan_id         INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      plan_code       TEXT      UNIQUE NOT NULL,
      plan_name       TEXT      UNIQUE NOT NULL,
      plan_category   TEXT      NOT NULL,
      plan_level      TEXT      NOT NULL,
      plan_period     INTEGER   NOT NULL,
      description     TEXT,
      contributor     TEXT,
      gmt_create      TEXT,
      gmt_modified    TEXT
    );
    """;

  static const String ddlForPlanHasGroup = """
    CREATE TABLE $tableNameOfPlanHasGroup  (
      plan_has_group_id   INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      plan_id             INTEGER   NOT NULL,
      group_id            INTEGER   NOT NULL,
      day_number          INTEGER   NOT NULL
    );
    """;

  static const String ddlForTrainedDetailLog = """
    CREATE TABLE $tableNameOfTrainedDetailLog (
      trained_detail_log_id   INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      trained_date            TEXT,
      user_id                 INTEGER   NOT NULL,
      plan_name               TEXT,
      plan_category           TEXT,
      plan_level              TEXT,
      day_number              INTEGER,
      group_name              TEXT,
      group_category          TEXT,
      group_level             TEXT,
      consumption             INTEGER,
      trained_start_time      TEXT      NOT NULL,
      trained_end_time        TEXT      NOT NULL,
      trained_duration        INTEGER   NOT NULL,
      totol_paused_time       INTEGER   NOT NULL,
      total_rest_time         INTEGER   NOT NULL
    );
    """;
}

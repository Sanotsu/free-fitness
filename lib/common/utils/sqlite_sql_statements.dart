/// sqlite中创建table的sql语句
/// 2023-10-23 训练模块相关db语句
///
/// /// 这个训练计划从小到大应该是：
///   1、一个基础活动（Exercise）就是最基础的活动的元数据，描述这个活动的一些信息。
///   2、一个动作（Action）是一个基础活动+对应配置。比如俯卧撑+30个，高抬腿+30秒。注意，一个动作只针对一个基础活动进行配置，当然一个基础活动可以有不同的配置，则变成不同的动作。
///   3、一个动作组（Group）有多个动作。注意，一个动作可以被多个不同的动作组使用，多对多的关系（group_has_action）。
///   4、一个训练计划（Plan）有多个训练日，一个训练日实际就是一组动作，即一个动作组。注意，一个动作组也可以被多个不同的训练计划使用，多对多的关系（plan_has_group）。
///
class DbCconstants {
  // db名称
  static String databaseName = "embedded_workout.db";
}

class TrainingDdl {
  /// db name、table names
  // 创建的表名加上项目前缀，避免出现关键字问题
  // 基础活动基础表
  static const tableNameOfExercise = 'ff_exercise';
  // 动作基础表
  static const tableNameOfAction = 'ff_action';
  // 动作组表
  static const tableNameOfGroup = 'ff_group';
  // 动作组-动作关系表
  static const tableNameOfGroupHasAction = 'ff_group_has_action';
  // 训练计划基础表
  static const tableNameOfPlan = 'ff_plan';
  // 训练计划-动作组关系表
  static const tableNameOfPlanHasGroup = 'ff_plan_has_group';
  // 用户基础表
  static const tableNameOfUser = 'ff_user';
  // 训练日志记录表
  static const tableNameOfTrainingLog = 'ff_training_log';
  // 体重趋势记录表
  static const tableNameOfWeightTrend = 'ff_weight_trend';

  static const String ddlForExercise = """
    CREATE TABLE $tableNameOfExercise (
      exercise_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      exercise_code TEXT UNIQUE NOT NULL,
      exercise_name TEXT UNIQUE NOT NULL,
      force TEXT,
      level TEXT,
      mechanic TEXT,
      equipment TEXT,
      standard_duration TEXT DEFAULT '1',
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
      action_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      action_code TEXT UNIQUE NOT NULL,
      action_name TEXT UNIQUE NOT NULL,
      exercise_id INTEGER,
      frequency INTEGER,
      duration  INTEGER,
      rest_interval  INTEGER,
      equipment_weight  TEXT,
      action_level TEXT,
      description  REAL,
      contributor TEXT,
      gmt_create  TEXT,
      gmt_modified  TEXT
    );
    """;

  static const String ddlForGroup = """
    CREATE TABLE $tableNameOfGroup (
      group_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      group_code TEXT UNIQUE NOT NULL,
      group_name TEXT UNIQUE NOT NULL,
      group_category TEXT,
      group_level TEXT,
      consumption INTEGER,
      time_spent INTEGER,
      description TEXT,
      contributor TEXT,
      gmt_create TEXT,
      gmt_modified TEXT
    );
    """;

  static const String ddlForGroupHaAction = """
    CREATE TABLE $tableNameOfGroupHasAction (
      group_has_action_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      group_id INTEGER,
      action_id INTEGER,
      action_order INTEGER
    );
    """;

  static const String ddlForPlan = """
    CREATE TABLE $tableNameOfPlan (
      plan_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      plan_code TEXT UNIQUE NOT NULL,
      plan_name TEXT UNIQUE NOT NULL,
      plan_category TEXT,
      plan_level  INTEGER,
      description TEXT,
      contributor TEXT,
      gmt_create  TEXT,
      gmt_modified  TEXT
    );
    """;

  static const String ddlForPlanHasGroup = """
    CREATE TABLE $tableNameOfPlanHasGroup  (
      plan_has_group_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
      plan_id INTEGER,
      group_id INTEGER,
      group_order INTEGER
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

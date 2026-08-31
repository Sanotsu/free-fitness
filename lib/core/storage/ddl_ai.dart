/// sqlite中创建table的sql语句
/// 2026-08-27 AI 助手模块相关db语句
/// 风格与其他四库一致(embedded_ 前缀库名 / ff_ 前缀表名 / 整型自增主键 / gmt_ 时间字段)
/// AI 模块为当前版本全新内容，建表即最终形态，无历史库兼容问题
/// (测试期数据不兼容时卸载重装即可)；后续如需改表再引入版本化升级。
class AiDdl {
  // db名称
  static String databaseName = "embedded_ai.db";

  static const tableNameOfAiConversation = 'ff_ai_conversation';
  static const tableNameOfAiMessage = 'ff_ai_message';
  static const tableNameOfAiRole = 'ff_ai_role';

  static const String ddlForAiConversation =
      """
    CREATE TABLE IF NOT EXISTS $tableNameOfAiConversation (
      conversation_id   INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      title             TEXT,
      role_key          TEXT      NOT NULL,
      config_id         TEXT,
      config_name       TEXT,
      model_name        TEXT,
      gmt_create        TEXT,
      gmt_modified      TEXT,
      biz_type          TEXT,
      biz_key           TEXT,
      biz_hash          TEXT
    );
    """;

  static const String ddlForAiMessage =
      """
    CREATE TABLE IF NOT EXISTS $tableNameOfAiMessage (
      message_id        INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      conversation_id   INTEGER   NOT NULL,
      role              TEXT      NOT NULL,
      content           TEXT,
      image_paths       TEXT,
      model_name        TEXT,
      status            TEXT,
      gmt_create        TEXT
    );
    """;

  static const String ddlForAiRole =
      """
    CREATE TABLE IF NOT EXISTS $tableNameOfAiRole (
      role_id           INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      name              TEXT      NOT NULL,
      system_prompt     TEXT      NOT NULL,
      gmt_create        TEXT,
      gmt_modified      TEXT
    );
    """;
}

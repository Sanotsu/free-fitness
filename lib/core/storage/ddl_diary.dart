/// sqlite中创建table的sql语句
/// 2023-10-23 训练模块相关db语句
class DiaryDdl {
  // db名称
  static String databaseName = "embedded_diary.db";

  static const tableNameOfDiary = 'ff_diary';

  static const String ddlForDiary = """
    CREATE TABLE IF NOT EXISTS $tableNameOfDiary (
      diary_id      INTEGER   NOT NULL PRIMARY KEY AUTOINCREMENT,
      date          TEXT      NOT NULL,
      title         TEXT      NOT NULL,
      content       TEXT      NOT NULL,
      tags          TEXT,
      category      TEXT,
      mood          TEXT,
      photos        TEXT,
      user_id       INTEGER,
      gmt_create    TEXT,
      gmt_modified  TEXT
    );
    """;
}

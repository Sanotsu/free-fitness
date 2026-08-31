import 'package:sqflite/sqflite.dart';

import '../../l10n/app_localizations.dart';
import '../utils/import_progress.dart';
import 'db_ai_helper.dart';
import 'db_diary_helper.dart';
import 'db_dietary_helper.dart';
import 'db_training_helper.dart';
import 'db_user_helper.dart';
import 'ddl_ai.dart';
import 'ddl_diary.dart';
import 'ddl_dietary.dart';
import 'ddl_training.dart';
import 'ddl_user.dart';

/// 2026-08-27 备份恢复的"去重合并"结果统计
class BackupMergeResult {
  int inserted = 0;
  int skipped = 0;

  // 其中因"内置数据身份已存在"而跳过的行数(提示用户用)
  int builtinSkipped = 0;

  // AI 会话 备份旧id → 本机新id 映射(图片目录合并时使用)
  Map<int, int> aiConversationIdMap = {};
}

///
/// 恢复合并进度的全局通知中心(复用 ImportProgress 模型与 UI 浮层)：
/// mergeAll 按"表"为最小单位推进——先统计待合并总行数，
/// 每处理完一张表上报一次 current/total 与当前表名，
/// 页面在恢复前 showImportProgressOverlay()、结束后关闭即可看到实时进度。
///
class RestoreProgressCenter {
  static void update(ImportProgress? p) => ImportProgressCenter.update(p);

  /// 全部表合并完成后的收尾通知
  static void done() => ImportProgressCenter.update(null);
}

///
/// 恢复模块划分(页面选块恢复与文件名归组的单一事实来源)
///
/// 备份 zip 内每个模块对应若干 ff_*.json 表文件；AI 模块还额外包含
/// llm_config.json 与 ai_images/ 目录(由页面代码一并处理)。
/// 用户链始终最先合并(其余模块的外键 id 重映射依赖 userMap，
/// 未勾选用户模块时各处都有 `userMap[oldId] ?? 原id` 兜底)。
///
class RestoreModules {
  static const Set<String> userTables = {
    'ff_user',
    'ff_intake_daily_goal',
    'ff_weight_trend',
  };
  static const Set<String> dietaryTables = {
    'ff_food',
    'ff_serving_info',
    'ff_daily_food_item',
    'ff_meal_photo',
  };
  static const Set<String> diaryTables = {'ff_diary'};
  static const Set<String> trainingTables = {
    'ff_exercise',
    'ff_group',
    'ff_action',
    'ff_plan',
    'ff_plan_has_group',
    'ff_trained_detail_log',
  };
  static const Set<String> aiTables = {
    'ff_ai_conversation',
    'ff_ai_message',
    'ff_ai_role',
  };

  static const String modUser = 'user';
  static const String modDietary = 'dietary';
  static const String modDiary = 'diary';
  static const String modTraining = 'training';
  static const String modAi = 'ai';

  static const Set<String> all = {
    modUser,
    modDietary,
    modDiary,
    modTraining,
    modAi,
  };

  /// 模块 → 该模块包含的表文件名集合(llm_config.json 与 ai_images 在模块外单独处理)
  static Set<String> tablesOf(String module) => switch (module) {
    modUser => userTables,
    modDietary => dietaryTables,
    modDiary => diaryTables,
    modTraining => trainingTables,
    modAi => aiTables,
    _ => {},
  };
}

///
/// 2026-08-27 备份恢复的去重合并服务
///
/// 需求：恢复备份时本机已有数据(如全新安装使用一段时间后发现历史备份)，
/// 结果应是【本机数据 ∪ 备份数据】的去重合并，而不是删库重灌/整体覆盖，
/// 尽可能兼容并完整保留双方数据。
///
/// 实现策略：
/// 1. 支持按模块选择恢复(RestoreModules；2026-08-27 补充)，只合并勾选模块的表；
/// 2. 每张表用"自然键"判重(优先取 DDL 中的 UNIQUE 约束列；无约束的表
///    用业务字段组合)，已存在则跳过，否则以新自增主键插入(不保留备份中的旧id)；
/// 3. 内置基础数据的身份保护(2026-08-27 补充)：用户导入内置动作/食物后可修改、
///    可删除，恢复旧备份时不允许把内置档案再原样引回来造成重复——
///    - 食物：《中国食物成分表》导出行 brand 即 foodCode(^\d{6}x?$)，
///      本机已存在同编码行时跳过(自然键是 brand+product，防的是"用户改过名称"
///      后被旧档以旧名称二次插入同编码食物)；
///    - 训练动作：free-exercise-db 的源 id 即 exercise_code，本来就是合并
///      自然键，同码行天然命中跳过；
/// 4. 存在外键引用的链路做 id 重映射，保证合并进来的行引用本机实体：
///    - 用户链：ff_user(user_name,user_code) → 各表 user_id 重映射
///    - 饮食链：ff_food(brand,product) → ff_serving_info(food_id,规格)
///      → ff_daily_food_item(food_id/serving_info_id/user_id)
///    - 训练链：ff_exercise(exercise_code) / ff_group(group_name) /
///      ff_plan(plan_code) → ff_action(group/exercise) / ff_plan_has_group(plan/group)
///    - AI 链：ff_ai_conversation(biz 或 标题+角色+创建时间) → ff_ai_message(
///      conversation_id 重映射并改写 image_paths 的会话目录前缀)
/// 5. 重复恢复同一备份：自然键全部命中 → 全部跳过，幂等。
///
class BackupMergeService {
  /// 合并入库。
  /// tables 的 key 为 json 文件名去掉 .json 后缀(即表名)，value 为该表的行 Map 列表
  /// (来自备份 zip 解压出的 json)；modules 为勾选要恢复的模块(null/空 = 全部兼容旧调用)；
  /// l10n 为调用方(页面)传入的本地化实例——服务层无 BuildContext，
  /// 进度浮层的模块/表名文案经它取 ARB 翻译(后续新增语言无需改本文件)。
  ///
  /// 进度：以"表"为粒度，每合并完一张表通过 RestoreProgressCenter 上报
  /// (标题=当前表说明,分母=勾选模块总行数)，页面配合 showImportProgressOverlay 展示。
  Future<BackupMergeResult> mergeAll(
    Map<String, List<Map<String, dynamic>>> tables, {
    Set<String>? modules,
    required AppLocalizations l10n,
  }) async {
    var mods = (modules == null || modules.isEmpty)
        ? RestoreModules.all
        : modules;
    var result = BackupMergeResult();

    // ===== 恢复进度的统计与上报辅助 =====
    // 模块名与表名说明全部走 ARB(由页面传入 l10n 实例)
    var modNames = {
      RestoreModules.modUser: l10n.restoreModUser,
      RestoreModules.modDietary: l10n.restoreModDietary,
      RestoreModules.modDiary: l10n.restoreModDiary,
      RestoreModules.modTraining: l10n.restoreModTraining,
      RestoreModules.modAi: l10n.restoreModAi,
    };
    // 表名 → 说明(进度浮层显示用)
    var tableLabels = {
      UserDdl.tableNameOfUser: l10n.restoreTblUser,
      UserDdl.tableNameOfIntakeDailyGoal: l10n.restoreTblIntakeGoal,
      UserDdl.tableNameWeightTrend: l10n.restoreTblWeightTrend,
      DietaryDdl.tableNameOfFood: l10n.restoreTblFood,
      DietaryDdl.tableNameOfServingInfo: l10n.restoreTblServing,
      DietaryDdl.tableNameOfDailyFoodItem: l10n.restoreTblDailyIntake,
      DietaryDdl.tableNameOfMealPhoto: l10n.restoreTblMealPhoto,
      DiaryDdl.tableNameOfDiary: l10n.restoreTblDiary,
      TrainingDdl.tableNameOfExercise: l10n.restoreTblExercise,
      TrainingDdl.tableNameOfGroup: l10n.restoreTblGroup,
      TrainingDdl.tableNameOfAction: l10n.restoreTblAction,
      TrainingDdl.tableNameOfPlan: l10n.restoreTblPlan,
      TrainingDdl.tableNameOfPlanHasGroup: l10n.restoreTblPlanDay,
      TrainingDdl.tableNameOfTrainedDetailLog: l10n.restoreTblTrainLog,
      AiDdl.tableNameOfAiConversation: l10n.restoreTblAiConv,
      AiDdl.tableNameOfAiMessage: l10n.restoreTblAiMsg,
      AiDdl.tableNameOfAiRole: l10n.restoreTblAiRole,
    };

    int progressCurrent = 0;
    int progressTotal = mods.fold<int>(
      0,
      (sum, m) =>
          sum +
          RestoreModules.tablesOf(
            m,
          ).fold<int>(0, (s, t) => s + (tables[t]?.length ?? 0)),
    );
    String currentModule = '';

    void report(String tableName) {
      if (progressTotal <= 0) return;
      ImportProgressCenter.update(
        ImportProgress(
          title:
              "${modNames[currentModule] ?? ''} · ${tableLabels[tableName] ?? tableName}",
          detail: l10n.restoreProgressDetail(progressCurrent, progressTotal),
          current: progressCurrent,
          total: progressTotal,
        ),
      );
    }

    Future<void> mergeTable({
      required Database db,
      required String table,
      required String idCol,
      required List<String> keyCols,
      void Function(Map<String, dynamic> row)? remap,
      void Function(Map<String, dynamic> oldRow, int newId)? onInserted,
      void Function(Map<String, dynamic> row, Map<String, dynamic> localRow)?
      onSkipped,
      String? identityCol,
      bool Function(dynamic value)? identityTest,
      Map<String, dynamic>? localIdentityIndex,
    }) async {
      await _mergeSimple(
        db: db,
        table: table,
        idCol: idCol,
        rows: _rows(tables, table),
        keyCols: keyCols,
        result: result,
        remap: remap,
        onInserted: onInserted,
        onSkipped: onSkipped,
        identityCol: identityCol,
        identityTest: identityTest,
        localIdentityIndex: localIdentityIndex,
        onRowDone: (_) {
          progressCurrent++;
        },
      );
      report(table);
    }

    var userDb = await DBUserHelper().database;
    var dietaryDb = await DBDietaryHelper().database;
    var trainingDb = await DBTrainingHelper().database;
    var diaryDb = await DBDiaryHelper().database;
    var aiDb = await DBAiHelper().database;

    // ========== 用户链(先合并用户，拿到 user_id 重映射) ==========
    var userMap = <int, int>{};
    if (mods.contains(RestoreModules.modUser)) {
      currentModule = RestoreModules.modUser;
      var userKeySet = <String>{};
      var existingUsers = await userDb.query(UserDdl.tableNameOfUser);
      for (var row in existingUsers) {
        userKeySet.add(_key(row, ['user_name', 'user_code']));
      }

      for (var row in _rows(tables, UserDdl.tableNameOfUser)) {
        var key = _key(row, ['user_name', 'user_code']);
        if (userKeySet.contains(key)) {
          // 已存在同(名,编号)用户：找到本机id建立映射
          var local = existingUsers.firstWhere(
            (e) => _key(e, ['user_name', 'user_code']) == key,
          );
          userMap[row['user_id'] as int] = local['user_id'] as int;
          result.skipped++;
        } else {
          var newRow = _stripId(row, 'user_id');
          var newId = await userDb.insert(UserDdl.tableNameOfUser, newRow);
          userMap[row['user_id'] as int] = newId;
          userKeySet.add(key);
          result.inserted++;
        }
        progressCurrent++;
      }
      report(UserDdl.tableNameOfUser);
    }
    // 占位说明：若备份中的行引用了不在备份用户表里的 user_id，
    // 保留原值不做映射(极端场景，不丢弃数据)

    // ========== 摄入目标/体重趋势(user_id 重映射) ==========
    if (mods.contains(RestoreModules.modUser)) {
      await mergeTable(
        db: userDb,
        table: UserDdl.tableNameOfIntakeDailyGoal,
        idCol: 'intake_daily_goal_id',
        keyCols: ['user_id', 'day_of_week'],
        remap: (row) =>
            row['user_id'] = userMap[row['user_id']] ?? row['user_id'],
      );

      await mergeTable(
        db: userDb,
        table: UserDdl.tableNameWeightTrend,
        idCol: 'weight_trend_id',
        keyCols: ['user_id', 'gmt_create'],
        remap: (row) =>
            row['user_id'] = userMap[row['user_id']] ?? row['user_id'],
      );
    }

    // ========== 饮食链：食物 → 份量信息 → 每日摄入 ==========
    if (mods.contains(RestoreModules.modDietary)) {
      // 内置食物(brand=成分表编码)的本机身份索引：编码→已有行
      var codeRegex = RegExp(r'^\d{6}x?$');
      var localFoodCodeIndex = <String, Map<String, dynamic>>{};
      for (var row in await dietaryDb.query(DietaryDdl.tableNameOfFood)) {
        var brand = row['brand'];
        if (brand is String && codeRegex.hasMatch(brand)) {
          localFoodCodeIndex.putIfAbsent(brand, () => row);
        }
      }

      var foodMap = <int, int>{};
      await mergeTable(
        db: dietaryDb,
        table: DietaryDdl.tableNameOfFood,
        idCol: 'food_id',
        keyCols: ['brand', 'product'],
        // 内置身份保护：同 foodCode 已存在于本机则整体跳过
        identityCol: 'brand',
        identityTest: (v) => v is String && codeRegex.hasMatch(v),
        localIdentityIndex: localFoodCodeIndex,
        onInserted: (oldRow, newId) =>
            foodMap[oldRow['food_id'] as int] = newId,
        onSkipped: (row, local) =>
            foodMap[row['food_id'] as int] = local['food_id'] as int,
      );

      var servingMap = <int, int>{};
      await mergeTable(
        db: dietaryDb,
        table: DietaryDdl.tableNameOfServingInfo,
        idCol: 'serving_info_id',
        keyCols: ['food_id', 'serving_size', 'serving_unit'],
        remap: (row) =>
            row['food_id'] = foodMap[row['food_id']] ?? row['food_id'],
        onInserted: (oldRow, newId) =>
            servingMap[oldRow['serving_info_id'] as int] = newId,
        onSkipped: (row, local) => servingMap[row['serving_info_id'] as int] =
            local['serving_info_id'] as int,
      );

      await mergeTable(
        db: dietaryDb,
        table: DietaryDdl.tableNameOfDailyFoodItem,
        idCol: 'daily_food_item_id',
        keyCols: [
          'user_id',
          'date',
          'meal_category',
          'food_id',
          'food_intake_size',
          'serving_info_id',
          'gmt_create',
        ],
        remap: (row) {
          row['user_id'] = userMap[row['user_id']] ?? row['user_id'];
          row['food_id'] = foodMap[row['food_id']] ?? row['food_id'];
          row['serving_info_id'] =
              servingMap[row['serving_info_id']] ?? row['serving_info_id'];
        },
      );

      await mergeTable(
        db: dietaryDb,
        table: DietaryDdl.tableNameOfMealPhoto,
        idCol: 'meal_photo_id',
        keyCols: ['user_id', 'date', 'meal_category'],
        remap: (row) =>
            row['user_id'] = userMap[row['user_id']] ?? row['user_id'],
      );
    }

    // ========== 手记(user_id 重映射) ==========
    if (mods.contains(RestoreModules.modDiary)) {
      currentModule = RestoreModules.modDiary;
      await mergeTable(
        db: diaryDb,
        table: DiaryDdl.tableNameOfDiary,
        idCol: 'diary_id',
        keyCols: ['user_id', 'date', 'title', 'gmt_create'],
        remap: (row) =>
            row['user_id'] = userMap[row['user_id']] ?? row['user_id'],
      );
    }

    // ========== 训练链：基础活动/动作组/计划 → 动作/计划关系/日志 ==========
    if (mods.contains(RestoreModules.modTraining)) {
      currentModule = RestoreModules.modTraining;
      var exerciseMap = <int, int>{};
      await mergeTable(
        db: trainingDb,
        table: TrainingDdl.tableNameOfExercise,
        idCol: 'exercise_id',
        // exercise_code 即 free-exercise-db 源 id，是内置动作身份，也是自然键：
        // 本机同码已存在一律跳过(改过名的不会被重复插入)
        keyCols: ['exercise_code'],
        onInserted: (oldRow, newId) =>
            exerciseMap[oldRow['exercise_id'] as int] = newId,
        onSkipped: (row, local) => exerciseMap[row['exercise_id'] as int] =
            local['exercise_id'] as int,
      );

      var groupMap = <int, int>{};
      await mergeTable(
        db: trainingDb,
        table: TrainingDdl.tableNameOfGroup,
        idCol: 'group_id',
        keyCols: ['group_name'],
        onInserted: (oldRow, newId) =>
            groupMap[oldRow['group_id'] as int] = newId,
        onSkipped: (row, local) =>
            groupMap[row['group_id'] as int] = local['group_id'] as int,
      );

      await mergeTable(
        db: trainingDb,
        table: TrainingDdl.tableNameOfAction,
        idCol: 'action_id',
        keyCols: [
          'group_id',
          'exercise_id',
          'frequency',
          'duration',
          'equipment_weight',
        ],
        remap: (row) {
          row['group_id'] = groupMap[row['group_id']] ?? row['group_id'];
          row['exercise_id'] =
              exerciseMap[row['exercise_id']] ?? row['exercise_id'];
        },
      );

      var planMap = <int, int>{};
      await mergeTable(
        db: trainingDb,
        table: TrainingDdl.tableNameOfPlan,
        idCol: 'plan_id',
        keyCols: ['plan_code'],
        onInserted: (oldRow, newId) =>
            planMap[oldRow['plan_id'] as int] = newId,
        onSkipped: (row, local) =>
            planMap[row['plan_id'] as int] = local['plan_id'] as int,
      );

      await mergeTable(
        db: trainingDb,
        table: TrainingDdl.tableNameOfPlanHasGroup,
        idCol: 'plan_has_group_id',
        keyCols: ['plan_id', 'group_id', 'day_number'],
        remap: (row) {
          row['plan_id'] = planMap[row['plan_id']] ?? row['plan_id'];
          row['group_id'] = groupMap[row['group_id']] ?? row['group_id'];
        },
      );

      await mergeTable(
        db: trainingDb,
        table: TrainingDdl.tableNameOfTrainedDetailLog,
        idCol: 'trained_detail_log_id',
        keyCols: ['user_id', 'trained_start_time'],
        remap: (row) =>
            row['user_id'] = userMap[row['user_id']] ?? row['user_id'],
      );
    }

    // ========== AI 链：会话 → 消息(改写图片路径前缀)；自定义角色 ==========
    if (mods.contains(RestoreModules.modAi)) {
      currentModule = RestoreModules.modAi;
      // 会话判重：业务场景会话(有 biz_type/biz_key)按业务身份判重(两台设备同一
      // 业务对象只保留一条会话)；自由会话按(标题+角色+创建时间)判重
      var plainKeyCols = ['title', 'role_key', 'gmt_create'];
      var existingConvs = await aiDb.query(AiDdl.tableNameOfAiConversation);

      // 本机会话的两套索引：业务身份 / 自然键
      var bizKeySet = <String>{};
      var plainKeySet = <String>{};
      Map<String, Map<String, dynamic>> bizRowMap = {};
      Map<String, Map<String, dynamic>> plainRowMap = {};
      for (var row in existingConvs) {
        if (row['biz_type'] != null && row['biz_key'] != null) {
          var k = _key(row, ['biz_type', 'biz_key']);
          bizKeySet.add(k);
          bizRowMap[k] = row;
        } else {
          var k = _key(row, plainKeyCols);
          plainKeySet.add(k);
          plainRowMap[k] = row;
        }
      }

      for (var row in _rows(tables, AiDdl.tableNameOfAiConversation)) {
        var oldId = row['conversation_id'] as int;
        var isBiz = row['biz_type'] != null && row['biz_key'] != null;
        var key = isBiz
            ? _key(row, ['biz_type', 'biz_key'])
            : _key(row, plainKeyCols);
        var keySet = isBiz ? bizKeySet : plainKeySet;

        if (keySet.contains(key)) {
          var local = isBiz ? bizRowMap[key]! : plainRowMap[key]!;
          result.aiConversationIdMap[oldId] = local['conversation_id'] as int;
          result.skipped++;
        } else {
          var newRow = _stripId(row, 'conversation_id');
          var newId = await aiDb.insert(
            AiDdl.tableNameOfAiConversation,
            newRow,
          );
          result.aiConversationIdMap[oldId] = newId;
          keySet.add(key);
          if (isBiz) {
            bizRowMap[key] = newRow..['conversation_id'] = newId;
          } else {
            plainRowMap[key] = newRow..['conversation_id'] = newId;
          }
          result.inserted++;
        }
        progressCurrent++;
      }
      report(AiDdl.tableNameOfAiConversation);

      await mergeTable(
        db: aiDb,
        table: AiDdl.tableNameOfAiMessage,
        idCol: 'message_id',
        keyCols: ['conversation_id', 'role', 'content', 'gmt_create'],
        remap: (row) {
          var oldConvId = row['conversation_id'] as int;
          var newConvId = result.aiConversationIdMap[oldConvId] ?? oldConvId;
          row['conversation_id'] = newConvId;

          // 图片相对路径前缀为旧会话id目录，映射到新会话id目录
          var paths = row['image_paths'] as String?;
          if (paths != null && paths.startsWith('$oldConvId/')) {
            row['image_paths'] =
                '$newConvId/${paths.substring('$oldConvId/'.length)}';
          }
        },
      );

      await mergeTable(
        db: aiDb,
        table: AiDdl.tableNameOfAiRole,
        idCol: 'role_id',
        keyCols: ['name', 'system_prompt'],
      );
    }

    return result;
  }

  // 取表数据(表不在备份里返回空列表——旧版本备份自然跳过)
  List<Map<String, dynamic>> _rows(
    Map<String, List<Map<String, dynamic>>> tables,
    String table,
  ) => tables[table] ?? [];

  /// 通用合并：加载本机表 → 逐行(可选重映射外键后)按 keyCols 判重 → 跳过或去 id 插入
  Future<void> _mergeSimple({
    required Database db,
    required String table,
    required String idCol,
    required List<Map<String, dynamic>> rows,
    required List<String> keyCols,
    required BackupMergeResult result,
    void Function(Map<String, dynamic> row)? remap,
    void Function(Map<String, dynamic> oldRow, int newId)? onInserted,
    void Function(Map<String, dynamic> row, Map<String, dynamic> localRow)?
    onSkipped,

    /// 2026-08-27 内置数据身份保护(三件套，null=不启用)：
    /// 备份行的 identityCol 取值通过 identityTest 判定为"内置编码"
    /// 且 localIdentityIndex 中已有同值行时，整行直接跳过——
    /// 这是自然键之外的第二道防线，防止用户改过内置项名称后被旧备份
    /// 以旧名称重复引入(食物 brand=foodCode 场景)
    String? identityCol,
    bool Function(dynamic value)? identityTest,
    Map<String, dynamic>? localIdentityIndex,

    /// 每处理完一行(插入或跳过)的回调(恢复进度统计用)
    void Function(Map<String, dynamic> row)? onRowDone,
  }) async {
    // 本机已有行建立 key 索引(供跳过时回查本机行，用于 id 映射回调)
    var existing = await db.query(table);
    var keySet = <String>{};
    Map<String, Map<String, dynamic>> keyRowMap = {};
    for (var row in existing) {
      var k = _key(row, keyCols);
      keySet.add(k);
      keyRowMap[k] = row;
    }

    for (var row in rows) {
      // 备份行先复制再重映射外键(不改动原始数据)
      var newRow = Map<String, dynamic>.from(row);
      remap?.call(newRow);

      // 内置身份优先判重(命中即视为"本机内置档案已存在")
      if (identityCol != null &&
          identityTest != null &&
          localIdentityIndex != null) {
        var iv = newRow[identityCol];
        if (iv != null &&
            identityTest(iv) &&
            localIdentityIndex.containsKey(iv)) {
          onSkipped?.call(row, localIdentityIndex[iv]!);
          result.skipped++;
          result.builtinSkipped++;
          onRowDone?.call(newRow);
          continue;
        }
      }

      var key = _key(newRow, keyCols);
      if (keySet.contains(key)) {
        onSkipped?.call(row, keyRowMap[key]!);
        result.skipped++;
      } else {
        var inserted = _stripId(newRow, idCol);
        var newId = await db.insert(table, inserted);
        keySet.add(key);
        keyRowMap[key] = newRow..[idCol] = newId;
        onInserted?.call(row, newId);
        result.inserted++;
      }
      onRowDone?.call(newRow);
    }
  }

  /// 行的自然键字符串(按列顺序取值拼接，null 归一为空串避免类型抖动)
  static String _key(Map<String, dynamic> row, List<String> cols) {
    return cols.map((c) => '${row[c] ?? ''}').join('⊂⊃');
  }

  /// 去掉自增主键列(让数据库自增分配新 id)
  static Map<String, dynamic> _stripId(Map<String, dynamic> row, String idCol) {
    var newRow = Map<String, dynamic>.from(row);
    newRow.remove(idCol);
    return newRow;
  }
}

import '../../utils/training_time_estimator.dart';
import '../../utils/tools.dart';
import '../../../core/constants/constants.dart';
import '../../../models/training_state.dart';

/// 2026-08-28 训练组业务数据的指纹串(纯数据，不含 prompt 模板文案)
///
/// 作为 AI 业务会话的 biz_hash 比对基准：只有组信息/动作配置/间隔休息
/// 这些真正参与分析的数据变化才触发重析；prompt 模板文案演进不影响指纹。
/// 动作含名称(改名也值得重析)；预估耗时由数据派生，以间隔休息配置入指纹。
String buildTrainingGroupDataHash(
  TrainingGroup group,
  List<ActionDetail> actions, {
  int? restSeconds,
}) {
  var sb = StringBuffer('g|${group.groupId}|${group.groupName}')
    ..write('|${group.groupCategory}|${group.groupLevel}');
  for (var ad in actions) {
    sb.write('|${ad.exercise.exerciseId}:${ad.exercise.exerciseName}');
    sb.write(':${ad.action.frequency}:${ad.action.duration}');
    sb.write(':${ad.action.equipmentWeight}');
  }
  sb.write('|r:${restSeconds ?? defaultActionRestSeconds}');
  return fnv1a64Hash(sb.toString());
}

/// 训划业务数据指纹(计划字段+每日各组动作配置，口径同上)
String buildTrainingPlanDataHash(
  TrainingPlan plan,
  List<GroupWithActions> groups, {
  int? restSeconds,
}) {
  var sb = StringBuffer('p|${plan.planId}|${plan.planName}')
    ..write('|${plan.planCategory}|${plan.planLevel}|${plan.planPeriod}');
  for (var gwa in groups) {
    sb.write('|#${gwa.group.groupId}');
    for (var ad in gwa.actionDetailList) {
      sb.write(':${ad.exercise.exerciseId}:${ad.action.frequency}');
      sb.write(':${ad.action.duration}:${ad.action.equipmentWeight}');
    }
  }
  sb.write('|r:${restSeconds ?? defaultActionRestSeconds}');
  return fnv1a64Hash(sb.toString());
}

/// 2026-08-27 训练组(单个训练)分析的 prompt 构建
/// 输入：训练组基础信息 + 组内动作列表(含基础活动详情)
///
/// 2026-08-28 组耗时改为实时估算(与跟练页执行口径一致)：
/// Σ(计时:duration | 计次:frequency×standardDuration) + 动作数×间隔休息。
/// 历史列 time_spent 从未录入(恒0)，不再使用。
String buildTrainingGroupPrompt(
  TrainingGroup group,
  List<ActionDetail> actions, {
  int? restSeconds,
}) {
  var isEn = box.read('language') == 'en';

  // 预估耗时(分钟)
  var estMinutes = estimateGroupMinutes(actions, restSeconds: restSeconds);
  var rest = restSeconds ?? defaultActionRestSeconds;

  var str = isEn
      ? """Please analyze this training workout, evaluate its intensity, duration reasonableness and give improvement suggestions.

Training name: ${group.groupName}
Category: ${getCusLabelText(group.groupCategory, categoryOptions)}
Level: ${getCusLabelText(group.groupLevel, levelOptions)}
Estimated time: about $estMinutes minutes (estimated from each exercise's standard duration plus ${rest}s rest between exercises)

The exercise list is as follows:\n"""
      : """请分析这个训练，评估它的强度、时长合理性，并给出改进建议。

训练名称：${group.groupName}
分类：${getCusLabelText(group.groupCategory, categoryOptions)}
难度：${getCusLabelText(group.groupLevel, levelOptions)}
预估耗时：约 $estMinutes 分钟（按各动作标准耗时与动作间休息$rest秒估算）

动作列表如下：\n""";

  for (var ad in actions) {
    var ex = ad.exercise;
    var act = ad.action;

    // 计次/计时动作的配置描述不同
    var configDesc = ex.countingMode == 'timed'
        ? (isEn ? "duration ${act.duration ?? 0}s" : "时长 ${act.duration ?? 0}秒")
        : (isEn ? "${act.frequency ?? 0} reps" : "${act.frequency ?? 0} 次");

    // 有负重才展示
    var weightDesc = (act.equipmentWeight ?? 0) > 0
        ? (isEn
              ? ", weight ${act.equipmentWeight}"
              : "，负重 ${act.equipmentWeight}")
        : "";

    str += """  - ${ex.exerciseName} ($configDesc$weightDesc)\n""";
  }

  return str;
}

/// 2026-08-27 训练计划(周期+每日分布)分析的 prompt 构建
/// 输入：计划基础信息 + 按训练日排序的训练组列表(含各组的动作)
///
/// 2026-08-28 每日耗时改为实时估算(口径同上)，不再使用恒0的 time_spent
String buildTrainingPlanPrompt(
  TrainingPlan plan,
  List<GroupWithActions> groups, {
  int? restSeconds,
}) {
  var isEn = box.read('language') == 'en';

  var str = isEn
      ? """Please analyze this training plan, evaluate its muscle group coverage, rest arrangement and progressive overload design, then give improvement suggestions.

Plan name: ${plan.planName}
Category: ${getCusLabelText(plan.planCategory, categoryOptions)}
Level: ${getCusLabelText(plan.planLevel, levelOptions)}
Period: ${plan.planPeriod} days

Daily training distribution:\n"""
      : """请分析这个训练计划，评估它的肌群覆盖、休息安排和渐进超负荷设计，并给出改进建议。

计划名称：${plan.planName}
分类：${getCusLabelText(plan.planCategory, categoryOptions)}
难度：${getCusLabelText(plan.planLevel, levelOptions)}
周期：${plan.planPeriod} 天

每日训练分布如下：\n""";

  // 列表索引即训练日顺序(day 1..N)
  for (var i = 0; i < groups.length; i++) {
    var g = groups[i].group;

    // 该训练日的预估耗时(分钟)
    var estMinutes = estimateGroupMinutes(
      groups[i].actionDetailList,
      restSeconds: restSeconds,
    );

    str += isEn
        ? "\nDay ${i + 1}: ${g.groupName} (${getCusLabelText(g.groupCategory, categoryOptions)}, ~${estMinutes}min)\n"
        : "\n第 ${i + 1} 天：${g.groupName}（${getCusLabelText(g.groupCategory, categoryOptions)}，约$estMinutes分钟）\n";

    for (var ad in groups[i].actionDetailList) {
      str += "  - ${ad.exercise.exerciseName}\n";
    }
  }

  return str;
}

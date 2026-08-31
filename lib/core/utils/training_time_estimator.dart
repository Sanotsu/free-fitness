import '../constants/constants.dart';
import '../storage/db_user_helper.dart';
import '../../models/training_state.dart';

/// 2026-08-28 训练耗时的统一估算工具
///
/// 口径与跟练页(action_follow_practice)实际执行完全一致：
/// - 计时动作：动作配置的 duration(秒，空按10兜底同跟练页)；
/// - 计次动作：frequency × 基础动作的 standardDuration(标准单次耗时)；
/// - 每个动作结束后都会进入间隔休息(用户设置 actionRestTime，默认10秒)。
///
/// 估算值不落库(训练组 time_spent 列保留但不再使用)，统一供
/// AI 分析 prompt 与训练组/计划列表的"预估耗时"展示实时计算。

/// 单个动作的预估耗时(秒)
int estimateActionSeconds(ActionDetail ad) {
  // 计时(第一个选项)
  if (ad.exercise.countingMode == countingOptions.first.value) {
    return ad.action.duration ?? 10;
  }
  // 计次：次数 × 标准单次耗时
  return (ad.action.frequency ?? 1) * ad.exercise.standardDuration;
}

/// 训练组预估耗时(分钟)：Σ动作耗时 + 动作数×间隔休息
/// 动作列表为空时返回 0
int estimateGroupMinutes(List<ActionDetail> actions, {int? restSeconds}) {
  var rest = restSeconds ?? defaultActionRestSeconds;
  var total = actions.length * rest;
  for (var ad in actions) {
    total += estimateActionSeconds(ad);
  }
  return (total / 60).round();
}

/// 与跟练页一致的默认间隔休息秒数
const int defaultActionRestSeconds = 10;

/// 读取用户配置的跟练动作间隔休息秒数(查不到用户时默认10，与跟练页一致)
Future<int> fetchActionRestSeconds() async {
  try {
    var user = await DBUserHelper().queryUser(userId: CacheUser.userId);
    return user?.actionRestTime ?? defaultActionRestSeconds;
  } catch (_) {
    return defaultActionRestSeconds;
  }
}

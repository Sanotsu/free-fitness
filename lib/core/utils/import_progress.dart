import 'package:flutter/foundation.dart';

/// 内置数据导入的进度信息
class ImportProgress {
  /// 阶段标题，如"基础动作"/"食物成分"
  final String title;

  /// 补充说明，如当前读取的分册文件名、已写入条数等
  final String detail;

  /// 已完成的步骤/条数
  final int current;

  /// 总步骤/条数(total<=0 时进度条显示为不定态)
  final int total;

  const ImportProgress({
    required this.title,
    this.detail = '',
    required this.current,
    required this.total,
  });

  double get ratio => total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
}

/// 导入进度的全局通知中心
/// 导入服务在后台更新进度，UI 浮层通过 ValueListenableBuilder 监听实时渲染
class ImportProgressCenter {
  static final ValueNotifier<ImportProgress?> notifier = ValueNotifier(null);

  static void update(ImportProgress? progress) => notifier.value = progress;
}

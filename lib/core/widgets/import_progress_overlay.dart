import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/import_progress.dart';

/// 展示内置数据导入进度的悬浮层(替代原先只有转圈圈的 loading)
/// 全局模态遮罩：导入期间拦截点击/滑动与系统返回键，避免用户操作与导入产生冲突。
/// 用法：导入前调用本方法拿到 CancelFunc；导入服务内部通过 ImportProgressCenter
/// 更新进度；导入结束后由调用方执行 CancelFunc 关闭浮层
CancelFunc showImportProgressOverlay() {
  return BotToast.showEnhancedWidget(
    // 半透明全屏背景屏障，配合 allowClick=false 阻断下层页面的一切交互
    backgroundColor: Colors.black38,
    allowClick: false,
    clickClose: false,
    // 导入期间拦截返回键，防止中途离开页面造成状态不一致
    backButtonBehavior: BackButtonBehavior.ignore,
    toastBuilder: (_) => ValueListenableBuilder<ImportProgress?>(
      valueListenable: ImportProgressCenter.notifier,
      builder: (context, progress, _) {
        // BotToast 浮层不在 Material 组件树内，必须包一层透明的 Material，
        // 否则内部 Text 会使用默认样式渲染出双黄下划线
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 0.7.sw,
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    progress?.title ?? "...",
                    style: TextStyle(color: Colors.white, fontSize: 15.sp),
                  ),
                  SizedBox(height: 10.sp),
                  LinearProgressIndicator(
                    value: progress?.ratio ?? 0,
                    minHeight: 6.sp,
                    borderRadius: BorderRadius.circular(3.sp),
                  ),
                  SizedBox(height: 8.sp),
                  Text(
                    "${progress?.current ?? 0} / ${progress?.total ?? 0}",
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                  if (progress != null && progress.detail.isNotEmpty) ...[
                    SizedBox(height: 4.sp),
                    Text(
                      progress.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white60, fontSize: 11.sp),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

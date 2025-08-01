import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';

class ToastUtils {
  // 基础配置
  static const Duration _defaultDuration = Duration(seconds: 2);

  /// 1. 成功提示 (✅ + 绿色)
  static void showSuccess(
    String message, {
    Duration? duration,
    Alignment? align,
  }) {
    _showIconToast(
      message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
      duration: duration,
      align: align,
    );
  }

  /// 2. 错误提示 (❌ + 红色)
  static void showError(
    String message, {
    Duration? duration,
    Alignment? align,
  }) {
    _showIconToast(
      message,
      icon: Icons.error,
      backgroundColor: Colors.red,
      duration: duration,
      align: align,
    );
  }

  /// 3. 警告提示 (⚠️ + 橙色)
  static void showWarning(
    String message, {
    Duration? duration,
    Alignment? align,
  }) {
    _showIconToast(
      message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.orange,
      duration: duration,
      align: align,
    );
  }

  /// 4. 信息提示 (ℹ️ + 蓝色)
  static void showInfo(String message, {Duration? duration, Alignment? align}) {
    _showIconToast(
      message,
      icon: Icons.info,
      backgroundColor: Colors.blue,
      duration: duration,
      align: align,
    );
  }

  /// 5. 普通文字提示 (居中)
  static void showToast(
    String message, {
    Duration? duration,
    Color? bgColor,
    Alignment? align,
  }) {
    BotToast.showText(
      text: message,
      align: align ?? const Alignment(0, 0),
      contentColor: bgColor ?? Colors.black87,
      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
      duration: duration ?? _defaultDuration,
    );
  }

  /// 6. 显示加载中 (可手动关闭)
  static CancelFunc showLoading([String? message, Alignment? align]) {
    return BotToast.showCustomLoading(
      align: align ?? Alignment.center,
      toastBuilder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            if (message != null) ...[
              SizedBox(height: 8),
              Text(message, style: const TextStyle(color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }

  /// 图标提示的私有实现方法
  static void _showIconToast(
    String message, {
    required IconData icon,
    required Color backgroundColor,
    Duration? duration,
    Alignment? align,
  }) {
    BotToast.showCustomNotification(
      align: align ?? Alignment.topCenter,
      duration: duration ?? _defaultDuration,
      toastBuilder: (cancel) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

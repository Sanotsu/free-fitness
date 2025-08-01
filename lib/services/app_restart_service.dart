import 'dart:async';
import 'package:flutter/material.dart';

/// 应用重启服务，提供安全地重启应用的方法
class AppRestartService {
  /// 全局重启控制器
  static final _restartController = StreamController<bool>.broadcast();

  /// 重启流，用于监听重启事件
  static Stream<bool> get onRestart => _restartController.stream;

  /// 安全地重启应用程序
  ///
  /// 不创建新的MaterialApp实例，而是通过重建Widget树来应用新设置
  static void restartApp(BuildContext context) {
    // 触发重启事件
    _restartController.add(true);
  }

  /// 关闭控制器
  static void dispose() {
    _restartController.close();
  }
}

/// 应用重启包装器，监听重启事件并重建子树
class AppRestartWrapper extends StatefulWidget {
  final Widget child;

  const AppRestartWrapper({super.key, required this.child});

  @override
  State<AppRestartWrapper> createState() => _AppRestartWrapperState();
}

class _AppRestartWrapperState extends State<AppRestartWrapper> {
  Key _key = UniqueKey();
  late StreamSubscription<bool> _subscription;

  @override
  void initState() {
    super.initState();

    // 监听重启事件
    _subscription = AppRestartService.onRestart.listen((event) {
      if (event) {
        setState(() {
          // 更改key，强制重建整个子树
          _key = UniqueKey();
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用key包装子部件，当key变化时整个子树会重建
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get_storage/get_storage.dart';

import 'core/utils/toast_utils.dart';
import 'layout/app.dart';
import 'services/app_restart_service.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  AppCatchError().run();
}

//全局异常的捕捉
class AppCatchError {
  void run() {
    ///Flutter 框架异常
    FlutterError.onError = (FlutterErrorDetails details) async {
      ///线上环境 todo
      if (kReleaseMode) {
        Zone.current.handleUncaughtError(details.exception, details.stack!);
      } else {
        //开发期间 print
        FlutterError.dumpErrorToConsole(details);
      }
    };

    runZonedGuarded(() {
      //受保护的代码块
      WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]).then((_) async {
        WidgetsFlutterBinding.ensureInitialized();
        await GetStorage.init();
        // await GetStorage().write('language', 'en');
        // await GetStorage().write('language', 'zh');
        await GetStorage().write('language', 'system');
        // await GetStorage().write('mode', 'dark');
        // await GetStorage().write('mode', 'light');
        await GetStorage().write('mode', 'system');

        // 注册应用生命周期回调，确保在应用退出时关闭控制器
        WidgetsBinding.instance.addObserver(_AppLifecycleObserver());

        runApp(const FreeFitnessApp());
      });
    }, (error, stack) => catchError(error, stack));
  }

  ///对搜集的 异常进行处理  上报等等
  Future<void> catchError(Object error, StackTrace stack) async {
    //是否是 Release版本
    debugPrint("AppCatchError>>>>>>>>>> [ kReleaseMode ] $kReleaseMode");
    debugPrint('AppCatchError>>>>>>>>>> [ Message ] $error');
    debugPrint('AppCatchError>>>>>>>>>> [ Stack ] \n$stack');

    // 判断是否可以显示Toast
    try {
      // 尝试显示错误提示
      ToastUtils.showError(
        error.toString(),
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      // Toast初始化可能还未完成，只记录错误
      debugPrint('无法显示Toast，可能是界面尚未准备好: $e');
    }

    // 判断返回数据中是否包含"token失效"的信息
    // 一些错误处理，比如token失效这里退出到登录页面之类的
    if (error.toString().contains("登录出错")) {
      if (kDebugMode) {
        print(error);
      }
    }
  }
}

/// 应用生命周期观察者，用于处理应用退出时的清理工作
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // 应用被终止时，关闭重启服务的控制器
      AppRestartService.dispose();
    }
  }
}

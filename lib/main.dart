import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get_storage/get_storage.dart';

import 'layout/app.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  AppCatchError().run();
}

//全局异常的捕捉
class AppCatchError {
  run() {
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

    runZonedGuarded(
      () {
        //受保护的代码块
        WidgetsFlutterBinding.ensureInitialized();
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
            .then((_) async {
          WidgetsFlutterBinding.ensureInitialized();
          await GetStorage.init();
          await GetStorage().write('language', 'en');
          // await GetStorage().write('language', 'cn');
          // await GetStorage().write('language', 'system');
          // await GetStorage().write('mode', 'dark');
          // await GetStorage().write('mode', 'light');
          await GetStorage().write('mode', 'system');
          runApp(const FreeFitnessApp());
        });
      },
      (error, stack) => catchError(error, stack),
    );
  }

  ///对搜集的 异常进行处理  上报等等
  catchError(Object error, StackTrace stack) async {
    //是否是 Release版本
    debugPrint("AppCatchError>>>>>>>>>> [ kReleaseMode ] $kReleaseMode");
    debugPrint('AppCatchError>>>>>>>>>> [ Message ] $error');
    debugPrint('AppCatchError>>>>>>>>>> [ Stack ] \n$stack');

    // 弹窗提醒用户
    EasyLoading.showToast(
      error.toString(),
      duration: const Duration(seconds: 5),
      toastPosition: EasyLoadingToastPosition.top,
    );

    // 判断返回数据中是否包含"token失效"的信息
    // 一些错误处理，比如token失效这里退出到登录页面之类的
    if (error.toString().contains("token无效") ||
        error.toString().contains("token已过期") ||
        error.toString().contains("登录出错") ||
        error.toString().toLowerCase().contains("invalid")) {
      if (kDebugMode) {
        print(error);
      }
    }
  }
}

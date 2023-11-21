// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../views/dietary/foods/index.dart';
import '../views/dietary/records/index.dart';
import '../views/dietary/reports/index.dart';
import '../views/dietary/settings/index.dart';
import 'home.dart';

class FreeFitnessApp extends StatelessWidget {
  const FreeFitnessApp({Key? key}) : super(key: key);

  // 应用程序的根部件
  @override
  Widget build(BuildContext context) {
    // 所有命名路由自定义参数的初始都默认为空对象
    // （不能设为const，否则返回会无法修改参数值，
    //  这也是抽在这里的原因，下面RouteSettings 直接赋值{}会提示使用const，然后就报错）
    var routeSettingsArgs = {};

    return ScreenUtilInit(
      designSize: const Size(360, 640), // 1080p / 3 ,单位dp
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, widget) {
        return MaterialApp(
          title: 'free_fitness',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CH'),
            Locale('en', 'US'),
          ],
          locale: const Locale('zh'),
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),

          initialRoute: '/',

          /// routes 和 onGenerateRoute 这两个属性执行相同的操作，都为了命名路由使用，首先检查 routes
          /// 路由明都带了 / 在前面，匹配时也注意

          // 静态路由表（没法自定义参数）
          // routes: {
          //   '/': (context) => const HomePage(),
          //   '/dietaryRecords': (context) => const DietaryRecords(),
          // },

          /// 使用 onGenerateRoute 为您提供了一个在推送新路由（页面）之前添加自定义业务逻辑的位置。
          onGenerateRoute: (settings) {
            // 在饮食日记主页的命名路由添加参数栏位，以供后续使用popUntil返回该页面时能带上自定义数据
            if (settings.name == "/dietaryRecords") {
              // 可带上自定义参数(注意，这里不能带const，否则popuntil修改参数就无法修改)
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/dietaryRecords',
                  arguments: routeSettingsArgs,
                ),
                builder: (_) => const DietaryRecords(),
              );
            } else if (settings.name == "/dietaryReports") {
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/dietaryReports',
                  arguments: routeSettingsArgs,
                ),
                builder: (_) => const DietaryReports(),
              );
            } else if (settings.name == "/dietarySettings") {
              return MaterialPageRoute(builder: (_) => const DietarySettings());
            } else if (settings.name == "/dietaryFoods") {
              return MaterialPageRoute(builder: (_) => const DietaryFoods());
            } else if (settings.name == "/") {
              // 可带上自定义参数
              return MaterialPageRoute(builder: (_) => const HomePage());
            } else {
              return null;
            }
          },
          // 使用了initalRoute就不能使用home了，参看文档：
          // https://flutter.cn/docs/cookbook/navigation/named-routes#2-define-the-routes
          // home: const HomePage(),
        );
      },
    );
  }
}

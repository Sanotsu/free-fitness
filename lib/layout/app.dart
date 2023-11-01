// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../views/dietary/records/index.dart';
import 'home.dart';

class FreeFitnessApp extends StatelessWidget {
  const FreeFitnessApp({Key? key}) : super(key: key);

  // 应用程序的根部件
  @override
  Widget build(BuildContext context) {
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

          // 初始化路由为Home页面
          initialRoute: '/',
          // 在饮食日记中 index -> food list -> food detail,我需要一次性返回到这个主页，所以加个路由名称
          routes: {
            '/': (context) => const HomePage(),
            '/dietaryRecords': (context) => const DietaryRecords(),
          },
          // 在上面设置的路由，这里生成路由可带参数
          onGenerateRoute: (settings) {
            if (settings.name == '/dietaryRecords') {
              final args = settings;

              print("在app 页面的args-------- $args");

              return MaterialPageRoute(
                settings: const RouteSettings(
                  name: '/dietaryRecords',
                  arguments: {},
                ),
                builder: (_) => const DietaryRecords(),
              );
            } else {
              // 其他回传不带参数的可暂时不管
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

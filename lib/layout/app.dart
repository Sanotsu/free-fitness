// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
          // 使用了initalRoute就不能使用home了，参看文档：
          // https://flutter.cn/docs/cookbook/navigation/named-routes#2-define-the-routes
          home: const HomePage(),
        );
      },
    );
  }
}

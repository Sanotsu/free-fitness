// ignore_for_file: avoid_print

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:free_fitness/layout/init_guide_page.dart';

import '../common/global/constants.dart';

import 'home.dart';

class FreeFitnessApp extends StatefulWidget {
  const FreeFitnessApp({Key? key}) : super(key: key);

  @override
  State<FreeFitnessApp> createState() => _FreeFitnessAppState();
}

class _FreeFitnessAppState extends State<FreeFitnessApp> {
  // 获取缓存中的用户编号
  int? get getUserId => box.read(LocalStorageKey.userId);

  // 应用程序的根部件
  @override
  Widget build(BuildContext context) {
    print("getUserId---$getUserId");

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
            // ？？？2023-11-22：升级到flutter 3.16 之后默认为true，现在还没有兼容修改部件，后续再启用
            useMaterial3: false,
            appBarTheme: AppBarTheme(
              color: Colors.blue,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(fontSize: 20.sp),
            ),
          ),
          // theme: lightTheme,
          // theme: darkTheme,

          // theme: FlexThemeData.light(
          //   scheme: FlexScheme.aquaBlue,
          // ),
          darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed),
          // 根据系统设置使用深色或浅色主题
          themeMode: ThemeMode.light,

          // 使用了initalRoute就不能使用home了，参看文档：
          // https://flutter.cn/docs/cookbook/navigation/named-routes#2-define-the-routes

          // 如果没有在缓存获取到用户信息，就要用户输入；否则就直接进入首页
          home: getUserId != null ? const HomePage() : const InitGuidePage(),
        );
      },
    );
  }
}

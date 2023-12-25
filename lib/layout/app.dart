// ignore_for_file: avoid_print

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:free_fitness/layout/init_guide_page.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:free_fitness/models/cus_app_localizations.dart';

import '../common/global/constants.dart';

import 'home.dart';

class FreeFitnessApp extends StatefulWidget {
  const FreeFitnessApp({Key? key}) : super(key: key);

  @override
  State<FreeFitnessApp> createState() => _FreeFitnessAppState();
}

class _FreeFitnessAppState extends State<FreeFitnessApp> {
  // 应用程序的根部件
  @override
  Widget build(BuildContext context) {
    print("getUserId---${box.read(LocalStorageKey.userId)}");
    print("language mode---${box.read('language')} ${box.read('mode')}");

    return ScreenUtilInit(
      designSize: const Size(360, 640), // 1080p / 3 ,单位dp
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, widget) {
        return MaterialApp(
          title: 'free_fitness',
          onGenerateTitle: (context) {
            return CusAL.of(context).appTitle;
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // form builder表单验证的多国语言
            FormBuilderLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CH'),
            Locale('en', 'US'),
            ...FormBuilderLocalizations.supportedLocales,
          ],
          // locale: null,
          // locale: const Locale('en'),

          locale: box.read('language') == 'system'
              ? null
              : Locale(box.read('language')),

          // theme: ThemeData(
          //   primarySwatch: Colors.blue,
          //   // ？？？2023-11-22：升级到flutter 3.16 之后默认为true，现在还没有兼容修改部件，后续再启用
          //   useMaterial3: false,
          //   appBarTheme: AppBarTheme(
          //     color: Colors.blue,
          //     iconTheme: const IconThemeData(color: Colors.white),
          //     titleTextStyle: TextStyle(fontSize: 20.sp),
          //   ),
          // ),

          // // 默认使用浅色主题，预览一个深色主题使用的预设值
          // darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed),
          // themeMode: ThemeMode.light,

          /// 根据系统设置使用深色或浅色主题(当有完善的深色模式之后再启用)
          theme: box.read('mode') == 'system'
              ? null
              : box.read('mode') == 'dark'
                  ? FlexThemeData.dark(scheme: FlexScheme.mandyRed)
                  : FlexThemeData.light(scheme: FlexScheme.aquaBlue),

          // 使用了initalRoute就不能使用home了，参看文档：
          // https://flutter.cn/docs/cookbook/navigation/named-routes#2-define-the-routes

          // 如果没有在缓存获取到用户信息，就要用户输入；否则就直接进入首页
          home: box.read(LocalStorageKey.userId) != null
              ? const HomePage()
              : const InitGuidePage(),
        );
      },
    );
  }
}

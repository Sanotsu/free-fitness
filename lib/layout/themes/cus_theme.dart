import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 浅色主题
ThemeData lightTheme = ThemeData(
  // 浅色背景
  brightness: Brightness.light,
  // 启用material3
  useMaterial3: true,
  // 文本主题
  // 定制好一些文本样式，后续直接使用,例如：`style: Theme.of(context).textTheme.bodySmall`
  // 否则就是默认的
  textTheme: TextTheme(
    displayLarge: TextStyle(
        fontSize: 96.sp, fontWeight: FontWeight.w300, color: Colors.black),
    displayMedium: TextStyle(
        fontSize: 60.sp, fontWeight: FontWeight.w400, color: Colors.black),
    displaySmall: TextStyle(
        fontSize: 48.sp, fontWeight: FontWeight.w400, color: Colors.black),
    headlineMedium: TextStyle(
        fontSize: 34.sp, fontWeight: FontWeight.w400, color: Colors.black),
    headlineSmall: TextStyle(
        fontSize: 24.sp, fontWeight: FontWeight.w400, color: Colors.black),
    titleLarge: TextStyle(
        fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.black),
    bodyLarge: TextStyle(
        fontSize: 16.sp, fontWeight: FontWeight.w400, color: Colors.black87),
    bodyMedium: TextStyle(
        fontSize: 14.sp, fontWeight: FontWeight.w400, color: Colors.black87),
    bodySmall: TextStyle(
        fontSize: 12.sp, fontWeight: FontWeight.w400, color: Colors.black54),
    labelLarge: TextStyle(
        fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.white),
  ),
  // appbar主题
  appBarTheme: AppBarTheme(
    // color: Colors.blue,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(fontSize: 20.sp),
  ),
  // 颜色组，定义应用可以使用的颜色集。定义了许多小部件的默认颜色
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
  ).copyWith(
    primary: Colors.green,
  ),
  // 指定某种按钮的主体
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color?>(
      (Set<WidgetState> states) => Colors.red,
    ),
  )),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: false,
  brightness: Brightness.light,
  primaryColor: Colors.greenAccent,
  canvasColor: Colors.yellow,
  cardColor: Colors.black,
  secondaryHeaderColor: Colors.grey,
  primarySwatch: Colors.red,
  textTheme: TextTheme(
    displayLarge: TextStyle(
      fontSize: 52.sp,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(fontSize: 18.sp),
  ),
);

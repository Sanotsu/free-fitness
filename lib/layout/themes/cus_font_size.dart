import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 自定义各个字体的大小
class CusFontSizes {
  CusFontSizes._();

  // 一般的卡片或者ListTile中的标题、子标题、正文的大小
  static double itemTitle = 18.sp;
  static double itemSubTitle = 14.sp;
  static double itemContent = 12.sp;
  static double itemSubContent = 10.sp;

  // 一般的页面的标题、子标题、正文、附录等大学
  static double pageTitle = 20.sp;
  static double pageSubTitle = 16.sp;
  // Text()部件的默认字体大小也是15
  static double pageContent = 15.sp;
  static double pageSubContent = 13.sp;
  static double pageAppendix = 12.sp;

  // 输入框的文字大小
  static double searchInputLarge = 18.sp;
  static double searchInputMedium = 14.sp;
  static double searchInputSmall = 12.sp;

  // 有些特别标识的字体更大些
  static double flagVeryLarge = 50.sp;
  static double flagLarge = 36.sp;
  static double flagVeryBig = 32.sp;
  static double flagBig = 28.sp;
  static double flagMediumBig = 24.sp;
  static double flagMedium = 20.sp;
  static double flagSmall = 16.sp;
  static double flagTiny = 10.sp;
  static double flagMinute = 8.sp;

  // 按钮的文字大小
  static double buttonLarge = 28.sp;
  static double buttonBig = 24.sp;
  static double buttonMedium = 20.sp;
  static double buttonSmall = 15.sp;
  static double buttonTiny = 12.sp;
}

// 图标的大小，除开默认的，就稍微巨大和较小的
class CusIconSizes {
  CusIconSizes._();

  static double iconLarge = 36.sp;
  static double iconBig = 30.sp;
  static double iconMedium = 24.sp;
  static double iconNormal = 20.sp;
  static double iconSmall = 16.sp;
  static double iconTiny = 12.sp;
}

// 一些特殊的背景色

class CusColors {
  CusColors._();

  // 一些弹窗中需要上下翻页的背景色
  static Color pageChangeBg = const Color.fromARGB(255, 1, 191, 155);

  // appbar的下拉框的背景色，深色/浅色主题下，背景都是灰色的话白色文字就看得见
  static Color dropdownColor = const Color.fromARGB(255, 124, 96, 96);

// 手记模块心情、分类、标签、更多的小图标的背景色
  static Color moodTinyTagBg = Colors.red[300]!;
  static Color cateTinyTagBg = Colors.lightBlue;
  static Color tagTinyTagBg = Colors.lightGreen;
  static Color moreTinyTagBg = Colors.grey;
}

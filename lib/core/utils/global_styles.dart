import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'tool_widgets.dart';

// 定义常用的颜色

var blackHeadTextStyle = TextStyle(
  fontFamily: "BarlowBold",
  fontSize: 16.sp,
  color: Colors.black,
);

var appBarTextStyle = TextStyle(
  fontFamily: "BarlowBold",
  fontSize: 20.sp,
);

// 图标的大小
var appBarIconButtonSize = 20.sp;
var bottomIconButtonSize1 = 20.sp;

var bottomIconButtonSize2 = 16.sp;
var bottomIconButtonSize3 = 12.sp;

// tabview中tab标题文字的宽度
var tabWidth = 80.sp;
var tabContainerHeight = 30.sp;

// 定义常用的字体大小
var sizeHeadline0 = 24.sp;
var sizeHeadline1 = 20.sp;
var sizeHeadline2 = 16.sp;
var sizeHeadline3 = 14.sp;
var sizeHeadline4 = 12.sp;
var sizeContent0 = 18.sp;
var sizeContent1 = 16.sp;
var sizeContent2 = 14.sp;
var sizeContent3 = 12.sp;
var sizeContent4 = 10.sp;

// 定义dialog字体
var sizeDialogTitle = 16.sp;
var sizeDialogContent = 14.sp;
var sizeDialogButton = 14.sp;

// 测试本地音乐的显示背景色，整体背景色和mini bar的有稍微区别(后缀越大，颜色越深)
// 后续应该要整专门的自定义主题进行切换，例如深色/浅色模式
// 测试用的深色背景色

var dartThemeMaterialColor1 =
    buildMaterialColor(const Color.fromARGB(255, 116, 102, 102));

var dartThemeMaterialColor2 =
    buildMaterialColor(const Color.fromARGB(255, 87, 82, 82));

var dartThemeMaterialColor3 =
    buildMaterialColor(const Color.fromARGB(255, 59, 56, 56));

import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:math' as math;

//  hexadecimal color code 转为 material color
MaterialColor buildMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

// 生成随机颜色
Color genRandomColor() =>
    Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

// 随机icon（可能没效果）
final List<int> points = <int>[0xe0b0, 0xe0b1, 0xe0b2, 0xe0b3, 0xe0b4];
final Random r = Random();
IconData genRandomIcon() =>
    IconData(r.nextInt(points.length), fontFamily: 'MaterialIcons');
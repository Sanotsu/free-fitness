import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

import '../global/constants.dart';

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

// 指定卡路里转化为千焦数值
String caloryToKjStr(int calory) =>
    "${(calory / oneCalToKjRatio).toStringAsFixed(2)} 千焦";

// 绘制转圈圈
Widget buildLoader(bool isLoading) {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  } else {
    return Container();
  }
}

/// 构建供frombuilder库创建的下拉选择框的选项列表(这里不声明返回类型)
/// 目前主要用在基础活动exercise的一些分类选项
//    返回的是List<DropdownMenuItem<Object>>，
//    表单使用是FormBuilderDropdown<String>但要注意类型改为匹配的，或者不指定String
List<DropdownMenuItem<Object>> genDropdownMenuItems(
  List<CusLabel> options, {
  double? textSize = 16,
}) {
  return options
      .map(
        (option) => DropdownMenuItem(
          alignment: AlignmentDirectional.centerStart,
          value: option.value,
          child: Text(option.cnLabel, style: TextStyle(fontSize: textSize)),
        ),
      )
      .toList();
}

///
/// form builder 库中文本栏位和下拉选择框组件的二次封装
///
// 构建表单的文本输入框
Widget cusFormBuilerTextField(
  String name, {
  String? initialValue,
  int? maxLines,
  String? hintText, // 可不传提示语
  TextStyle? hintStyle,
  String? labelText, // 可不传栏位标签，在输入框前面有就行
  String? Function(Object?)? validator,
  bool? isOutline = false, // 输入框是否有线条
}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10.sp),
    child: FormBuilderTextField(
      name: name,
      initialValue: initialValue,
      maxLines: maxLines,
      decoration: _buildInputDecoration(
        isOutline,
        labelText,
        hintText,
        hintStyle,
      ),
      // decoration: isOutline != null && isOutline
      //     ? InputDecoration(
      //         isDense: true, // 边框没有默认是紧凑型
      //         labelText: labelText,
      //         hintText: hintText,
      //         // 调整内边距，使得下拉框更紧凑
      //         contentPadding:
      //             EdgeInsets.symmetric(horizontal: 5.sp, vertical: 15),
      //         border: OutlineInputBorder(
      //           borderRadius: BorderRadius.circular(10.0), // 设置圆弧半径
      //         ),
      //       )
      //     : InputDecoration(
      //         isDense: true, // 边框没有默认是紧凑型
      //         labelText: labelText,
      //         hintText: hintText,
      //         // 调整内边距，使得下拉框更紧凑
      //         contentPadding:
      //             EdgeInsets.symmetric(horizontal: 5.sp, vertical: 5),
      //       ),
      validator: validator,
    ),
  );
}

// 构建表单的下拉选择框
Widget cusFormBuilerDropdown(
  String name,
  List<CusLabel> options, {
  Object? initialValue,
  String? labelText,
  String? hintText,
  TextStyle? hintStyle,
  double? optionFontSize,
  String? Function(Object?)? validator,
  bool? isOutline = false, // 输入框是否有线条
}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10.sp),
    child: FormBuilderDropdown(
      borderRadius: BorderRadius.all(Radius.circular(10.sp)),
      name: name,
      initialValue: initialValue,
      // 是否显示四面边框线(默认只有底线)
      decoration: _buildInputDecoration(
        isOutline,
        labelText,
        hintText,
        hintStyle,
      ),

      // decoration: isOutline != null && isOutline
      //     ? InputDecoration(
      //         isDense: true, // 边框没有默认是紧凑型
      //         labelText: labelText,
      //         hintText: hintText,
      //         hintStyle: hintStyle,
      //         // 调整内边距，使得下拉框更紧凑
      //         contentPadding:
      //             EdgeInsets.symmetric(horizontal: 5.sp, vertical: 15),
      //         border: OutlineInputBorder(
      //           borderRadius: BorderRadius.circular(10.0), // 设置圆弧半径
      //         ),
      //       )
      //     : InputDecoration(
      //         isDense: true, // 边框没有默认是紧凑型
      //         labelText: labelText,
      //         hintText: hintText,
      //         // 调整内边距，使得下拉框更紧凑
      //         contentPadding:
      //             EdgeInsets.symmetric(horizontal: 5.sp, vertical: 5),
      //       ),
      validator: validator,
      items: genDropdownMenuItems(options, textSize: optionFontSize),
      menuMaxHeight: 0.5.sh,
      // alignment: AlignmentDirectional.bottomEnd,
      valueTransformer: (val) => val?.toString(),
    ),
  );
}

// formbuilder 下拉框和文本输入框的样式等内容
InputDecoration _buildInputDecoration(
  bool? isOutline,
  String? labelText,
  String? hintText,
  TextStyle? hintStyle,
) {
  final contentPadding = isOutline != null && isOutline
      ? EdgeInsets.symmetric(horizontal: 5.sp, vertical: 15.sp)
      : EdgeInsets.symmetric(horizontal: 5.sp, vertical: 5.sp);

  return InputDecoration(
    isDense: true,
    labelText: labelText,
    hintText: hintText,
    hintStyle: hintStyle,
    contentPadding: contentPadding,
    border: isOutline != null && isOutline
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          )
        : null,
  );
}

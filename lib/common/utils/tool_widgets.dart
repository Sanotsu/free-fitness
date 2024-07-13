import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

import '../../layout/themes/cus_font_size.dart';
import '../../models/cus_app_localizations.dart';
import '../global/constants.dart';
import 'tools.dart';

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
    (calory * oneCalToKjRatio).toStringAsFixed(2);

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
  double? textSize,
}) {
// 2023-12-30 为了英文的时候输入框显示完整，字体小点(13)，中午就16
  var fontSize = textSize ??
      (box.read('language') == "en"
          ? CusFontSizes.pageSubContent
          : CusFontSizes.pageSubTitle);

  return options
      .map(
        (option) => DropdownMenuItem(
          alignment: AlignmentDirectional.centerStart,
          value: option.value,
          child: Text(
            showCusLable(option),
            style: TextStyle(fontSize: fontSize),
          ),
        ),
      )
      .toList();
}

///
/// form builder 库中文本栏位和下拉选择框组件的二次封装
///
// 构建表单的文本输入框
Widget cusFormBuilerTextField(String name,
    {String? initialValue,
    double? valueFontSize,
    int? maxLines,
    String? hintText, // 可不传提示语
    TextStyle? hintStyle,
    String? labelText, // 可不传栏位标签，在输入框前面有就行
    String? Function(Object?)? validator,
    bool? isOutline = false, // 输入框是否有线条
    bool isReadOnly = false, // 输入框是否有线条
    TextInputType? keyboardType,
    void Function(String?)? onChanged,
    List<TextInputFormatter>? inputFormatters}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10.sp),
    child: FormBuilderTextField(
      name: name,
      initialValue: initialValue,
      maxLines: maxLines,
      readOnly: isReadOnly,
      style: TextStyle(fontSize: valueFontSize),
      // 2023-12-04 没有传默认使用name，原本默认的.text会弹安全键盘，可能无法输入中文
      // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
      // 注意：如果有最大行超过1的话，默认启用多行的键盘类型
      enableSuggestions: true,
      keyboardType: keyboardType ??
          ((maxLines != null && maxLines > 1)
              ? TextInputType.multiline
              : TextInputType.text),

      decoration: _buildInputDecoration(
        isOutline,
        isReadOnly,
        labelText,
        hintText,
        hintStyle,
      ),
      validator: validator,
      onChanged: onChanged,
      // 输入的格式限制
      inputFormatters: inputFormatters,
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
  bool isReadOnly = false, // 输入框是否有线条
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
        isReadOnly,
        labelText,
        hintText,
        hintStyle,
      ),

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
  bool isReadOnly,
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
        : isReadOnly
            ? InputBorder.none
            : null,
    // 设置透明底色
    filled: true,
    fillColor: Colors.transparent,
  );
}

commonExceptionDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message, style: TextStyle(fontSize: 15.sp)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(CusAL.of(context).confirmLabel),
          ),
        ],
      );
    },
  );
}

buildSmallChip(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return Chip(
    label: Text(labelText),
    backgroundColor: bgColor,
    labelStyle: TextStyle(fontSize: labelTextSize),
    labelPadding: EdgeInsets.zero,
    // 设置负数会报错，但好像看到有点效果呢
    // labelPadding: EdgeInsets.fromLTRB(0, -6.sp, 0, -6.sp),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

// 用一个按钮假装是一个标签，用来展示
buildSmallButtonTag(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return RawMaterialButton(
    onPressed: () {},
    constraints: const BoxConstraints(),
    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    fillColor: bgColor ?? Colors.grey[300],
    child: Text(
      labelText,
      style: TextStyle(fontSize: labelTextSize ?? 12.sp),
    ),
  );
}

// 一般当做标签用，比上面个还小
// 传入的字体最好不超过10
buildTinyButtonTag(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return SizedBox(
    // 传入大于12的字体，修正为12；不传则默认12
    height: ((labelTextSize != null && labelTextSize > 10.sp)
            ? 10.sp
            : labelTextSize ?? 10.sp) +
        10.sp,
    child: RawMaterialButton(
      onPressed: () {},
      constraints: const BoxConstraints(),
      padding: EdgeInsets.fromLTRB(4.sp, 2.sp, 4.sp, 2.sp),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp),
      ),
      fillColor: bgColor ?? Colors.grey[300],
      child: Text(
        labelText,
        style: TextStyle(
          // 传入大于10的字体，修正为10；不传则默认10
          fontSize: (labelTextSize != null && labelTextSize > 10.sp)
              ? 10.sp
              : labelTextSize ?? 10.sp,
        ),
      ),
    ),
  );
}

// 带有横线滚动条的datatable
buildDataTableWithHorizontalScrollbar({
  required ScrollController scrollController,
  required List<DataColumn> columns,
  required List<DataRow> rows,
}) {
  return Scrollbar(
    thickness: 5,
    // 设置交互模式后，滚动条和手势滚动方向才一致
    interactive: true,
    radius: Radius.circular(5.sp),
    // 不设置这个，滚动条默认不显示，在滚动时才显示
    thumbVisibility: true,
    // trackVisibility: true,
    // 滚动条默认在右边，要改在左边就配合Transform进行修改(此例没必要)
    // 刻意预留一点空间给滚动条
    controller: scrollController,
    child: SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: DataTable(
        // dataRowHeight: 10.sp,
        dataRowMinHeight: 60.sp, // 设置行高范围
        dataRowMaxHeight: 100.sp,
        headingRowHeight: 25, // 设置表头行高
        horizontalMargin: 10, // 设置水平边距
        columnSpacing: 20.sp, // 设置列间距
        columns: columns,
        rows: rows,
      ),
    ),
  );
}

// 显示底部提示条(默认都是出错或者提示的)
void showSnackMessage(
  BuildContext context,
  String message, {
  Color? backgroundColor = Colors.red,
}) {
  var snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
    backgroundColor: backgroundColor,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

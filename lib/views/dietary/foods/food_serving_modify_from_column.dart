import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';

/// 构建食物的单份营养素使用formbuilder的表单栏位
buildServingModifyFormColumn(CusLabel servingType) {
  return Column(
    children: [
      if (servingType.value == "metric")
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(child: Center(child: Text("100"))),
            _buildUnitDropdown("serving_unit"),
          ],
        ),
      // 如果是自定义的单份食物营养素，需要输入单位，可输入等价标准数值
      if (servingType.value == "custom") ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(child: Center(child: Text("1"))),
            Flexible(
              child: FormBuilderTextField(
                name: "serving_unit",
                decoration: const InputDecoration(labelText: "*单位"),
                // 2023-12-04 需要指定使用name，原本默认的.text会弹安全键盘，可能无法输入中文
                keyboardType: TextInputType.name,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: "单位不可为空"),
                ]),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(flex: 1, child: SizedBox()),
            const Flexible(flex: 2, child: Text("等价度量值及单位")),
            Flexible(
              flex: 1,
              child: _cusTextField("metric_serving_size", "", suffix: ''),
            ),
            _buildUnitDropdown("metric_serving_unit"),
          ],
        ),
      ],

      // 食物的品牌和产品名称(没有对应数据库，没法更人性化的筛选，都是用户输入)
      _cusTextField("energy", "*能量", suffix: "千焦", errorText: '能量不可为空'),
      _cusTextField("protein", "*蛋白质", errorText: '蛋白质不可为空'),
      _cusTextField("total_fat", "*脂肪", errorText: '脂肪不可为空'),
      _cusSubTextFieldRow("saturated_fat", "饱和脂肪"),
      _cusSubTextFieldRow("trans_fat", "反式脂肪"),
      _cusSubTextFieldRow("polyunsaturated_fat", "多不饱和脂肪"),
      _cusSubTextFieldRow("monounsaturated_fat", "单不饱和脂肪"),
      _cusTextField("total_carbohydrate", "*总碳水化合物", errorText: '总碳水化合物不可为空'),
      _cusSubTextFieldRow("sugar", "糖"),
      _cusSubTextFieldRow("dietary_fiber", "膳食纤维"),
      _cusTextField("sodium", "*钠", suffix: '毫克', errorText: '钠不可为空'),
      _cusTextField("potassium", "钾", suffix: '毫克'),
      _cusTextField("cholesterol", "胆固醇", suffix: '毫克'),
    ],
  );
}

// 标准单份和客制化单份时的单位下拉选择框，只有名称不一样
_buildUnitDropdown(String name) {
  return Flexible(
    flex: 1,
    child: Center(
      child: FormBuilderDropdown<String>(
        name: name,
        initialValue: "g",
        items: ["ml", "g"]
            .map((unit) => DropdownMenuItem(
                  alignment: AlignmentDirectional.center,
                  value: unit,
                  child: Text(unit),
                ))
            .toList(),
      ),
    ),
  );
}

// 这个修改的表单栏位，大部分都是文本输入框，且要求输入数字
_cusTextField(
  String name,
  String labelText, {
  String? suffix = "克",
  String? errorText,
  String? initialValue,
  TextInputType? keyboardType,
}) {
  return FormBuilderTextField(
    name: name,
    initialValue: initialValue,
    decoration: InputDecoration(
      labelText: labelText,
      suffixText: suffix,
    ),
    // 正则来只允许输入数字和小数点
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp(r'^\d*\.?\d*$'),
      )
    ],
    // 默认展示数字键盘，客制化单位时传入文本键盘
    // 2023-12-04 没有传默认使用name，原本默认的.text会弹安全键盘，可能无法输入中文
    keyboardType: keyboardType ?? TextInputType.number,
    // 这里的验证都只是不为空而已，有传错误信息，说明才有验证不为空
    validator: errorText != null
        ? FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: errorText),
          ])
        : null,
  );
}

// 像脂肪还有细分像，是个row，前面有空白。单位都是克，只需要name和名称即可
_cusSubTextFieldRow(String name, String labelText) {
  return Row(
    children: [
      const Expanded(flex: 1, child: SizedBox()),
      Expanded(
        flex: 4,
        child: _cusTextField(name, labelText),
      ),
    ],
  );
}

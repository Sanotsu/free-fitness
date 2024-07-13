// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/dietary_state.dart';

///
/// 食物的新增和修改为了逻辑方便使用两个页面，但其中很多内容是重复的，所以集中放在这里。
/// 有尝试过统一为食物编辑表单和营养素编辑表单，额外的处理比较麻烦，所以保留新增和修改分开。
///
///
/// 新增的地方: 饮食条目选择食物找不到时可以新增；食物成分模块食物列表页面可以新增
///   (这两者处理一样，新增食物一定需要带单份营养素)
/// 修改的地方: 目前只有食物成分模块-> 选中某个食物进入详情页面。
///   (食物的基本信息和单份营养素是分开修改的，且只有在食物详情页面才有删除指定单份营养素；
///   而食物的删除，就在食物成分模块的食物列表页面，会同时删除食物及其所有单份营养素)
///

/// 构建食物的单份营养素使用formbuilder的表单栏位
buildServingModifyFormColumn(BuildContext context, CusLabel servingType) {
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
                decoration: InputDecoration(
                  labelText: "*${CusAL.of(context).servingUnit}",
                  // 设置透明底色
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                // 2023-12-04 需要指定使用name，原本默认的.text会弹安全键盘，可能无法输入中文
                // keyboardType: TextInputType.name,
                // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
                enableSuggestions: true,
                validator: FormBuilderValidators.required(),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(flex: 1, child: SizedBox()),
            Flexible(
              flex: 2,
              child: Text(CusAL.of(context).servingEquivalence),
            ),
            Flexible(
              flex: 1,
              child: _cusNumberTextField(
                context,
                "metric_serving_size",
                "",
                suffix: '',
              ),
            ),
            _buildUnitDropdown("metric_serving_unit"),
          ],
        ),
      ],

      // 食物的品牌和产品名称(没有对应数据库，没法更人性化的筛选，都是用户输入)
      _cusNumberTextField(
        context,
        "energy",
        "*${CusAL.of(context).mainNutrients('0')}",
        suffix: CusAL.of(context).unitLabels('3'),
        errorText: CusAL.of(context).requiredErrorText(
          CusAL.of(context).mainNutrients('0'),
        ),
      ),
      _cusNumberTextField(
        context,
        "protein",
        "*${CusAL.of(context).mainNutrients('2')}",
        errorText: CusAL.of(context).requiredErrorText(
          CusAL.of(context).mainNutrients('2'),
        ),
      ),
      _cusNumberTextField(
        context,
        "total_fat",
        "*${CusAL.of(context).mainNutrients('3')}",
        errorText: CusAL.of(context).requiredErrorText(
          CusAL.of(context).mainNutrients('2'),
        ),
      ),
      _cusSubTextFieldRow(
        context,
        "saturated_fat",
        CusAL.of(context).fatNutrients('1'),
      ),
      _cusSubTextFieldRow(
        context,
        "trans_fat",
        CusAL.of(context).fatNutrients('2'),
      ),
      _cusSubTextFieldRow(
        context,
        "polyunsaturated_fat",
        CusAL.of(context).fatNutrients('3'),
      ),
      _cusSubTextFieldRow(
        context,
        "monounsaturated_fat",
        CusAL.of(context).fatNutrients('4'),
      ),
      _cusNumberTextField(
        context,
        "total_carbohydrate",
        "*${CusAL.of(context).mainNutrients('4')}",
        errorText: CusAL.of(context).requiredErrorText(
          CusAL.of(context).mainNutrients('4'),
        ),
      ),
      _cusSubTextFieldRow(
        context,
        "sugar",
        CusAL.of(context).choNutrients('1'),
      ),
      _cusSubTextFieldRow(
        context,
        "dietary_fiber",
        CusAL.of(context).choNutrients('2'),
      ),
      _cusNumberTextField(
        context,
        "sodium",
        "*${CusAL.of(context).microNutrients('0')}",
        suffix: CusAL.of(context).unitLabels('1'),
        errorText: CusAL.of(context).requiredErrorText(
          CusAL.of(context).microNutrients('0'),
        ),
      ),
      _cusNumberTextField(
        context,
        "potassium",
        CusAL.of(context).microNutrients('1'),
        suffix: CusAL.of(context).unitLabels('1'),
      ),
      _cusNumberTextField(
        context,
        "cholesterol",
        CusAL.of(context).microNutrients('2'),
        suffix: CusAL.of(context).unitLabels('1'),
      ),
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
        decoration: const InputDecoration(
          // 设置透明底色
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    ),
  );
}

// 这个修改的表单栏位，大部分都是文本输入框，且要求输入数字
_cusNumberTextField(
  BuildContext context,
  String name,
  String labelText, {
  String? suffix,
  String? errorText,
  String? initialValue,
}) {
  return FormBuilderTextField(
    name: name,
    initialValue: initialValue,
    decoration: InputDecoration(
      labelText: labelText,
      suffixText: suffix ?? CusAL.of(context).unitLabels('0'),
      // 设置透明底色
      filled: true,
      fillColor: Colors.transparent,
    ),
    // 正则来只允许输入数字和小数点
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
    ],
    // 默认展示数字键盘，客制化单位时传入文本键盘
    keyboardType: TextInputType.number,
    // 这里的验证都只是不为空而已，有传错误信息，说明才有验证不为空
    validator: errorText != null
        ? FormBuilderValidators.required(errorText: errorText)
        : null,
  );
}

// 像脂肪还有细分像，是个row，前面有空白。单位都是克，只需要name和名称即可
_cusSubTextFieldRow(BuildContext context, String name, String labelText) {
  return Row(
    children: [
      const Expanded(flex: 1, child: SizedBox()),
      Expanded(
        flex: 4,
        child: _cusNumberTextField(context, name, labelText),
      ),
    ],
  );
}

/// 修改食物基本信息时表单所需栏位
/// 新增的时候还有标准单份和客制化单份单选框等其他内容，所以这里只是column的值
buildFoodModifyFormColumns(
  BuildContext context, {
  List<PlatformFile>? initImages,
}) {
  return [
    // 食物的品牌和产品名称(没有对应数据库，没法更人性化的筛选，都是用户输入)
    cusFormBuilerTextField(
      "product",
      labelText: '*${CusAL.of(context).foodLabels("0")}',
      validator: FormBuilderValidators.required(),
    ),
    cusFormBuilerTextField(
      "brand",
      labelText: '*${CusAL.of(context).foodLabels("1")}',
      validator: FormBuilderValidators.required(),
    ),
    cusFormBuilerTextField(
      "tags",
      labelText: CusAL.of(context).foodLabels("2"),
    ),
    cusFormBuilerTextField(
      "category",
      labelText: CusAL.of(context).foodLabels("3"),
    ),
    cusFormBuilerTextField(
      "description",
      maxLines: 4,
      labelText: CusAL.of(context).foodLabels("4"),
    ),

    const SizedBox(height: 10),
    // 上传活动示例图片（静态图或者gif）
    FormBuilderFilePicker(
      name: 'images',
      decoration: InputDecoration(
        labelText: CusAL.of(context).foodLabels("5"),
        // 设置透明底色
        filled: true,
        fillColor: Colors.transparent,
      ),
      initialValue: initImages,
      maxFiles: null,
      allowMultiple: true,
      previewImages: true,
      onChanged: (val) => debugPrint(val.toString()),
      typeSelectors: [
        TypeSelector(
          type: FileType.image,
          selector: Row(
            children: <Widget>[
              const Icon(Icons.file_upload),
              Text(CusAL.of(context).imageUploadLabel),
            ],
          ),
        )
      ],
      customTypeViewerBuilder: (children) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: children,
      ),
      onFileLoading: (val) {
        debugPrint(val.toString());
      },
    ),
  ];
}

/// 格式化单份营养素表单对象数据为数据库指定类型数据
List<ServingInfo> parseServingInfo(
  Map<String, dynamic> servingInfo,
  String servingType, {
  // 如果有传食物，说明是给已有的食物添加新的单份营养素信息，则修改其对应食物编号
  int? foodId,
  // 2023-12-19 如果有传单份营养素编号，说明是修改单份营养素，不额外增加其他单份数据
  int? servingInfoId,
}) {
  // 创建单份营养素实例
  ServingInfo createServingInfo(double multiplier, int size, String unit) {
    // ServingInfo类的一些属性，【注意】：营养素新增的表单中的name是和数据库中一样的蛇式命名这里才能转
    // 2023-12-06 这里改为sanke格式的话，只是少一次转换而已。
    final propNames = [
      'energy',
      'protein',
      'totalFat',
      'saturatedFat',
      'transFat',
      'polyunsaturatedFat',
      'monounsaturatedFat',
      'totalCarbohydrate',
      'sugar',
      'dietaryFiber',
      'sodium',
      'potassium',
      'cholesterol'
    ];

    // 如果用户有输入值的栏位才计算相关转换单位内容，为null的就直接保存null
    final props = Map.fromEntries(propNames.map((key) {
      final propName = getPropName(key);

      final val = servingInfo[propName];
      return MapEntry(
        propName,
        val == null ? null : _calculatePercentage(val, multiplier),
      );
    }));

    return ServingInfo(
      // 有传食物编号则赋值；没有就随意给个值，存入数据库时会修改
      foodId: foodId ?? 0,
      servingSize: size,
      servingUnit: unit,
      energy: props['energy'] ?? 0.0,
      protein: props['protein'] ?? 0.0,
      totalFat: props['total_fat'] ?? 0.0,
      saturatedFat: props['saturated_fat'],
      transFat: props['trans_fat'],
      polyunsaturatedFat: props['polyunsaturated_fat'],
      monounsaturatedFat: props['monounsaturated_fat'],
      totalCarbohydrate: props['total_carbohydrate'] ?? 0.0,
      sugar: props['sugar'],
      dietaryFiber: props['dietary_fiber'],
      sodium: props['sodium'] ?? 0.0,
      cholesterol: props['cholesterol'],
      potassium: props['potassium'],
      contributor: CacheUser.userName,
      gmtCreate: getCurrentDateTime(),
      isDeleted: false,
    );
  }

  // 用于记录要返回的营养素列表
  final servingList = <ServingInfo>[];

  // 不管是标准度量还是自定义的，数值都要记录
  // final inputSize = servingType == 'metric' ? 100 : 1;
  // final inputUnit = servingType == servingInfo['serving_unit'] as String;

  // 【重点】这里输入值应该都是1,单位则是标准单份为100g或100ml，自定义则为1份
  const inputSize = 1;
  final originUnit = servingInfo['serving_unit'] as String;
  var inputUnit = servingType == 'metric' ? "100$originUnit" : "1$originUnit";

  // 2023-12-06 如果客制化单份有标准度量，作为单位文字一起保存(不然这个表单栏位没用到)
  if (servingType == 'custom') {
    // 如果是自定义的单份，且有输入对应的标准度量值，将其作为客制化单位的一部分
    final temp = double.tryParse(servingInfo['metric_serving_size'] ?? '');
    if (temp != null) {
      final tempUnit = servingInfo['metric_serving_unit'] as String;
      inputUnit += "($temp $tempUnit)";
    }
  }

  servingList.add(createServingInfo(1.0, inputSize, inputUnit));

  // 2023-12-19 如果有单份营养素信息，则不需要1ml/g的值
  if (servingInfoId != null) {
    return servingList;
  }

  // 如果是标准的，还需要保留1ml/g的值(标准度量为100ml/g，单个ml/g的营养素比例就是其0.01)
  if (servingType == 'metric') {
    servingList.add(createServingInfo(0.01, 1, "1$originUnit"));
  }

  // 2023-12-06 新加了唯一约束:foodId+servingSize+servingUnit，
  // 所以这里客制化即便有对应标准度量值，也不保存单份1ml/g了
  // else if (servingType == 'custom') {
  //   // 如果是自定义的单份，且有输入对应的标准度量值，也计算出对应1mg/g的值
  //   final temp = double.tryParse(servingInfo['metric_serving_size'] ?? '');
  //   if (temp != null) {
  //     final tempUnit = servingInfo['metric_serving_unit'] as String;
  //     final tempMultiplier = double.parse((1 / temp).toStringAsFixed(2));
  //     servingList.add(createServingInfo(tempMultiplier, 1, "1$tempUnit"));
  //   }
  // }

  return servingList;
}

double _calculatePercentage(dynamic value, double percentage) {
  return double.parse(
    (double.parse(value.toString()) * percentage).toStringAsFixed(2),
  );
}

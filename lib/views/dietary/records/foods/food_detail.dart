// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../common/global/constants.dart';
import '../../../../models/dietary_state.dart';

class FoodDetail extends StatefulWidget {
  final FoodAndServingInfo foodItem;
  const FoodDetail({super.key, required this.foodItem});

  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  final _formKey = GlobalKey<FormBuilderState>();

  // 食物营养素单位选项
  // 一种食物可能有多个单位，标准单份显示的栏位是metricServingUnit，自定份数的显示栏位是servingSize
  // 所以这个选项列表的值类型为{flag:bool,value:dynamic},flag标识是否是标准化单份，value为单份取值(上一行说明)
  var servingUnitOptions = [];

  // 用户输入的食物数量和单位
  double inputServingValue = 1;
  // 单位就是上面选项选中的值，用于计算是其value
  var inputServingUnit = {};

  /// 显示的营养素总值= 标准单位 ? (输入值*(标准单位/100)*单克/毫升的营养素) : 输入值*自定单份单位*单份营养素
  // 当前食物的营养素是否为标准量化单位
  bool isMetricServing = false;
  // 用于计算的数量，即用户输入值是否要除以100用克/毫升算，还是直接份用算
  // (是标准单份则除以100的单克，不是标准单份就直接是1份)
  double inputMetricServingUnit = 0;
  // 保存要用于计算的单份营养素信息
  late ServingInfo nutrientsInfo;

  @override
  void initState() {
    super.initState();

    _getDefaulFoodServingInfo();
  }

  // 可能存在1种食物多个营养素单份单位，默认取第一个用于显示
  _getDefaulFoodServingInfo() {
    var temp = widget.foodItem.servingInfoList;
    // 构建初始化值
    if (temp[0].isMetric) {
      inputServingValue = (temp[0].metricServingSize ?? 1).toDouble();
      inputServingUnit = {
        "flag": true,
        "value": temp[0].metricServingUnit,
      };
      isMetricServing = true;
      inputMetricServingUnit = inputServingValue / 100;
    } else {
      inputServingValue = 1;
      inputServingUnit = {
        "flag": false,
        "value": temp[0].servingSize,
      };
      isMetricServing = false;
      inputMetricServingUnit = inputServingValue;
    }

    nutrientsInfo = temp[0];

// 构建可选单位列表
    for (var info in temp) {
      if (info.isMetric) {
        servingUnitOptions.add({
          "flag": true,
          "value": info.metricServingUnit,
        });
      } else {
        servingUnitOptions.add({
          "flag": false,
          "value": info.servingSize,
        });
      }
    }
  }

  _recalculateNutrients() {
    print("_recalculateNutrients inputServingUnit $inputServingUnit");
    print("_recalculateNutrients inputServingValue $inputServingValue");

    var tempList = widget.foodItem.servingInfoList;

    print("-----------temp $tempList inputServingUnit $inputServingUnit ");

    var flag = inputServingUnit["flag"];
    var value = inputServingUnit["value"];

    //  ？？？注意，如果这里没有匹配的，肯定是哪里出问题了
    // 2023-10-21
    // 标准单份数据库存入100g/ml的含量，这里计算是要除以100；自定义单份则无需
    var metricServing = tempList
        .where((e) =>
            (!flag && e.servingSize == value) ||
            (flag && e.metricServingUnit == value))
        .first;

    print("-----------metricServing $metricServing");

    setState(() {
      nutrientsInfo = metricServing;
      isMetricServing = flag;
      inputMetricServingUnit =
          flag ? inputServingValue / 100 : inputServingValue;

      print("处理结果： $nutrientsInfo --$inputMetricServingUnit");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Food Details - ${widget.foodItem.food.brand}'),
      ),
      body: ListView(
        children: [
          // 修改数量和单位
          Padding(
            padding: EdgeInsets.only(left: 20.sp, right: 20.sp),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  FormBuilderTextField(
                    name: 'serving_value',
                    initialValue: "$inputServingValue",
                    decoration: const InputDecoration(labelText: '数量'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.numeric(errorText: '数量只能为数字'),
                    ]),
                    onChanged: (value) {
                      if (_formKey.currentState?.validate() != true) {
                        return;
                      }
                      setState(() {
                        inputServingValue = (value != "" && value != null)
                            ? double.parse(value)
                            : 1.0;
                        _recalculateNutrients();
                      });
                    },
                  ),
                  SizedBox(height: 5.sp),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FormBuilderDropdown<dynamic>(
                          name: 'serving_unit',
                          decoration: const InputDecoration(
                            labelText: '单位',
                          ),
                          initialValue: servingUnitOptions[0],
                          items: servingUnitOptions
                              .map((unit) => DropdownMenuItem(
                                    alignment: AlignmentDirectional.center,
                                    value: unit,
                                    child: Text(unit['value']),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _formKey.currentState?.fields['serving_unit']
                                  ?.save();
                              print("unit onchanged value now is $val");

                              inputServingUnit = val;
                              _recalculateNutrients();
                            });
                          },
                          valueTransformer: (val) => val?.toString(),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextButton(
                          onPressed: () {},
                          // 2023-10-21 应该也是跳转到新增food的表单，但是可能是修改或新增已有的营养素子栏位，食物信息不变化
                          // 这里的sql方法好像还没有
                          child: const Text("添加新单位?"),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ？？？ 这里还缺一个动态的新增到餐点、从餐点中移除 的按钮。
          Padding(
              padding: EdgeInsets.only(left: 20.sp, right: 20.sp, top: 20.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text("移除")),
                  ElevatedButton(onPressed: () {}, child: const Text("添加"))
                ],
              )),
          // 主要营养素表格
          Padding(
            padding: EdgeInsets.only(left: 20.sp, right: 20.sp, top: 20.sp),
            child: Text(
              "主要营养信息",
              style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20.sp, right: 20.sp),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.grey, // 设置背景色
                // 其他背景样式，例如渐变等
              ),
              child: Table(
                border: TableBorder.all(),
                columnWidths: const <int, TableColumnWidth>{
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: <TableRow>[
                  TableRow(
                    children: <Widget>[
                      _genEssentialNutrientsTableCell(
                        "卡路里",
                        "${(inputMetricServingUnit * nutrientsInfo.energy / oneCalToKjRatio).toStringAsFixed(2)} 大卡",
                      ),
                      _genEssentialNutrientsTableCell(
                        "碳水化合物",
                        formatNutrientValue(inputMetricServingUnit *
                            nutrientsInfo.totalCarbohydrate),
                      ),
                    ],
                  ),
                  TableRow(
                    // decoration: const BoxDecoration(color: Colors.white),
                    children: <Widget>[
                      _genEssentialNutrientsTableCell(
                        "脂肪",
                        formatNutrientValue(
                            inputMetricServingUnit * nutrientsInfo.totalFat),
                      ),
                      _genEssentialNutrientsTableCell(
                        "蛋白质",
                        formatNutrientValue(
                            inputMetricServingUnit * nutrientsInfo.protein),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 详细营养素区域
          Padding(
            padding: EdgeInsets.only(left: 20.sp, right: 20.sp, top: 20.sp),
            child: Text(
              "全部营养信息",
              style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold),
            ),
          ),
          // listview中嵌入listview可能会出问题，使用这个scollview也不能放到expanded里面
          // 实测是根据外部listview滚动，而不是内部单独再滚动
          Padding(
            padding: EdgeInsets.only(left: 20.sp, right: 20.sp),
            child: _genAllNutrientsCard(),
          ),
        ],
      ),
    );
  }

  _genEssentialNutrientsTableCell(String title, String value) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: EdgeInsets.all(10.sp),
        child: Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title\n', // 没有这个换行符两个会放到一行来
                  style: TextStyle(
                    color: Theme.of(context).canvasColor,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: Theme.of(context).canvasColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _genAllNutrientsCard() {
    var nutrientValues = {
      // '食用量': '$inputServingValue X ${inputServingUnit["value"]}',
      // '卡路里': inputMetricServingUnit * nutrientsInfo.energy,
      '蛋白质': inputMetricServingUnit * nutrientsInfo.protein,
      '脂肪': inputMetricServingUnit * nutrientsInfo.totalFat,
      '碳水化合物': inputMetricServingUnit * nutrientsInfo.totalCarbohydrate,
      '钠': inputMetricServingUnit * nutrientsInfo.sodium,
      '胆固醇': nutrientsInfo.cholesterol != null
          ? inputMetricServingUnit * nutrientsInfo.cholesterol!
          : 0.0,
      '钾': nutrientsInfo.potassium != null
          ? inputMetricServingUnit * nutrientsInfo.potassium!
          : 0.0,
    };

    var subtitles = {
      // '卡路里': [
      //   {'': nutrientsInfo.energy / 1000},
      // ],
      '脂肪': [
        {'反式脂肪': nutrientsInfo.transFat},
        {'多不饱和脂肪': nutrientsInfo.polyunsaturatedFat},
        {'单不饱和脂肪': nutrientsInfo.monounsaturatedFat},
        {'饱和脂肪': nutrientsInfo.saturatedFat},
      ],
      '碳水化合物': [
        {'糖': nutrientsInfo.sugar},
        {'纤维': nutrientsInfo.dietaryFiber},
      ],
    };

    return SingleChildScrollView(
      child: Column(
        children: [
          // 食用量和能量(卡路里)这两个比较特殊，单独处理
          _buildCard(
            "食用量",
            '$inputServingValue X ${inputServingUnit["value"]}',
          ),
          _buildCard(
            "卡路里",
            '${(inputMetricServingUnit * nutrientsInfo.energy).toStringAsFixed(2)} 千焦',
            [
              Row(
                children: [
                  const Expanded(child: Text("")),
                  // 子行的单位都是克，不用传其他参数
                  Text(
                    "${(inputMetricServingUnit * nutrientsInfo.energy / oneCalToKjRatio).toStringAsFixed(2)} 大卡",
                  ),
                ],
              )
            ],
          ),
          // 除了食用量和能力行之外，其他处理都一样
          ...nutrientValues.entries.map((entry) {
            var title = entry.key;
            var value = entry.value;

            List<Widget>? subtitleRows;

            // print("value----------------------$title - $value");

            if (subtitles.containsKey(title)) {
              subtitleRows = subtitles[title]!
                  .where((subtitle) => subtitle.values.first != null)
                  .map((subtitle) => buildSubtitleRow(
                      subtitle.keys.first, subtitle.values.first))
                  .toList();
            }

            return _buildCard(
                title,
                formatNutrientValue(
                  value,
                  isCalories: title == '卡路里',
                  isMilligram: ["钠", "胆固醇", "钾"].contains(title),
                ),
                subtitleRows);
          }).toList()
        ],
      ),
    );
  }

  // 能量栏位也单独处理的话这里不用格式化千焦和大卡了
  String formatNutrientValue(
    double value, {
    bool isCalories = false, // 是否是卡路里（默认显示克，大卡和毫克要指定）
    bool isMilligram = false, // 是否是毫克
  }) {
    final formattedValue = value.toStringAsFixed(2);
    return isCalories
        ? '$formattedValue 千焦'
        : isMilligram
            ? '$formattedValue 毫克'
            : '$formattedValue 克';
  }

  //  构建卡片
  Widget _buildCard(String title, String value, [List<Widget>? subtitleRows]) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(title)),
            Text(value),
          ],
        ),
        subtitle: (subtitleRows != null && subtitleRows.isNotEmpty)
            ? Column(children: subtitleRows)
            : null,
      ),
    );
  }

  // 构建卡片中ListTile的子标题部件
  Widget buildSubtitleRow(String title, double? value) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        // 子行的单位都是克，不用传其他参数
        Text(formatNutrientValue(inputMetricServingUnit * value!)),
      ],
    );
  }
}

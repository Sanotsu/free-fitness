// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../models/dietary_state.dart';

class FoodDetail extends StatefulWidget {
  final FoodAndServingInfo foodItem;
  const FoodDetail({super.key, required this.foodItem});

  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  final _formKey = GlobalKey<FormBuilderState>();

// 食物营养素详情
  var servingUnitOptions = [];

  // 用户输入的食物数量和单位
  var inputServingValue = 1;
  var inputServingUnit = {};

  // 用于显示的主要营养素的值(顺序默认为能量、碳水、脂肪、蛋白质)
  // 2023-10-21 因为改变了数量和单位之后不知主营养素改变，下方的详情也要变，所以这里改为对象取对应属性
  List<double> mainNutrients = [];
  Map<String, double> allNutrients = {};

  @override
  void initState() {
    super.initState();

    _getDefaulFoodServingInfo();
  }

  _getDefaulFoodServingInfo() {
    var temp = widget.foodItem.servingInfoList;
    // 构建初始化值
    if (temp[0].isMetric) {
      inputServingValue = temp[0].metricServingSize ?? 1;
      inputServingUnit = {
        "flag": true,
        "value": temp[0].metricServingUnit,
      };
    } else {
      inputServingValue = 1;
      inputServingUnit = {
        "flag": false,
        "value": temp[0].servingSize,
      };
    }
    mainNutrients = [
      temp[0].energy,
      temp[0].totalCarbohydrate,
      temp[0].totalFat,
      temp[0].protein
    ];

    allNutrients = {
      "energy": temp[0].energy,
      "totalCarbohydrate": temp[0].totalCarbohydrate,
      "totalFat": temp[0].totalFat,
      "protein": temp[0].protein
    };

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

    var temp = widget.foodItem.servingInfoList;

    print(
        "-----------temp $temp inputServingUnit['flag'] ${inputServingUnit["flag"]}  ${inputServingUnit["value"]}");

    var flag = inputServingUnit["flag"];
    var value = inputServingUnit["value"];
    var size = inputServingValue;

    //  ？？？注意，如果这里没有匹配的，肯定是哪里出问题了
    // 2023-10-21
    // 标准单份数据库存入100g/ml的含量，这里计算是要除以100；自定义单份则无需
    var metricServing = temp
        .where((e) =>
            (!flag && e.servingSize == value) ||
            (flag && e.metricServingUnit == value))
        .first;

    print("-----------metricServing $metricServing");

    setState(() {
      // ！！！这个取值处理方案挺不错的
      mainNutrients = [
        metricServing.energy,
        metricServing.totalCarbohydrate,
        metricServing.totalFat,
        metricServing.protein,
      ]
          .map((value) => double.parse(
              (flag ? size / 100 * value : size * value).toStringAsFixed(2)))
          .toList();

      allNutrients = {
        "energy": metricServing.energy,
        "totalCarbohydrate": metricServing.totalCarbohydrate,
        "totalFat": metricServing.totalFat,
        "protein": metricServing.protein
      }
          .map((key, value) => MapEntry(
              key,
              double.parse((flag ? size / 100 * value : size * value)
                  .toStringAsFixed(2))))
          .cast<String, double>();

      print("处理结果： $allNutrients");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Details - ${widget.foodItem.food.brand}'),
      ),
      body: Column(
        children: [
          FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                FormBuilderTextField(
                  name: 'serving_value',
                  initialValue: "$inputServingValue",
                  decoration: InputDecoration(labelText: '$inputServingValue'),
                  onChanged: (value) {
                    setState(() {
                      inputServingValue =
                          (value != "" && value != null) ? int.parse(value) : 1;
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
          SizedBox(height: 50.sp),
          DecoratedBox(
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
                      "${(allNutrients['energy']! / 4.184).toStringAsFixed(2)} 大卡",
                    ),
                    _genEssentialNutrientsTableCell(
                      "碳水化合物",
                      "${(allNutrients['totalCarbohydrate'])} 克",
                    ),
                  ],
                ),
                TableRow(
                  // decoration: const BoxDecoration(color: Colors.white),
                  children: <Widget>[
                    _genEssentialNutrientsTableCell(
                      "脂肪",
                      "${mainNutrients[2]} 克",
                    ),
                    _genEssentialNutrientsTableCell(
                      "蛋白质",
                      "${mainNutrients[3]} 克",
                    ),
                  ],
                ),
              ],
            ),
          )
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
}

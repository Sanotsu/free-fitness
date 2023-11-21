// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../common/global/constants.dart';
import '../../../../models/dietary_state.dart';

// ？？？看能不能和日志中的food detail 拆一些复用部件来
class FoodNutrientDetail extends StatefulWidget {
  // 这个是食物搜索页面点击食物进来详情页时传入的数据
  final FoodAndServingInfo foodItem;

  const FoodNutrientDetail({super.key, required this.foodItem});

  @override
  State<FoodNutrientDetail> createState() => _FoodNutrientDetailState();
}

class _FoodNutrientDetailState extends State<FoodNutrientDetail> {
  final _formKey = GlobalKey<FormBuilderState>();
  // 传入的食物详细数据
  late FoodAndServingInfo fsInfo;

  /// 食物营养素单位选项
  // 一种食物可能有多个单份单位，所以是列表供用户下拉选择，对应数据库表中的 servingUnit。
  var servingUnitOptions = [];
  // 用户输入的食物数量
  double inputServingValue = 1;
  // 用户输入的食物摄入单位，就是上面选项选中的单位（主要是根据单位找到用于计算的营养素信息）
  var inputServingUnit = "";
  // 用于计算的单份营养素信息
  late ServingInfo nutrientsInfo;

  @override
  void initState() {
    super.initState();

    setState(() {
      fsInfo = widget.foodItem;
      _getDefaulFoodServingInfo();
    });
  }

  // m默认显示指定食物的第一个单份营养素(理论上不存在没有单份营养素的食物)
  _getDefaulFoodServingInfo() {
    var temp = fsInfo.servingInfoList;
    nutrientsInfo = temp[0];
    inputServingValue = (nutrientsInfo.servingSize).toDouble();
    inputServingUnit = nutrientsInfo.servingUnit;

    // 构建可选单位列表(不管是新增还是修改，对应食物的单份营养素列表都一样)
    for (var info in temp) {
      servingUnitOptions.add(info.servingUnit);
    }
  }

  // 修改了摄入量数值和单位，都要重新计算用于显示的营养素信息(这里是重新获取修改后的营养素单位)
  _recalculateNutrients() {
    var tempList = fsInfo.servingInfoList;

    //  ？？？注意，如果这里没有匹配的，肯定是哪里出问题了
    // 从用户输入的单份食物单位，找到对应的营养素信息
    var metricServing =
        tempList.where((e) => e.servingUnit == inputServingUnit).first;

    setState(() {
      // 更新当前用于计算的单份营养素信息
      nutrientsInfo = metricServing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('食物详情'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.edit, size: 20.sp),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(20.sp),
            child: Center(
              child: Text(
                '${fsInfo.food.product} (${fsInfo.food.brand})',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
                    decoration: InputDecoration(
                      labelText: '数量',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
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
                        inputServingValue = double.tryParse(value ?? "1") ?? 1;
                        _recalculateNutrients();
                      });
                    },
                  ),
                  SizedBox(height: 10.sp),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FormBuilderDropdown<dynamic>(
                          name: 'serving_unit',
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: '单位',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          initialValue: servingUnitOptions[0],
                          items: servingUnitOptions
                              .map((unit) => DropdownMenuItem(
                                    alignment: AlignmentDirectional.center,
                                    value: unit,
                                    child: Text(unit),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
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

          ...genMainNutrientArea(),
          // 详细营养素区域
          Padding(
            padding: EdgeInsets.only(left: 20.sp, right: 20.sp, top: 20.sp),
            child: Text(
              "全部营养信息",
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
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

  genMainNutrientArea() {
    // 主要营养素表格
    return [
      Padding(
        padding: EdgeInsets.only(left: 20.sp, right: 20.sp, top: 20.sp),
        child: Text(
          "主要营养信息",
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
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
                    "${(inputServingValue * nutrientsInfo.energy / oneCalToKjRatio).toStringAsFixed(2)} 大卡",
                  ),
                  _genEssentialNutrientsTableCell(
                    "碳水化合物",
                    formatNutrientValue(
                        inputServingValue * nutrientsInfo.totalCarbohydrate),
                  ),
                ],
              ),
              TableRow(
                // decoration: const BoxDecoration(color: Colors.white),
                children: <Widget>[
                  _genEssentialNutrientsTableCell(
                    "脂肪",
                    formatNutrientValue(
                        inputServingValue * nutrientsInfo.totalFat),
                  ),
                  _genEssentialNutrientsTableCell(
                    "蛋白质",
                    formatNutrientValue(
                        inputServingValue * nutrientsInfo.protein),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
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
      // '食用量': '$inputServingValue X ${inputServingUnit}',
      // '卡路里': inputServingValue * nutrientsInfo.energy,
      '蛋白质': inputServingValue * nutrientsInfo.protein,
      '脂肪': inputServingValue * nutrientsInfo.totalFat,
      '碳水化合物': inputServingValue * nutrientsInfo.totalCarbohydrate,
      '钠': inputServingValue * nutrientsInfo.sodium,
      '胆固醇': nutrientsInfo.cholesterol != null
          ? inputServingValue * nutrientsInfo.cholesterol!
          : 0.0,
      '钾': nutrientsInfo.potassium != null
          ? inputServingValue * nutrientsInfo.potassium!
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
            '$inputServingValue X $inputServingUnit',
          ),
          _buildCard(
            "卡路里",
            '${(inputServingValue * nutrientsInfo.energy).toStringAsFixed(2)} 千焦',
            [
              Row(
                children: [
                  const Expanded(child: Text("")),
                  // 子行的单位都是克，不用传其他参数
                  Text(
                    "${(inputServingValue * nutrientsInfo.energy / oneCalToKjRatio).toStringAsFixed(2)} 大卡",
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
        Text(formatNutrientValue(inputServingValue * value!)),
      ],
    );
  }
}

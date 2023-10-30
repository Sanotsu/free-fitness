// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../common/global/constants.dart';
import '../../../../models/dietary_state.dart';

class FoodDetail extends StatefulWidget {
  // 这个是食物搜索页面点击食物进来详情页时传入的数据
  final FoodAndServingInfo foodItem;
  // 同时需要知道该日期的日记信息和对应的餐次信息
  // 主页点击item的话，这个一定有，而且是修改数量和单位(餐次暂不可修改)；
  // food list 点击的话，可能是添加当日第一条，不一定有（这个只能是新增）。
  final FoodDailyLogRecord? fdlr;
  // 当前传入的食物item。（理论上只有log index过来的才有）
  final MealFoodItemDetail? mfid;
  // ？？？这次item 新增/修改 所属的餐次和日期（暂时不支持修改餐次，太麻烦了）
  final Mealtimes mealtime;
  final String logDate;

  /// 直接从主页面的item点击过来时的数据（这个可能能是修改量，删除）
  ///   不能修改餐次的话，那就只有修改量了；
  ///   但如果有删除的话，需要考虑该餐次删除这个item之后为空，也要一并删除meal，再修改log对应的meal id
  /// 从food list 过来，只能是新增了
  final String jumpSource; // 调到详情页的来源，删除、修改、新增的按钮显示的来源

  const FoodDetail({
    super.key,
    required this.foodItem,
    this.fdlr,
    this.mfid,
    required this.mealtime,
    required this.logDate,
    required this.jumpSource,
  });

  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  final _formKey = GlobalKey<FormBuilderState>();

  // 食物营养素单位选项
  // 一种食物可能有多个单份单位，所以是列表供用户下拉选择，对应数据库表中的 servingUnit。
  var servingUnitOptions = [];

  // 用户输入的食物摄入数量
  double inputServingValue = 1;
  // 用户输入的食物摄入单位，就是上面选项选中的单位（主要是根据单位找到用于计算的营养素信息）
  var inputServingUnit = "";
  // 保存要用于计算的单份营养素信息
  late ServingInfo nutrientsInfo;

  @override
  void initState() {
    super.initState();

    _getDefaulFoodServingInfo();

    // if (widget.jumpSource == "FOOD_LIST") {
    //   _getDefaulFoodServingInfo();
    // } else if (widget.jumpSource == "LOG_INDEX") {
    //   _getInputFoodServingInfoFromFdlr();
    // }

// =================================================

//--------------？？？ 这里显示的摄入量和单位（营养素的食物单份数据）根据来源不同，取值也不同
// 新增的时候，一个食物有多种单份营养素，默认取第一个
// 修改的时候，fdlr中有对应的serving info  和摄入量的值
// --- 区别只是默认显示数据，修改和新增用户修改摄入量和单份类型后，其他显示或其他操作都一样的逻辑。

    // setState(() {
    //   print("yi饮食主界面或者food list传入的额数据---------------");
    //   print(widget.foodItem);
    //   log("${widget.fdlr}");
    //   print(widget.logDate);
    //   print(widget.mealtime);
    //   print(widget.jumpSource);
    // });
  }

  // 可能存在1种食物多个营养素单份单位，默认取第一个用于显示
  // --- 这个是food list选择指定food之后的显示值处理
  _getDefaulFoodServingInfo() {
    var temp = widget.foodItem.servingInfoList;
    // 默认给传入的食物的第一个营养素信息，daily log 主页面传入时会修改为指定的
    nutrientsInfo = temp[0];

    // 1 如果是查询的food list 直接点击的食物详情，取默认第一个营养素信息
    if (widget.jumpSource == "FOOD_LIST") {
      // 构建初始化值
      // 没有传入的数据就用列表第一个
      inputServingValue = (nutrientsInfo.servingSize).toDouble();
      inputServingUnit = nutrientsInfo.servingUnit;
    } else if (widget.jumpSource == "LOG_INDEX") {
      // 有传入的数据就用传入的
      nutrientsInfo = widget.mfid!.servingInfo;
      inputServingValue = widget.mfid!.mealFoodItem.foodIntakeSize;
      inputServingUnit = nutrientsInfo.servingUnit;
    }

    // 构建可选单位列表(不管是新增还是修改，对应食物的单份营养素列表都一样)
    for (var info in temp) {
      servingUnitOptions.add(info.servingUnit);
    }
  }

  // 修改了摄入量数值和单位，都要重新计算用于显示的营养素信息(这里是重新获取修改后的营养素单位)
  _recalculateNutrients() {
    print("_recalculateNutrients inputServingUnit $inputServingUnit");
    print("_recalculateNutrients inputServingValue $inputServingValue");

    var tempList = widget.foodItem.servingInfoList;

    print("-----------temp $tempList inputServingUnit $inputServingUnit ");

    //  ？？？注意，如果这里没有匹配的，肯定是哪里出问题了
    // 从用户输入的单份食物单位，找到对应的营养素信息
    var metricServing =
        tempList.where((e) => e.servingUnit == inputServingUnit).first;

    print("-----------metricServing $metricServing");

    setState(() {
      nutrientsInfo = metricServing;
      print("处理结果： $nutrientsInfo ");
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
                                    child: Text(unit),
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
                        "${(inputServingValue * nutrientsInfo.energy / oneCalToKjRatio).toStringAsFixed(2)} 大卡",
                      ),
                      _genEssentialNutrientsTableCell(
                        "碳水化合物",
                        formatNutrientValue(inputServingValue *
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

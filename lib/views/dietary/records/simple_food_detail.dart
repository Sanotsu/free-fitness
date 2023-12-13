import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../common/global/constants.dart';
import '../../../../common/utils/db_dietary_helper.dart';
import '../../../../models/dietary_state.dart';
import '../../../common/utils/tools.dart';

/// 2023-12-04 这个是饮食条目选择食物的时候展示的食物列表，点击之后显示的食物详情；
/// 和单独的“食物成分”模块不一样，显示的内容更少些，主要是选择餐次、单份营养素种类和添加食物摄入数量而已
class SimpleFoodDetail extends StatefulWidget {
  // 这个是食物搜索页面点击食物进来详情页时传入的数据
  final FoodAndServingInfo foodItem;

  // 饮食日记主页，点击条目详情传入的饮食日记条目详情中什么都有（条目的修改、删除）
  //    支持修改的餐次、食物摄入数量、食物单份单位在这个详情中都有原始的供显示
  // 但是点击添加，先到查询食物列表，再跳转过来的话则没有这个饮食日记条目详情（条目的新增）
  //    删除、修改、新增的按钮显示的来源
  final DailyFoodItemWithFoodServing? dfiwfs;

  // 新增时(food list 进入)需要带上新增属于哪个餐次和那个日期，修改时饮食日记条目详情都有
  final CusMeals? mealtime;
  final String? logDate;

  const SimpleFoodDetail({
    super.key,
    required this.foodItem,
    this.dfiwfs,
    this.mealtime,
    this.logDate,
  });

  @override
  State<SimpleFoodDetail> createState() => _SimpleFoodDetailState();
}

class _SimpleFoodDetailState extends State<SimpleFoodDetail> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

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

  // 要移动到的目标餐次（原始餐次直接去widget的值即可，新的则需要根据用户选择而改变）
  late CusLabel inputMealtimeValue;

  @override
  void initState() {
    super.initState();

    // ---这里显示的摄入量和单位（营养素的食物单份数据）根据来源不同，取值也不同
    // 新增的时候，一个食物有多种单份营养素，默认取第一个
    // 修改的时候，fdlr中有对应的serving info  和摄入量的值
    // --- 区别只是默认显示数据，修改和新增用户修改摄入量和单份类型后，其他显示或其他操作都一样的逻辑。
    _getDefaulFoodServingInfo();
  }

  // 可能存在1种食物多个营养素单份单位，默认取第一个用于显示
  // --- 这个是food list选择指定food之后的显示值处理
  _getDefaulFoodServingInfo() {
    var temp = widget.foodItem.servingInfoList;
    // 默认给传入的食物的第一个营养素信息，daily log 主页面传入时会修改为指定的
    nutrientsInfo = temp[0];

    // 1 如果有饮食日记条目详情，则是log index 跳转的修改或删除
    if (widget.dfiwfs != null) {
      // 有传入的数据就用传入的
      nutrientsInfo = widget.dfiwfs!.servingInfo;
      inputServingValue = widget.dfiwfs!.dailyFoodItem.foodIntakeSize;
      inputServingUnit = nutrientsInfo.servingUnit;
      // 构建初始的目标餐次(移除或修改时不会单独传日期和餐次的)
      inputMealtimeValue = mealtimeList.firstWhere(
          (e) => e.enLabel == widget.dfiwfs!.dailyFoodItem.mealCategory);
    } else {
      // 2 如果没有饮食日记条目详情，则是food list跳转的新增
      // 构建初始化值
      // 没有传入的数据就用列表第一个
      inputServingValue = (nutrientsInfo.servingSize).toDouble();
      inputServingUnit = nutrientsInfo.servingUnit;
      // 构建初始的目标餐次
      inputMealtimeValue =
          mealtimeList.firstWhere((e) => e.value == widget.mealtime);
    }

    // 构建可选单位列表(不管是新增还是修改，对应食物的单份营养素列表都一样)
    for (var info in temp) {
      servingUnitOptions.add(info.servingUnit);
    }
  }

  // 修改了摄入量数值和单位，都要重新计算用于显示的营养素信息(这里是重新获取修改后的营养素单位)
  _recalculateNutrients() {
    //  ？？？注意，如果这里没有匹配的，肯定是哪里出问题了
    // 从用户输入的单份食物单位，找到对应的营养素信息
    var metricServing = widget.foodItem.servingInfoList
        .where((e) => e.servingUnit == inputServingUnit)
        .first;

    setState(() {
      nutrientsInfo = metricServing;
    });
  }

  // 修改指定的饮食条目的摄入量、单份营养素单位、餐次信息
  _updateDailyFoodItem() async {
    var updatedMfi = widget.dfiwfs!.dailyFoodItem;
    updatedMfi.foodIntakeSize = inputServingValue;
    updatedMfi.servingInfoId = nutrientsInfo.servingInfoId!;
    updatedMfi.mealCategory = inputMealtimeValue.enLabel;
    updatedMfi.gmtModified = getCurrentDateTime();

    var rst = await _dietaryHelper.updateDailyFoodItem(updatedMfi);

    if (rst > 0) {
      if (!mounted) return;

      // 父组件应该重新加载(传参到父组件中重新加载)
      Navigator.pop(context, true);
    }
  }

  // 删除饮食日记条目不用管用户修改了什么，且一定是饮食日记主页传递而来确定有条目数据
  _removeDailyFoodItem() async {
    var mfiId = widget.dfiwfs!.dailyFoodItem.dailyFoodItemId!;
    var rst = await _dietaryHelper.deleteDailyFoodItem(mfiId);

    if (rst > 0) {
      if (!mounted) return;
      // 父组件应该重新加载
      Navigator.pop(context, true);
    }
  }

  /// 新增饮食日记条目详情
  /// 食物编号、日期 父组件有传；摄入量、食物单份营养素编号、餐次 用户有自行选择(否则就是默认食物第一个单份营养素和早餐)。
  _addDailyFoodItem() async {
    var temp = DailyFoodItem(
      // 主键数据库自增
      date: widget.logDate!,
      mealCategory: inputMealtimeValue.enLabel,
      foodId: widget.foodItem.food.foodId!,
      servingInfoId: nutrientsInfo.servingInfoId!,
      foodIntakeSize: inputServingValue,
      userId: CacheUser.userId,
      gmtCreate: getCurrentDateTime(),
    );

    var rst = await _dietaryHelper.insertDailyFoodItemList([temp]);

    if (rst.isNotEmpty) {
      if (!mounted) return;

      // 这个可以直接返回到上上的部件，但也没办法带参数
      Navigator.of(context)
        ..pop()
        ..pop(inputMealtimeValue.enLabel);

      // 使用 Navigator.pushReplacement() 方法来替换当前的 DietaryRecords 页面，使其状态更新为最新。
      // 但直接这样是重新加载了主页面条目，会重置为今天。即便有选择显示其他日期的话，依旧重置
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (_) => const DietaryRecords()),
      // );

      // 这个会返回到最初的页面(及打开app的第一级)
      // Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: '食物信息概述\n',
                style: TextStyle(fontSize: 18.sp),
              ),
              TextSpan(
                text:
                    "${widget.foodItem.food.product}(${widget.foodItem.food.brand})",
                style: TextStyle(fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(10.sp),
        child: ListView(
          children: [
            // 修改数量和单位
            buildInputFormArea(),
            SizedBox(height: 10.sp),
            // 饮食日记主界面点击知道item进来有“移除”和“修改”，点指定餐次新增进来则显示“新增”
            buildButtonsRowArea(),
            SizedBox(height: 10.sp),
            // 主要营养素表格
            buildNutrientTableArea(),
            // 详细营养素区域
            buildAllNutrientTableArea(),
            buildAllNutrientCardArea(),
          ],
        ),
      ),
    );
  }

  /// 传入的食物摄入量、单份单位、餐次信息表单区域
  buildInputFormArea() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          // 用封装的那个，验证器有问题
          FormBuilderTextField(
            name: 'serving_value',
            initialValue: cusDoubleTryToIntString(inputServingValue),
            decoration: const InputDecoration(labelText: '数量'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.numeric(errorText: '数量只能为数字'),
            ]),
            onChanged: (value) {
              if (_formKey.currentState?.validate() != true) {
                return;
              }
              setState(() {
                inputServingValue =
                    (value != "" && value != null) ? double.parse(value) : 1.0;
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
                      // 保存选择的单位
                      _formKey.currentState?.fields['serving_unit']?.save();
                      // 重新计算切换单位后的营养素数值
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
          // 切换餐次
          FormBuilderDropdown<CusLabel>(
            name: 'new_mealtime',
            decoration: const InputDecoration(
              labelText: '餐次',
            ),
            initialValue: inputMealtimeValue,
            items: mealtimeList
                .map((unit) => DropdownMenuItem(
                      alignment: AlignmentDirectional.center,
                      value: unit,
                      child: Text(unit.cnLabel),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                _formKey.currentState?.fields['new_mealtime']?.save();
                inputMealtimeValue = val!;
              });
            },
            valueTransformer: (val) => val?.toString(),
          ),
        ],
      ),
    );
  }

  /// 构建移除、修改、新增的功能按钮区域
  buildButtonsRowArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 有传条目信息，则是修改和删除
        if (widget.dfiwfs != null)
          Expanded(
            flex: 4,
            child: ElevatedButton(
              onPressed: _removeDailyFoodItem,
              child: const Text("移除"),
            ),
          ),
        // 两个按钮之间的占位空白
        if (widget.dfiwfs != null) const Expanded(flex: 1, child: SizedBox()),
        if (widget.dfiwfs != null)
          Expanded(
            flex: 4,
            child: ElevatedButton(
              onPressed: _updateDailyFoodItem,
              child: const Text("修改"),
            ),
          ),

        // 没有传条目信息，则是新增
        if (widget.dfiwfs == null)
          Expanded(
            child: ElevatedButton(
              onPressed: _addDailyFoodItem,
              child: const Text("添加"),
            ),
          ),
      ],
    );
  }

  /// 构建主要营养素表格区域
  buildNutrientTableArea() {
    return Column(
      children: [
        Text(
          "主要营养信息",
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
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
                    "${(inputServingValue * nutrientsInfo.energy / oneCalToKjRatio).toStringAsFixed(2)} 大卡",
                  ),
                  _genEssentialNutrientsTableCell(
                    "碳水化合物",
                    formatNutrientValue(
                      inputServingValue * nutrientsInfo.totalCarbohydrate,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: <Widget>[
                  _genEssentialNutrientsTableCell(
                    "脂肪",
                    formatNutrientValue(
                      inputServingValue * nutrientsInfo.totalFat,
                    ),
                  ),
                  _genEssentialNutrientsTableCell(
                    "蛋白质",
                    formatNutrientValue(
                      inputServingValue * nutrientsInfo.protein,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

  /// 全部营养素表格展示
  /// 这个表格比卡片样式更简洁
  buildAllNutrientTableArea() {
    return Column(
      children: [
        Text(
          "全部营养信息",
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        Table(
          border: TableBorder.all(), // 设置表格边框
          // 设置每列的宽度占比
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildTableRow(
              "食用量",
              '${cusDoubleTryToIntString(inputServingValue)} X $inputServingUnit',
            ),
            _buildTableRow(
              "卡路里",
              '${cusDoubleToString(inputServingValue * nutrientsInfo.energy / oneCalToKjRatio)} 大卡',
            ),
            _buildTableRow(
              "能量",
              '${cusDoubleToString(inputServingValue * nutrientsInfo.energy)} 千焦',
              labelAligh: TextAlign.right,
              fontColor: Colors.grey,
            ),
            _buildTableRow(
              "蛋白质",
              '${cusDoubleToString(inputServingValue * nutrientsInfo.protein)} 克',
            ),
            _buildTableRow(
              "脂肪",
              '${cusDoubleToString(inputServingValue * nutrientsInfo.totalFat)} 克',
            ),
            if (nutrientsInfo.transFat != null)
              _buildTableRow(
                "反式脂肪",
                '${cusDoubleToString(inputServingValue * nutrientsInfo.transFat!)} 克',
                labelAligh: TextAlign.right,
                fontColor: Colors.grey,
              ),
            if (nutrientsInfo.saturatedFat != null)
              _buildTableRow(
                "饱和脂肪",
                '${cusDoubleToString(inputServingValue * nutrientsInfo.saturatedFat!)} 克',
                labelAligh: TextAlign.right,
                fontColor: Colors.grey,
              ),
            if (nutrientsInfo.polyunsaturatedFat != null)
              _buildTableRow(
                "多不饱和脂肪",
                '${cusDoubleToString(inputServingValue * nutrientsInfo.polyunsaturatedFat!)} 克',
                labelAligh: TextAlign.right,
                fontColor: Colors.grey,
              ),
            if (nutrientsInfo.monounsaturatedFat != null)
              _buildTableRow(
                "单不饱和脂肪",
                '${cusDoubleToString(inputServingValue * nutrientsInfo.monounsaturatedFat!)} 克',
                labelAligh: TextAlign.right,
                fontColor: Colors.grey,
              ),
            _buildTableRow(
              "碳水化合物",
              '${cusDoubleToString(inputServingValue * nutrientsInfo.totalCarbohydrate)} 克',
            ),
            if (nutrientsInfo.sugar != null)
              _buildTableRow(
                "糖",
                '${cusDoubleToString(inputServingValue * nutrientsInfo.sugar!)} 克',
                labelAligh: TextAlign.right,
                fontColor: Colors.grey,
              ),
            if (nutrientsInfo.dietaryFiber != null)
              _buildTableRow(
                "纤维",
                '${cusDoubleToString(inputServingValue * nutrientsInfo.dietaryFiber!)} 克',
                labelAligh: TextAlign.right,
                fontColor: Colors.grey,
              ),
            _buildTableRow(
              "钠",
              '${cusDoubleToString(inputServingValue * nutrientsInfo.sodium)} 毫克',
            ),
            if (nutrientsInfo.cholesterol != null)
              _buildTableRow(
                "胆固醇",
                '${cusDoubleToString(inputServingValue * nutrientsInfo.cholesterol!)} 毫克',
              ),
            if (nutrientsInfo.potassium != null)
              _buildTableRow(
                "钾",
                '${cusDoubleToString(inputServingValue * nutrientsInfo.potassium!)} 毫克',
              ),
          ],
        ),
      ],
    );
  }

  // 构建表格行数据
  _buildTableRow(
    String label,
    String value, {
    TextAlign? labelAligh = TextAlign.left,
    Color? fontColor,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            label,
            style: TextStyle(fontSize: 16.sp, color: fontColor),
            textAlign: labelAligh,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            value,
            style: TextStyle(fontSize: 14.0.sp, color: fontColor),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// 构建全部营养素信息卡片区域
  /// 这个更复杂点
  buildAllNutrientCardArea() {
    return Column(
      children: [
        Text(
          "全部营养信息",
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        _genAllNutrientsCard(),
      ],
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
            '${inputServingValue.toStringAsFixed(2)} X $inputServingUnit',
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

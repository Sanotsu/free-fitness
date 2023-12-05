// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../common/global/constants.dart';
import '../../../../models/dietary_state.dart';
import '../../../common/utils/tools.dart';

// ？？？看能不能和日志中的food detail 拆一些复用部件来
/// 2023-12-04 和饮食记录模块的食物详情不太一样:
/// 本页面要修改食物基本信息、新增删除修改单份营养素信息，不关联餐次；
/// 后者显示的内容更少些，主要是选择餐次、单份营养素种类和添加食物摄入数量而已
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

/**
 * 新结构，上面是食物基本信息，下面是详情表格，右上角修改按钮，修改基本信息，可删除表格数据，点击表格进入单份营养素修改？？？
 */

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
          /// ？？？食物基本信息，带图
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
                    keyboardType: TextInputType.name,
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

          ///
          /// 展示所有单份的数据，不用实时根据摄入数量修改值
          ///
          /// ？？？这个table可以用高级点的，
          ///
          _buildSimpleFoodTable(fsInfo),
        ],
      ),
    );
  }

  /// 表格展示？？？
  ///
  _buildSimpleFoodTable(FoodAndServingInfo fsi) {
    var food = fsi.food;
    var servingList = fsi.servingInfoList;
    var foodName = "${food.product} (${food.brand})";

    return Card(
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: 1.sw,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0), // 设置所有圆角的大小
                // 设置展开前的背景色
                color: const Color.fromARGB(255, 195, 198, 201),
              ),
              child: Padding(
                padding: EdgeInsets.all(10.sp),
                child: RichText(
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '食物名称: ',
                        style: TextStyle(fontSize: 14.sp, color: Colors.black),
                      ),
                      TextSpan(
                        text: foodName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              // dataRowHeight: 10.sp,
              dataRowMinHeight: 60.sp, // 设置行高范围
              dataRowMaxHeight: 100.sp,
              headingRowHeight: 25, // 设置表头行高
              horizontalMargin: 10, // 设置水平边距
              columnSpacing: 20.sp, // 设置列间距
              columns: [
                DataColumn(
                  label: Text('单份', style: TextStyle(fontSize: 14.sp)),
                ),
                DataColumn(
                  label: Text('能量(大卡)', style: TextStyle(fontSize: 14.sp)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('蛋白质(克)', style: TextStyle(fontSize: 14.sp)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('脂肪(克)', style: TextStyle(fontSize: 14.sp)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('碳水(克)', style: TextStyle(fontSize: 14.sp)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('微量元素(毫克)', style: TextStyle(fontSize: 14.sp)),
                  numeric: true,
                ),
              ],
              rows: List<DataRow>.generate(servingList.length, (index) {
                var serving = servingList[index];

                return DataRow(
                  cells: [
                    _buildDataCell(serving.servingUnit),
                    _buildDataCell(
                        formatDoubleToString(serving.energy / oneCalToKjRatio)),
                    _buildDataCell(formatDoubleToString(serving.protein)),
                    _buildFatDataCell(
                      formatDoubleToString(serving.totalFat),
                      serving.transFat?.toStringAsFixed(2) ?? "",
                      serving.saturatedFat?.toStringAsFixed(2) ?? "",
                      serving.monounsaturatedFat?.toStringAsFixed(2) ?? "",
                      serving.polyunsaturatedFat?.toStringAsFixed(2) ?? "",
                    ),
                    _buildChoDataCell(
                      formatDoubleToString(serving.totalCarbohydrate),
                      serving.sugar?.toStringAsFixed(2) ?? "",
                      serving.dietaryFiber?.toStringAsFixed(2) ?? "",
                    ),
                    _buildMicroDataCell(
                      formatDoubleToString(serving.sodium),
                      serving.cholesterol?.toStringAsFixed(2) ?? "",
                      serving.potassium?.toStringAsFixed(2) ?? "",
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  _buildDataCell(String text) {
    return DataCell(
      Text(
        text,
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }

  _buildFatDataCell(
    String totalFat,
    String transFat,
    String saturatedFat,
    String muFat,
    String puFat,
  ) {
    return DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("总脂肪 ", style: TextStyle(fontSize: 14.sp)),
              Text(totalFat, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          _buildDetailRowCellText("反式脂肪 ", transFat),
          _buildDetailRowCellText("饱和脂肪 ", transFat),
          _buildDetailRowCellText("单不饱和脂肪 ", transFat),
          _buildDetailRowCellText("多不饱和脂肪 ", transFat),
        ],
      ),
    );
  }

  _buildChoDataCell(String totalCho, String sugar, String dietaryFiber) {
    return DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("总碳水 ", style: TextStyle(fontSize: 14.sp)),
              Text(totalCho, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          _buildDetailRowCellText("糖 ", sugar),
          _buildDetailRowCellText("膳食纤维 ", dietaryFiber),
        ],
      ),
    );
  }

  _buildMicroDataCell(
    String sodium,
    String potassium,
    String cholesterol,
  ) {
    return DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("钠 ", style: TextStyle(fontSize: 14.sp)),
              Text(sodium, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("钾 ", style: TextStyle(fontSize: 14.sp)),
              Text(potassium, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("胆固醇 ", style: TextStyle(fontSize: 14.sp)),
              Text(cholesterol, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
        ],
      ),
    );
  }

  _buildDetailRowCellText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]!),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]!),
        ),
      ],
    );
  }
}

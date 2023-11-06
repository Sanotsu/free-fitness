// ignore_for_file: avoid_print

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../common/global/constants.dart';
import '../../../../common/utils/sqlite_db_helper.dart';
import '../../../../models/dietary_state.dart';
import 'food_serving_info_modify_form.dart';

// 目前这个是食物新增时使用，新增时会同时至少新增一条单份食物营养素信息。
// 而食物某一单份营养素信息的修改可以在食物详情找到修改入口，但食物基本信息的修改入口还不明确
class FoodModify extends StatefulWidget {
  const FoodModify({super.key});

  @override
  State<FoodModify> createState() => _FoodModifyState();
}

class _FoodModifyState extends State<FoodModify> {
  TextEditingController foodNameController = TextEditingController();
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

//  食物添加的表单key
  final _foodFormKey = GlobalKey<FormBuilderState>();
  // 要添加的食物信息和单份营养素信息
  late Food inputFood;
  List<ServingInfo> inputServingInfos = [];

  // 当前选中的单份食物营养素类型
  late CusDropdownOption servingType;

  // 如果是有进入了营养素表单并且填了值返回，则保存该表单的值
  Map<String, dynamic>? tempServingFormData;
  // 上一个map的属性是数据库的栏位，还包含只为null的属性，这个是用于格式化展示的变量，更加可读
  var formattedTempServingFormData = "";

  void handleSave() async {
    String newFood = foodNameController.text;

    var res = await _addFoodDemo();

    print("res----------$res");

    if (!mounted) return;
    if (newFood.isNotEmpty) {
      Navigator.pop(context, newFood);
    }
  }

  _addFoodDemo() async {
    // _dietaryHelper.deleteDb();
    // return;
    // var dfood = Food(brand: "重庆", product: '豆豉鲮鱼');
    var dfood = Food(brand: "重庆", product: '豇豆');

    // 输入公制单位营养素
    var dserving2 = ServingInfo(
        energy: 13456,
        foodId: 1, // 这个id会在insert语句中被成功插入的food的id替代
        servingSize: 1,
        servingUnit: "堆",
        protein: 43.5,
        totalFat: 56.3,
        saturatedFat: 10,
        transFat: 11,
        polyunsaturatedFat: 12,
        monounsaturatedFat: 13,
        totalCarbohydrate: 76.6,
        sugar: 30.5,
        dietaryFiber: 34.65,
        sodium: 555,
        potassium: 113,
        cholesterol: 456);

    int ret = await _dietaryHelper.insertFoodWithServingInfoList(
      food: dfood,
      servingInfoList: [dserving2],
    );
    return ret;
  }

  _addFoodAndServingList() async {
    print("_foodFormKey---${_foodFormKey.currentState?.value}");

    var flag = _foodFormKey.currentState!.saveAndValidate();

    print("_foodFormKey flag ---$flag, $inputServingInfos");

    if (flag && inputServingInfos.isNotEmpty) {
      var temp = _foodFormKey.currentState?.value;
      var food = Food(
        brand: temp?["brand"],
        product: temp?["product"],
        tags: temp?["product"],
        category: temp?["product"],
        photos: temp?["images"] != null
            ? (temp?["images"] as List<PlatformFile>)
                .map((e) => e.path)
                .toList()
                .join(",")
            : "",
        contributor: "<登录用户>",
        gmtCreate: DateTime.now().toString(),
      );

      try {
        int ret = await _dietaryHelper.insertFoodWithServingInfoList(
          food: food,
          servingInfoList: inputServingInfos,
        );
        print("插入食物和营养素的结果 ---$ret");

        // ？？？是返回上一层，还是把当前食物信息带着跳到food detail去？
        if (ret > 0) {
          if (!mounted) return;

          // 父组件应该重新加载(传参到父组件中重新加载)
          Navigator.pop(context, {"isFoodAdded": true});
        }
      } catch (e) {
        // 或者显示一个SnackBar

        var errorMessage = "数据插入数据库失败,可能该产品已存在";

        if (e is DatabaseException) {
          // 这里可以直接去sqlite的结果代码 e.getResultCode()，
          // 具体代码含义参看文档： https://www.sqlite.org/rescode.html

          print("食物和营养素插入报错：$e");

          /// 它默认有判断是否是哪种错误，常见的唯一值重复还可以指定检查哪个栏位重复。

          if (e.isUniqueConstraintError()) {
            errorMessage = '该【食物品牌】+【产品名称】已存在！';
          }
        }

        // 在底部显示错误信息
        if (!mounted) return;
        showErrorMessage(context, errorMessage);
      }
    } else if (inputServingInfos.isEmpty) {
      if (!mounted) return;
      showErrorMessage(context, "无单份营养素信息");
    }
  }

  void showErrorMessage(BuildContext context, String errorMessage) {
    var snackBar = SnackBar(
      content: Text(errorMessage),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  _formatTempServingFormDate() {
// 在完成添加/修改单份营养素详情的表单之后，点击保存会把填入的营养素信息传回食物修改页面。
// 为了更加可视化这些用户填入的营养素，需要对其进行一些格式化之后显示文本

    if (tempServingFormData != null) {
      var filteredData = Map.fromEntries(tempServingFormData!.entries
          .where((entry) => entry.value != null)
          .map((entry) => entry));

      var tempList = [];

      filteredData.forEach((key, value) {
        // 找到该属性对应的中文
        var temp = nutrientList.where((e) => e.value == key).toList();

        if (temp.isNotEmpty) {
          tempList.add('${temp[0].name}:$value');
        }
      });

      setState(() {
        formattedTempServingFormData = tempList.join(", ");
      });

      print("formattedTempServingFormData---$formattedTempServingFormData");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food'),
      ),
      body: _buildFoodForm(),
      // Padding(
      //   padding: const EdgeInsets.all(16.0),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Text(
      //         'Food Name:',
      //         style: TextStyle(fontSize: 16.sp),
      //       ),
      //       TextField(
      //         controller: foodNameController,
      //       ),
      //       SizedBox(height: 16.sp),
      //       ElevatedButton(
      //         onPressed: _handleSave,
      //         child: const Text('Save'),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  // 将单份营养素的信息处理成对应的对象实例列表（旧的）
  List<ServingInfo> parseServingInfo2(
    Map<String, dynamic> servingInfo,
    String servingType,
  ) {
    final servingList = <ServingInfo>[];
    final servingSize = servingType == "metric" ? 100 : 1;

    ServingInfo createServingInfo(double servingMultiplier, String unit) {
      return ServingInfo(
        foodId: 1,
        servingSize: servingSize,
        servingUnit: unit,
        energy: _calculatePercentage(
          servingInfo["energy"],
          servingMultiplier,
        ),
        protein: _calculatePercentage(
          servingInfo["protein"],
          servingMultiplier,
        ),
        totalFat: _calculatePercentage(
          servingInfo["total_fat"],
          servingMultiplier,
        ),
        saturatedFat: servingInfo["saturated_fat"] != null
            ? _calculatePercentage(
                servingInfo["saturated_fat"], servingMultiplier)
            : null,
        transFat: servingInfo["trans_fat"] != null
            ? _calculatePercentage(
                servingInfo["trans_fat"],
                servingMultiplier,
              )
            : null,
        polyunsaturatedFat: servingInfo["polyunsaturated_fat"] != null
            ? _calculatePercentage(
                servingInfo["polyunsaturated_fat"],
                servingMultiplier,
              )
            : null,
        monounsaturatedFat: servingInfo["monounsaturated_fat"] != null
            ? _calculatePercentage(
                servingInfo["monounsaturated_fat"],
                servingMultiplier,
              )
            : null,
        totalCarbohydrate: _calculatePercentage(
          servingInfo["total_carbohydrate"],
          servingMultiplier,
        ),
        sugar: servingInfo["sugar"] != null
            ? _calculatePercentage(
                servingInfo["sugar"],
                servingMultiplier,
              )
            : null,
        dietaryFiber: servingInfo["dietary_fiber"] != null
            ? _calculatePercentage(
                servingInfo["dietary_fiber"],
                servingMultiplier,
              )
            : null,
        sodium: _calculatePercentage(
          servingInfo["sodium"],
          servingMultiplier,
        ),
        potassium: servingInfo["potassium"] != null
            ? _calculatePercentage(
                servingInfo["potassium"],
                servingMultiplier,
              )
            : null,
        cholesterol: servingInfo["cholesterol"] != null
            ? _calculatePercentage(
                servingInfo["cholesterol"],
                servingMultiplier,
              )
            : null,
      );
    }

    // 不管是标准度量还是自定义的，数值都要记录
    var inputUnit = servingInfo["serving_unit"] as String;
    servingList.add(createServingInfo(1.0, inputUnit));

    // 如果是标准的，还需要保留1ml/g的值
    if (servingType == "metric") {
      servingList.add(createServingInfo(0.01, inputUnit));
    } else if (servingType == "custom") {
      // 如果是自定义的单份，但有输入对应的标准度量值，也计算出对应1mg/g的值
      final temp = double.tryParse(servingInfo["metric_serving_size"] ?? "");
      if (temp != null) {
        var tempSize = double.parse((1 / temp).toStringAsFixed(2));

        servingList.add(
          createServingInfo(
            tempSize,
            servingInfo["metric_serving_unit"] as String,
          ),
        );
      }
    }

    return servingList;
  }

  double _calculatePercentage(dynamic value, double percentage) {
    return double.parse(
      (double.parse(value.toString()) * percentage).toStringAsFixed(2),
    );
  }

  List<ServingInfo> _parseServingInfo(
    Map<String, dynamic> servingInfo,
    String servingType,
  ) {
    // 把驼峰命名法的栏位转为全小写下划线连接  snake_case 方式表示
    String getPropName(String camelCaseName) {
      final pattern = RegExp(r'[A-Z]');
      return camelCaseName.splitMapJoin(pattern,
          onMatch: (m) => '_${m.group(0)?.toLowerCase()}');
    }

    // 创建单份营养素实例
    ServingInfo createServingInfo(double multiplier, int size, String unit) {
      // ServingInfo类的一些属性，【注意】：营养素新增的表单中的name是和数据库中一样的蛇式命名这里才能转
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
        foodId: 1, // 随意给个值，存入数据库时会修改
        servingSize: size,
        servingUnit: unit,
        energy: props['energy'] ?? 0.0,
        protein: props['protein'] ?? 0.0,
        totalFat: props['totalFat'] ?? 0.0,
        saturatedFat: props['saturatedFat'],
        transFat: props['transFat'],
        polyunsaturatedFat: props['polyunsaturatedFat'],
        monounsaturatedFat: props['monounsaturatedFat'],
        totalCarbohydrate: props['totalCarbohydrate'] ?? 0.0,
        sugar: props['sugar'],
        dietaryFiber: props['dietaryFiber'],
        sodium: props['sodium'] ?? 0.0,
        cholesterol: props['cholesterol'],
        potassium: props['potassium'],
        contributor: "<预设登录用户>",
        gmtCreate: DateTime.now().toString(),
      );
    }

    // 用于记录要返回的营养素列表
    final servingList = <ServingInfo>[];

    // 不管是标准度量还是自定义的，数值都要记录
    // final inputSize = servingType == 'metric' ? 100 : 1;
    // final inputUnit = servingType == servingInfo['serving_unit'] as String;

    // 这里输入值应该都是1,单位则是标准单份为100g或100ml，自定义则为1份
    const inputSize = 1;
    final originUnit = servingInfo['serving_unit'] as String;
    final inputUnit =
        servingType == 'metric' ? "100$originUnit" : "1$originUnit";
    servingList.add(createServingInfo(1.0, inputSize, inputUnit));

    // 如果是标准的，还需要保留1ml/g的值(标准度量为100ml/g，单个ml/g的营养素比例就是其0.01)
    if (servingType == 'metric') {
      servingList.add(createServingInfo(0.01, 1, "1$originUnit"));
    } else if (servingType == 'custom') {
      // 如果是自定义的单份，且有输入对应的标准度量值，也计算出对应1mg/g的值
      final temp = double.tryParse(servingInfo['metric_serving_size'] ?? '');
      if (temp != null) {
        final tempUnit = servingInfo['metric_serving_unit'] as String;
        final tempMultiplier = double.parse((1 / temp).toStringAsFixed(2));
        servingList.add(createServingInfo(tempMultiplier, 1, "1$tempUnit"));
      }
    }

    return servingList;
  }

  _buildFoodForm() {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(10.sp),
          child: SingleChildScrollView(
            child: FormBuilder(
                key: _foodFormKey,
                child: Column(
                  children: [
                    // 食物的品牌和产品名称(没有对应数据库，没法更人性化的筛选，都是用户输入)
                    FormBuilderTextField(
                      name: 'brand',
                      decoration: const InputDecoration(labelText: '*食物品牌'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '品牌不可为空'),
                      ]),
                    ),
                    FormBuilderTextField(
                      name: 'product',
                      decoration: const InputDecoration(labelText: '*产品名称'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '名称不可为空'),
                      ]),
                    ),
                    FormBuilderRadioGroup(
                      decoration: const InputDecoration(labelText: '营养成分'),
                      name: 'serving_info_type',
                      validator: FormBuilderValidators.required(),
                      // initialValue: servingTypeList[1].name,
                      options: servingTypeList
                          .map(
                            (servingType) => FormBuilderFieldOption(
                              value: servingType.name,
                              // 当点击被选中的单选框的文本时，弹出的营养素表单才带有之前返回的数据
                              // 单选框值变化后的弹窗，则是全新的表单
                              child: GestureDetector(
                                onTap: () {
                                  final currentValue = _foodFormKey.currentState
                                      ?.fields['serving_info_type']?.value;

                                  if (currentValue == servingType.name) {
                                    print(
                                        "之前传回的表单数据:---------$tempServingFormData");

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FoodServingInfoModifyForm(
                                          servingType: servingType,
                                          currentServingInfo:
                                              tempServingFormData,
                                        ),
                                      ),
                                    ).then((value) {
                                      print("从食物营养素表单返回------- $value");

                                      if (value != null) {
                                        print(
                                            "------- ${value["servingInfo"].toString()}");
                                        var servingList = _parseServingInfo(
                                          value["servingInfo"],
                                          servingType.value,
                                        );
                                        log("处理后的营养素信息xxxxxxxxxxx $servingList");

                                        setState(() {
                                          tempServingFormData =
                                              value["servingInfo"];
                                          inputServingInfos = servingList;
                                        });
                                        _formatTempServingFormDate();
                                      }
                                    });
                                    // showDialog(
                                    //   context: context,
                                    //   builder: (BuildContext context) {
                                    //     return AlertDialog(
                                    //       title: const Text('Dialog Title'),
                                    //       content: Text('${servingType.name}'),
                                    //       actions: [
                                    //         ElevatedButton(
                                    //           onPressed: () {
                                    //             Navigator.of(context).pop();
                                    //           },
                                    //           child: const Text('Close'),
                                    //         ),
                                    //       ],
                                    //     );
                                    //   },
                                    // );
                                  }
                                },
                                child: Text("${servingType.name}"),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        print("食物营养素分类 $value");

                        setState(() {
                          // 有切换单份类型之后，先要把存的之前的单份营养素信息清空
                          tempServingFormData = null;
                          inputServingInfos = [];
                          servingType = servingTypeList
                              .firstWhere((e) => e.name == value);
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodServingInfoModifyForm(
                              servingType: servingType,
                            ),
                          ),
                        ).then((value) {
                          print("从食物营养素表单返回------- $value");

                          if (value != null) {
                            print("------- ${value["servingInfo"].toString()}");

                            var servingList = _parseServingInfo(
                              value["servingInfo"],
                              servingType.value,
                            );
                            log("处理后的营养素信息xxxxxxxxxxx $servingList");

                            setState(() {
                              tempServingFormData = value["servingInfo"];
                              inputServingInfos = servingList;
                            });
                            _formatTempServingFormDate();
                          }

/*
                          // 获取营养素表单返回的数据 servingFormValue
                          var sfValue =
                              value["servingInfo"] as Map<String, dynamic>;

                          List<ServingInfo> sevingList = [];

                          if (servingType.value == "metric") {
                            var tempServing = ServingInfo(
                              foodId: 1, // 随意给个值，存入数据库时会修改
                              servingSize: 100,
                              servingUnit: sfValue["serving_unit"] as String,
                              energy: sfValue["energy"] as double,
                              protein: sfValue["protein"] as double,
                              totalFat: sfValue["totalFat"] as double,
                              saturatedFat: sfValue["saturated_fat"],
                              transFat: sfValue["trans_fat"] as double?,
                              polyunsaturatedFat:
                                  sfValue["polyunsaturated_fat"] as double?,
                              monounsaturatedFat:
                                  sfValue["monounsaturated_fat"] as double?,
                              totalCarbohydrate:
                                  sfValue["total_carbohydrate"] as double,
                              sugar: sfValue["sugar"] as double?,
                              dietaryFiber: sfValue["dietary_fiber"] as double?,
                              sodium: sfValue["sodium"] as double,
                              potassium: sfValue["potassium"] as double?,
                              cholesterol: sfValue["cholesterol"] as double?,
                            );

                            var tempSmallServing = ServingInfo(
                              foodId: 1, // 随意给个值，存入数据库时会修改
                              servingSize: 1,
                              servingUnit: sfValue["serving_unit"] as String,
                              energy: double.parse(
                                ((sfValue["energy"] as double) / 100)
                                    .toStringAsFixed(2),
                              ),
                              protein: double.parse(
                                ((sfValue["protein"] as double) / 100)
                                    .toStringAsFixed(2),
                              ),
                              totalFat: double.parse(
                                ((sfValue["total_fat"] as double) / 100)
                                    .toStringAsFixed(2),
                              ),
                              saturatedFat: double.parse(
                                ((sfValue["saturated_fat"] as double? ?? 0) /
                                        100)
                                    .toStringAsFixed(2),
                              ),
                              transFat: double.parse(
                                ((sfValue["trans_fat"] as double? ?? 0) / 100)
                                    .toStringAsFixed(2),
                              ),
                              polyunsaturatedFat: double.parse(
                                ((sfValue["polyunsaturated_fat"] as double? ??
                                            0) /
                                        100)
                                    .toStringAsFixed(2),
                              ),
                              monounsaturatedFat: double.parse(
                                ((sfValue["monounsaturated_fat"] as double? ??
                                            0) /
                                        100)
                                    .toStringAsFixed(2),
                              ),
                              totalCarbohydrate: double.parse(
                                ((sfValue["energy"] as double) / 100)
                                    .toStringAsFixed(2),
                              ),
                              sugar: double.parse(
                                ((sfValue["sugar"] as double? ?? 0) / 100)
                                    .toStringAsFixed(2),
                              ),
                              dietaryFiber: double.parse(
                                ((sfValue["dietary_fiber"] as double? ?? 0) /
                                        100)
                                    .toStringAsFixed(2),
                              ),
                              sodium: double.parse(
                                ((sfValue["sodium"] as double? ?? 0) / 100)
                                    .toStringAsFixed(2),
                              ),
                              potassium: double.parse(
                                ((sfValue["potassium"] as double? ?? 0) / 100)
                                    .toStringAsFixed(2),
                              ),
                              cholesterol: double.parse(
                                ((sfValue["cholesterol"] as double? ?? 0) / 100)
                                    .toStringAsFixed(2),
                              ),
                            );

                            sevingList.add(tempServing);
                            sevingList.add(tempSmallServing);
                          } else if (servingType.value == "custom") {
                            var tempServing = ServingInfo(
                              foodId: 1, // 随意给个值，存入数据库时会修改
                              servingSize: 1,
                              servingUnit: sfValue["serving_unit"] as String,
                              energy: sfValue["energy"] as double,
                              protein: sfValue["protein"] as double,
                              totalFat: sfValue["totalFat"] as double,
                              saturatedFat: sfValue["saturated_fat"],
                              transFat: sfValue["trans_fat"] as double?,
                              polyunsaturatedFat:
                                  sfValue["polyunsaturated_fat"] as double?,
                              monounsaturatedFat:
                                  sfValue["monounsaturated_fat"] as double?,
                              totalCarbohydrate:
                                  sfValue["total_carbohydrate"] as double,
                              sugar: sfValue["sugar"] as double?,
                              dietaryFiber: sfValue["dietary_fiber"] as double?,
                              sodium: sfValue["sodium"] as double,
                              potassium: sfValue["potassium"] as double?,
                              cholesterol: sfValue["cholesterol"] as double?,
                            );

                            sevingList.add(tempServing);

                            var tempMetricServingSize =
                                sfValue["metric_serving_size"] as double?;

                            if (tempMetricServingSize != null) {
                              var tempSmallServing = ServingInfo(
                                foodId: 1, // 随意给个值，存入数据库时会修改
                                servingSize: 1,
                                servingUnit: sfValue["serving_unit"] as String,
                                energy: double.parse(
                                  ((sfValue["energy"] as double) / 100)
                                      .toStringAsFixed(2),
                                ),
                                protein: double.parse(
                                  ((sfValue["protein"] as double) / 100)
                                      .toStringAsFixed(2),
                                ),
                                totalFat: double.parse(
                                  ((sfValue["total_fat"] as double) / 100)
                                      .toStringAsFixed(2),
                                ),
                                saturatedFat: double.parse(
                                  ((sfValue["saturated_fat"] as double? ?? 0) /
                                          100)
                                      .toStringAsFixed(2),
                                ),
                                transFat: double.parse(
                                  ((sfValue["trans_fat"] as double? ?? 0) / 100)
                                      .toStringAsFixed(2),
                                ),
                                polyunsaturatedFat: double.parse(
                                  ((sfValue["polyunsaturated_fat"] as double? ??
                                              0) /
                                          100)
                                      .toStringAsFixed(2),
                                ),
                                monounsaturatedFat: double.parse(
                                  ((sfValue["monounsaturated_fat"] as double? ??
                                              0) /
                                          100)
                                      .toStringAsFixed(2),
                                ),
                                totalCarbohydrate: double.parse(
                                  ((sfValue["energy"] as double) / 100)
                                      .toStringAsFixed(2),
                                ),
                                sugar: double.parse(
                                  ((sfValue["sugar"] as double? ?? 0) / 100)
                                      .toStringAsFixed(2),
                                ),
                                dietaryFiber: double.parse(
                                  ((sfValue["dietary_fiber"] as double? ?? 0) /
                                          100)
                                      .toStringAsFixed(2),
                                ),
                                sodium: double.parse(
                                  ((sfValue["sodium"] as double? ?? 0) / 100)
                                      .toStringAsFixed(2),
                                ),
                                potassium: double.parse(
                                  ((sfValue["potassium"] as double? ?? 0) / 100)
                                      .toStringAsFixed(2),
                                ),
                                cholesterol: double.parse(
                                  ((sfValue["cholesterol"] as double? ?? 0) /
                                          100)
                                      .toStringAsFixed(2),
                                ),
                              );
                              sevingList.add(tempSmallServing);
                            }
                          }


                          print("处理后的营养素信息xxxxxxxxxxx $sevingList");
                          */
                        });
                      },
                    ),
                    Text(
                      formattedTempServingFormData,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    FormBuilderTextField(
                      name: 'tags',
                      decoration: const InputDecoration(labelText: '标签'),
                    ),
                    FormBuilderTextField(
                      name: 'category',
                      decoration: const InputDecoration(labelText: '分类'),
                    ),
                    const SizedBox(height: 10),
                    // 上传活动示例图片（静态图或者gif）
                    FormBuilderFilePicker(
                      name: 'images',
                      decoration: const InputDecoration(labelText: '演示图片'),
                      maxFiles: null,
                      allowMultiple: true,
                      previewImages: true,
                      onChanged: (val) => debugPrint(val.toString()),
                      typeSelectors: const [
                        TypeSelector(
                          type: FileType.image,
                          selector: Row(
                            children: <Widget>[
                              Icon(Icons.file_upload),
                              Text('图片上传'),
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
                  ],
                )),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 20.sp, right: 20.sp, top: 20.sp),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {"isFoodModified": false});
                  },
                  child: const Text("返回"),
                ),
              ),
              // 两个按钮之间的占位空白
              const Expanded(flex: 1, child: SizedBox()),
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  onPressed: _addFoodAndServingList,
                  child: const Text("添加"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

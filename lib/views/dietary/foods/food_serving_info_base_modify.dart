// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/dietary_state.dart';

/// 这个是在食物详情中，修改了某个食物单份营养素信息而已，简单传入单份营养素信息，然后修改即可
class FoodServingInfoBaseModify extends StatefulWidget {
  // 新增时一定会传单份食物营养素的分类(度量的metric 或者自定义的custom)
  // ？？？因为修改时 db表没有这个栏位，所以暂时不提供修改，以新增+删除代替修改
  final CusLabel servingType;
  // 方便看食物名称
  final Food food;

  // 修改时可能会带上已有的单份营养素信息，新增时则没有
  final ServingInfo? currentServingInfo;

  const FoodServingInfoBaseModify({
    required this.servingType,
    this.currentServingInfo,
    super.key,
    required this.food,
  });

  @override
  State<FoodServingInfoBaseModify> createState() =>
      _FoodServingInfoBaseModifyState();
}

class _FoodServingInfoBaseModifyState extends State<FoodServingInfoBaseModify> {
  final _servingInfoformKey = GlobalKey<FormBuilderState>();
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  ServingInfo? serving;

  @override
  void initState() {
    super.initState();

    /// todo 2023-12-05 暂时不提供修改，以新增+删除代替修改；所以先不管这个初始化值的设定了
    if (widget.currentServingInfo != null) {
      serving = widget.currentServingInfo;
    }

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // 如果有传表单的初始对象值，就显示该值
    //   if (widget.currentServingInfo != null) {
    //     print("有传当前表单值过来--${widget.currentServingInfo}");
    //     setState(() {
    //       _servingInfoformKey.currentState
    //           ?.patchValue(widget.currentServingInfo!.toMap());
    //     });
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增单份营养素'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(10.sp),
            child: SingleChildScrollView(
              child: FormBuilder(
                key: _servingInfoformKey,
                child: Column(
                  children: [
                    if (widget.servingType.value == "metric")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Center(
                              child: Text("100"),
                            ),
                          ),
                          Flexible(
                            child: Center(
                              child: FormBuilderDropdown<String>(
                                name: 'serving_unit',
                                initialValue: "g",
                                items: ["ml", "g"]
                                    .map((unit) => DropdownMenuItem(
                                          alignment:
                                              AlignmentDirectional.center,
                                          value: unit,
                                          child: Text(unit),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    // 如果是自定义的单份食物营养素，需要输入单位，可输入等价标准数值
                    if (widget.servingType.value == "custom")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Center(
                              child: Text("1"),
                            ),
                          ),
                          Flexible(
                            child: cusFormBuilerTextField(
                              "serving_unit",
                              labelText: '*单位',
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                    errorText: '单位不可为空'),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    if (widget.servingType.value == "custom")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(flex: 1, child: SizedBox()),
                          const Flexible(flex: 2, child: Text("等价度量值及单位")),
                          Flexible(
                            flex: 1,
                            child: FormBuilderTextField(
                              name: 'metric_serving_size',
                              // 正则来只允许输入数字和小数点
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*$'),
                                )
                              ],
                              // 展示数字键盘
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: Center(
                              child: FormBuilderDropdown<String>(
                                name: 'metric_serving_unit',
                                initialValue: "g",
                                items: ["ml", "g"]
                                    .map((unit) => DropdownMenuItem(
                                          alignment:
                                              AlignmentDirectional.center,
                                          value: unit,
                                          child: Text(unit),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // 食物的品牌和产品名称(没有对应数据库，没法更人性化的筛选，都是用户输入)
                    FormBuilderTextField(
                      name: 'energy',
                      initialValue: serving?.energy.toString(),
                      decoration: const InputDecoration(
                        labelText: '*能量',
                        suffixText: '千焦',
                      ),
                      // 正则来只允许输入数字和小数点
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        )
                      ],
                      // 展示数字键盘
                      keyboardType: TextInputType.number,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '能量不可为空'),
                        FormBuilderValidators.numeric(errorText: '只能输入数字和小数')
                      ]),
                    ),
                    FormBuilderTextField(
                      name: 'protein',
                      decoration: const InputDecoration(
                        labelText: '*蛋白质',
                        suffixText: '克',
                      ),
                      // 正则来只允许输入数字和小数点
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        )
                      ],
                      // 展示数字键盘
                      keyboardType: TextInputType.number,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '蛋白质不可为空'),
                      ]),
                    ),
                    FormBuilderTextField(
                      name: 'total_fat',
                      decoration: const InputDecoration(
                        labelText: '*脂肪',
                        suffixText: '克',
                      ),
                      // 正则来只允许输入数字和小数点
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        )
                      ],
                      // 展示数字键盘
                      keyboardType: TextInputType.number,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '脂肪不可为空'),
                      ]),
                    ),
                    Row(
                      children: [
                        const Expanded(flex: 1, child: SizedBox()),
                        Expanded(
                          flex: 4,
                          child: FormBuilderTextField(
                            name: 'saturated_fat',
                            decoration: const InputDecoration(
                              labelText: '饱和脂肪',
                              suffixText: '克',
                            ),
                            // 正则来只允许输入数字和小数点
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              )
                            ],
                            // 展示数字键盘
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(flex: 1, child: SizedBox()),
                        Expanded(
                          flex: 4,
                          child: FormBuilderTextField(
                            name: 'trans_fat',
                            decoration: const InputDecoration(
                              labelText: '反式脂肪',
                              suffixText: '克',
                            ),
                            // 正则来只允许输入数字和小数点
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              )
                            ],
                            // 展示数字键盘
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(flex: 1, child: SizedBox()),
                        Expanded(
                          flex: 4,
                          child: FormBuilderTextField(
                            name: 'polyunsaturated_fat',
                            decoration: const InputDecoration(
                              labelText: '多不饱和脂肪',
                              suffixText: '克',
                            ),
                            // 正则来只允许输入数字和小数点
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              )
                            ],
                            // 展示数字键盘
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(flex: 1, child: SizedBox()),
                        Expanded(
                          flex: 4,
                          child: FormBuilderTextField(
                            name: 'monounsaturated_fat',
                            decoration: const InputDecoration(
                              labelText: '单不饱和脂肪',
                              suffixText: '克',
                            ),
                            // 正则来只允许输入数字和小数点
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              )
                            ],
                            // 展示数字键盘
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    FormBuilderTextField(
                      name: 'total_carbohydrate',
                      decoration: const InputDecoration(
                        labelText: '*总碳水化合物',
                        suffixText: '克',
                      ),
                      // 正则来只允许输入数字和小数点
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        )
                      ],
                      // 展示数字键盘
                      keyboardType: TextInputType.number,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '总碳水化合物不可为空'),
                      ]),
                    ),
                    Row(
                      children: [
                        const Expanded(flex: 1, child: SizedBox()),
                        Expanded(
                          flex: 4,
                          child: FormBuilderTextField(
                            name: 'sugar',
                            decoration: const InputDecoration(
                              labelText: '糖',
                              suffixText: '克',
                            ),
                            // 正则来只允许输入数字和小数点
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              )
                            ],
                            // 展示数字键盘
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(flex: 1, child: SizedBox()),
                        Expanded(
                          flex: 4,
                          child: FormBuilderTextField(
                            name: 'dietary_fiber',
                            decoration: const InputDecoration(
                              labelText: '膳食纤维',
                              suffixText: '克',
                            ),
                            // 正则来只允许输入数字和小数点
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$'),
                              )
                            ],
                            // 展示数字键盘
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    FormBuilderTextField(
                      name: 'sodium',
                      decoration: const InputDecoration(
                        labelText: '*钠',
                        suffixText: '毫克',
                      ),
                      // 正则来只允许输入数字和小数点
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        )
                      ],
                      // 展示数字键盘
                      keyboardType: TextInputType.number,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '钠不可为空'),
                      ]),
                    ),
                    FormBuilderTextField(
                      name: 'potassium',
                      decoration: const InputDecoration(
                        labelText: '钾',
                        suffixText: '毫克',
                      ),
                      // 正则来只允许输入数字和小数点
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        )
                      ],
                      // 展示数字键盘
                      keyboardType: TextInputType.number,
                    ),
                    FormBuilderTextField(
                      name: 'cholesterol',
                      decoration: const InputDecoration(
                        labelText: '胆固醇',
                        suffixText: '毫克',
                      ),
                      // 正则来只允许输入数字和小数点
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        )
                      ],
                      // 展示数字键盘
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("取消"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_servingInfoformKey.currentState!.saveAndValidate()) {
                      print(
                        "_servingInfoformKey.currentState ${_servingInfoformKey.currentState?.value.toString()}",
                      );

                      var servingList = _parseServingInfo(
                          _servingInfoformKey.currentState!.value,
                          widget.servingType.value,
                          foodId: widget.food.foodId);

                      print("servingList--------$servingList");

                      // ============这里新增单份营养素，要参考就得写法，在前面处理00000000000000
                      await _dietaryHelper.insertFoodWithServingInfoList(
                        servingInfoList: servingList,
                      );

                      if (!mounted) return;
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text("添加"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculatePercentage(dynamic value, double percentage) {
    return double.parse(
      (double.parse(value.toString()) * percentage).toStringAsFixed(2),
    );
  }

  List<ServingInfo> _parseServingInfo(
    Map<String, dynamic> servingInfo,
    String servingType, {
    // 如果有传食物，说明是给已有的食物添加新的单份营养素信息，则修改其对应食物编号
    int? foodId,
  }) {
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

        print("propName---$propName");

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

    print("食物新增时处理后的营养素信息servingList $servingList");

    return servingList;
  }
}

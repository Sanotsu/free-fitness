// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/dietary_state.dart';

class FoodServingInfoModifyForm extends StatefulWidget {
  // 一定会传单份食物营养素的分类(度量的metric 或者自定义的custom)
  final CusLabel servingType;

  // 可能会传指定营养素信息(修改的时候)
  final ServingInfo? servingInfo;

  // 新增食物添加了营养素确认之后返回到食物新增表单，但可以想要修改，又再点击来到营养素表单，会带上之前传上去的对象
  final Map<String, dynamic>? currentServingInfo;

  const FoodServingInfoModifyForm({
    required this.servingType,
    this.servingInfo,
    this.currentServingInfo,
    super.key,
  });

  @override
  State<FoodServingInfoModifyForm> createState() =>
      _FoodServingInfoModifyFormState();
}

class _FoodServingInfoModifyFormState extends State<FoodServingInfoModifyForm> {
  final _servingInfoformKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果有传表单的初始对象值，就显示该值
      if (widget.currentServingInfo != null) {
        print("有传当前表单值过来--${widget.currentServingInfo}");
        setState(() {
          _servingInfoformKey.currentState
              ?.patchValue(widget.currentServingInfo!);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Update Food Serving Info'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(10.sp),
            child: SingleChildScrollView(
              child: FormBuilder(
                key: _servingInfoformKey,
                initialValue: widget.currentServingInfo != null
                    ? widget.currentServingInfo!
                    : {},
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
            padding: EdgeInsets.only(left: 20.sp, right: 20.sp, top: 20.sp),
            child: ElevatedButton(
              onPressed: () {
                var flag = _servingInfoformKey.currentState!.saveAndValidate();
                debugPrint(_servingInfoformKey.currentState?.value.toString());
                if (flag) {
                  print(
                    "_servingInfoformKey.currentState ${_servingInfoformKey.currentState?.value.toString()}",
                  );

                  var temp = _servingInfoformKey.currentState?.value;
                  Navigator.pop(context, {"servingInfo": temp});
                }
              },
              child: const Text("添加"),
            ),
          ),
        ],
      ),
    );
  }
}

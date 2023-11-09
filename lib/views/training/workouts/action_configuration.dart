// ignore_for_file: unnecessary_brace_in_string_interps, avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:free_fitness/models/training_state.dart';
import 'package:free_fitness/views/training/workouts/action_list.dart';

import '../../../common/global/constants.dart';
import 'counter_widget.dart';

class ActionConfiguration extends StatefulWidget {
  // 进入action配置页面，一定要有基础动作的信息
  final Exercise item;
  // 进入配置页面的来源
  //    1 group list -> new group -> simple exercise list -> action config => new action list
  //    2 action list -> add new item -> simple exercise list -> action config => origin action list
  //    2 action list -> update old item  -> action config => origin action list
  final String source;

  // 如果是action list 进入action配置页面，应该带上已有的action，这样就能修改预设值，上面的来源就可以少一种
  final TrainingAction? actionItem;

  const ActionConfiguration({
    super.key,
    required this.item,
    required this.source,
    this.actionItem,
  });

  @override
  State<ActionConfiguration> createState() => _ActionConfigurationState();
}

class _ActionConfigurationState extends State<ActionConfiguration> {
  // final DBTrainHelper _dbHelper = DBTrainHelper();

  String placeholderImageUrl = 'assets/images/no_image.png';
  late Exercise _currentItem;

  // 默认动作配置最少20秒或者10次
  int _timeInSeconds = 20;
  int _count = 10;

  // 其他需要输入的例如器械重量、action名称、描述之类的
  final _formKey = GlobalKey<FormBuilderState>();

  // 把预设的基础活动选项列表转化为 FormBuilderDropdown 支持的列表
  _genItems(List<ExerciseDefaultOption> options) {
    return options
        .map((option) => DropdownMenuItem(
              alignment: AlignmentDirectional.centerStart,
              value: option.value,
              child: Text(option.label),
            ))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    print(
        "widget.source inActionConfiguration --${widget.source} ${_currentItem.countingMode} ");

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // 放在safearea不会遮住顶部的状态栏
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 固定显示图片区域的高度，其他内容自动往下滚就好
              SizedBox(
                height: 300.sp,
                child: Container(
                  // 预设的图片背景色一般是白色，所以这里也设置为白色，看起来一致
                  // color: Colors.white,
                  color: const Color.fromARGB(255, 239, 243, 244),
                  child: Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Center(
                        child: Image.file(
                          File(_currentItem.images?.split(",")[0] ?? ""),
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                            return Image.asset(
                              placeholderImageUrl,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop(); // 关闭弹窗
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// 预设的选项就两个，等于第一个的值就是计时，等于最后一个的值就是计次
              if (_currentItem.countingMode == countingOptions.first.value)
                CounterWidget(
                  isTimeMode: true,
                  initialCount: _timeInSeconds ~/ 10,
                  onCountChanged: (newCount) {
                    setState(() {
                      _timeInSeconds = newCount * 10;
                    });
                  },
                ),
              const SizedBox(height: 20),
              if (_currentItem.countingMode == countingOptions.last.value)
                CounterWidget(
                  initialCount: _count,
                  onCountChanged: (newCount) {
                    setState(() {
                      _count = newCount;
                    });
                  },
                ),
              const SizedBox(height: 20),

              /// ？？？器材重量区域
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.sp,
                        vertical: 10.sp,
                      ),
                      child: FormBuilderTextField(
                        name: 'action_name',
                        decoration: InputDecoration(
                          labelText: '*名称',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black, // 设置边框颜色
                              width: 1.0.sp, // 设置边框宽度
                            ),
                          ),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '名称不可为空'),
                        ]),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.sp,
                        vertical: 5.sp,
                      ),
                      child: FormBuilderTextField(
                        name: 'action_code',
                        decoration: InputDecoration(
                          labelText: '代号',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black, // 设置边框颜色
                              width: 1.0.sp, // 设置边框宽度
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 代号和名称
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.sp,
                        vertical: 5.sp,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: FormBuilderTextField(
                              name: 'equipment_weight',
                              decoration: InputDecoration(
                                labelText: '器械重量(kg)',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black, // 设置边框颜色
                                    width: 1.0.sp, // 设置边框宽度
                                  ),
                                ),
                              ),
                              // 限制只能输入数字和1位小数
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,1}$')),
                                FilteringTextInputFormatter.deny(
                                    RegExp(r'^[0]{2,}')),
                              ],
                              // 打开数字键盘
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          SizedBox(width: 10.sp),
                          Flexible(
                            child: FormBuilderDropdown<String>(
                              name: 'action_level',
                              decoration: InputDecoration(
                                labelText: '动作级别',
                                hintText: '选择动作级别',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black, // 设置边框颜色
                                    width: 1.0.sp, // 设置边框宽度
                                  ),
                                ),
                              ),
                              items: _genItems(levelOptions),
                              valueTransformer: (val) => val?.toString(),
                            ),
                          )
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.sp,
                        vertical: 5.sp,
                      ),
                      child: FormBuilderTextField(
                        name: 'description',
                        decoration: InputDecoration(
                          labelText: '动作说明',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black, // 设置边框颜色
                              width: 1.0.sp, // 设置边框宽度
                            ),
                          ),
                        ),
                        maxLines: 5,
                      ),
                    ),
                  ],
                ),
              ),

              /// ？？？手动填写 action_code、action_name、action_level、description 等栏位？

              const Center(
                child: Text(
                  'ActionConfiguration. 动作配置页面，显示exercise的大概信息，选择个数或持续时间，点保存，返回到action list页面.这里点击保存之后，应该返回该group的action list页面，不管是新增训练计划group还是修改等',
                ),
              ),
              SizedBox(
                height: 16.0.sp,
              ),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                },
                children: [
                  _buildTableRow(
                    "代号",
                    _currentItem.exerciseCode,
                  ),
                  _buildTableRow(
                    "名称",
                    _currentItem.exerciseName,
                  ),
                  _buildTableRow(
                    "发力方式",
                    _getOptionLabel(_currentItem.force, forceOptions),
                  ),
                  _buildTableRow(
                    "级别",
                    _getOptionLabel(_currentItem.level, levelOptions),
                  ),
                  _buildTableRow(
                    "计数方式",
                    _getOptionLabel(_currentItem.countingMode, countingOptions),
                  ),
                  _buildTableRow(
                    "基础活动类别",
                    _getOptionLabel(_currentItem.mechanic, mechanicOptions),
                  ),
                  _buildTableRow(
                    "所需器械",
                    _getOptionLabel(_currentItem.equipment, equipmentOptions),
                  ),
                  _buildTableRow(
                    "分类",
                    _getOptionLabel(_currentItem.category, categoryOptions),
                  ),
                  _buildTableRow(
                    "主要肌肉",
                    _genMuscleOptionLabel(_currentItem.primaryMuscles),
                  ),
                  _buildTableRow(
                    "次要肌肉",
                    _genMuscleOptionLabel(_currentItem.secondaryMuscles),
                  ),
                  _buildTableRow(
                    "是否用户上传",
                    "${_currentItem.isCustom}",
                  ),
                ],
              ),
              SizedBox(
                height: 16.0.sp,
              ),
              Padding(
                padding: EdgeInsets.all(16.0.sp),
                child: Text(
                  "基础活动要点",
                  style: TextStyle(fontSize: 24.0.sp),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0.sp),
                child: Text(
                  "${_currentItem.instructions}",
                  style: TextStyle(fontSize: 16.0.sp),
                ),
              ),
              SizedBox(
                height: 100.sp,
              )
            ],
          ),
        ),
      ),
      // 悬浮按钮,正式的时候是一个放在底部的普通保存按钮即可
      floatingActionButton: SizedBox(
        width: 300,
        child: FloatingActionButton.extended(
          // ？？？保存的逻辑等数据库设计修改之后、有db helper的函数了再说
          onPressed: () async {
            // 点击事件处理逻辑
            print('Time in seconds: $_timeInSeconds');
            print('Count: $_count');

            // !!!!!!!这里不保存到数据库，只是把选择的数据传递给新的action list表，
            // 在新的action list表再点击保存时同时新增group和action

            var flag3 = _formKey.currentState!.saveAndValidate();

            if (flag3) {
              var temp = _formKey.currentState?.value;

              print('temp?["equipment_weight"] --${temp?["equipment_weight"]}');

              var tempAction = TrainingAction(
                actionCode: temp?["action_code"],
                actionName: temp?["action_name"],
                exerciseId: _currentItem.exerciseId!,
                frequency: _count,
                duration: _timeInSeconds,
                equipmentWeight: double.parse(temp?["equipment_weight"]),
                actionLevel: temp?["action_level"],
                description: temp?["description"],
                contributor: "<登录用户>",
                gmtCreate: temp?["action_code"],
              );

// =========== 这里逻辑变了，不在action config插入数据库，新增训练计划时，也把action传到action list去，

// 在新增时，就无法区分是已有group新增action，还是没有group新增action---> 在action进入simple exercise list中带参数即可

              // 如果是新增训练计划： new group -> simple exercise list -> action config,source 为空字串或者null
              //    ->  使用 Navigator.pushReplacement 跳到新的action list，再新增action时进入simple exercise list，source也为空字串或者null
              // 如果是已有的训练计划新增动作： existing group -> action list -> simple exercise list -> action config, source 为group_id
              //    ->  使用..pop()..pop()返回，然后强制刷新？(不然就只能动态路由的代参命名路由了)
              // 如果是已有的训练计划修改动作： existing group -> action list -> action config, source 为 action_modify 字符串
              //    ->  使用.pop()返回，可以带返回参数父组件then进行刷新

              /// 全新训练计划一步步到这里
              if (widget.source == "") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActionList(
                      actionItem: tempAction,
                    ),
                  ),
                );
              } else if (widget.source == "action_modify") {
                // 剩下就是在action list中点击已存在的action进行修改，直接返回就好
                // 父组件应该重新加载(传参到父组件中重新加载)
                Navigator.pop(context, {"isActionModified": true});
              } else {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              }

              print(" _formKey.currentState--${_formKey.currentState?.value}");
            }
          },
          label: const Text('增加'),
          backgroundColor: Colors.green, // 按钮颜色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // 圆角大小
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // 处理保存按钮点击事件之后返回
      //     // 但这里的返回比较麻烦，
      //     // 因为workout(index)的主页点击新增进入simple exercise list，选中指定exercise再到这里；
      //     // 或者在action list 点击新增进入simple exercise list，选中指定exercise再到这里；
      //     // 还是在action list 点击指定action进行修改，直接进入这里；
      //     // 三者不相同，比较难统一处理，跨级别的带参数还不好在app出使用route配置
      //     //    前两者甚至都是返回action list主页，不过前者是db先新增成功之后才有数据（group和action list数据先都不存在），后者是已有现成数据
      //     // 这里根据不同传入的值，返回不同属性，，各自层的逻辑不关心这个属性，就在pop到上一层去，在各自上层组件中去判断吧。

      //     // 这是示例，返回上一层去

      //     Navigator.pop(context, "parent widget map?");
      //   },
      //   backgroundColor: Colors.green,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(20.0), // 圆角大小
      //   ),
      //   child: const Icon(Icons.save),
      // ),
      // 悬浮按钮位置
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // 根据数据库值从预设选项中显示对应标签
  _getOptionLabel(String? value, List<ExerciseDefaultOption> options) {
    if (value == null) {
      return "";
    }
    for (ExerciseDefaultOption option in options) {
      if (option.value == value) {
        return option.label;
      }
    }
    return "";
  }

  // 肌肉这个有多项，所以从预设选项中显示对应标签略有不同
  _genMuscleOptionLabel(String? muscleStr) {
    if (muscleStr == null) {
      return "";
    }
    List<String> selectedValues = muscleStr.split(',');
    List<String> selectedLabels = [];

    for (String selectedValue in selectedValues) {
      String selectedLabel = _getOptionLabel(selectedValue, musclesOptions);
      if (selectedLabel.isNotEmpty) {
        selectedLabels.add(selectedLabel);
      }
    }

    return selectedLabels.join(", ");
  }

  _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.0.sp),
          child: Text(label),
        ),
        Padding(
          padding: EdgeInsets.only(right: 16.0.sp),
          child: Text(
            value,
            style: TextStyle(fontSize: 16.0.sp),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

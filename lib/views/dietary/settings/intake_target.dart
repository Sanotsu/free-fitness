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
import 'week_intake_bar_chart.dart';

class IntakeTargetPage extends StatefulWidget {
  final DietaryUser userInfo;
  const IntakeTargetPage({super.key, required this.userInfo});

  @override
  State<IntakeTargetPage> createState() => _IntakeTargetPageState();
}

class _IntakeTargetPageState extends State<IntakeTargetPage> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
  late DietaryUser user;

  // 是否在修改整体卡路里和宏量素
  bool _isEditing = false;
  // 整体卡路里宏量素表单全局key，用于验证表单
  final _macrosFormKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic> initialMacrosMap = {};
  // 能量卡里里等效千焦数
  String equivalentKJdata = '';

  // 是否在修改每日卡路里和宏量素
  bool _isWeekdayEditing = false;
  // 每日卡路里宏量素表单全局key，用于验证表单
  final _weekMacrosFormKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic> initialWeekMacrosMap = {};
  String weekKJdata = '';

  // 默认选择今天是周几(1-7)
  int selectedDay = DateTime.now().weekday;

  // 默认的每日营养素目标的结构是这样的，但初始化可能不必如此（男女还应该不一样）
  Map<int, CusMacro> intakeData = {
    1: CusMacro(calory: 2250, carbs: 120, fat: 25, protein: 60),
    2: CusMacro(calory: 2250, carbs: 120, fat: 25, protein: 60),
    3: CusMacro(calory: 2250, carbs: 120, fat: 25, protein: 60),
    4: CusMacro(calory: 2250, carbs: 120, fat: 25, protein: 60),
    5: CusMacro(calory: 2250, carbs: 120, fat: 25, protein: 60),
    6: CusMacro(calory: 2250, carbs: 120, fat: 25, protein: 60),
    7: CusMacro(calory: 2250, carbs: 120, fat: 25, protein: 60),
  };

// ----------------------

  // 模拟数据
  final List<double> calorieData = [2000, 1800, 2200, 2500, 1900, 2300, 2100];
  final List<double> fatData = [50, 45, 55, 60, 48, 58, 52];
  final List<double> proteinData = [80, 75, 85, 90, 78, 88, 82];
  final List<double> carbData = [150, 140, 160, 170, 145, 165, 155];

  @override
  void initState() {
    super.initState();

    // 初始化整体卡路里和营养素目标
    user = widget.userInfo;
    setState(() {
      // 给整体营养素目标设置初始值
      // (注意key要和表单中name一致。因为是两个不同的表单，所以和每日营养素目标表单同名了也不影响)
      initialMacrosMap = {
        "calory": (user.rdaGoal ?? 0).toString(),
        "carbs": (user.choGoal ?? 0).toString(),
        "fat": (user.fatGoal ?? 0).toString(),
        "protein": (user.proteinGoal ?? 0).toString(),
      };

      equivalentKJdata = caloryToKjStr(user.rdaGoal ?? 0);
      _macrosFormKey.currentState?.patchValue(initialMacrosMap);
    });

    // 格式化处理每日卡路里和营养素目标
    formatDailyIntakeMap();
  }

  // 格式化已经存在的每日卡路里和营养素目标
  formatDailyIntakeMap() async {
    var temp = await _dietaryHelper.queryDietaryUserWithIntakeGoal();

    // 如果没有每周设定的值，就使用总体平均值；如果后者都没有，则是显示推荐值(中国居民膳食指南18岁~。)
    // ？？？具体细节再考虑
    Map<int, CusMacro> tempIntakes = {};

    // 构建周一到周日的营养素目标，如果不存在，则使用基础预设值
    for (int i = 1; i <= 7; i++) {
      // 如果没有每周几的预设值或者某个值不存在则使用基础预设值
      if (temp.goals.isEmpty ||
          temp.goals.every((goal) => int.parse(goal.dayOfWeek) != i)) {
        tempIntakes[i] = CusMacro(
          calory: temp.user.rdaGoal ?? 2250,
          carbs: temp.user.choGoal ?? 120,
          fat: temp.user.fatGoal ?? 25,
          protein: temp.user.proteinGoal ?? 60,
        );
      }
    }

    // 有设置的则直接使用（注意，dayOfWeek 存入的也就是1-7的字符串，后续可以改为统一的int型）
    for (var goal in temp.goals) {
      tempIntakes[int.parse(goal.dayOfWeek)] = CusMacro(
        calory: goal.rdaDailyGoal,
        carbs: goal.choDailyGoal,
        fat: goal.fatDailyGoal,
        protein: goal.proteinDailyGoal,
      );
    }

    setState(() {
      intakeData = tempIntakes;
    });

    refreshWeekMacrosData();
  }

  // 当每日营养素目标切换了星期几的时候，要更新显示的表单为新的日期的数据
  refreshWeekMacrosData() {
    setState(() {
      // 给每日营养素目标设置初始值
      initialWeekMacrosMap = {
        "calory": intakeData[selectedDay]?.calory.toString(),
        "carbs": intakeData[selectedDay]?.carbs.toString(),
        "fat": intakeData[selectedDay]?.fat.toString(),
        "protein": intakeData[selectedDay]?.protein.toString(),
      };

      print("initialWeekMacrosMap-------$initialWeekMacrosMap");

      weekKJdata = caloryToKjStr(intakeData[selectedDay]?.calory ?? 0);
      _weekMacrosFormKey.currentState?.patchValue(initialWeekMacrosMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('摄入目标'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // 修改整理卡路里和宏量素
            buildEditMacrosCard(),
            // 定制一周7天的卡路里和宏量素
            buildEditWeekMacrosCard(),
            // 一周7天的摄入宏量素目标条状图
            buildWeekMacrosBarChartCard(),
            // 底部稍微一点空隙来显示卡片阴影
            SizedBox(height: 20.sp),
          ],
        ),
      ),
    );
  }

  buildWeekMacrosBarChartCard() {
    return Card(
      elevation: 10,
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "每日宏量素目标图示",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w400,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 16.sp, height: 16.sp, color: Colors.grey),
                SizedBox(width: 8.sp),
                const Text("碳水"),
                SizedBox(width: 8.sp),
                Container(width: 16.sp, height: 16.sp, color: Colors.red),
                SizedBox(width: 8.sp),
                const Text("脂肪"),
                SizedBox(width: 8.sp),
                Container(width: 16.sp, height: 16.sp, color: Colors.green),
                SizedBox(width: 8.sp),
                const Text("蛋白质")
              ],
            ),
            SizedBox(height: 10.sp),
            WeekIntakeBarChart(intakeData: intakeData),
          ],
        ),
      ),
    );
  }

  /// 构建修改整体宏量素目标的卡片
  buildEditMacrosCard() {
    return Card(
      elevation: 10,
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "整体宏量素目标",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.green,
                    ),
                  ),
                ),
                // 如果是编辑状态，可以点取消
                if (_isEditing)
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () async {
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                      child: const Text('取消'),
                    ),
                  ),
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () async {
                      // 先保存到数据库，然后再显示非修改画面

                      if (_isEditing) {
                        print("现在是修改后点击了保存");
                        if (_macrosFormKey.currentState!.saveAndValidate()) {
                          setState(() {
                            user.rdaGoal = int.parse(_macrosFormKey
                                .currentState!.fields['calory']!.value);
                            equivalentKJdata = caloryToKjStr(user.rdaGoal!);
                            user.choGoal = double.parse(_macrosFormKey
                                .currentState!.fields['carbs']!.value);
                            user.fatGoal = double.parse(_macrosFormKey
                                .currentState!.fields['fat']!.value);
                            user.proteinGoal = double.parse(_macrosFormKey
                                .currentState!.fields['protein']!.value);
                          });
                          await _dietaryHelper.updateDietaryUser(user);
                          
                          // 平均营养素目标修改后，也更新下方图表的值
                          setState(() {
                            formatDailyIntakeMap();
                          });
                        }
                      }
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    child: Text(_isEditing ? '保存' : '修改'),
                  ),
                ),
              ],
            ),
            Divider(height: 5.sp, thickness: 3),
            SingleChildScrollView(
              child: FormBuilder(
                key: _macrosFormKey,
                initialValue: initialMacrosMap,
                // 使用FormBuilderTextField来替代原始的TextFormField
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormTextField(_isEditing, 'calory', '卡路里', '大卡'),
                    // 显示大卡对应千焦数据(靠右显示)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          equivalentKJdata,
                          style: TextStyle(fontSize: 14.sp),
                        )
                      ],
                    ),
                    _buildFormTextField(_isEditing, 'carbs', '碳水', '克'),
                    _buildFormTextField(_isEditing, 'fat', '脂肪', '克'),
                    _buildFormTextField(_isEditing, 'protein', '蛋白质', '克'),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 绘制统一的表单输入框
  Widget _buildFormTextField(
    bool editFlag,
    String name,
    String labelText,
    String suffixText,
  ) {
    return FormBuilderTextField(
      name: name,
      // 非编辑状态只读
      readOnly: !editFlag,
      decoration: InputDecoration(
        labelText: labelText,
        suffixText: suffixText,
        // 只读的时候移除下划线，编辑时显示下划线
        border: !editFlag
            ? InputBorder.none
            : const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
      ),
      // 必须输入且只能是数字
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(),
        FormBuilderValidators.numeric(),
      ]),
      // 输入时默认为数字键盘
      keyboardType: TextInputType.number,
      // 限制键盘输入只能是数字和小数
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d+\.?\d{0,2}'),
        ),
      ],
    );
  }

  /// 构建修改每日卡路里和宏量素目标的卡片
  buildEditWeekMacrosCard() {
    return Card(
      elevation: 10,
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "每日宏量素目标",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w400,
                color: Colors.green,
              ),
            ),
            // 上方是横向列表，用于切换周一到周日
            _buildWeekTab(),
            Divider(height: 5.sp, thickness: 3),
            // 下方根据选择的周几显示对应当日的主要营养素信息和修改按钮
            _buildWeekTabView(),
          ],
        ),
      ),
    );
  }

  // 上方的星期切换tab
  _buildWeekTab() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        bool isSelected = selectedDay == index + 1;

        return Flexible(
          child: TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (isSelected) {
                  return Colors.blue; // 设置选中时的背景色
                }
                return null; // 默认情况下不设置背景色
              }),
            ),
            // 切换星期时也更新表单数据
            onPressed: () {
              setState(() {
                selectedDay = index + 1;
              });
              refreshWeekMacrosData();
            },
            child: Text(
              weekdayStringMap[index + 1]?.cnLabel ?? '',
              style: TextStyle(fontSize: 14.sp, color: Colors.black),
            ),
          ),
        );
      }),
    );
  }

  // 下方的每日营养素详情
  _buildWeekTabView() {
    return SingleChildScrollView(
      child: FormBuilder(
        key: _weekMacrosFormKey,
        initialValue: initialWeekMacrosMap,
        // 使用FormBuilderTextField来替代原始的TextFormField
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(weekdayStringMap[selectedDay]?.cnLabel ?? ''),
                ),
                // 如果是编辑状态，可以点取消
                if (_isWeekdayEditing)
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () async {
                        setState(() {
                          _isWeekdayEditing = !_isWeekdayEditing;
                        });
                      },
                      child: const Text('取消'),
                    ),
                  ),
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: _updateWeekMacroData,
                    child: Text(_isWeekdayEditing ? '保存' : '修改'),
                  ),
                ),
              ],
            ),
            _buildFormTextField(_isWeekdayEditing, 'calory', '卡路里', '大卡'),
            // 显示大卡对应千焦数据(靠右显示)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Text(weekKJdata, style: TextStyle(fontSize: 14.sp))],
            ),
            _buildFormTextField(_isWeekdayEditing, 'carbs', '碳水', '克'),
            _buildFormTextField(_isWeekdayEditing, 'fat', '脂肪', '克'),
            _buildFormTextField(_isWeekdayEditing, 'protein', '蛋白质', '克'),
          ],
        ),
      ),
    );
  }

  // 点击保存修改数据
  _updateWeekMacroData() async {
    // 先保存到数据库，然后再显示非修改画面
    if (_isWeekdayEditing) {
      print("现在是修改后点击了保存");
      if (_weekMacrosFormKey.currentState!.saveAndValidate()) {
        CusMacro newData = CusMacro(
          calory: int.parse(
              _weekMacrosFormKey.currentState!.fields['calory']!.value),
          carbs: double.parse(
              _weekMacrosFormKey.currentState!.fields['carbs']!.value),
          fat: double.parse(
              _weekMacrosFormKey.currentState!.fields['fat']!.value),
          protein: double.parse(
              _weekMacrosFormKey.currentState!.fields['protein']!.value),
        );
        var temp = IntakeDailyGoal(
          userId: user.userId!,
          dayOfWeek: selectedDay.toString(),
          rdaDailyGoal: newData.calory,
          proteinDailyGoal: newData.protein,
          fatDailyGoal: newData.fat,
          choDailyGoal: newData.carbs,
        );

        await _dietaryHelper.updateUserIntakeDailyGoal([temp]);
        // 修改了数据库，也修改对应显示内容
        setState(() {
          intakeData[selectedDay] = newData;
        });
      }
    }
    // 不管是不是编辑中，点击了按钮都要切换状态
    setState(() {
      _isWeekdayEditing = !_isWeekdayEditing;
    });
  }
}

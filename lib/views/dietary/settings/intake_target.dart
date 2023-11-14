// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/sqlite_db_helper.dart';
import '../../../models/dietary_state.dart';

class IntakeTargetPage extends StatefulWidget {
  final DietaryUser userInfo;
  const IntakeTargetPage({super.key, required this.userInfo});

  @override
  State<IntakeTargetPage> createState() => _IntakeTargetPageState();
}

class _IntakeTargetPageState extends State<IntakeTargetPage> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  // 是否在修改整体宏量素
  bool _isEditing = false;
  // 是否在修改整体卡路里
  bool _isRdaEditing = false;

  // 整体营养素和卡路里的文本框控制器
  final _rdaController = TextEditingController();
  final _choController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  late DietaryUser user;

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

  @override
  void dispose() {
    _rdaController.dispose();
    _choController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // 初始化整体卡路里和营养素目标
    user = widget.userInfo;
    setState(() {
      _rdaController.text = (user.rdaGoal ?? 0).toString();
      _choController.text = (user.choGoal ?? 0).toString();
      _proteinController.text = (user.proteinGoal ?? 0).toString();
      _fatController.text = (user.fatGoal ?? 0).toString();
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

    print("带有每日摄入目标的用户信息: $temp");
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
            // 修改卡路里
            buildEditCaloryCard(),
            // 修改宏量素
            buildEditMacrosCard(),
            // 定制一周7天的卡路里和宏量素
            buildEditWeekMacrosCard(),
          ],
        ),
      ),
    );
  }

  /// 构建修改整体卡路里目标的卡片
  buildEditCaloryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "整体卡路里目标",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.green,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () async {
                      // 先保存到数据库，然后再显示非修改画面

                      if (_isRdaEditing) {
                        print("现在是修改后点击了保存");
                        setState(() {
                          user.rdaGoal = int.tryParse(_rdaController.text) ?? 0;
                        });
                        await _dietaryHelper.updateDietaryUser(user);
                      }
                      setState(() {
                        _isRdaEditing = !_isRdaEditing;
                      });

                      print("修改后的rda数据${_rdaController.text}");
                    },
                    child: Text(_isRdaEditing ? '保存' : '修改'),
                  ),
                )
              ],
            ),
            Divider(height: 2.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.sp),
              child: buildRow(
                'RDA',
                _isRdaEditing
                    ? _buildTextField(_rdaController)
                    : Text(
                        "${_rdaController.text} 大卡",
                        style: TextStyle(
                          fontSize: 24.sp,
                        ),
                      ),
              ),
            ),
            Divider(height: 2.sp),
            Text(
              "这里是rda的相关简单说明",
              textAlign: TextAlign.left,
              maxLines: 4,
              style: TextStyle(fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建修改整体宏量素目标的卡片
  buildEditMacrosCard() {
    return Card(
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
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () async {
                      // 先保存到数据库，然后再显示非修改画面

                      if (_isEditing) {
                        print("现在是修改后点击了保存");
                        setState(() {
                          user.fatGoal =
                              double.tryParse(_fatController.text) ?? 0;
                          user.proteinGoal =
                              double.tryParse(_proteinController.text) ?? 0;
                          user.choGoal =
                              double.tryParse(_choController.text) ?? 0;
                        });
                        await _dietaryHelper.updateDietaryUser(user);
                      }
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    child: Text(_isEditing ? '保存' : '修改'),
                  ),
                )
              ],
            ),
            Divider(height: 2.sp),
            _genListView(),
          ],
        ),
      ),
    );
  }

  _genListView() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        buildRow(
          '碳水',
          _isEditing
              ? _buildTextField(_choController)
              : Text(
                  "${_choController.text} 克",
                  style: TextStyle(
                    fontSize: 24.sp,
                  ),
                ),
        ),
        buildRow(
          '脂肪',
          _isEditing
              ? _buildTextField(_fatController)
              : Text(
                  "${_fatController.text} 克",
                  style: TextStyle(
                    fontSize: 24.sp,
                  ),
                ),
        ),
        buildRow(
          '蛋白质',
          _isEditing
              ? _buildTextField(_proteinController)
              : Text(
                  "${_proteinController.text} 克",
                  style: TextStyle(
                    fontSize: 24.sp,
                  ),
                ),
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }

  Widget buildRow(String labelText, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(labelText, style: TextStyle(fontSize: 24.sp)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        print("validator中的value $value");

        if (value!.isEmpty || value == "") {
          return '请输入有效数值';
        }
        if (double.tryParse(value) == null) {
          return '请输入正确的营养素数值(整数或小数)';
        }

        return null;
      },
    );
  }

  /// 构建修改每日卡路里和宏量素目标的卡片
  buildEditWeekMacrosCard() {
    return Card(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                bool isSelected = selectedDay == index + 1;

                return Flexible(
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.resolveWith((states) {
                        if (isSelected) {
                          return Colors.blue; // 设置选中时的背景色
                        }
                        return null; // 默认情况下不设置背景色
                      }),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedDay = index + 1;
                      });
                    },
                    child: Text(
                      _getDayString(index + 1),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
            // 下方卡片根据选择的周几显示对应当日的主要营养素信息和修改按钮
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(_getDayString(selectedDay)),
                    trailing: TextButton(
                      onPressed: () {
                        // 弹出对话框进行修改
                        _modifyIntakeData(context, selectedDay);
                      },
                      child: const Text('修改'),
                    ),
                  ),
                  ListTile(
                    title: Text('卡路里: ${intakeData[selectedDay]?.calory} 大卡'),
                  ),
                  ListTile(
                    title: Text('碳水: ${intakeData[selectedDay]?.carbs} 克'),
                  ),
                  ListTile(
                    title: Text('脂肪: ${intakeData[selectedDay]?.fat} 克'),
                  ),
                  ListTile(
                    title: Text('蛋白质: ${intakeData[selectedDay]?.protein} 克'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 通过数字获取显示的文字（如果把摄入目标对象的key改为文字，可能就不需要这个了）
  String _getDayString(int day) {
    // 根据星期几的数字返回对应的字符串
    // 这里可以根据实际情况自行实现
    switch (day) {
      case 1:
        // return 'Mon';
        return '周一';
      case 2:
        // return 'Tue';
        return '周二';
      case 3:
        // return 'Wed';
        return '周三';
      case 4:
        // return 'Thu';
        return '周四';
      case 5:
        // return 'Fri';
        return '周五';
      case 6:
        // return 'Sat';
        return '周六';
      case 7:
        // return 'Sun';
        return '周日';
      default:
        return '';
    }
  }

  // 弹窗修改指定星期几的主要营养素
  Future<void> _modifyIntakeData(BuildContext context, int day) async {
    // 通过FormBuilderKey来创建一个全局key用于验证表单
    final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

    CusMacro? newData = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('修改 ${_getDayString(selectedDay)} 营养素目标'),
          content: SingleChildScrollView(
            child: FormBuilder(
              key: formKey,
              // 使用FormBuilderTextField来替代原始的TextFormField
              child: Column(
                children: [
                  FormBuilderTextField(
                    name: 'calory',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '卡路里',
                      suffixText: "大卡",
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                    ]),
                  ),
                  FormBuilderTextField(
                    name: 'carbs',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '碳水',
                      suffixText: "克",
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                    ]),
                  ),
                  FormBuilderTextField(
                    name: 'fat',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '脂肪',
                      suffixText: "克",
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                    ]),
                  ),
                  FormBuilderTextField(
                    name: 'protein',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '蛋白质',
                      suffixText: "克",
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                if (formKey.currentState!.saveAndValidate()) {
                  CusMacro newData = CusMacro(
                    calory: int.parse(
                        formKey.currentState!.fields['calory']!.value),
                    carbs: double.parse(
                        formKey.currentState!.fields['carbs']!.value),
                    fat: double.parse(
                        formKey.currentState!.fields['fat']!.value),
                    protein: double.parse(
                        formKey.currentState!.fields['protein']!.value),
                  );
                  Navigator.of(context).pop(newData);
                }
              },
            ),
          ],
        );
      },
    );

    print("修改弹窗返回的数据newData222 $newData");
    // 这里更新显示的内容，上面弹窗保存时存入数据库

    // 如果弹窗返回的是null，则说明放弃了修改，则不必更新数据
    if (newData != null) {
      updateIntakeData(day, newData);
    }
  }

  // 修改弹窗修改的每日卡路里和营养素值到数据库
  void updateIntakeData(int day, CusMacro newData) async {
    var temp = IntakeDailyGoal(
      userId: user.userId!,
      dayOfWeek: day.toString(),
      rdaDailyGoal: newData.calory,
      proteinDailyGoal: newData.protein,
      fatDailyGoal: newData.fat,
      choDailyGoal: newData.carbs,
    );

    // ？？？这里也没有处理出错的情况
    await _dietaryHelper.updateUserIntakeDailyGoal([temp]);
    // 修改了数据库，也修改对应显示内容
    setState(() {
      intakeData[day] = newData;
    });
  }
}

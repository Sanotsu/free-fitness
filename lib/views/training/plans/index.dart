// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/sqlite_db_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/training_state.dart';
import 'group_list.dart';

class TrainingPlans extends StatefulWidget {
  const TrainingPlans({super.key});

  @override
  State<TrainingPlans> createState() => _TrainingPlansState();
}

class _TrainingPlansState extends State<TrainingPlans> {
  final DBTrainHelper _dbHelper = DBTrainHelper();

  // 展示计划列表(训练列表一次性查询所有，应该不会太多)
  List<PlanWithGroups> planList = [];

  // 可以筛选训练，条件用个map来存，初始化一个空map
  Map<String, dynamic> conditionMap = {};

  bool isLoading = false;

  final _planFormKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();

    print("conditionMap.isEmpty---${conditionMap.isEmpty}");
    // _dbHelper.deleteDb();
    // return;

    setState(() {});
    getPlanList();
  }

  demoInsertPlan() async {
    var demoPlanItem = TrainingPlan(
      planId: 1,
      planName: '测试计划',
      planCode: "Lost Weight",
      planCategory: '减肥',
      planLevel: "beginner",
      planPeriod: 30,
      description: "好好减肥",
      contributor: "<登入用户>",
      gmtCreate: DateTime.now().toString(),
    );

    var demoPlanItem2 = TrainingPlan(
      planId: 2,
      planName: '计划2',
      planCode: "muscle",
      planCategory: '健体',
      planLevel: "beginner",
      planPeriod: 30,
      description: "大肌霸",
      contributor: "<登入用户>",
      gmtCreate: DateTime.now().toString(),
    );

    await _dbHelper.insertTrainingPlan(demoPlanItem);
    await _dbHelper.insertTrainingPlan(demoPlanItem2);
  }

  // 把预设的基础活动选项列表转化为 FormBuilderDropdown 支持的列表
  // ？？？这个函数到处都在用，要么改改常量列表，要么改改这个函数复用
  _genItems(List<ExerciseDefaultOption> options) {
    return options
        .map((option) => DropdownMenuItem(
              alignment: AlignmentDirectional.centerStart,
              value: option.value,
              child: Text(option.label),
            ))
        .toList();
  }

  // 查询已有的训练
  getPlanList() async {
    // _dbHelper.deleteDb();
    // return;

    // demoInsertPlan();
    // return;

    // 如果已经在查询数据中，则忽略此次新的查询
    if (isLoading) return;

    // 如果没在查询中，设置状态为查询中
    setState(() {
      isLoading = true;
    });

    // 等待查询结果
    List<PlanWithGroups> temp;
    if (conditionMap.isEmpty) {
      temp = await _dbHelper.searchPlanWithGroups();
    } else {
      // TODO 处理条件，使用条件查询
      temp = await _dbHelper.searchPlanWithGroups();
    }

    print("getPlanList---$temp");

    // 设置查询结果
    setState(() {
      // ？？？因为没有分页查询，所有这里直接替换已有的数组
      planList = temp;
      // 重置状态为查询完成
      isLoading = false;
      print("groupList---$planList");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrainingPlans'),
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Column(
              children: [
                const Center(
                  child: Text(
                    'TrainingWorkouts index，这里是已存在的训练计划列表（不多的话一次性展示所有，多的话还是分页。现在先直接展示所有）',
                  ),
                ),
                Card(
                  elevation: 10,
                  child: SizedBox(
                    height: 50.sp,
                    child: const Center(
                      child: Text(
                        '这里预留【计划】的条件查询位置，名称关键字、难度、级别 ',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: planList.length,
                    itemBuilder: (context, index) {
                      final planItem = planList[index];

                      return Card(
                        elevation: 5.sp,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: Icon(Icons.alarm_on, size: 36.sp),
                              title: Text(
                                planItem.plan.planName,
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                  "${planItem.plan.planCategory}-${planItem.plan.planLevel}-${planItem.groupDetailList.length}",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w500,
                                  )),
                              trailing: const Icon(Icons.more_vert),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupList(
                                      planItem: planItem.plan,
                                    ),
                                  ),
                                ).then((value) {
                                  print("GroupList list 返回的数据 $value");
                                  // ？？？暂时返回这个页面时都重新加载最新的训练列表数据

                                  setState(() {
                                    getPlanList();
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      // 悬浮按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 点击新增，简单弹窗用户输入训练计划名称

          // _dbHelper.deleteDb();
          // return;

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('新建计划'),
                content: FormBuilder(
                  key: _planFormKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        FormBuilderTextField(
                          name: 'plan_name',
                          decoration: const InputDecoration(labelText: '名称'),
                          validator: FormBuilderValidators.required(),
                        ),
                        FormBuilderTextField(
                          name: 'plan_code',
                          decoration: const InputDecoration(labelText: '代号'),
                          validator: FormBuilderValidators.required(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: FormBuilderDropdown<String>(
                                name: 'plan_category',
                                decoration: const InputDecoration(
                                  labelText: '*计划分类',
                                  hintText: '选择分类',
                                ),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText: '分类不可为空')
                                ]),
                                items: _genItems(levelOptions),
                                valueTransformer: (val) => val?.toString(),
                              ),
                            ),
                            Flexible(
                              child: FormBuilderDropdown<String>(
                                name: 'plan_level',
                                decoration: const InputDecoration(
                                  labelText: '*难度',
                                  hintText: '选择难度',
                                ),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                      errorText: '难度不可为空')
                                ]),
                                items: _genItems(categoryOptions),
                                valueTransformer: (val) => val?.toString(),
                              ),
                            ),
                          ],
                        ),
                        FormBuilderTextField(
                          name: 'plan_period',
                          decoration: const InputDecoration(labelText: '训练周期'),
                          validator: FormBuilderValidators.required(),
                        ),
                        FormBuilderTextField(
                          name: 'description',
                          decoration: const InputDecoration(labelText: '概述'),
                          validator: FormBuilderValidators.required(),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('取消'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  ElevatedButton(
                    child: const Text('确认'),
                    onPressed: () async {
                      if (_planFormKey.currentState!.saveAndValidate()) {
                        // 获取表单数值
                        Map<String, dynamic> formData =
                            _planFormKey.currentState!.value;
                        // 处理数据提交逻辑
                        print(formData);

                        // 对周期进行类型转换
                        var planPeriod = int.parse(formData['plan_period']);
                        // 再放回去
                        // 深拷贝表单数据的Map，修改拷贝后的(原始的那个好像是不可修改的，会报错)
                        var copiedFormData =
                            Map<String, dynamic>.from(formData);
                        copiedFormData["plan_period"] = planPeriod;

                        var temp = TrainingPlan.fromMap(copiedFormData);

                        // ？？？这里应该验证是否新增成功
                        var planId = await _dbHelper.insertTrainingPlan(temp);
                        temp.planId = planId;

                        if (!mounted) return;
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupList(
                              planItem: temp,
                            ),
                          ),
                        ).then((value) {
                          print("新增计划，push到group list然后 返回的数据 $value");
                          // ？？？暂时返回这个页面时都重新加载最新的计划列表数据

                          setState(() {
                            getPlanList();
                          });
                        });
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      // 悬浮按钮位置
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

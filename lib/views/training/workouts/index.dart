// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/sqlite_db_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/training_state.dart';
import 'action_list.dart';
import 'modify_workouts_form.dart';

class TrainingWorkouts extends StatefulWidget {
  // 2023-11-15 这个页面复用，直接看【训练】模块不会传东西，
  // 但在【计划】模块，指定计划的训练列表中新增时，则传一个标志过来。
  // 当检测到这个标志时，点击指定行数据后就把这行数据返回到计划的新增页面去。
  // 不是指定计划的新增，则使用正常逻辑。
  final bool? isPlanAdd;
  const TrainingWorkouts({super.key, this.isPlanAdd});

  @override
  State<TrainingWorkouts> createState() => _TrainingWorkoutsState();
}

class _TrainingWorkoutsState extends State<TrainingWorkouts> {
  /// 这里是workout index，肯定就是group list页面
  /// 点击某一个group，进入action list 页面
  ///

  final DBTrainHelper _dbHelper = DBTrainHelper();

  // 展示训练列表(训练列表一次性查询所有，应该不会太多)
  List<GroupWithActions> groupList = [];

  // 可以筛选训练，条件用个map来存，初始化一个空map
  Map<String, dynamic> conditionMap = {};

  bool isLoading = false;

  late TrainingGroup demoGroupItem;

  final GlobalKey<FormBuilderState> _groupFormKey =
      GlobalKey<FormBuilderState>();

  bool isPlanAddGroup = false;

  @override
  void initState() {
    super.initState();

    print("conditionMap.isEmpty---${conditionMap.isEmpty}");
    // _dbHelper.deleteDb();
    // return;

    setState(() {
      getGroupList();
      // 如果没有传这个标志，则不是计划新增训练调过来的；如果有传，取其bool值
      isPlanAddGroup = (widget.isPlanAdd == null) ? false : widget.isPlanAdd!;

      demoGroupItem = TrainingGroup(
        groupId: 1,
        groupName: '测试动作组',
        groupCategory: '减肥',
        groupLevel: "beginner",
        restInterval: 15,
        consumption: 300,
        timeSpent: 180,
        description: "好好减肥",
        contributor: "<登入用户>",
        gmtCreate: DateTime.now().toString(),
      );
    });
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
  getGroupList() async {
    // 如果已经在查询数据中，则忽略此次新的查询
    if (isLoading) return;

    // 如果没在查询中，设置状态为查询中
    setState(() {
      isLoading = true;
    });

    // 等待查询结果
    List<GroupWithActions> temp;
    if (conditionMap.isEmpty) {
      temp = await _dbHelper.searchGroupWithActions();
    } else {
      // TODO 处理条件，使用条件查询
      temp = await _dbHelper.searchGroupWithActions();
    }

    print("getGroupList---$temp");

    // 设置查询结果
    setState(() {
      // ？？？因为没有分页查询，所有这里直接替换已有的数组
      groupList = temp;
      // 重置状态为查询完成
      isLoading = false;
      print("groupList---$groupList");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 打开键盘不重置按钮布局
      appBar: AppBar(
        title: const Text('TrainingWorkouts(即DB中的Group)'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle: TextStyle(fontSize: 16.sp),
            ),
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext ctx) {
                    return const ModifyWorkoutsForm();
                  },
                ),
              );
            },
            child: const Text('新增'),
          )
        ],
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
                        '这里预留训练的条件查询位置，名称关键字、难度、级别 ',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: groupList.length,
                    itemBuilder: (context, index) {
                      final groupItem = groupList[index];

                      return Card(
                        elevation: 5.sp,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              leading: Icon(Icons.alarm_on, size: 36.sp),
                              title: Text(
                                groupItem.group.groupName,
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                  "${groupItem.group.groupCategory}-${groupItem.group.groupLevel}-${groupItem.actionDetailList.length}",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w500,
                                  )),
                              trailing: const Icon(Icons.more_vert),
                              onTap: () {
                                // 如果是计划新增训练跳转过来的，点击条目直接带值返回
                                // (类型要一致，是GroupWithActions就好)
                                if (isPlanAddGroup) {
                                  Navigator.pop(context, groupItem);
                                } else {
                                  //  不传 GroupWithActions 类数据给 action list是因为：
                                  // 1 新增训练时，还没有group；2 而且进入action list页面后，还是会不时修改其实。
                                  // 所以还是直接传TrainingGroup，主要给子组件group id即可
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ActionList(
                                        groupItem: groupItem.group,
                                      ),
                                    ),
                                  ).then((value) {
                                    print("action list 返回的数据 $value");
                                    // ？？？暂时返回这个页面时都重新加载最新的训练列表数据

                                    setState(() {
                                      getGroupList();
                                    });
                                  });
                                }
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
      floatingActionButton: !isPlanAddGroup
          ? FloatingActionButton(
              onPressed: () {
                // 点击新增，简单弹窗用户输入训练计划名称

                // _dbHelper.deleteDb();
                // return;

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('新建训练计划'),
                      content: FormBuilder(
                        key: _groupFormKey,
                        autovalidateMode: AutovalidateMode.always,
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              FormBuilderTextField(
                                name: 'group_name',
                                decoration:
                                    const InputDecoration(labelText: '名称'),
                                validator: FormBuilderValidators.required(),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Flexible(
                                    child: FormBuilderDropdown<String>(
                                      name: 'group_category',
                                      decoration: const InputDecoration(
                                        labelText: '*分类',
                                        hintText: '选择分类',
                                      ),
                                      validator: FormBuilderValidators.compose([
                                        FormBuilderValidators.required(
                                            errorText: '分类不可为空')
                                      ]),
                                      items: _genItems(levelOptions),
                                      valueTransformer: (val) =>
                                          val?.toString(),
                                    ),
                                  ),
                                  Flexible(
                                    child: FormBuilderDropdown<String>(
                                      name: 'group_level',
                                      decoration: const InputDecoration(
                                        labelText: '*难度',
                                        hintText: '选择难度',
                                      ),
                                      validator: FormBuilderValidators.compose([
                                        FormBuilderValidators.required(
                                            errorText: '难度不可为空')
                                      ]),
                                      items: _genItems(categoryOptions),
                                      valueTransformer: (val) =>
                                          val?.toString(),
                                    ),
                                  )
                                ],
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
                            if (_groupFormKey.currentState!.saveAndValidate()) {
                              // 获取表单数值
                              Map<String, dynamic> formData =
                                  _groupFormKey.currentState!.value;
                              // 处理数据提交逻辑
                              print(formData);

                              var temp = TrainingGroup.fromMap(formData);

                              // ？？？这里应该验证是否新增成功
                              var groupId =
                                  await _dbHelper.insertTrainingGroup(temp);
                              temp.groupId = groupId;

                              if (!mounted) return;
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActionList(
                                    groupItem: temp,
                                  ),
                                ),
                              ).then((value) {
                                print("新增训练，push到 action list然后 返回的数据 $value");
                                // 总是刷新
                                setState(() {
                                  getGroupList();
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
            )
          : null,
      // 悬浮按钮位置
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

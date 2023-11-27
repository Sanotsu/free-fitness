// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/training_state.dart';
import 'action_list.dart';

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
  final DBTrainingHelper _dbHelper = DBTrainingHelper();
  // 查询表单的key
  final _queryFormKey = GlobalKey<FormBuilderState>();
  // 新增表单的key
  final _groupFormKey = GlobalKey<FormBuilderState>();

  // 展示训练列表(训练列表一次性查询所有，应该不会太多)
  List<GroupWithActions> groupList = [];

  // 可以筛选训练，条件用个map来存，初始化一个空map
  Map<String, dynamic> conditionMap = {};

  bool isLoading = false;

  bool isPlanAddGroup = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      getGroupList();
      // 如果没有传这个标志，则不是计划新增训练调过来的；如果有传，取其bool值
      isPlanAddGroup = (widget.isPlanAdd == null) ? false : widget.isPlanAdd!;
    });
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
      // 处理条件，使用条件查询
      temp = await _dbHelper.searchGroupWithActions(
        groupName: conditionMap["group_name"],
        groupCategory: conditionMap["group_category"],
        groupLevel: conditionMap["group_level"],
      );
    }

    print("getGroupList---$temp");

    if (!mounted) return;
    // 设置查询结果
    setState(() {
      // 因为没有分页查询，所有这里直接替换已有的数组
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
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '训练组    ', style: TextStyle(fontSize: 20.sp)),
              TextSpan(
                text: "共 ${groupList.length} 个",
                style: TextStyle(fontSize: 12.sp),
              ),
            ],
          ),
        ),

        // 2023-11-23 如果是计划新增训练跳转来的,则不允许修改已有的训练或者新增训练，还是严格各自模块去完成各自的内容。
        // 如果说需要计划新增训练时可以再新增训练或者修改指定训练，则不做下面这个限制
        actions: isPlanAddGroup
            ? null
            : [
                /// 新增训练组基本信息
                IconButton(
                  icon: Icon(Icons.add, size: 30.sp),
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: _modifyGroupInfo,
                ),
              ],
      ),
      body: Column(
        children: [
          /// 查询条件区域
          _buildQueryArea(),
          isLoading ? buildLoader(isLoading) : Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // 条件查询区域
  _buildQueryArea() {
    return FormBuilder(
      key: _queryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Card(
            elevation: 5.sp,
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "名称",
                    style: TextStyle(fontSize: 14.sp, color: Colors.black),
                  ),
                  Flexible(
                    child: cusFormBuilerTextField(
                      "group_name",
                      hintText: "输入名称",
                      hintStyle: TextStyle(fontSize: 14.sp),
                      valueFontSize: 14.sp,
                    ),
                  ),
                  SizedBox(
                    width: 40.sp,
                    height: 36,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _queryFormKey.currentState?.reset();
                          conditionMap = {};
                          getGroupList();
                        });
                        // 如果有键盘就收起键盘
                        FocusScope.of(context).focusedChild?.unfocus();
                      },
                      child: Text(
                        "重置",
                        style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "分类",
                    style: TextStyle(fontSize: 14.sp, color: Colors.black),
                  ),
                  Flexible(
                    child: cusFormBuilerDropdown(
                      "group_category",
                      groupCategoryOptions,
                      hintText: "选择分类",
                      hintStyle: TextStyle(fontSize: 14.sp),
                      optionFontSize: 14,
                    ),
                  ),
                  Text(
                    "难度",
                    style: TextStyle(fontSize: 14.sp, color: Colors.black),
                  ),
                  Flexible(
                    child: cusFormBuilerDropdown(
                      "group_level",
                      levelOptions,
                      hintText: "选择难度",
                      hintStyle: TextStyle(fontSize: 14.sp),
                      optionFontSize: 14,
                    ),
                  ),

                  // SizedBox(
                  //   width: 30.sp,
                  //   child: IconButton(
                  //     icon: const Icon(Icons.refresh, color: Colors.blue),
                  //     onPressed: () {
                  //       setState(() {
                  //         _queryFormKey.currentState?.reset();
                  //         conditionMap = {};
                  //         getGroupList();
                  //       });
                  //     },
                  //   ),
                  // )
                ],
              ),
              dense: true,
              trailing: Container(
                width: 24.sp,
                alignment: Alignment.center,
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.blue),
                  onPressed: () {
                    if (_queryFormKey.currentState!.saveAndValidate()) {
                      setState(() {
                        conditionMap = _queryFormKey.currentState!.value;
                        getGroupList();
                      });
                    }
                    // 如果有键盘就收起键盘
                    FocusScope.of(context).focusedChild?.unfocus();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 数据列表区域
  _buildList() {
    return ListView.builder(
      itemCount: groupList.length,
      itemBuilder: (context, index) {
        final groupItem = groupList[index];

        return Card(
          elevation: 5.sp,
          child: ListTile(
            leading: Icon(Icons.alarm_on, size: 36.sp),
            title: Text(
              groupItem.group.groupName,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              "${groupItem.group.groupCategory}-${groupItem.group.groupLevel}-${groupItem.actionDetailList.length}",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            // 2023-11-23 如果是计划新增训练跳转来的,则不允许修改已有的训练或者新增训练，还是严格各自模块去完成各自的内容。
            // 如果说需要计划新增训练时可以再新增训练或者修改指定训练，则不做下面这个限制
            trailing: isPlanAddGroup
                ? null
                : SizedBox(
                    width: 30.sp,
                    child: IconButton(
                      icon: Icon(Icons.edit, size: 20.sp, color: Colors.blue),
                      onPressed: () {
                        print("indexindexindex=$index ${groupItem.group}");
                        _modifyGroupInfo(groupItem: groupItem.group);
                      },
                    ),
                  ),
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
        );
      },
    );
  }

  // 弹窗新增训练组信息
  _modifyGroupInfo({TrainingGroup? groupItem}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("${groupItem != null ? '修改' : '新建'}训练"),
          content: FormBuilder(
            key: _groupFormKey,
            initialValue: groupItem != null ? groupItem.toMap() : {},
            // autovalidateMode: AutovalidateMode.always,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  cusFormBuilerTextField(
                    "group_name",
                    labelText: '*名称',
                    hintText: "输入名称",
                    hintStyle: TextStyle(fontSize: 14.sp),
                    validator: FormBuilderValidators.compose(
                        [FormBuilderValidators.required(errorText: '名称不可为空')]),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "group_category",
                          groupCategoryOptions,
                          labelText: '*分类',
                          hintText: "选择分类",
                          hintStyle: TextStyle(fontSize: 14.sp),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: '难度不可为空')
                          ]),
                        ),
                      ),
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "group_level",
                          levelOptions,
                          labelText: '*难度',
                          hintText: "选择难度",
                          hintStyle: TextStyle(fontSize: 14.sp),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: '难度不可为空')
                          ]),
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
                  var temp = TrainingGroup.fromMap(formData);

                  // 如果是新增
                  if (groupItem == null) {
                    // ？？？这里应该验证是否新增成功
                    var groupId = await _dbHelper.insertTrainingGroup(temp);
                    temp.groupId = groupId;

                    if (!mounted) return;
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActionList(groupItem: temp),
                      ),
                    ).then((value) {
                      setState(() {
                        getGroupList();
                      });
                    });
                  } else {
                    // 如果是修改
                    // ？？？这里应该验证是否修成功
                    temp.groupId = groupItem.groupId!;
                    await _dbHelper.updateTrainingGroup(
                      groupItem.groupId!,
                      temp,
                    );

                    // 如果是修改就返回训练组列表，而不是进入动作列表
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    setState(() {
                      getGroupList();
                    });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

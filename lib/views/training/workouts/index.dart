// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
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

    print(DateTime.now());
    var a = DateTime.now().microsecondsSinceEpoch;

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

    if (!mounted) return;
    // 设置查询结果
    setState(() {
      // 因为没有分页查询，所有这里直接替换已有的数组
      groupList = temp;
      // 重置状态为查询完成
      isLoading = false;

      var b = DateTime.now().microsecondsSinceEpoch;
      print(DateTime.now());
      print('训练查询耗时，微秒: ${b - a}');
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
              TextSpan(
                text: CusAL.of(context).workouts,
                style: TextStyle(fontSize: CusFontSizes.pageTitle),
              ),
              TextSpan(
                text: "\n${CusAL.of(context).itemCount(groupList.length)}",
                style: TextStyle(fontSize: CusFontSizes.pageAppendix),
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
                  icon: const Icon(Icons.add),
                  onPressed: _modifyGroupInfo,
                ),
              ],
      ),
      body: Column(
        children: [
          /// 查询条件区域
          FormBuilder(
            key: _queryFormKey,
            child: Card(
              elevation: 5.sp,
              child: Column(
                children: [_buildQueryAreaRow(), SizedBox(height: 10.sp)],
              ),
            ),
          ),
          isLoading ? buildLoader(isLoading) : Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // 条件查询区域
  _buildQueryAreaRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: cusFormBuilerTextField(
                      "group_name",
                      labelText: CusAL.of(context).workoutQuerys('0'),
                    ),
                  ),
                  SizedBox(
                    width: 50.sp,
                    height: 36.sp,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _queryFormKey.currentState?.reset();
                          // 2023-12-12 不知道为什么，reset对下拉选中的没有效，所以手动清除
                          _queryFormKey.currentState?.fields['group_category']
                              ?.didChange(null);
                          _queryFormKey.currentState?.fields['group_level']
                              ?.didChange(null);
                          conditionMap = {};
                          getGroupList();
                        });
                        // 如果有键盘就收起键盘
                        FocusScope.of(context).focusedChild?.unfocus();
                      },
                      child: Text(
                        CusAL.of(context).resetLabel,
                        style: TextStyle(
                          fontSize: CusFontSizes.pageAppendix,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: cusFormBuilerDropdown(
                      "group_category",
                      categoryOptions,
                      labelText: CusAL.of(context).workoutQuerys('1'),
                    ),
                  ),
                  Expanded(
                    child: cusFormBuilerDropdown(
                      "group_level",
                      levelOptions,
                      labelText: CusAL.of(context).workoutQuerys('2'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 50.sp,
          alignment: Alignment.center,
          child: IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
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
        )
      ],
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
            leading: Icon(Icons.alarm_on, size: CusIconSizes.iconLarge),
            title: Text(
              groupItem.group.groupName,
              style: TextStyle(
                fontSize: CusFontSizes.itemTitle,
                color: Theme.of(context).primaryColor,
              ),
            ),
            subtitle: RichText(
              textAlign: TextAlign.left,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${groupItem.actionDetailList.length} ${CusAL.of(context).exercise}',
                    // 这里只是取text的默认颜色，避免浅主题时文字不显示(好像默认是白色，反正看不到)
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  TextSpan(
                    text:
                        '  ${getCusLabelText(groupItem.group.groupLevel, levelOptions)}  ',
                    style: TextStyle(color: Colors.green[500]),
                  ),
                  TextSpan(
                    text:
                        '${getCusLabelText(groupItem.group.groupCategory, categoryOptions)}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),

            // 2023-11-23 如果是计划新增训练跳转来的,则不允许修改已有的训练或者新增训练，还是严格各自模块去完成各自的内容。
            // 如果说需要计划新增训练时可以再新增训练或者修改指定训练，则不做下面这个限制
            trailing: isPlanAddGroup
                ? null
                : SizedBox(
                    width: 30.sp,
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: CusIconSizes.iconNormal,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
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
                  // ？？？暂时返回这个页面时都重新加载最新的训练列表数据
                  setState(() {
                    getGroupList();
                  });
                });
              }
            },
            // 长按点击弹窗提示是否删除
            onLongPress: () async {
              // 如果该训练有被使用，则不允许直接删除
              var list = await _dbHelper.isGroupUsed(groupItem.group.groupId!);

              if (!context.mounted) return;
              if (list.isNotEmpty) {
                commonExceptionDialog(
                  context,
                  CusAL.of(context).exceptionWarningTitle,
                  CusAL.of(context).groupInUse(groupItem.group.groupName),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(CusAL.of(context).deleteConfirm),
                      content: Text(CusAL.of(context)
                          .groupDeleteAlert(groupItem.group.groupName)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: Text(CusAL.of(context).cancelLabel),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: Text(CusAL.of(context).confirmLabel),
                        ),
                      ],
                    );
                  },
                ).then((value) async {
                  if (value != null && value) {
                    try {
                      await _dbHelper.deleteGroupById(groupItem.group.groupId!);

                      // 删除后重新查询
                      getGroupList();
                    } catch (e) {
                      if (!context.mounted) return;
                      commonExceptionDialog(
                        context,
                        CusAL.of(context).exceptionWarningTitle,
                        e.toString(),
                      );
                    }
                  }
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
          title: Text(
            groupItem != null
                ? CusAL.of(context).modifyGroupLabels('1')
                : CusAL.of(context).modifyGroupLabels('0'),
          ),
          content: FormBuilder(
            key: _groupFormKey,
            initialValue: groupItem != null ? groupItem.toMap() : {},
            // autovalidateMode: AutovalidateMode.always,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  cusFormBuilerTextField(
                    "group_name",
                    labelText: '*${CusAL.of(context).workoutQuerys('0')}',
                    validator: FormBuilderValidators.required(),
                  ),
                  cusFormBuilerDropdown(
                    "group_category",
                    categoryOptions,
                    labelText: '*${CusAL.of(context).workoutQuerys('1')}',
                    validator: FormBuilderValidators.required(),
                  ),
                  cusFormBuilerDropdown(
                    "group_level",
                    levelOptions,
                    labelText: '*${CusAL.of(context).workoutQuerys('2')}',
                    validator: FormBuilderValidators.required(),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(CusAL.of(context).cancelLabel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(CusAL.of(context).confirmLabel),
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

                    if (!context.mounted) return;
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
                    if (!context.mounted) return;
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

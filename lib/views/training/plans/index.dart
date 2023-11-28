// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/training_state.dart';
import 'group_list.dart';

///
/// 2023-11-22 和workout index 基本类似，几乎一模一样
///
///
class TrainingPlans extends StatefulWidget {
  const TrainingPlans({super.key});

  @override
  State<TrainingPlans> createState() => _TrainingPlansState();
}

class _TrainingPlansState extends State<TrainingPlans> {
  final DBTrainingHelper _dbHelper = DBTrainingHelper();
  // plan查询表单的key
  final _queryFormKey = GlobalKey<FormBuilderState>();
  // plan新增保单的key
  final _addFormKey = GlobalKey<FormBuilderState>();

  // 展示计划列表(训练列表一次性查询所有，应该不会太多)
  List<PlanWithGroups> planList = [];

  // 可以筛选训练，条件用个map来存，初始化一个空map
  Map<String, dynamic> conditionMap = {};

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getPlanList();
  }

  // 查询已有的训练
  getPlanList() async {
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
      temp = await _dbHelper.searchPlanWithGroups(
        planName: conditionMap["plan_name"],
        planCategory: conditionMap["plan_category"],
        planLevel: conditionMap["plan_level"],
      );
    }

    print("getPlanList---$temp");

    // 设置查询结果
    if (!mounted) return;
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
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '周期计划    ', style: TextStyle(fontSize: 20.sp)),
              TextSpan(
                text: "共 ${planList.length} 个",
                style: TextStyle(fontSize: 12.sp),
              ),
            ],
          ),
        ),
        actions: [
          /// 新增训练组基本信息
          IconButton(
            icon: Icon(Icons.add, size: 30.sp),
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            ),
            onPressed: _modifyPlanInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQueryArea(),
          isLoading
              ? buildLoader(isLoading)
              : Expanded(child: _buildPlanList()),
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
                      "plan_name",
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
                          getPlanList();
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
                      "plan_category",
                      categoryOptions,
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
                      "plan_level",
                      levelOptions,
                      hintText: "选择难度",
                      hintStyle: TextStyle(fontSize: 14.sp),
                      optionFontSize: 14,
                    ),
                  ),
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
                        getPlanList();
                      });
                    }
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
  _buildPlanList() {
    return ListView.builder(
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
                trailing: SizedBox(
                  width: 30.sp,
                  child: IconButton(
                    icon: Icon(Icons.edit, size: 20.sp, color: Colors.blue),
                    onPressed: () {
                      print("indexindexinde--------x=$index ${planItem.plan}");
                      _modifyPlanInfo(planItem: planItem.plan);
                    },
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupList(
                        planItem: planItem.plan,
                      ),
                    ),
                  ).then((value) {
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
    );
  }

  // 修改计划基本信息的弹窗
  // ？？？这和训练的基本信息修改也一样，但弹窗的宽度可以想办法在自定义下
  _modifyPlanInfo({TrainingPlan? planItem}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("${planItem != null ? '修改' : '新建'}计划"),
          content: FormBuilder(
            key: _addFormKey,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  cusFormBuilerTextField(
                    "plan_name",
                    labelText: '*名称',
                    hintText: "输入名称",
                    hintStyle: TextStyle(fontSize: 14.sp),
                    initialValue: planItem?.planName,
                    validator: FormBuilderValidators.compose(
                        [FormBuilderValidators.required(errorText: '名称不可为空')]),
                  ),
                  cusFormBuilerTextField(
                    "plan_code",
                    labelText: '*代号',
                    hintText: "输入代号",
                    hintStyle: TextStyle(fontSize: 14.sp),
                    initialValue: planItem?.planCode,
                    validator: FormBuilderValidators.compose(
                        [FormBuilderValidators.required(errorText: '代号不可为空')]),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "plan_category",
                          categoryOptions,
                          labelText: '*分类',
                          initialValue: planItem?.planCategory,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: '分类不可为空')
                          ]),
                        ),
                      ),
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "plan_level",
                          levelOptions,
                          labelText: '*级别',
                          initialValue: planItem?.planLevel,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: '级别不可为空')
                          ]),
                        ),
                      ),
                    ],
                  ),
                  cusFormBuilerTextField(
                    "plan_period",
                    labelText: '*训练周期',
                    initialValue: planItem?.planPeriod.toString(),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: '训练周期不可为空'),
                      // FormBuilderValidators.numeric(),
                    ]),
                    keyboardType: TextInputType.number,
                  ),
                  cusFormBuilerTextField(
                    "description",
                    labelText: '*概述',
                    initialValue: planItem?.description,
                    maxLines: 3,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: '概述不可为空'),
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
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('确认'),
              onPressed: () async {
                if (_addFormKey.currentState!.saveAndValidate()) {
                  // 获取表单数值
                  Map<String, dynamic> formData =
                      _addFormKey.currentState!.value;
                  // 处理数据提交逻辑
                  print(formData);

                  // 对周期进行类型转换
                  var planPeriod = int.parse(formData['plan_period']);
                  // 再放回去
                  // 深拷贝表单数据的Map，修改拷贝后的(原始的那个好像是不可修改的，会报错)
                  var copiedFormData = Map<String, dynamic>.from(formData);
                  copiedFormData["plan_period"] = planPeriod;

                  var temp = TrainingPlan.fromMap(copiedFormData);

                  // 如果是新增
                  if (planItem == null) {
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
                  } else {
                    // 如果是修改
                    // ？？？这里应该验证是否修成功
                    temp.planId = planItem.planId!;
                    await _dbHelper.updateTrainingPlanById(
                      planItem.planId!,
                      temp,
                    );

                    // 如果是修改就返回训练组列表，而不是进入动作列表
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    setState(() {
                      getPlanList();
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

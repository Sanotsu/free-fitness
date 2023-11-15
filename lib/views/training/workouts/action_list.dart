// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';

// import 'action_configuration.dart';
import '../../../common/global/constants.dart';
import '../../../common/utils/sqlite_db_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/training_state.dart';
import 'action_config_dialog.dart';
import 'action_detail.dart';
import 'simple_exercise_list.dart';

class ActionList extends StatefulWidget {
//  从已存在的训练进入action list，会带上group信息去查询已存在的action list
// ？？？但进入simple exercise list之后，跳到action config之后返回跨级别了，需要看其他方式或者参数，比如带参数命名路由
  final TrainingGroup groupItem;

  const ActionList({super.key, required this.groupItem});

  @override
  State<ActionList> createState() => _ActionListState();
}

class _ActionListState extends State<ActionList> {
  var log = Logger();

  final DBTrainHelper _dbHelper = DBTrainHelper();

  // 这里不使用TrainingAction 是因为actionDetail有更多信息可以直接显示
  List<ActionDetail> actionList = [];

  // 是否在加载数据
  bool isLoading = false;

  // 是否处于编辑状态
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    print("widget.groupItem initState---${widget.groupItem}");

    // ？？？应该不需要放在setstate里面才对
    setState(() {
      _getActionListByGroupId();
    });
  }

  demoInsertGroupAndAction() async {
    var groupId = widget.groupItem.groupId!;

    // 主要这里的exerciseId和计时或者计次和示例数据的exercise list中要一样，否则显示不对
    var tempAction = TrainingAction(
      groupId: groupId,
      exerciseId: 2,
      frequency: 12,
      equipmentWeight: 5,
    );
    var tempAction1 = TrainingAction(
      groupId: groupId,
      exerciseId: 1,
      duration: 30,
      equipmentWeight: 5,
    );
    var tempAction2 = TrainingAction(
      groupId: groupId,
      exerciseId: 2,
      frequency: 30,
      equipmentWeight: 10,
    );
    var rst = await _dbHelper
        .insertTrainingActionList([tempAction, tempAction1, tempAction2]);

    print("ActionList----$rst");
  }

  // 查询指定训练中的动作列表
  _getActionListByGroupId() async {
    // await demoInsertGroupAndAction();

    // _dbHelper.deleteDb();
    // return;
    log.d("tempaa===============================");

    // 如果已经在查询数据中，则忽略此次新的查询
    if (isLoading) return;

    // 如果没在查询中，设置状态为查询中
    setState(() {
      isLoading = true;
    });

    // ？？？正常来讲，这里一定只有1个结果，不会有多个，也不会没有（验证就暂时不做了）
    var tempGWA = await _dbHelper.searchGroupWithActions(
      groupId: widget.groupItem.groupId,
    );

    log.d("tempGWA------$tempGWA");

    // 设置查询结果
    setState(() {
      // ？？？因为没有分页查询，所有这里直接替换已有的数组
      actionList = tempGWA.isNotEmpty ? tempGWA[0].actionDetailList : [];
      // 重置状态为查询完成
      isLoading = false;
    });
  }

// 保存现有的动作列表到当前训练中
  _saveActionList() async {
    // 必须要把原本的action id置为空，然后让数据库设定的自增生效，否则显示的结果默认以主键排序，和实际显示的结果可能不一致。
    List<TrainingAction> tempList =
        actionList.map((e) => e.action..actionId = null).toList();

    log.i(tempList);

    var renewRst = await _dbHelper.renewGroupWithActionsList(
      widget.groupItem.groupId!,
      tempList,
    );

    print("_saveActionList---$renewRst");
  }

  void _onEditPressed() {
    print("点击了修改按钮，进入了_onEditPressed");

    setState(() {
      _isEditing = true;
    });
  }

  void _onSavePressed() async {
    log.i("点击了保存按钮，进入了_onSavePressed $actionList");

    await _saveActionList();
    setState(() {
      _isEditing = false;
    });

    await _getActionListByGroupId();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      var item = actionList.removeAt(oldIndex);
      actionList.insert(newIndex, item);
    });
  }

  void _onDelete(int index) {
    // 进入了移除功能
    print("点击进入了移除功能 $index");
    setState(() {
      actionList.removeAt(index);
    });
  }

  /// 当处于编辑状态时，点击动作卡片进入动作编辑弹窗
  void _onConfigure(BuildContext context, ActionDetail adItem, int index) {
    // 弹出配置弹窗的逻辑
    print("预留点击进入action配置，使用弹窗 $index");

    // showConfigurationDialog(context, adItem, onConfigurationDialogClosed);

    showConfigDialog(context, adItem, index, onConfiguClosed);
    // ...
  }

  // 关闭动作弹窗时，根据其回调函数中的值，修改当前显示的动作配置为修改后的值
  void onConfiguClosed(int index, ActionDetail adItem) {
    // 在这里处理从弹窗中获得的数据
    print(
      "Received data from ------------: ${adItem.action} $index > ${actionList.length}",
    );

    setState(() {
      // 如果索引大于等于(理论上就是等于)原本的列表长度，说明是新增的，直接添加到底部
      if (index >= actionList.length) {
        actionList.add(adItem);
      } else {
        // 否则就是修改原有的
        actionList[index] = adItem;
      }
    });
  }

  // 关闭动作弹窗时，根据其回调函数中的值，修改当前显示的动作配置为修改后的值
  void onConfigurationDialogClosed(
    ActionDetail adItem,
    Map<String, dynamic> data,
  ) {
    // 在这里处理从弹窗中获得的数据
    log.d("Received data from dialog: $data");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 如果是编辑中，点击下方返回按钮取消编辑状态；如果不是编辑中，则返回上一页
        if (_isEditing) {
          // 取消时数据恢复原本的内容
          await _getActionListByGroupId();
          setState(() {
            _isEditing = !_isEditing;
          });
          return false; // 返回true表示不返回上一页
        } else {
          // 在这里添加处理返回按钮的逻辑
          Navigator.of(context).pop();
          return true; // 返回true表示允许返回
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('ActionList ${actionList.length}个动作'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // 如果是编辑中，点击返回箭头取消编辑状态；如果不是编辑中，则返回上一页
              if (_isEditing) {
                // 取消时数据恢复原本的内容
                await _getActionListByGroupId();
                setState(() {
                  _isEditing = !_isEditing;
                });
              } else {
                // 在这里添加处理返回按钮的逻辑
                Navigator.of(context).pop();
              }
            },
          ),
          actions: <Widget>[
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.cancel_outlined),
                onPressed: () async {
                  // 取消时数据恢复原本的内容
                  await _getActionListByGroupId();
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
              ),
            IconButton(
              icon: Icon(_isEditing ? Icons.done : Icons.edit),
              onPressed: _isEditing ? _onSavePressed : _onEditPressed,
            ),
          ],
        ),
        body: isLoading
            ? buildLoader(isLoading)
            : Column(
                children: [
                  const Center(
                    child: Text(
                      'ActionList.点击某一个group进来。 如果训练计划没有任何action，说明是全新的训练计划新增。如果已有action，则是对group添加action（group没有任何action是否可以自动删除该group）',
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: _isEditing, // 如果是修改，才允许长按进行拖拽
                      itemCount: actionList.length,
                      itemBuilder: (context, index) {
                        // actionDetailItem
                        var adItem = actionList[index];
                        var actionItem = adItem.action;

                        // 显示次数、持续时间、器械重量
                        String result = "";

                        String? formatValue(value, unit) {
                          return value != null ? "$value $unit" : null;
                        }

                        var frequency = formatValue(actionItem.frequency, '次');
                        var duration = formatValue(actionItem.duration, '秒');
                        var equipmentWeight =
                            formatValue(actionItem.equipmentWeight, '公斤');

                        if (adItem.exercise.countingMode ==
                            countingOptions.first.value) {
                          result = [duration, equipmentWeight]
                              .where((element) => element != null)
                              .join(' + ');
                        } else {
                          result = [frequency, equipmentWeight]
                              .where((element) => element != null)
                              .join(' + ');
                        }

                        // String result = "";

                        // var temp1 = actionItem.frequency != null
                        //     ? "${actionItem.frequency} 次"
                        //     : null;
                        // var temp2 = actionItem.duration != null
                        //     ? "${actionItem.duration} 秒"
                        //     : null;
                        // var temp3 = actionItem.equipmentWeight != null
                        //     ? "${actionItem.equipmentWeight} 公斤"
                        //     : null;

                        // // 第一个是计时，最后一个是计次（就两个，后续看改枚举）
                        // if (adItem.exercise.countingMode ==
                        //     countingOptions.first.value) {
                        //   List<String?> tempList = [temp2, temp3];
                        //   result = tempList
                        //       .where((element) => element != null)
                        //       .join(' + ');
                        // } else {
                        //   List<String?> tempList = [temp1, temp3];
                        //   result = tempList
                        //       .where((element) => element != null)
                        //       .join(' + ');
                        // }

                        return Card(
                          key: Key('$index'),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading:
                                    _isEditing ? const Icon(Icons.menu) : null,
                                // 不存在action name，就是exercise name就好
                                title: Text(adItem.exercise.exerciseName),
                                subtitle: Text(result),
                                // 如果没有缩略图，就应该显示技术动作要点的文本
                                // trailing: const Text("这里应该是缩略图"),
                                // 应该是上方点击了【编辑】之后，才能对列表进行调整、修改、删除、新增
                                onTap: () {
                                  if (_isEditing) {
                                    print(
                                        "修改时点击了action 指定卡片 ${adItem.exercise.countingMode}");

                                    _onConfigure(context, adItem, index);
                                  }
                                  if (!_isEditing) {
                                    showModalBottomSheet(
                                      context: context,
                                      // 设置滚动控制为true，子部件设置dialog的高度才有效，不然固定在9/16左右无法更多。
                                      isScrollControlled: true,
                                      builder: (BuildContext context) {
                                        return ActionDetailDialog(
                                          adItems: actionList,
                                          adIndex: index,
                                        );
                                      },
                                    ).then((value) {
                                      print(
                                          "-------打开action detail 弹窗后的返回 $value");
                                      // 修改exercise之后，重新加载列表
                                    });
                                  }
                                },
                                trailing: _isEditing
                                    ? SizedBox(
                                        width: 70.sp,
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text("图片")),
                                            Expanded(
                                                child: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () => _onDelete(index),
                                            ))
                                          ],
                                        ),
                                      )
                                    : SizedBox(
                                        width: 70.sp,
                                        child: const Text("这是图片"),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                      // onReorder: _isEditing ? _onReorder : null, // 根据编辑状态设置是否允许拖动
                      onReorder: _onReorder, // 根据编辑状态设置是否允许拖动
                    ),
                  ),
                  // 避免修改时新增按钮遮住最后一条列表
                  if (_isEditing) SizedBox(height: 80.sp),
                ],
              ),
        // 这里点击新增按钮，新增新的action，还是跳转到查询的exercise list
        floatingActionButton: _isEditing
            ? FloatingActionButton(
                onPressed: () {
                  // 处理按钮点击事件
                  // 这里点击新增训练计划，一定是要新增一个 group和action，后续在对应action list中新增action，都需要带上这个group id（group_has_action多一条数据）

                  //  在训练计划中点击【新增】，此时没有group id，先跳转到
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SimpleExerciseList(
                        // 如果是已存在的训练计划新增，则会有group id；如果是全新的训练计划新增，则暂时还没有id
                        source: widget.groupItem.groupId.toString(),
                      ),
                    ),
                  ).then((value) {
                    print("simple exercise list 返回的数据: $value");

                    if (value["selectedExerciseItem"] != null) {
                      var selectedExerciseItem =
                          value["selectedExerciseItem"] as Exercise;

                      var tempAction = TrainingAction(
                        exerciseId: selectedExerciseItem.exerciseId!,
                        groupId: widget.groupItem.groupId!,
                      );

                      var temp = ActionDetail(
                        exercise: selectedExerciseItem,
                        action: tempAction,
                      );

                      // 索引从0开始，所以新增的时候就从 actionList.length 开始
                      showConfigDialog(
                          context, temp, actionList.length, onConfiguClosed);
                    }
                  });
                },
                // backgroundColor: Colors.yellow,
                child: const Icon(Icons.add),
              )
            : SizedBox(
                height: 50.sp,
                width: 0.6.sw,
                child: ElevatedButton(
                  onPressed: () {
                    // 【点击开始跟练
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0), // 设置圆角
                    ),
                    backgroundColor: Colors.green,
                  ),
                  child: Text('开始', style: TextStyle(fontSize: 20.sp)),
                ),
              ),
        // 悬浮按钮位置
        floatingActionButtonLocation: _isEditing
            ? FloatingActionButtonLocation.endFloat
            : FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

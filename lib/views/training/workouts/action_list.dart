// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/training_state.dart';
import 'action_config_dialog.dart';
import 'action_detail.dart';
import 'action_follow_practice.dart';
import 'simple_exercise_list.dart';

class ActionList extends StatefulWidget {
  // 从已存在的训练进入action list，会带上group信息去查询已存在的action list
  // 2023-12-04 如果是从计划页面跳转过来，就需要带上计划的编号已经训练日信息
  final TrainingGroup groupItem;
  final TrainingPlan? planItem;
  final int? dayNumber;

  const ActionList({
    super.key,
    required this.groupItem,
    this.planItem,
    this.dayNumber,
  });

  @override
  State<ActionList> createState() => _ActionListState();
}

class _ActionListState extends State<ActionList> {
  var log = Logger();

  final DBTrainingHelper _dbHelper = DBTrainingHelper();

  // 这里不使用TrainingAction 是因为actionDetail有更多信息可以直接显示
  List<ActionDetail> actionList = [];

  // 是否在加载数据
  bool isLoading = false;

  // 是否处于编辑状态
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    _getActionListByGroupId();
  }

  // 查询指定训练中的动作列表
  _getActionListByGroupId() async {
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

    await _dbHelper.renewGroupWithActionsList(
      widget.groupItem.groupId!,
      tempList,
    );
  }

  // 点击顶部修改按钮时，把页面状态改为修改中，显示所有修改香瓜的功能
  void _onEditPressed() {
    setState(() {
      _isEditing = true;
    });
  }

  // 点击了顶部保存按钮，把新的动作列表存入数据库，并更新动作列表页面
  void _onSavePressed() async {
    await _saveActionList();
    setState(() {
      _isEditing = false;
    });

    await _getActionListByGroupId();
  }

  // 当对列表重新排序后，更新当前列表的数据
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      var item = actionList.removeAt(oldIndex);
      actionList.insert(newIndex, item);
    });
  }

  // 当点击了删除按钮后，冲列表中移除该数据
  void _onDelete(int index) {
    setState(() {
      actionList.removeAt(index);
    });
  }

  // 关闭动作弹窗时，根据其回调函数中的值，修改当前显示的动作配置为修改后的值
  void onConfiguClosed(int index, ActionDetail adItem) {
    // 在这里处理从弹窗中获得的数据
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 在修改中就不能返回
      canPop: !_isEditing,
      // 处理pop操作。如果 didPop 为false，则pop被阻止，进行执行后面代码块的操作。
      // 如果didPop为true，则直接返回。
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // ？？？这下面好像没生效，但返回上一层的逻辑又是正确的
        // (修改中点击返回按钮变为非修改中；非修改中点击返回则返回尚义页)
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
      child: Scaffold(
        appBar: AppBar(
          title: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                    text: widget.groupItem.groupName,
                    style: TextStyle(fontSize: CusFontSizes.pageTitle)),
                TextSpan(
                  text:
                      "\n${CusAL.of(context).actionLabel('1')}: ${CusAL.of(context).itemCount(actionList.length)}",
                  style: TextStyle(fontSize: CusFontSizes.pageAppendix),
                ),
              ],
            ),
          ),
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
          // 2023-12-23 如果有planId，则从计划跳某一个训练日，再到这里，就不允许修改这个训练组，只能查看
          actions: widget.planItem != null
              ? null
              : <Widget>[
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
                  Expanded(
                    child: _buildReorderableList(),
                  ),
                  // 避免修改时新增按钮遮住最后一条列表
                  if (_isEditing) SizedBox(height: 80.sp),
                ],
              ),
        // 这里点击新增按钮，新增新的action，还是跳转到查询的exercise list
        floatingActionButton: _isEditing
            ? _buildAddActionButton()
            : SizedBox(
                height: 50.sp,
                width: 0.6.sw,
                child: (actionList.isNotEmpty)
                    ? ElevatedButton(
                        onPressed: () {
                          /// 点击开始跟练
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActionFollowPracticeWithTTS(
                                // 虽然计划编号、训练日 和训练编号都有传，但理论上两者不会同时存在也不会同时为空
                                plan: widget.planItem,
                                dayNumber: widget.dayNumber,
                                // 有计划编号，就不传训练编号了
                                group: widget.planItem != null
                                    ? null
                                    : widget.groupItem,
                                // 动作组数据是必须要传的
                                actionList: actionList,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.sp), // 设置圆角
                          ),
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          CusAL.of(context).startLabel,
                          style: TextStyle(fontSize: CusFontSizes.pageTitle),
                        ),
                      )
                    : Container(),
              ),
        // 悬浮按钮位置
        floatingActionButtonLocation: _isEditing
            ? FloatingActionButtonLocation.endFloat
            : FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // 构建可以重新排序的动作列表
  _buildReorderableList() {
    return ReorderableListView.builder(
      // 如果是修改，才允许长按进行拖拽
      buildDefaultDragHandles: _isEditing,
      itemCount: actionList.length,
      itemBuilder: (context, index) {
        // actionDetailItem
        var adItem = actionList[index];
        var actionItem = adItem.action;

        // 显示次数、持续时间、器械重量
        String subTitle = "";
        var frequency = actionItem.frequency != null
            ? "${actionItem.frequency} ${CusAL.of(context).unitLabels('7')}"
            : null;
        var duration = actionItem.duration != null
            ? "${actionItem.duration} ${CusAL.of(context).unitLabels('6')}"
            : null;
        // 值是double类型，转2位小数的字符串
        var equipmentWeight = actionItem.equipmentWeight != null
            ? "${cusDoubleTryToIntString(actionItem.equipmentWeight!)} ${CusAL.of(context).unitLabels('5')}"
            : null;
        // 如果是计时的运动，子标题显示持续时间和器械重量(如果有的话)
        if (adItem.exercise.countingMode == countingOptions.first.value) {
          subTitle = [duration, equipmentWeight]
              .where((element) => element != null)
              .join(' + ');
        } else {
          // 如果是计次的运动，子标题显示重复次数和器械重量(如果有的话)
          subTitle = [frequency, equipmentWeight]
              .where((element) => element != null)
              .join(' + ');
        }

        // 基础动作的图片
        List<String> imageList =
            (adItem.exercise.images?.trim().isNotEmpty == true)
                ? adItem.exercise.images!.split(",")
                : [];

        return Card(
          elevation: 3,
          key: Key('$index'),
          child: InkWell(
            onTap: () {
              /// 当处于编辑状态时，点击动作卡片进入动作编辑弹窗
              // 应该是上方点击了【编辑】之后，才能对列表进行调整、修改、删除、新增
              if (_isEditing) {
                showConfigDialog(context, adItem, index, onConfiguClosed);
              }
              if (!_isEditing) {
                showModalBottomSheet(
                  context: context,
                  // 设置滚动控制为true，子部件设置dialog的高度才有效，不然固定在9/16左右无法更多。
                  isScrollControlled: true,
                  builder: (BuildContext context) =>
                      ActionDetailDialog(adItems: actionList, adIndex: index),
                );
              }
            },
            // 由于ListTile的 trailing 无法自定义高度，这里就用Row来构建显示
            child: SizedBox(
              height: 0.15.sh,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_isEditing)
                    Expanded(
                      flex: 2,
                      child: Icon(
                        Icons.menu,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  Expanded(
                    flex: 9,
                    child: ListTile(
                      // 不存在action name，就是exercise name就好
                      title: Text(
                        "${index + 1} ${adItem.exercise.exerciseName}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: CusFontSizes.itemTitle,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      subtitle: Text(subTitle),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: EdgeInsets.all(_isEditing ? 5.sp : 10.sp),
                      child: buildImageCarouselSlider(imageList),
                    ),
                  ),
                  if (_isEditing)
                    Expanded(
                      flex: 2,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () => _onDelete(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      onReorder: _onReorder,
    );
  }

  /// 动作列表中新增动作，会查询简单exercise列表，选中某个exercise之后带回本页面，加入到action list中
  _buildAddActionButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SimpleExerciseList(),
          ),
        ).then((value) {
          // 如果返回的不是null，也不是false，那就应该是被选中的exercise类
          if (value != null && value != false) {
            var selectedExercise = value as Exercise;

            var tempAction = TrainingAction(
              exerciseId: selectedExercise.exerciseId!,
              groupId: widget.groupItem.groupId!,
            );

            var temp = ActionDetail(
              exercise: selectedExercise,
              action: tempAction,
            );

            // 索引从0开始，所以新增的时候就从 actionList.length 开始
            showConfigDialog(context, temp, actionList.length, onConfiguClosed);
          }
        });
      },
      child: const Icon(Icons.add),
    );
  }
}

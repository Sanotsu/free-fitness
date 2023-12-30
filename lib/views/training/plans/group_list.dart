// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/views/training/workouts/action_list.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/training_state.dart';
import '../workouts/index.dart';

///
/// 这个 GroupList 和训练的列表首页 TrainingWorkouts 的区别:
///
///   这个是指定plan 的内容，后者是所有的训练数据；
///   在这个知道plan中新增训练，就需要跳转到后者列表去选择指定的训练，再带回来进行新增。
///   这里删除某个训练只是从plan中移除某一个训练，后者删除某个训练就是直接从数据库删除了。
///
///
///
class GroupList extends StatefulWidget {
//  从已存在的计划进入group list，会带上plan信息去查询已存在的group list
  final TrainingPlan planItem;

  const GroupList({super.key, required this.planItem});

  @override
  State<GroupList> createState() => _GroupListState();
}

// group list里面的修改，就删除、新增、调整group数据就好，没有点击进行配置
// （没啥可配的，action有地方配置,goup基础信息也有地方修改）
class _GroupListState extends State<GroupList> {
  final DBTrainingHelper _dbHelper = DBTrainingHelper();

  // 这里不使用TrainingAction 是因为actionDetail有更多信息可以直接显示
  List<GroupWithActions> groupList = [];

  // 当前计划的每个训练日最后一次训练的日志map
  Map<int, TrainedDetailLog?> logMap = {};

  late TrainingPlan planItem;

  // 是否在加载数据
  bool isLoading = false;

  // 是否处于编辑状态
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      planItem = widget.planItem;
      _getGroupListByPlanId();
    });
  }

  // 查询指定训练中的动作列表
  _getGroupListByPlanId() async {
    // 如果已经在查询数据中，则忽略此次新的查询
    if (isLoading) return;

    // 如果没在查询中，设置状态为查询中
    setState(() {
      isLoading = true;
    });

    // ？？？正常来讲，这里一定只有1个结果，不会有多个，也不会没有（验证就暂时不做了）
    // 指定计划包含多个训练
    var tempPWG = await _dbHelper.searchPlanWithGroups(
      planId: planItem.planId,
    );

    // 查询该训练计划的跟练日志信息，用于显示每个训练的最后一次跟练时间
    var tempLog =
        await _dbHelper.queryLastTrainingDetailLogByPlanName(planItem);

    print("动作组的跟练日志$tempLog");

    // 设置查询结果
    setState(() {
      // 因为没有分页查询，所有这里直接替换已有的数组
      groupList = tempPWG.isNotEmpty ? tempPWG[0].groupDetailList : [];
      logMap = tempLog;
      // 重置状态为查询完成
      isLoading = false;
    });
  }

  void _onEditPressed() {
    setState(() {
      _isEditing = true;
    });
  }

  void _onSavePressed() async {
    // 保存现有的动作列表到当前训练中
    // 必须要把plan has group中对应plan的旧的plan has group id 删除
    // 然后让数据库设定的自增生效，否则显示的结果默认以主键排序，和实际显示的结果可能不一致。
    var planId = planItem.planId!;
    List<PlanHasGroup> tempList = [];

    for (var i = 0; i < groupList.length; i++) {
      var temp = PlanHasGroup(
        planId: planId,
        groupId: groupList[i].group.groupId!,
        dayNumber: i + 1,
      );
      tempList.add(temp);
    }

    try {
      // 2023-12-30 也一并修改计划的周期为目前group列表的长度
      await _dbHelper.renewPlanWithGroupList(planId, tempList);
      await _getGroupListByPlanId();
      // 虽然更新了plan，则重新获取最新的plan
      var plans = await _dbHelper.queryTrainingPlanById(planItem.planId!);
      if (plans.isNotEmpty) {
        setState(() {
          planItem = plans.first;
        });
      }
    } catch (e) {
      // 弹出报错提示框
      if (!mounted) return;
      commonExceptionDialog(
        context,
        CusAL.of(context).exceptionWarningTitle,
        e.toString(),
      );
    } finally {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      var item = groupList.removeAt(oldIndex);
      groupList.insert(newIndex, item);
    });
  }

  void _onDelete(int index) {
    // 进入了移除功能
    setState(() {
      groupList.removeAt(index);
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
        // (修改中点击返回按钮变为非修改中；非修改中点击返回则返回上一页)
        if (_isEditing) {
          // 取消时数据恢复原本的内容
          await _getGroupListByPlanId();
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
            text: TextSpan(
              children: [
                TextSpan(
                  text: planItem.planName,
                  style: TextStyle(fontSize: CusFontSizes.pageTitle),
                ),
                TextSpan(
                  text: "\n${groupList.length} ${CusAL.of(context).workouts}",
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
                await _getGroupListByPlanId();
                setState(() {
                  _isEditing = !_isEditing;
                });
              } else {
                // 在这里添加处理返回按钮的逻辑
                Navigator.of(context).pop();
              }
            },
          ),
          // 2023-12-04 因为有跟练日志之后再修改计划的内容可能会导致日志查不到对应的基础表数据
          // 所以暂时有跟练的计划不让修改内容(理论上对应的action list也不允许再改了)
          actions: (logMap.values.where((value) => value != null).isNotEmpty)
              ? null
              : <Widget>[
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: () async {
                        // 取消时数据恢复原本的内容
                        await _getGroupListByPlanId();
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
                    child: ReorderableListView.builder(
                      // 如果是修改，才允许长按进行拖拽
                      buildDefaultDragHandles: _isEditing,
                      itemCount: groupList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          key: Key('$index'),
                          elevation: 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _buildGroupItemListTile(groupList, index),
                            ],
                          ),
                        );
                      },
                      onReorder: _onReorder,
                    ),
                  ),
                  // 避免修改时新增按钮遮住最后一条列表
                  if (_isEditing) SizedBox(height: 80.sp),
                ],
              ),
        // 这里点击新增按钮，新增 group 到当前list，先跳到simple group list 查询页面，选中某个group之后返回
        floatingActionButton: _isEditing
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 复用训练列表主页面，并告知是计划新增训练
                      builder: (context) => const TrainingWorkouts(
                        isPlanAdd: true,
                      ),
                    ),
                  ).then((value) {
                    // 这里正常返回值的话，一定是一个GroupWithActions类型的 groupItem，
                    // 存入group列表尾部就好了
                    setState(() {
                      groupList.add(value);
                    });
                  });
                },
                child: const Icon(Icons.add),
              )
            : null,
        // 悬浮按钮位置
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // 构建训练条目瓦片
  _buildGroupItemListTile(List<GroupWithActions> groupList, int index) {
    // actionDetailItem
    GroupWithActions gwaItem = groupList[index];
    TrainingGroup groupItem = gwaItem.group;

    return ListTile(
      leading: _isEditing
          ? SizedBox(
              width: 30.sp,
              child: Row(
                children: [
                  Expanded(
                    child: Icon(
                      Icons.menu,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                ],
              ),
            )
          : null,
      // 不存在action name，就是exercise name就好
      title: Text(
        "${CusAL.of(context).dayNumber(index + 1)} ${groupItem.groupName}",
        style: TextStyle(
          fontSize: CusFontSizes.itemTitle,
          color: Theme.of(context).primaryColor,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
                  '${gwaItem.actionDetailList.length} ${CusAL.of(context).exercise} ',
              style: TextStyle(color: Theme.of(context).shadowColor),
            ),
            TextSpan(
              text: '${getCusLabelText(
                groupItem.groupLevel,
                levelOptions,
              )}  ',
              style: TextStyle(color: Colors.green[500]),
            ),
            TextSpan(
              text: '\n${getCusLabelText(
                groupItem.groupCategory,
                categoryOptions,
              )}',
              style: TextStyle(color: Theme.of(context).shadowColor),
            ),
          ],
        ),
      ),

      // 如果点击时是修改状态，不做任何操作（修改group的基本信息在group模块点击省略号的时候去做）；
      // 如果不是修改状态，就应该直接跳转到action list去。

      ///  2023-12-23
      ///  计划修改训练：只能添加或删除已经有的workout(group)，不能修改group中的action list；
      ///     要修改action list 去workout(group)模块进行。
      ///  所以此处非修改状态下点击某一个训练日，就是查看该训练日动作准备跟练。
      onTap: () {
        if (!_isEditing) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActionList(
                groupItem: groupItem,
                planItem: planItem,
                dayNumber: index + 1,
              ),
            ),
          );
        }
      },
      // trailing 是有高度上限的56好像是
      trailing: _isEditing
          ? SizedBox(
              width: 40.sp,
              child: Row(
                children: [
                  Expanded(
                      child: IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => _onDelete(index),
                  ))
                ],
              ),
            )
          : SizedBox(
              width: 65.sp,
              // 跟练状态和上次运动时间
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                // 注意索引index是从0开始，logmap中的key是从1开始(第一个训练日)
                children: [
                  Icon(
                    (index > 0 && logMap[index + 1] == null)
                        ? Icons.do_not_disturb_alt_rounded
                        : Icons.play_arrow,
                  ),
                  Text(
                    logMap[index + 1]?.trainedDate ??
                        CusAL.of(context).incompleteLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: CusFontSizes.itemContent),
                  ),
                ],
              ),
            ),
    );
  }
}

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/views/training/workouts/action_list.dart';
import 'package:logger/logger.dart';

import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/training_state.dart';
import '../workouts/index.dart';

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
  var log = Logger();

  final DBTrainingHelper _dbHelper = DBTrainingHelper();

  // 这里不使用TrainingAction 是因为actionDetail有更多信息可以直接显示
  List<GroupWithActions> groupList = [];

  // 是否在加载数据
  bool isLoading = false;

  // 是否处于编辑状态
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    print("widget.planItem initState---${widget.planItem}");

    // ？？？应该不需要放在setstate里面才对
    setState(() {
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
      planId: widget.planItem.planId,
    );

    log.d("tempPWG------$tempPWG");

    // 设置查询结果
    setState(() {
      // ？？？因为没有分页查询，所有这里直接替换已有的数组
      groupList = tempPWG.isNotEmpty ? tempPWG[0].groupDetailList : [];
      // 重置状态为查询完成
      isLoading = false;
    });
  }

// 保存现有的动作列表到当前训练中
  _saveGroupList() async {
    // 必须要把plan has group中对应plan的旧的plan has group id 删除
    // 然后让数据库设定的自增生效，否则显示的结果默认以主键排序，和实际显示的结果可能不一致。

    var planId = widget.planItem.planId!;

    List<PlanHasGroup> tempList = [];

    for (var i = 0; i < groupList.length; i++) {
      var temp = PlanHasGroup(
        planId: planId,
        groupId: groupList[i].group.groupId!,
        dayNumber: i + 1,
      );
      tempList.add(temp);
    }

    log.i(tempList);

    var renewRst = await _dbHelper.renewPlanWithGroupList(planId, tempList);

    print("_saveGroupList---$renewRst");
  }

  void _onEditPressed() {
    print("点击了修改按钮，进入了_onEditPressed");

    setState(() {
      _isEditing = true;
    });
  }

  void _onSavePressed() async {
    log.i("点击了保存按钮，进入了_onSavePressed $groupList");

    await _saveGroupList();
    setState(() {
      _isEditing = false;
    });

    await _getGroupListByPlanId();
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
    print("点击进入了移除功能 $index");
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
        // ？？？这下面好像没生效，但返回上一层的逻辑又是正确的
        // (修改中点击返回按钮变为非修改中；非修改中点击返回则返回尚义页)
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
          title: const Text('GroupList'),
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
          actions: <Widget>[
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
                  const Center(
                    child: Text(
                      'GroupList.点击某一个plan进来。 如果计划没有任何group，说明是全新的计划，可能需要新增。如果已有group，则是对plan 中的group进行添加修改调顺序等，或者直接跟着做',
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: _isEditing, // 如果是修改，才允许长按进行拖拽
                      itemCount: groupList.length,
                      itemBuilder: (context, index) {
                        // actionDetailItem
                        GroupWithActions gwaItem = groupList[index];
                        TrainingGroup groupItem = gwaItem.group;

                        return Card(
                          key: Key('$index'),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading:
                                    _isEditing ? const Icon(Icons.menu) : null,
                                // 不存在action name，就是exercise name就好
                                title: Text(
                                  "第${index + 1}天 - ${groupItem.groupName}",
                                ),
                                subtitle: Text(
                                  "${groupItem.groupLevel}- 共${gwaItem.actionDetailList.length}个动作",
                                ),

                                // 【【【 如果点击时是修改状态，不做任何操作（修改group的基本信息在group模块点击省略号的时候去做）；
                                // 如果不是修改状态，就应该直接跳转到action list去。
                                // 后续在action list中的修改、开始跟练都一样一样的
                                onTap: () {
                                  if (!_isEditing) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ActionList(
                                          groupItem: groupItem,
                                        ),
                                      ),
                                    ).then((value) {
                                      print("action list 返回的数据 $value");
                                      // ？？？暂时返回这个页面时都重新加载最新的训练列表数据

                                      // 如果进入action list有修改、做了跟练之类的，这里要更新训练日的状态（已练习、未练）
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
                    print("TrainingWorkouts 返回的数据: $value");
                    // 这里正常返回值的话，一定是一个GroupWithActions类型的 groupItem，存入group列表尾部就好了
                    setState(() {
                      groupList.add(value);
                    });
                  });
                },
                backgroundColor: Colors.yellow,
                child: const Icon(Icons.add),
              )
            : null,
        // 悬浮按钮位置
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

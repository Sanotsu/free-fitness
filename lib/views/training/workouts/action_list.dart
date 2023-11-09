// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// import 'action_configuration.dart';
import '../../../models/training_state.dart';
import 'simple_exercise_list.dart';

class ActionList extends StatefulWidget {
//  从已存在的训练计划进入action list，会带上group信息去查询已存在的action list
  final TrainingGroup? groupItem;
  // 如果是新增训练计划，是先到action config，把配置好的一个action传到action list，再保存时连同新的group存入数据库
  final TrainingAction? actionItem;

  const ActionList({super.key, this.groupItem, this.actionItem});

  @override
  State<ActionList> createState() => _ActionListState();
}

class _ActionListState extends State<ActionList> {
  List<TrainingAction> actionList = [];

  @override
  void initState() {
    super.initState();

    print("widget.groupItem---${widget.groupItem}");
    print("widget.actionItem---${widget.actionItem}");

    var tempAction = TrainingAction(
      actionCode: "action_code",
      actionName: "action_name",
      exerciseId: 1,
      frequency: 10,
      duration: 20,
      equipmentWeight: 12,
      actionLevel: "初级",
      description: "就是初级",
      contributor: "<登录用户>",
      gmtCreate: DateTime.now().toString(),
    );

    setState(() {
      actionList.add(tempAction);
      if (widget.actionItem != null) {
        actionList.add(widget.actionItem!);
      }
      print("actionList----$actionList");
    });
  }

  /// 如果是group进来的，就是直接查询db中存在的action 列表，展示到这里
  /// 如果是新传 actionItem，存放到已有的action list中去
  /// ？？？？ pushReplacement 好像是重新刷新了，旧数据没有保存，新增训练计划的时候永远只有1条？？？

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ActionList'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle: TextStyle(fontSize: 16.sp),
            ),
            onPressed: () {},
            child: const Text('新增'),
          )
        ],
      ),
      body: Column(
        children: [
          const Center(
            child: Text(
              'ActionList.点击某一个group进来。 如果训练计划没有任何action，说明是全新的训练计划新增。如果已有action，则是对group添加action（group没有任何action是否可以自动删除该group）',
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                return Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        title: const Text("exercise name"),
                        subtitle: const Text(
                            "应该没有内容，点击这个ListTile ，带上exercise信息进入action配置页面"),
                        trailing: const Text("这里应该是缩略图"),
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const ActionConfiguration(
                          //       // item 是这里选择的那个运动
                          //       item: null,
                          //       // source应该是父组件传的，来源可能是 训练计划列表 或者 指定训练计划的动作列表
                          //       source: 'action_modify',
                          //     ),
                          //   ),
                          // );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            child: const Text('BUY TICKETS'),
                            onPressed: () {/* ... */},
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            child: const Text('LISTEN'),
                            onPressed: () {/* ... */},
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // 这里点击新增按钮，新增新的action，还是跳转到查询的exercise list
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 处理按钮点击事件
          // 这里点击新增训练计划，一定是要新增一个 group和action，后续在对应action list中新增action，都需要带上这个group id（group_has_action多一条数据）

          //  在训练计划中点击【新增】，此时没有group id，先跳转到
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimpleExerciseList(
                // 如果是已存在的训练计划新增，则会有group id；如果是全新的训练计划新增，则暂时还没有id
                source: (widget.groupItem != null) ? "group_id" : '',
              ),
            ),
          );
        },
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add),
      ),
      // 悬浮按钮位置
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

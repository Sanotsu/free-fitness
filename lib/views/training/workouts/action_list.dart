import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'action_configuration.dart';
import 'simple_exercise_list.dart';

class ActionList extends StatefulWidget {
  const ActionList({super.key});

  @override
  State<ActionList> createState() => _ActionListState();
}

class _ActionListState extends State<ActionList> {
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ActionConfiguration(),
                            ),
                          );
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
              builder: (context) => const SimpleExerciseList(),
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

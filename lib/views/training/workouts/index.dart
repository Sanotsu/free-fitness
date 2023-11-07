import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'action_list.dart';
import 'modify_workouts_form.dart';
import 'simple_exercise_list.dart';

class TrainingWorkouts extends StatefulWidget {
  const TrainingWorkouts({super.key});

  @override
  State<TrainingWorkouts> createState() => _TrainingWorkoutsState();
}

class _TrainingWorkoutsState extends State<TrainingWorkouts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Column(
        children: [
          const Center(
            child: Text(
              'TrainingWorkouts index，这里是已存在的训练计划列表（不多的话一次性展示所有，多的话还是分页。现在先直接展示所有）',
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
                        title: const Text("group name"),
                        subtitle: const Text(
                            "subtitle 应该没有内容，点击这个ListTile ，带上exercise信息进入action配置页面"),
                        trailing: const Text("这里应该是点击跳到该group的action 列表"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ActionList(),
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
      // 悬浮按钮
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
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      // 悬浮按钮位置
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

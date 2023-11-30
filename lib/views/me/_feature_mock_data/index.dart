// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import '../../../common/utils/db_diary_helper.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/db_user_helper.dart';
import 'test_funcs.dart';

class FeatureMockDemo extends StatefulWidget {
  const FeatureMockDemo({super.key});

  @override
  State<FeatureMockDemo> createState() => _FeatureMockDemoState();
}

class _FeatureMockDemoState extends State<FeatureMockDemo> {
  final DBTrainingHelper _trainingHelper = DBTrainingHelper();
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
  final DBDiaryHelper _diaryHelper = DBDiaryHelper();
  final DBUserHelper _userHelper = DBUserHelper();

  Future<void> _showSimpleDialog(BuildContext context, String msg) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(msg),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("生成测试数据"),
      ),
      // ??? 从上倒下预计是:个人信息、功能按钮、软件信息等区块
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              /// ？？？在此处集中添加测试数据
              ///
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _dietaryHelper.deleteDB();
                      _showSimpleDialog(context, "已删除 dietary db");
                    },
                    child: const Text("delete dietary db"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _trainingHelper.deleteDB();
                      _showSimpleDialog(context, "已删除 training db");
                    },
                    child: const Text("delete training db"),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _diaryHelper.deleteDB();
                      _showSimpleDialog(context, "已删除 diary db");
                    },
                    child: const Text("delete diary db"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _userHelper.deleteDB();
                      _showSimpleDialog(context, "已删除 user db");
                    },
                    child: const Text("delete user db"),
                  ),
                ],
              ),

              TextButton(
                onPressed: () {},
                child: const Text("新增用户营养素目标(todo)"),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      // 新增饮食模块需要有个人信息，避免没有点击上面那个按钮
                      await insertOneUser();
                      // 7种食物(对应7*3种单份营养素)、70条饮食日记条目、随机插入最近7天中
                      // (一日四餐，每餐1个条目，7天都是7*4=28条数据)
                      await insertDailyLogDataDemo(7, 30, 7);
                      if (!mounted) return;
                      _showSimpleDialog(context, "已新增【饮食】模块示例");
                    },
                    child: const Text("新增饮食模块示例"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await insertOneRandomPlanHasGroup();
                      if (!mounted) return;
                      _showSimpleDialog(context, "已新增【训练】模块示例");
                    },
                    child: const Text("新增训练模块示例"),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await insertOneQuillDemo();
                      if (!mounted) return;
                      _showSimpleDialog(context, "已新增一篇【手记】示例");
                    },
                    child: const Text("新增一篇手记"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await insertOneUser();
                      if (!mounted) return;
                      _showSimpleDialog(context, "已新增唯一用户");
                    },
                    child: const Text("新增唯一用户"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:free_fitness/common/global/constants.dart';

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
                      CacheUser.clearUserId();
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
                      await insertExtraUsers();
                      if (!mounted) return;
                      _showSimpleDialog(context, "已新增额外用户");
                    },
                    child: const Text("新增额外两个用户"),
                  ),
                ],
              ),

              TextButton(
                onPressed: () async {
                  await insertBMIDemo();
                  if (!mounted) return;
                  _showSimpleDialog(context, "已新增10条篇【BMI】示例");
                },
                child: const Text("userId为1的新增10条随机BMI数据"),
              ),

              TextButton(
                onPressed: () async {
                  await insertTrainingLogDemo();
                  if (!mounted) return;
                  _showSimpleDialog(context, "已新增2条【训练日志】示例");
                },
                child: const Text("插入两条训练日志(先新增基础数据)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/utils/db_dietary_helper.dart';
import '../../common/utils/db_training_helper.dart';
import 'test_funcs.dart';

class UserCenter extends StatefulWidget {
  const UserCenter({super.key});

  @override
  State<UserCenter> createState() => _UserCenterState();
}

class _UserCenterState extends State<UserCenter> {
  final DBTrainingHelper _trainingHelper = DBTrainingHelper();
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

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
        title: const Text("我的"),
      ),
      // ??? 从上倒下预计是:个人信息、功能按钮、软件信息等区块
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ？？？在此处集中添加测试数据
            TextButton(
              onPressed: () {
                _dietaryHelper.deleteDB();
                _showSimpleDialog(context, "已删除 dietary db");
              },
              child: const Text("delete dietary db"),
            ),
            TextButton(
              onPressed: () {
                _trainingHelper.deleteDB();
                _showSimpleDialog(context, "已删除 training db");
              },
              child: const Text("delete training db"),
            ),
            TextButton(
              // onPressed: () async {
              //   await insertOneDietaryUser();
              //   if (!mounted) return;
              //   _showSimpleDialog(context, "已新增用户营养素目标");
              // },
              onPressed: () {},
              child: const Text("新增用户营养素目标(todo)"),
            ),
            TextButton(
              onPressed: () async {
                await insertOneDietaryUser();
                if (!mounted) return;
                _showSimpleDialog(context, "已新增唯一用户");
              },
              child: const Text("新增唯一用户"),
            ),
            TextButton(
              onPressed: () async {
                // 新增饮食模块需要有个人信息，避免没有点击上面那个按钮
                await insertOneDietaryUser();
                // 7种食物(对应7*3种单份营养素)、70条饮食日记条目、随机插入最近7天中
                // (一日四餐，每餐1个条目，7天都是7*4=28条数据)
                await insertDailyLogDataDemo(7, 30, 7);
                if (!mounted) return;
                _showSimpleDialog(context, "已新增【饮食】模块示例");
              },
              child: const Text("新增饮食模块示例"),
            ),
            TextButton(
              onPressed: () async {
                await insertOneRandomPlanHasGroup();
                if (!mounted) return;
                _showSimpleDialog(context, "已新增【训练】模块示例");
              },
              child: const Text("新增训练模块示例"),
            ),
            ListView.builder(
              // 解决 NEEDS-PAINT ……的问题
              shrinkWrap: true,
              // 只有外部的 SingleChildScrollView 滚动，这个内部的listview不滚动
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              //列表项构造器
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ListTile(
                    title: Text('预留设置 $index'),
                    subtitle: Text('预留设置 $index 子标题'),
                    minLeadingWidth: 20.sp, // 左侧缩略图标的最小宽度
                    // 这个小部件将查询/加载图像。
                    leading: const Icon(Icons.album),
                    onTap: () {/* ... */},
                    trailing: const Icon(Icons.arrow_forward),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

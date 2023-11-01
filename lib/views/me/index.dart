// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserCenter extends StatefulWidget {
  const UserCenter({super.key});

  @override
  State<UserCenter> createState() => _UserCenterState();
}

class _UserCenterState extends State<UserCenter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("我的"),
      ),
      // ??? 从上倒下预计是:个人信息、功能按钮、软件信息等区块
      body: Center(
        child: ListView.builder(
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
        ),
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'discovers/index.dart';
import 'plans/index.dart';
import 'reports/index.dart';
import 'settings/index.dart';

class Workout extends StatefulWidget {
  const Workout({super.key});

  @override
  State<Workout> createState() => _WorkoutState();
}

class _WorkoutState extends State<Workout> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("训练"),
      ),
      body: _buildBody(),
    );
  }

  /// 构建主体内容(是个 GridView)
  _buildBody() {
    return Builder(builder: (BuildContext context) {
      return Center(
        // 因为 GridView.count 默认会根据其内容进行滚动，所以先设置一个固定高度的容器，将该容器居中
        child: SizedBox(
          // 此外，设置了固定宽高之后，也更好定量每个card的尺寸
          height: 420.sp,
          width: 340.sp,
          child: GridView.count(
            crossAxisCount: 2, // 一行2个
            padding: EdgeInsets.all(10.sp), // 边框10
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 0.8, // 宽高比（单个card应该是160.sp * 200.sp）
            children: <Widget>[
              _buildCard(const WorkoutDiscovers(), "动作"),
              _buildCard(const WorkoutPlans(), "计划"),
              _buildCard(const WorkoutReports(), "报告"),
              _buildCard(const WorkoutSettings(), "设置"),
            ],
          ),
        ),
      );
    });
  }

  _buildCard(Widget widget, String title) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext ctx) => widget,
            ),
          );
        },
        child: Container(
          color: Colors.lightBlue[100],
          child: Center(
            child: Text(
              title,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

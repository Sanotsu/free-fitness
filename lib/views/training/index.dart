// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'exercise/index.dart';
import 'plans/index.dart';
import 'reports/index.dart';
import 'settings/index.dart';
import 'workouts/index.dart';

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training>
    with SingleTickerProviderStateMixin {
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
    return Center(
      child: Column(
        children: [
          SizedBox(
            // 此外，设置了固定宽高之后，也更好定量每个card的尺寸
            height: 0.20.sh,
            width: 340.sp,
            child: Padding(
              padding: EdgeInsets.all(10.sp),
              child: _buildCard(const TrainingReports(), "报告"),
            ),
          ),

          // 因为 GridView.count 默认会根据其内容进行滚动，所以先设置一个固定高度的容器，将该容器居中
          Expanded(
            child: SizedBox(
              // 此外，设置了固定宽高之后，也更好定量每个card的尺寸
              height: 340.sp,
              width: 340.sp,
              child: GridView.count(
                crossAxisCount: 2, // 一行2个
                padding: EdgeInsets.all(10.sp), // 边框10
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1, // 宽高比（单个card应该是160.sp * 160.sp）
                children: <Widget>[
                  _buildCard(const TrainingExercise(), "基础动作"),
                  _buildCard(const TrainingWorkouts(), "动作做组"),
                  _buildCard(const TrainingPlans(), "训练计划"),
                  _buildCard(const TrainingSettings(), "训练设置"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
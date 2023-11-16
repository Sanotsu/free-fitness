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

class _TrainingState extends State<Training> {
  String placeholderImageUrl = 'assets/images/no_image.png';
  String workoutManImageUrl = 'assets/covers/workout-man.png';
  String workoutWomanImageUrl = 'assets/covers/workout-woman.png';
  String workoutCalendarImageUrl = 'assets/covers/workout-calendar-dark.png';

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
        title: const Text("运动"),
      ),
      body: _buildBody(),
    );
  }

  /// 构建主体内容(是个 GridView)
  _buildBody() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(20.sp, 20.sp, 20.sp, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 100.sp,
                    child: _buildSmallCard(const TrainingReports(), "报告"),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 100.sp,
                    child: _buildSmallCard(const TrainingSettings(), "设置"),
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            // 不加这一行，gridView放在另一个滚动组件中会报错
            shrinkWrap: true,
            // 禁用外部滚动视图的滚动(不加这一行，触碰到gridview的区域就无法滚动)
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 1, // 每一行的数量
            padding: EdgeInsets.all(20.sp), // 内边框
            crossAxisSpacing: 10.0, // 主轴间间隔
            mainAxisSpacing: 10.0, // 交叉轴间隔
            childAspectRatio: 3, // 子组件的宽高比
            children: <Widget>[
              _buildCard(
                const TrainingExercise(),
                "动作",
                "动作库管理模块",
                workoutWomanImageUrl,
              ),
              _buildCard(
                const TrainingWorkouts(),
                "训练",
                "训练组管理模块",
                workoutManImageUrl,
              ),
              _buildCard(
                const TrainingPlans(),
                "计划",
                "计划库管理模块",
                workoutCalendarImageUrl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  _buildSmallCard(Widget widget, String title) {
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

  _buildCard(Widget widget, String title, String subtitle, String imageUrl) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Container(
        color: Colors.lightBlue[100],
        child: Center(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: Image.asset(imageUrl, fit: BoxFit.scaleDown),
                ),
              ),
              Expanded(
                flex: 3,
                child: ListTile(
                  title: Text(
                    title,
                    style:
                        TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(subtitle),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext ctx) => widget,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

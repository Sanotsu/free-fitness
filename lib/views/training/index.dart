// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/components/cus_cards.dart';
import '../../common/global/constants.dart';
import 'exercise/index.dart';
import 'plans/index.dart';
import 'reports/index.dart';
import 'workouts/index.dart';

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  // 查看和请求存储权限
  // _requestPermission() async {
  //   // 获取权限
  //   Map<Permission, PermissionStatus> statuses = await [
  //     Permission.accessMediaLocation,
  //     Permission.storage,
  //   ].request();

  //   print("------------statuses $statuses");
  //   final info = statuses[Permission.storage].toString();
  //   print("获取存取权限--------------$info");
  // }

  @override
  void initState() {
    // 进入运动模块就获取存储授权(应该是启动app就需要这个请求)
    // _requestPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 计算屏幕剩余的高度
    // 设备屏幕的总高度
    //  - 屏幕顶部的安全区域高度，即状态栏的高度
    //  - 屏幕底部的安全区域高度，即导航栏的高度或者虚拟按键的高度
    //  - 应用程序顶部的工具栏（如 AppBar）的高度
    //  - 应用程序底部的导航栏的高度
    //  - 组件的边框间隔(不一定就是2)
    double screenHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        kBottomNavigationBarHeight -
        2 * 12.sp; // 减的越多，上下空隙越大

    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("运动"),
      ),
      body: buildFixedBody(screenHeight),

      // buildBody(),
    );
  }

  // 可视页面固定等分居中、不可滚动的首页
  buildFixedBody(double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: screenHeight / 4,
            child: buildSmallCoverCard(
              context,
              const TrainingReports(),
              "运动报告",
            ),
          ),
          SizedBox(
            height: screenHeight / 4,
            child: buildCoverCard(
              context,
              const TrainingExercise(),
              "动作",
              "动作库管理模块",
              workoutWomanImageUrl,
            ),
          ),
          SizedBox(
            height: screenHeight / 4,
            child: buildCoverCard(
              context,
              const TrainingWorkouts(),
              "训练",
              "训练组管理模块",
              workoutManImageUrl,
            ),
          ),
          SizedBox(
            height: screenHeight / 4,
            child: buildCoverCard(
              context,
              const TrainingPlans(),
              "计划",
              "计划库管理模块",
              workoutCalendarImageUrl,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建模块首页主体内容(固定宽高，数量不限可滚动)
  buildBody() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50.sp,
                    child: buildSmallCoverCard(
                      context,
                      const TrainingReports(),
                      "运动报告",
                    ),
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
              buildCoverCard(
                context,
                const TrainingExercise(),
                "动作",
                "动作库管理模块",
                workoutWomanImageUrl,
              ),
              buildCoverCard(
                context,
                const TrainingWorkouts(),
                "训练",
                "训练组管理模块",
                workoutManImageUrl,
              ),
              buildCoverCard(
                context,
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
}

buildCard(
  BuildContext context,
  Widget widget,
  String title,
  String subtitle,
  String imageUrl,
) {
  return Card(
    clipBehavior: Clip.hardEdge,
    elevation: 5,
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
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
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
  );
}

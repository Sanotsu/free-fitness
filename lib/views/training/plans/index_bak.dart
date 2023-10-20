import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/utils/global_styles.dart';
import '../workouts/index.dart';
import 'index.dart';

// 动作组和计划还是分成两个页面吧，正好 动作(基础活动Exercise) - 锻炼(动作组 Group,子项Action) - 计划(Plan) 从小到大，也独立且方便

class WorkoutPlans extends StatefulWidget {
  const WorkoutPlans({super.key});

  @override
  State<WorkoutPlans> createState() => _WorkoutPlansState();
}

class _WorkoutPlansState extends State<WorkoutPlans> {
  // 当前tab索引，默认为0
  late int currentTabIndex = 0;

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('WorkoutPlans'),
  //     ),
  //     body: const Center(child: Text('WorkoutPlans index')),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: Container(
          height: kToolbarHeight, // 可以根据需要自定义高度
          color: Colors.blue, // 可以根据需要自定义颜色
          child: TabBar(
            // controller: _tabController,
            // 指示器的样式(标签下的下划线)
            indicator: UnderlineTabIndicator(
              // 下划线的粗度和颜色
              borderSide: BorderSide(
                width: 3.sp,
                color: Colors.white,
              ),
              // 下划线的四边的间距horizontal橫向
              // insets: EdgeInsets.symmetric(horizontal: 2.0.sp),
            ),
            indicatorWeight: 0,
            // 下划线的尺寸(这个label表示下划线执行器的宽度与标签文本宽度一致。默认是整个tab的宽度)
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(child: Text("计划", style: TextStyle(fontSize: sizeHeadline2))),
              Tab(child: Text("锻炼", style: TextStyle(fontSize: sizeHeadline2))),
            ],
          ),
        ),
        appBar: AppBar(
          title: const Text("饮食"),
          // 设置 AppBar 的高度为标准高度 - kTextTabBarHeight，配合PreferredSize 隐藏原本的title位置占位
          // toolbarHeight: kToolbarHeight - kTextTabBarHeight,
          // bottom: PreferredSize(
          //   preferredSize: const Size.fromHeight(kTextTabBarHeight),
          //   child: TabBar(
          //     // controller: _tabController,
          //     // 指示器的样式(标签下的下划线)
          //     indicator: UnderlineTabIndicator(
          //       // 下划线的粗度和颜色
          //       borderSide: BorderSide(
          //         width: 3.sp,
          //         color: Colors.white,
          //       ),
          //       // 下划线的四边的间距horizontal橫向
          //       // insets: EdgeInsets.symmetric(horizontal: 2.0.sp),
          //     ),
          //     indicatorWeight: 0,
          //     // 下划线的尺寸(这个label表示下划线执行器的宽度与标签文本宽度一致。默认是整个tab的宽度)
          //     indicatorSize: TabBarIndicatorSize.label,
          //     tabs: [
          //       Tab(
          //           child:
          //               Text("计划", style: TextStyle(fontSize: sizeHeadline2))),
          //       Tab(
          //           child:
          //               Text("锻炼", style: TextStyle(fontSize: sizeHeadline2))),
          //     ],
          //   ),
          // ),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return const Center(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: TabBarView(
                      // controller: _tabController,
                      children: <Widget>[
                        TrainingWorkouts(),
                        TrainingPlans(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

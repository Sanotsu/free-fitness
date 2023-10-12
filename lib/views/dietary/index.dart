// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/utils/global_styles.dart';

import 'records/index.dart';
import 'reports/index.dart';
import 'settings/index.dart';

class Dietary extends StatefulWidget {
  const Dietary({super.key});

  @override
  State<Dietary> createState() => _DietaryState();
}

class _DietaryState extends State<Dietary> with SingleTickerProviderStateMixin {
  // 当前tab索引，默认为0
  late int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  /// 构建标题工具栏
  _buildAppBar() {
    return AppBar(
      title: const Text("饮食"),
      bottom: TabBar(
        // controller: _tabController,
        // 指示器的样式(标签下的下划线)
        indicator: UnderlineTabIndicator(
          // 下划线的粗度和颜色
          borderSide: BorderSide(
            width: 3.0.sp,
            color: Colors.white,
          ),
          // 下划线的四边的间距horizontal橫向
          // insets: EdgeInsets.symmetric(horizontal: 2.0.sp),
        ),
        indicatorWeight: 0,
        // 下划线的尺寸(这个label表示下划线执行器的宽度与标签文本宽度一致。默认是整个tab的宽度)
        indicatorSize: TabBarIndicatorSize.label,
        tabs: [
          Tab(child: Text("记录", style: TextStyle(fontSize: sizeHeadline2))),
          Tab(child: Text("报告", style: TextStyle(fontSize: sizeHeadline2))),
          Tab(child: Text("设置", style: TextStyle(fontSize: sizeHeadline2))),
        ],
      ),
    );
  }

  /// 构建主体内容（是个 TabBarView）
  _buildBody() {
    return Builder(builder: (BuildContext context) {
      // final TabController tabController = DefaultTabController.of(context);

      return const Center(
        child: Column(
          children: <Widget>[
            Expanded(
              child: TabBarView(
                // controller: _tabController,
                children: <Widget>[
                  DietaryRecords(),
                  DietaryReports(),
                  DietarySettings(),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

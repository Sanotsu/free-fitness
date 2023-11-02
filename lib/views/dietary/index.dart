// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'records/index.dart';
import 'reports/index.dart';
import 'settings/index.dart';

class Dietary extends StatefulWidget {
  const Dietary({super.key});

  @override
  State<Dietary> createState() => _DietaryState();
}

class _DietaryState extends State<Dietary> with SingleTickerProviderStateMixin {
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
        title: const Text("饮食"),
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
              child:
                  _buildCard(const DietaryReports(), "报告", "/dietaryReports"),
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
                  _buildCard(const DietaryRecords(), "日记", "/dietaryRecords"),
                  _buildCard(const DietarySettings(), "我的", "/dietarySettings"),
                  // _buildCard(const DietaryReports(), "训练计划"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildCard(Widget widget, String title, String routeName) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          // 这里需要使用pushName 带上指定的路由名称，后续跨层级popUntil的时候才能指定路由名称进行传参
          Navigator.pushNamed(context, routeName);
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (BuildContext ctx) => widget,
          //   ),
          // );
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

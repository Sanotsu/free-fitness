import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 子组件是带text的容器的卡片
/// 用于显示模块首页一排两列的标题
buildSmallCoverCard(
  BuildContext context,
  Widget widget,
  String title, {
  String? routeName,
}) {
  return Card(
    clipBehavior: Clip.hardEdge,
    child: InkWell(
      splashColor: Colors.blue.withAlpha(30),
      onTap: () {
        if (routeName != null) {
          // 这里需要使用pushName 带上指定的路由名称，后续跨层级popUntil的时候才能指定路由名称进行传参
          Navigator.pushNamed(context, routeName);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext ctx) => widget,
            ),
          );
        }
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

/// 子组件是带listtile和图片的一行row容器的卡片
/// 用于显示模块首页一排一个带封面图的标题
buildCoverCard(
  BuildContext context,
  Widget widget,
  String title,
  String subtitle,
  String imageUrl, {
  String? routeName,
}) {
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
                  if (routeName != null) {
                    // 这里需要使用pushName 带上指定的路由名称，后续跨层级popUntil的时候才能指定路由名称进行传参
                    Navigator.pushNamed(context, routeName);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext ctx) => widget,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

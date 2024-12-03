import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/cus_app_localizations.dart';
import '../utils/tool_widgets.dart';
import '../utils/tools.dart';

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
    elevation: 2.sp,
    child: InkWell(
      onTap: () async {
        bool isGranted = await requestStoragePermission();

        if (!context.mounted) return;
        if (!isGranted) {
          commonExceptionDialog(
            context,
            CusAL.of(context).exceptionWarningTitle,
            "无存储授权",
          );
        }

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
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                subtitle: Text(subtitle),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

///
/// 运动或饮食主页面的入口卡片
///     上面函数式的部件写法
///
class CusCoverCard extends StatelessWidget {
  final Widget targetPage;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? routeName;

  const CusCoverCard({
    super.key,
    required this.targetPage,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 2.sp,
      child: InkWell(
        onTap: () async {
          bool isGranted = await requestStoragePermission();

          if (!context.mounted) return;
          if (!isGranted) {
            commonExceptionDialog(
              context,
              CusAL.of(context).exceptionWarningTitle,
              "无存储授权",
            );
          }

          if (routeName != null) {
            Navigator.pushNamed(context, routeName!);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext ctx) => targetPage,
              ),
            );
          }
        },
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
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  subtitle: Text(subtitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

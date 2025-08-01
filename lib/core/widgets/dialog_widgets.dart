import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../layout/themes/cus_font_size.dart';

/// 弹窗中的关闭按钮
/// 目前在基础运动详情弹窗、动作详情弹窗、动作配置弹窗中可复用
Container buildCloseButton(
  BuildContext context, {
  dynamic popValue, // 需要继续往上pop的数据
}) {
  return Container(
    color: Theme.of(context).canvasColor,
    child: Padding(
      padding: EdgeInsets.only(right: 10.sp),
      child: Align(
        alignment: Alignment.topRight,
        child: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: Theme.of(context).primaryColor,
            size: CusIconSizes.iconBig,
          ),
          onPressed: () {
            Navigator.of(context).pop(popValue); // 关闭弹窗
          },
        ),
      ),
    ),
  );
}

/// 弹窗中的标题部分
/// 主体是个ListTile，但有的地方其title只是显示文本，有的可能会是按钮，所以title部分保留传入部件
/// 目前在基础运动详情弹窗、动作详情弹窗、动作配置弹窗中可复用
Padding buildTitleAndDescription(Widget? title, String subtitle) {
  // color: const Color.fromARGB(255, 239, 243, 244),
  // 2023-12-25 因为有设计深色模式，所以不能固定为白色
  return Padding(
    padding: EdgeInsets.only(bottom: 50.sp), // 添加底部内边距
    child: ListTile(
      title: title,
      // 子标题的运动介绍也可以显示指定多少行，就不用再滚动了
      subtitle: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Text(
          subtitle,
          overflow: TextOverflow.clip, // ellipsis
          // maxLines: 10,
        ),
      ),
      onTap: () {},
    ),
  );
}

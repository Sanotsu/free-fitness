import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../layout/themes/cus_font_size.dart';
import '../../models/training_state.dart';
import '../global/constants.dart';

/// 弹窗中的关闭按钮
/// 目前在基础运动详情弹窗、动作详情弹窗、动作配置弹窗中可复用
buildCloseButton(
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

/// 弹窗中的图片展示
/// 目前在基础运动详情弹窗、动作详情弹窗、动作配置弹窗中可复用
buildImageArea(BuildContext context, Exercise exercise) {
  return Container(
    // 预设的图片背景色一般是白色，所以这里也设置为白色，看起来一致
    // color: Colors.white,
    // 2023-12-25 因为有设计深色模式，所以不能固定为白色
    color: Theme.of(context).canvasColor,
    child: Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 10.sp),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  child: Hero(
                    tag: 'imageTag',
                    child: buildExerciseImageCarouselSlider(exercise),
                  ),
                );
              },
            );
          },
          child: Hero(
            tag: 'imageTag',
            // child: buildExerciseImage(exercise),
            child: buildExerciseImageCarouselSlider(exercise),
          ),
        ),
      ),
    ),
  );
}

/// 弹窗中的标题部分
/// 主体是个ListTile，但有的地方其title只是显示文本，有的可能会是按钮，所以title部分保留传入部件
/// 目前在基础运动详情弹窗、动作详情弹窗、动作配置弹窗中可复用
buildTitleAndDescription(Widget? title, String subtitle) {
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

/// 构建锻炼动作的图片
/// 主要是是否加上相册地址前缀的判断
Image buildExerciseImage(Exercise exercise) {
  var imageUrl = (exercise.images?.split(",")[0] ?? "");
  // 如果是用户上传但路径没有DCIM关键字，就手动拼接前缀
  // 2023-11-29 在json上传的时候存入数据库之前已经拼接过了。
  // if (exercise.isCustom == "true" && !imageUrl.contains("DCIM")) {
  //   imageUrl = cusExImgPre + imageUrl;
  // }

  return Image.file(
    // 预备的时候，肯定显示第一个动作的图片
    File(imageUrl),
    errorBuilder:
        (BuildContext context, Object exception, StackTrace? stackTrace) {
      return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
    },
  );
}

// 锻炼的图片轮播图(后续如果食物的图片或者其他图片有类似功能，可能再抽一次)
buildExerciseImageCarouselSlider(Exercise exercise) {
  List<String> imageList = [];
  // 先要排除image是个空字符串
  if (exercise.images != null && exercise.images!.trim().isNotEmpty) {
    imageList = exercise.images!.split(",");
  }

  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true, // 自动播放
      enlargeCenterPage: true, // 居中图片放大
      aspectRatio: 16 / 9, // 图片宽高比
      viewportFraction: 1, // 图片占屏幕宽度的比例
      // 只有一张图片时不滚动
      enableInfiniteScroll: imageList.length > 1,
    ),
    // 没有图片显示一张占位图片
    items: imageList.isEmpty
        ? [Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown)]
        : imageList.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                  ),
                  child: Image.file(
                    File(imageUrl),
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return Image.asset(placeholderImageUrl,
                          fit: BoxFit.scaleDown);
                    },
                  ),
                );
              },
            );
          }).toList(),
  );
}

// 图片轮播
buildImageCarouselSlider(
  List<String> imageList, {
  bool isNoImage = false, // 是否不显示图片，默认就算无图片也显示占位图片
}) {
  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true, // 自动播放
      enlargeCenterPage: true, // 居中图片放大
      aspectRatio: 16 / 9, // 图片宽高比
      viewportFraction: 1, // 图片占屏幕宽度的比例
      // 只有一张图片时不滚动
      enableInfiniteScroll: imageList.length > 1,
    ),
    // 除非指定不显示图片，否则没有图片也显示一张占位图片
    items: isNoImage
        ? null
        : imageList.isEmpty
            ? [Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown)]
            : imageList.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                      ),
                      child: Image.file(
                        File(imageUrl),
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Image.asset(placeholderImageUrl,
                              fit: BoxFit.scaleDown);
                        },
                      ),
                    );
                  },
                );
              }).toList(),
  );
}

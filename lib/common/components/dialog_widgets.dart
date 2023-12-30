import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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

// 图片轮播
buildImageCarouselSlider(
  List<String> imageList, {
  bool isNoImage = false, // 是否不显示图片，默认就算无图片也显示占位图片
  int type = 3, // 轮播图是否可以点击预览图片，预设为3(具体类型参看下方实现方法)
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
                    return _buildImageCarouselSliderType(
                      type,
                      context,
                      imageUrl,
                      imageList,
                    );
                  },
                );
              }).toList(),
  );
}

/// 2023-12-26
/// 现在设计轮播图3种形态:
///   1 点击某张图片，可以弹窗显示该图片并进行缩放预览
///   2 点击某张图片，可以跳转新页面对该图片并进行缩放预览
///   3 点击某张图片，可以弹窗对该图片所在整个列表进行缩放预览(默认选项)
///   default 单纯的轮播展示,点击图片无动作
_buildImageCarouselSliderType(
  int type,
  BuildContext context,
  String imageUrl,
  List<String> imageList,
) {
  buildChildImage() => Image.file(
        File(imageUrl),
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) =>
                Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown),
      );

  buildCommonImageWidget(Function() onTap) =>
      GestureDetector(onTap: onTap, child: buildChildImage());

  switch (type) {
    // 这个直接弹窗显示图片可以缩放
    case 1:
      return buildCommonImageWidget(() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent, // 设置背景透明
              child: PhotoView(
                imageProvider: FileImage(File(imageUrl)),
                // 设置图片背景为透明
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                // 可以旋转
                enableRotation: true,
                // 缩放的最大最小限制
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
            );
          },
        );
      });
    case 2:
      return buildCommonImageWidget(() {
        // 这个是跳转到新的页面去
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoView(
              imageProvider: FileImage(File(imageUrl)),
              enableRotation: true,
            ),
          ),
        );
      });
    case 3:
      return buildCommonImageWidget(() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            // 这个弹窗默认是无法全屏的，上下左右会留点空，点击这些空隙可以关闭弹窗
            return Dialog(
              backgroundColor: Colors.transparent,
              child: PhotoViewGallery.builder(
                itemCount: imageList.length,
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: FileImage(File(imageList[index])),
                  );
                },
                // enableRotation: true,
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                loadingBuilder: (BuildContext context, ImageChunkEvent? event) {
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            );
          },
        );
      });
    default:
      return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: const BoxDecoration(color: Colors.grey),
        child: buildChildImage(),
      );
  }
}

buildImageCarouselSliderTypeOld(
  int type,
  BuildContext context,
  String imageUrl,
  List<String> imageList,
) {
  if (type == 1) {
    return GestureDetector(
      onTap: () {
        // 这个直接弹窗显示图片可以缩放
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent, // 设置背景透明
              child: PhotoView(
                imageProvider: FileImage(File(imageUrl)),
                // 设置图片背景为透明
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                // 可以旋转
                enableRotation: true,
                // 缩放的最大最小限制
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
            );
          },
        );
      },
      child: Image.file(
        File(imageUrl),
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
        },
      ),
    );
  } else if (type == 2) {
    return GestureDetector(
      onTap: () {
        // 这个是跳转到新的页面去
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoView(
              imageProvider: FileImage(File(imageUrl)),
            ),
          ),
        );
      },
      child: Image.file(
        File(imageUrl),
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
        },
      ),
    );
  } else if (type == 3) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            // 这个弹窗默认是无法全屏的，上下左右会留点空，点击这些空隙可以关闭弹窗
            return Dialog(
              backgroundColor: Colors.transparent, // 设置背景透明
              child: PhotoViewGallery.builder(
                itemCount: imageList.length,
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: FileImage(
                      File(imageList[index]),
                    ),
                  );
                },
                enableRotation: true,
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                loadingBuilder: (BuildContext context, ImageChunkEvent? event) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            );
          },
        );
      },
      child: Image.file(
        File(imageUrl),
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return Image.asset(
            placeholderImageUrl,
            fit: BoxFit.scaleDown,
          );
        },
      ),
    );
  } else {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: const BoxDecoration(
        color: Colors.grey,
      ),
      child: Image.file(
        File(imageUrl),
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
        },
      ),
    );
  }
}

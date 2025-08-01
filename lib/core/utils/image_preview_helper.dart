import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../constants/constants.dart';

/// 图片预览帮助
/// 各种图片预览相关的方法

/// 轮播图交互类型
enum CarouselType {
  none, // 无动作 - 单纯的轮播展示,点击图片无动作
  dialog, // 类型1 - 点击弹窗显示单张图片预览
  page, // 类型2 - 点击跳转新页面显示单张图片预览
  gallery, // 类型3 - 点击弹窗显示图片画廊(默认)
}

///
/// 构建图片轮播组件，仅仅轮播+单张点击预览，没有其他内容
///
Widget buildImageViewCarouselSlider(
  List<String> imageList, {
  double? aspectRatio,
}) {
  // 如果没有图片，显示占位图片
  final effectiveImages = imageList.isEmpty ? [placeholderImageUrl] : imageList;

  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true, // 自动播放
      enlargeCenterPage: true, // 居中图片放大
      aspectRatio: aspectRatio ?? 16 / 9, // 图片宽高比
      viewportFraction: 1, // 图片占屏幕宽度的比例
      // 只有一张图片时不滚动
      enableInfiniteScroll: effectiveImages.length > 1,
    ),
    items: effectiveImages.map((imageUrl) {
      return Builder(
        builder: (context) => GestureDetector(
          // 不是占位图片才可以点击图片进行预览
          onTap: imageUrl == placeholderImageUrl
              ? null
              : () => _handleImageTap(
                  context,
                  imageUrl,
                  effectiveImages,
                  CarouselType.dialog,
                ),
          child: buildNetworkOrFileImage(imageUrl, fit: BoxFit.cover),
        ),
      );
    }).toList(),
  );
}

///
/// 构建图片轮播组件
///
Widget buildImageCarouselSlider(
  List<String> imageList, {
  bool showPlaceholder = true, // 无图片时是否显示占位图
  CarouselType type = CarouselType.gallery, // 轮播图交互类型
  double? aspectRatio,
}) {
  final items = _buildCarouselItems(
    imageList,
    // 除非指定不显示图片，否则没有图片也显示一张占位图片
    showPlaceholder: showPlaceholder,
    type: type,
  );

  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true, // 自动播放
      enlargeCenterPage: true, // 居中图片放大
      aspectRatio: aspectRatio ?? 16 / 9, // 图片宽高比
      viewportFraction: 1, // 图片占屏幕宽度的比例
      // 只有一张图片时不滚动
      enableInfiniteScroll: imageList.length > 1,
    ),
    items: items,
  );
}

/// 构建轮播图子项
List<Widget>? _buildCarouselItems(
  List<String> imageList, {
  required bool showPlaceholder,
  required CarouselType type,
}) {
  if (!showPlaceholder && imageList.isEmpty) return null;

  final effectiveImages = imageList.isEmpty ? [placeholderImageUrl] : imageList;

  return effectiveImages.map((imageUrl) {
    return Builder(
      builder: (context) =>
          _buildCarouselItem(context, imageUrl, imageList, type: type),
    );
  }).toList();
}

/// 构建单个轮播图项
Widget _buildCarouselItem(
  BuildContext context,
  String imageUrl,
  List<String> imageList, {
  required CarouselType type,
}) {
  return GestureDetector(
    onTap: () => _handleImageTap(context, imageUrl, imageList, type),

    child: buildNetworkOrFileImage(imageUrl),
  );
}

/// 处理图片点击事件
void _handleImageTap(
  BuildContext context,
  String imageUrl,
  List<String> imageList,
  CarouselType type,
) {
  switch (type) {
    case CarouselType.dialog:
      showDialog(
        context: context,
        builder: (_) => _buildPhotoDialog(getImageProvider(imageUrl)),
      );
      break;
    case CarouselType.page:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _buildPhotoView(getImageProvider(imageUrl)),
        ),
      );
      break;
    case CarouselType.gallery:
      showDialog(
        context: context,
        builder: (_) => _buildPhotoGalleryDialog(imageList),
      );
      break;
    case CarouselType.none:
      break;
  }
}

/// 构建图片弹窗对话框（相册和单个图片预览都有用到）
Widget _buildPhotoDialog(ImageProvider imageProvider) {
  return Dialog(
    backgroundColor: Colors.transparent,
    child: _buildPhotoView(imageProvider),
  );
}

/// 构建图片画廊弹窗
Widget _buildPhotoGalleryDialog(List<String> imageList) {
  // 这个弹窗默认是无法全屏的，上下左右会留点空，点击这些空隙可以关闭弹窗
  return Dialog(
    backgroundColor: Colors.transparent,
    child: PhotoViewGallery.builder(
      itemCount: imageList.length,
      builder: (context, index) => PhotoViewGalleryPageOptions(
        imageProvider: getImageProvider(imageList[index]),
        errorBuilder: (_, _, _) => const Icon(Icons.error),
      ),
      scrollPhysics: const BouncingScrollPhysics(),
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      loadingBuilder: (_, _) =>
          const Center(child: CircularProgressIndicator()),
    ),
  );
}

/// 构建图片查看视图
Widget _buildPhotoView(
  ImageProvider imageProvider, {
  bool enableRotation = true,
}) {
  return PhotoView(
    imageProvider: imageProvider,
    // 设置图片背景为透明
    backgroundDecoration: const BoxDecoration(color: Colors.transparent),
    // 可以旋转
    enableRotation: enableRotation,
    // 缩放的最大最小限制
    minScale: PhotoViewComputedScale.contained * 0.8,
    maxScale: PhotoViewComputedScale.covered * 2,
    errorBuilder: (_, _, _) => const Icon(Icons.error),
  );
}

/// 获取图片提供者(暂时这3种)
ImageProvider getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http')) {
    return CachedNetworkImageProvider(imageUrl);
  } else if (imageUrl.startsWith('assets')) {
    return AssetImage(imageUrl);
  } else {
    return FileImage(File(imageUrl));
  }
}

///
/// 构建网络或本地图片组件
/// 用到的地方较多
///
Widget buildNetworkOrFileImage(String imageUrl, {BoxFit? fit}) {
  if (imageUrl.startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      // progressIndicatorBuilder: (context, url, progress) => Center(
      //   child: CircularProgressIndicator(
      //     value: progress.progress,
      //   ),
      // ),

      /// placeholder 和 progressIndicatorBuilder 只能2选1
      placeholder: (_, _) => const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      ),
      errorWidget: (_, _, _) => const Icon(Icons.error, size: 36),
    );
  } else {
    return Image(
      image: getImageProvider(imageUrl),
      fit: fit,
      errorBuilder: (_, _, _) =>
          Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown),
    );
  }
}

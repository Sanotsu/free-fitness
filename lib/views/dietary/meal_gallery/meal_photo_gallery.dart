import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/common/global/constants.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/dietary_state.dart';

class MealPhotoGallery extends StatefulWidget {
  const MealPhotoGallery({super.key});

  @override
  State<MealPhotoGallery> createState() => _MealPhotoGalleryState();
}

class _MealPhotoGalleryState extends State<MealPhotoGallery> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  // 一次只查询10张图片数据
  List<MealPhoto> photoItems = [];
  int currentPage = 1;
  int pageSize = 10;
  bool isLoading = false;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMealPhotoData();

    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (isLoading) return;

    final maxScrollExtent = scrollController.position.maxScrollExtent;
    final currentPosition = scrollController.position.pixels;
    final delta = 50.0.sp;

    if (maxScrollExtent - currentPosition <= delta) {
      _loadMealPhotoData();
    }
  }

  // 查询图片列表数据
  Future<void> _loadMealPhotoData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    var temp = await _dietaryHelper.queryMealPhotoList(
      CacheUser.userId,
      page: currentPage,
      pageSize: pageSize,
      dateSort: "DESC",
    );

    setState(() {
      photoItems.addAll(temp);
      currentPage++;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食相册'),
      ),
      body: (photoItems.isNotEmpty)
          ? ListView.builder(
              itemCount: photoItems.length + 1,
              itemBuilder: (context, index) {
                if (index == photoItems.length) {
                  return buildLoader(isLoading);
                } else {
                  return _buildMealPhotoCard(photoItems[index]);
                }
              },
              controller: scrollController,
            )
          : const Center(child: Text("暂未上传任何餐次食物照片")),
    );
  }

  _buildMealPhotoCard(MealPhoto mp) {
    if (mp.photos.trim().isEmpty) {
      return Container();
    }

    var photoList = mp.photos.split(",");
    if (photoList.isNotEmpty) {
      return Card(
        elevation: 5,
        child: Column(
          children: [
            ListTile(
              title: Text("${mp.date} "),
              subtitle: Text("${mp.mealCategory} "),
            ),
            buildImageCarouselSlider(photoList),
          ],
        ),
      );
    }
  }
}

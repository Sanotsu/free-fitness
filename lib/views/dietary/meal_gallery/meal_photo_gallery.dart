import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/common/global/constants.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/dietary_state.dart';
import '../records/save_meal_photo.dart';

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
        title: Text(CusAL.of(context).mealGallery),
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
          : Center(child: Text(CusAL.of(context).noRecordNote)),
    );
  }

  _buildMealPhotoCard(MealPhoto mp) {
    if (mp.photos.trim().isEmpty) {
      return Container();
    }

    List<String> photoList =
        mp.photos.trim().isNotEmpty ? mp.photos.trim().split(",") : [];

    // 数据库中存的餐次信息是英文标签，但显示时则需要按当前语言显示
    // 理论上是一定找得到一个符合条件的

    var temp = mealtimeList.firstWhere((e) => e.enLabel == mp.mealCategory);

    if (photoList.isNotEmpty) {
      return Card(
        elevation: 5,
        child: Column(
          children: [
            SizedBox(height: 10.sp),
            ListTile(
              title: Text(mp.date),
              subtitle: Text(
                '[${showCusLable(temp)}] ${photoList.length} ${CusAL.of(context).photoUnitLabel}',
              ),
              trailing: TextButton(
                onPressed: () {
                  handleImageAnalysis(context, photoList);
                },
                child: Text(
                  box.read('language') == "en" ? "AI analysis" : 'AI分析',
                ),
              ),
            ),
            buildImageCarouselSlider(photoList),
            SizedBox(height: 10.sp),
          ],
        ),
      );
    }
  }
}

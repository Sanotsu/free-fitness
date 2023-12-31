// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/components/cus_cards.dart';
import '../../common/global/constants.dart';
import '../../models/cus_app_localizations.dart';
import 'foods/index.dart';
import 'meal_gallery/meal_photo_gallery.dart';
import 'records/index.dart';
import 'reports/index.dart';

class Dietary extends StatefulWidget {
  const Dietary({super.key});

  @override
  State<Dietary> createState() => _DietaryState();
}

class _DietaryState extends State<Dietary> {
  @override
  Widget build(BuildContext context) {
    // 计算屏幕剩余的高度
    double screenHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        kBottomNavigationBarHeight -
        2 * 12.sp; // 减的越多，上下空隙越大

    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(CusAL.of(context).dietary),
      ),
      body: buildFixedBody(screenHeight),
    );
  }

  /// 可视页面固定等分居中、不可滚动的首页
  buildFixedBody(double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SizedBox(
          //   height: screenHeight / 4,
          //   child: buildSmallCoverCard(
          //     context,
          //     const DietaryReports(),
          //     CusAL.of(context).dietaryReports,
          //   ),
          // ),
          Expanded(
            child: SizedBox(
              height: screenHeight / 4,
              child: buildCoverCard(
                context,
                const DietaryReports(),
                CusAL.of(context).dietaryReports,
                CusAL.of(context).dietaryReportsSubtitle,
                reportImageUrl,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: screenHeight / 4,
              child: buildCoverCard(
                context,
                const DietaryFoods(),
                CusAL.of(context).foodCompo,
                CusAL.of(context).foodCompoSubtitle,
                dietaryNutritionImageUrl,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: screenHeight / 4,
              child: buildCoverCard(
                context,
                const MealPhotoGallery(),
                CusAL.of(context).mealGallery,
                CusAL.of(context).mealGallerySubtitle,
                dietaryMealImageUrl,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: screenHeight / 4,
              child: buildCoverCard(
                context,
                const DietaryRecords(),
                CusAL.of(context).dietaryRecords,
                CusAL.of(context).dietaryRecordsSubtitle,
                dietaryLogCoverImageUrl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

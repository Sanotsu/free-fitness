import 'package:flutter/material.dart';

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
    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(CusAL.of(context).dietary)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: CusCoverCard(
              targetPage: const DietaryReports(),
              title: CusAL.of(context).dietaryReports,
              subtitle: CusAL.of(context).dietaryReportsSubtitle,
              imageUrl: reportImageUrl,
            ),
          ),
          Expanded(
            child: CusCoverCard(
              targetPage: const DietaryFoods(),
              title: CusAL.of(context).foodCompo,
              subtitle: CusAL.of(context).foodCompoSubtitle,
              imageUrl: dietaryNutritionImageUrl,
            ),
          ),
          Expanded(
            child: CusCoverCard(
              targetPage: const MealPhotoGallery(),
              title: CusAL.of(context).mealGallery,
              subtitle: CusAL.of(context).mealGallerySubtitle,
              imageUrl: dietaryMealImageUrl,
            ),
          ),
          Expanded(
            child: CusCoverCard(
              targetPage: const DietaryRecords(),
              title: CusAL.of(context).dietaryRecords,
              subtitle: CusAL.of(context).dietaryRecordsSubtitle,
              imageUrl: dietaryLogCoverImageUrl,
            ),
          ),
        ],
      ),
    );
  }
}

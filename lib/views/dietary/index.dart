// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/components/cus_cards.dart';
import '../../common/global/constants.dart';
import '../me/user_gallery/meal_photo_gallery.dart';
import 'foods/index.dart';
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
        title: const Text("饮食"),
      ),
      body: buildFixedBody(screenHeight),
      //  _buildBody(),
    );
  }

  /// 可视页面固定等分居中、不可滚动的首页
  buildFixedBody(double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: screenHeight / 4,
            child: buildSmallCoverCard(
              context,
              const DietaryReports(),
              "饮食报告",
            ),
          ),
          SizedBox(
            height: screenHeight / 4,
            child: buildCoverCard(
              context,
              const DietaryFoods(),
              "食物成分",
              "中国食物营养成分标准",
              dietaryNutritionImageUrl,
            ),
          ),
          SizedBox(
            height: screenHeight / 4,
            child: buildCoverCard(
              context,
              const DietaryRecords(),
              "饮食日记",
              "每日饮食记录数据管理",
              dietaryLogCoverImageUrl,
            ),
          ),
          SizedBox(
            height: screenHeight / 4,
            child: buildCoverCard(
              context,
              const MealPhotoGallery(),
              "饮食相册",
              "浏览已有餐点食物照片",
              dietaryMealImageUrl,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主体内容(是个 GridView)
  ///
  buildBody() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50.sp,
                    child: buildSmallCoverCard(
                      context,
                      const DietaryReports(),
                      "饮食报告",
                    ),
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            // 不加这一行，gridView放在另一个滚动组件中会报错
            shrinkWrap: true,
            // 禁用外部滚动视图的滚动(不加这一行，触碰到gridview的区域就无法滚动)
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 1, // 每一行的数量
            padding: EdgeInsets.all(20.sp), // 内边框
            crossAxisSpacing: 10.0, // 主轴间间隔
            mainAxisSpacing: 10.0, // 交叉轴间隔
            childAspectRatio: 3, // 子组件的宽高比
            children: <Widget>[
              buildCoverCard(
                context,
                const DietaryRecords(),
                "饮食日记",
                "每日饮食记录数据管理",
                dietaryLogCoverImageUrl,
              ),
              buildCoverCard(
                context,
                const DietaryFoods(),
                "食物成分",
                "中国食物营养成分标准",
                dietaryNutritionImageUrl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

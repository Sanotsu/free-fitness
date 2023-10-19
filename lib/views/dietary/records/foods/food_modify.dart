// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/utils/sqlite_db_helper.dart';
import '../../../../models/dietary_state.dart';

class FoodModify extends StatefulWidget {
  const FoodModify({super.key});

  @override
  State<FoodModify> createState() => _FoodModifyState();
}

class _FoodModifyState extends State<FoodModify> {
  TextEditingController foodNameController = TextEditingController();
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  void _handleSave() async {
    String newFood = foodNameController.text;

    var res = await _addFoodDemo();

    print("res----------$res");

    if (!mounted) return;
    if (newFood.isNotEmpty) {
      Navigator.pop(context, newFood);
    }
  }

  _addFoodDemo() async {
    // _dietaryHelper.deleteDb();
    // return;
    // var dfood = Food(brand: "重庆", product: '豆豉鲮鱼');
    var dfood = Food(brand: "永川", product: '黄瓜');

    // 输入公制单位营养素
    var dserving = ServingInfo(
      energy: 4190,
      foodId: 1, // 这个id会在insert语句中被成功插入的food的id替代
      metricServingSize: 100,
      metricServingUnit: "克",
      isMetric: true,
      protein: 23.5,
      totalFat: 12.3,
      totalCarbohydrate: 45.5,
      sodium: 123,
    );

    // 输入公制单位营养素
    // var dserving2 = ServingInfo(
    //   energy: 4190,
    //   foodId: 1, // 这个id会在insert语句中被成功插入的food的id替代
    //   servingSize: '一条尾钩鱼',
    //   metricServingSize: 200,
    //   metricServingUnit: "克",
    //   isMetric: false,
    //   protein: 23.5,
    //   totalFat: 12.3,
    //   totalCarbohydrate: 45.5,
    //   sodium: 123,
    // );

    int ret = await _dietaryHelper.insertFoodWithServingInfo(dfood, dserving);
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food Name:',
              style: TextStyle(fontSize: 16.sp),
            ),
            TextField(
              controller: foodNameController,
            ),
            SizedBox(height: 16.sp),
            ElevatedButton(
              onPressed: _handleSave,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

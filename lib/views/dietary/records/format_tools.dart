// 格式化带营养素详情的饮食记录条目数据列表
import 'package:flutter/material.dart';

import '../../../common/global/constants.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/dietary_state.dart';

List<CusNutrientInfo> formatIntakeItemListForMarker(
  BuildContext context,
  List<DailyFoodItemWithFoodServing> list,
) {
  var tempEnergy = 0.0;
  var tempProtein = 0.0;
  var tempFat = 0.0;
  var tempCHO = 0.0;
  // 这几个在底部总计可能用到
  var tempSodium = 0.0;
  var tempCholesterol = 0.0;
  var tempDietaryFiber = 0.0;
  var tempPotassium = 0.0;
  var tempSugar = 0.0;

  for (var e in list) {
    var foodIntakeSize = e.dailyFoodItem.foodIntakeSize;
    var servingInfo = e.servingInfo;
    tempEnergy += foodIntakeSize * servingInfo.energy;
    tempProtein += foodIntakeSize * servingInfo.protein;
    tempFat += foodIntakeSize * servingInfo.totalFat;
    tempCHO += foodIntakeSize * servingInfo.totalCarbohydrate;
    tempSodium += foodIntakeSize * servingInfo.sodium;
    tempCholesterol += foodIntakeSize * (servingInfo.cholesterol ?? 0);
    tempDietaryFiber += foodIntakeSize * (servingInfo.dietaryFiber ?? 0);
    tempPotassium += foodIntakeSize * (servingInfo.potassium ?? 0);
    tempSugar += foodIntakeSize * (servingInfo.sugar ?? 0);
  }

  var tempCalories = tempEnergy / oneCalToKjRatio;

  // 当日主要营养素表格数据
  return [
    CusNutrientInfo(
      label: "calorie",
      value: tempCalories,
      color: cusNutrientColors[CusNutType.calorie]!,
      name: CusAL.of(context).mainNutrients('1'),
      unit: CusAL.of(context).unitLabels('2'),
    ),
    CusNutrientInfo(
      label: "energy",
      value: tempEnergy,
      color: cusNutrientColors[CusNutType.energy]!,
      name: CusAL.of(context).mainNutrients('0'),
      unit: CusAL.of(context).unitLabels('3'),
    ),
    CusNutrientInfo(
      label: "protein",
      value: tempProtein,
      color: cusNutrientColors[CusNutType.protein]!,
      name: CusAL.of(context).mainNutrients('2'),
      unit: CusAL.of(context).unitLabels('0'),
    ),
    CusNutrientInfo(
      label: "fat",
      value: tempFat,
      color: cusNutrientColors[CusNutType.totalFat]!,
      name: CusAL.of(context).mainNutrients('3'),
      unit: CusAL.of(context).unitLabels('0'),
    ),
    CusNutrientInfo(
      label: "cho",
      value: tempCHO,
      color: cusNutrientColors[CusNutType.totalCHO]!,
      name: CusAL.of(context).mainNutrients('4'),
      unit: CusAL.of(context).unitLabels('0'),
    ),
    CusNutrientInfo(
      label: "dietaryFiber",
      value: tempDietaryFiber,
      color: cusNutrientColors[CusNutType.dietaryFiber]!,
      name: CusAL.of(context).choNutrients('2'),
      unit: CusAL.of(context).unitLabels('0'),
    ),
    CusNutrientInfo(
      label: "sugar",
      value: tempSugar,
      color: cusNutrientColors[CusNutType.sugar]!,
      name: CusAL.of(context).choNutrients('1'),
      unit: CusAL.of(context).unitLabels('0'),
    ),
    CusNutrientInfo(
      label: "sodium",
      value: tempSodium,
      color: cusNutrientColors[CusNutType.sodium]!,
      name: CusAL.of(context).microNutrients('0'),
      unit: CusAL.of(context).unitLabels('1'),
    ),
    CusNutrientInfo(
      label: "cholesterol",
      value: tempCholesterol,
      color: cusNutrientColors[CusNutType.cholesterol]!,
      name: CusAL.of(context).microNutrients('2'),
      unit: CusAL.of(context).unitLabels('1'),
    ),
    CusNutrientInfo(
      label: "potassium",
      value: tempPotassium,
      color: cusNutrientColors[CusNutType.potassium]!,
      name: CusAL.of(context).microNutrients('1'),
      unit: CusAL.of(context).unitLabels('1'),
    ),
  ];
}

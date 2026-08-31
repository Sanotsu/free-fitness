import '../../../core/constants/constants.dart';
import '../../../core/utils/tools.dart';
import '../../../models/dietary_state.dart';

/// 2026-08-28 饮食摄入业务数据的指纹(纯数据，不含 prompt 模板文案)
///
/// 以条目关键字段(食物id/餐次/摄入量/份量单位，按展示顺序)为基准；
/// 营养素汇总图由条目派生不重复纳入；食物改名不影响指纹(分析数据未变)。
String buildDietIntakeDataHash(List<DailyFoodItemWithFoodServing> dfiwfsList) {
  var sb = StringBuffer('d');
  for (var e in dfiwfsList) {
    sb.write('|${e.dailyFoodItem.foodId}');
    sb.write(':${e.dailyFoodItem.mealCategory}');
    sb.write(':${e.dailyFoodItem.foodIntakeSize}');
    sb.write(':${e.servingInfo.servingUnit}');
  }
  return fnv1a64Hash(sb.toString());
}

/// 2026-08-27 饮食日记摄入分析的 prompt 构建(自 records/index.dart 的
/// buildSuggestionString 迁移，逻辑保持一致)
String buildDietIntakePrompt(
  List<DailyFoodItemWithFoodServing> dfiwfsList,
  List<CusNutrientInfo> mainNutrientsChartData,
) {
  var str = box.read('language') == 'en'
      ? """Please analyze my food intake today, provide effective healthy dietary recommendations, and arrange improved quantitative recipes.
        \n\nThis is my main food intake for today:\n"""
      : "请根据我今天的食物摄入做出分析，给出有效的健康饮食建议，安排改善后的量化食谱。\n\n这是我今天的主要食物摄入量:\n";

  for (var e in dfiwfsList) {
    var temp = mealtimeList.firstWhere(
      (m) => m.enLabel == e.dailyFoodItem.mealCategory,
    );

    str += """  - [${showCusLable(temp)}] ${e.food.product}
               ${e.dailyFoodItem.foodIntakeSize} x ${e.servingInfo.servingUnit}\n""";
  }

  str += box.read('language') == 'en'
      ? "\nThis is my main nutrient intake for today:\n"
      : "\n这是我今天的主要营养素摄入量:\n";

  for (var e in mainNutrientsChartData) {
    str += "  - ${e.name} ${e.value.toStringAsFixed(2)} ${e.unit}\n";
  }

  return str;
}

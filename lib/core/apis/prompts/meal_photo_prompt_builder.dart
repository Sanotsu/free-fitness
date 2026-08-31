import '../../../core/constants/constants.dart';

/// 2026-08-27 餐食照片分析的 prompt 构建
/// (自 save_meal_photo.dart 的 navigateToOneChatScreen 迁移，逻辑保持一致；
/// 现在支持最多4张图片，提示语相应调整)
String buildMealPhotoPrompt({String? mealCategoryLabel}) {
  var prefix = mealCategoryLabel == null || mealCategoryLabel.isEmpty
      ? ""
      : "[$mealCategoryLabel]";

  return box.read('language') == 'en'
      ? """$prefix Please analyze the given pictures and answer each of the following questions.
         \n\n - Please list the foods in the pictures and estimate the number of servings (in grams) of each food. If the food items are not present, answer truthfully; 
         \n\n - Analyze the nutritional composition of the meal in the picture, whether it is reasonably balanced and healthy;.
         \n\n - Optimize the proportions of the food provided in the picture to achieve nutritional balance."""
      : """$prefix 请分析给出的图片，分别回答以下问题:
         \n\n - 请列出图片中的食物，并预估每种食物的份量(单位：克)。如果不存在食物，请如实回答;
         \n\n - 分析图中这顿饭的营养搭配，是否合理均衡，是否健康;
         \n\n - 优化图片提供食物的比例，达到营养均衡。""";
}

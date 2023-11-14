import 'package:flutter/material.dart';

import '../../models/training_state.dart';

// 1 大卡 = 4.184 千焦
const double oneCalToKjRatio = 4.18400;

// 常量声明的示例,上面那种单个变量或者这种class
class LocalStorageKey {
  // add a private constructor to prevent this class being instantiated
  // e.g. invoke `LocalStorageKey()` accidentally
  LocalStorageKey._();

  // the properties are static so that we can use them without a class instance
  // e.g. can be retrieved by `LocalStorageKey.saveUserId`.
  static const String saveUserId = 'save_user_id';
  static const String userId = 'user_id';
  static const String language = 'language';
  static const String themeMode = 'theme_mode';
  static const String enablePushNotification = 'enable_push_notification';
}

/// 基础活动的一些分类选项
/// 来源： https://lite.datasette.io/?json=https://github.com/yuhonas/free-exercise-db/blob/main/dist/exercises.json#/data/exercises?_facet=force
List<ExerciseDefaultOption> mechanicOptions = [
  ExerciseDefaultOption(label: "孤立动作", value: 'isolation'),
  ExerciseDefaultOption(label: "复合动作", value: 'compound'),
];

List<ExerciseDefaultOption> forceOptions = [
  ExerciseDefaultOption(label: "拉", value: 'pull'),
  ExerciseDefaultOption(label: "推", value: 'push'),
  ExerciseDefaultOption(label: "静", value: 'static'),
];

List<ExerciseDefaultOption> levelOptions = [
  ExerciseDefaultOption(label: "初级", value: 'beginner'),
  ExerciseDefaultOption(label: "中级", value: 'intermediate'),
  ExerciseDefaultOption(label: "专家", value: 'expert'),
];

List<ExerciseDefaultOption> categoryOptions = [
  ExerciseDefaultOption(label: "力量", value: 'strength'),
  ExerciseDefaultOption(label: "拉伸", value: 'stretching'),
  ExerciseDefaultOption(label: "肌肉增强", value: 'plyometrics'),
  ExerciseDefaultOption(label: "力量举重", value: 'powerlifting'),
  ExerciseDefaultOption(label: "大力士", value: 'strongman'),
  ExerciseDefaultOption(label: "有氧", value: 'cardio'),
  ExerciseDefaultOption(label: "无氧", value: 'anaerobic'),
];

List<ExerciseDefaultOption> equipmentOptions = [
  ExerciseDefaultOption(label: "无器械", value: 'body'),
  ExerciseDefaultOption(label: "杠铃", value: 'barbell'),
  ExerciseDefaultOption(label: "哑铃", value: 'dumbbell'),
  ExerciseDefaultOption(label: "缆绳", value: 'cable'),
  ExerciseDefaultOption(label: "壶铃", value: 'kettlebells'),
  ExerciseDefaultOption(label: "健身带", value: 'bands'),
  ExerciseDefaultOption(label: "健身实心球", value: 'medicine ball'),
  ExerciseDefaultOption(label: "健身球", value: 'exercise ball'),
  ExerciseDefaultOption(label: "泡沫辊", value: 'foam roll'),
  ExerciseDefaultOption(label: "e-z卷曲棒", value: 'e-z curl bar'),
  ExerciseDefaultOption(label: "机器", value: 'machine'),
  ExerciseDefaultOption(label: "其他", value: 'other'),
];

List<ExerciseDefaultOption> standardDurationOptions = [
  ExerciseDefaultOption(label: "1 秒", value: '1'),
  ExerciseDefaultOption(label: "2 秒", value: '2'),
  ExerciseDefaultOption(label: "3 秒", value: '3'),
  ExerciseDefaultOption(label: "4 秒", value: '4'),
  ExerciseDefaultOption(label: "5 秒", value: '5'),
  ExerciseDefaultOption(label: "6 秒", value: '6'),
  ExerciseDefaultOption(label: "7 秒", value: '7'),
  ExerciseDefaultOption(label: "8 秒", value: '8'),
  ExerciseDefaultOption(label: "9 秒", value: '9'),
  ExerciseDefaultOption(label: "10 秒", value: '10'),
];

final List<ExerciseDefaultOption> musclesOptions = [
  ExerciseDefaultOption(label: "四头肌", value: 'quadriceps'),
  ExerciseDefaultOption(label: "肩膀", value: 'shoulders'),
  ExerciseDefaultOption(label: "腹肌", value: 'abdominals'),
  ExerciseDefaultOption(label: "胸部", value: 'chest'),
  ExerciseDefaultOption(label: "腘绳肌腱", value: 'hamstrings'),
  ExerciseDefaultOption(label: "三头肌", value: 'triceps'),
  ExerciseDefaultOption(label: "二头肌", value: 'biceps'),
  ExerciseDefaultOption(label: "背阔肌", value: 'lats'),
  ExerciseDefaultOption(label: "中背", value: 'middle back'),
  ExerciseDefaultOption(label: "小腿肌", value: 'calves'),
  ExerciseDefaultOption(label: "下背肌肉", value: 'lower back'),
  ExerciseDefaultOption(label: "前臂", value: 'forearms'),
  ExerciseDefaultOption(label: "臀肌", value: 'glutes'),
  ExerciseDefaultOption(label: "斜方肌", value: 'trapezius'),
  ExerciseDefaultOption(label: "内收肌", value: 'adductors'),
  ExerciseDefaultOption(label: "展肌", value: 'abductors'),
  ExerciseDefaultOption(label: "脖子", value: 'neck'),
];

// 一日三餐餐次名称关键字，避免直接使用魔法阵

enum Mealtimes {
  breakfast,
  lunch,
  dinner,
  other,
}

// 这个标识名称和值的类，在下拉选择框中可以通用，Mealtimes换为 dynamic 即可
class CusDropdownOption {
  final String label;
  final dynamic value;
  final String? name;

  CusDropdownOption({
    required this.label,
    required this.value,
    this.name,
  });
}

// 下拉选择框使用的餐次信息(用的这个，显示更方便)
List<CusDropdownOption> mealtimeList = [
  CusDropdownOption(label: "breakfast", name: "早餐", value: Mealtimes.breakfast),
  CusDropdownOption(label: "lunch", name: "午餐", value: Mealtimes.lunch),
  CusDropdownOption(label: "dinner", name: "晚餐", value: Mealtimes.dinner),
  CusDropdownOption(label: "other", name: "小食", value: Mealtimes.other),
];

// 新增食物营养素选择单位时使用
List<CusDropdownOption> servingTypeList = [
  CusDropdownOption(
    label: "100ml/100g",
    name: "100毫升/100克",
    value: "metric",
  ),
  CusDropdownOption(
    label: "1 serving( e.g. 1 glass, 1 piece)",
    name: "1 份(勺/杯/块 等)",
    value: "custom",
  ),
];

// 食物营养素列表(中文名，英文名对照，方便格式化展示之类的)
List<CusDropdownOption> nutrientList = [
  CusDropdownOption(value: "energy", name: "能量", label: "energy"),
  CusDropdownOption(value: "protein", name: "蛋白质", label: "protein"),
  CusDropdownOption(value: "total_fat", name: "总脂肪", label: "totalFat"),
  CusDropdownOption(
    value: "saturated_fat",
    name: "饱和脂肪",
    label: "saturatedFat",
  ),
  CusDropdownOption(value: "trans_fat", name: "反式脂肪", label: "transFat"),
  CusDropdownOption(
    value: "polyunsaturated_fat",
    name: "多不饱和脂肪",
    label: "polyunsaturatedFat",
  ),
  CusDropdownOption(
    value: "monounsaturated_fat",
    name: "单不饱和脂肪",
    label: "monounsaturatedFat",
  ),
  CusDropdownOption(value: "cholesterol", name: "胆固醇", label: "cholesterol"),
  CusDropdownOption(
    value: "total_carbohydrate",
    name: "总碳水化合物",
    label: "totalCarbohydrate",
  ),
  CusDropdownOption(value: "sugar", name: "糖", label: "sugar"),
  CusDropdownOption(
    value: "dietary_fiber",
    name: "膳食纤维",
    label: "dietaryFiber",
  ),
  CusDropdownOption(value: "sodium", name: "钠", label: "sodium"),
  CusDropdownOption(value: "potassium", name: "钾", label: "potassium")
];

// 饮食日记的每日主页显示的模式(摘要和详细)
List<CusDropdownOption> dietaryLogDisplayModeList = [
  CusDropdownOption(label: "摘要模式", name: "摘要", value: "summary"),
  CusDropdownOption(label: "详细模式", name: "详细", value: "detailed"),
];

// 用于展示的营养素需要的信息
class CusNutrientInfo {
  String label, name, unit;
  double value;
  Color? color;

  CusNutrientInfo({
    required this.label,
    required this.name,
    required this.unit,
    required this.value,
    this.color,
  });
}

// 预设可以查询的饮食记录报告选项(昨天、今天、上周、本周)
List<CusDropdownOption> dietaryReportDisplayModeList = [
  CusDropdownOption(label: "Today", name: "今天", value: "today"),
  CusDropdownOption(label: "Yesterday", name: "昨天", value: "yesterday"),
  CusDropdownOption(label: "ThisWeek", name: "本周", value: "this_week"),
  CusDropdownOption(label: "Lastweek", name: "上周", value: "last_week"),
];

// 摄入目标中用于每个星期的展示对象相关的类
class CusMacro {
  final int calory;
  final double carbs;
  final double fat;
  final double protein;

  CusMacro({
    required this.calory,
    required this.carbs,
    required this.fat,
    required this.protein,
  });
}

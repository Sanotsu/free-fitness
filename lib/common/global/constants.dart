// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

/// ********************************************************
/// 单变量区域
/// ********************************************************

const constDatetimeFormat = "yyyy-MM-dd HH:mm:ss";
const constDateFormat = "yyyy-MM-dd";
const constTimeFormat = "HH:mm:ss";
// 未知的时间字符串
const unknownDateTimeString = '1970-01-01 00:00:00';
const unknownDateString = '1970-01-01';

// 1 大卡 = 4.184 千焦
const double oneCalToKjRatio = 4.18400;

/// 一个封面图或示意图在asset的固定位置
const String placeholderImageUrl = 'assets/images/no_image.png';
const String dietaryLogCoverImageUrl = 'assets/covers/dietary-log-cover.jpg';
const String dietaryNutritionImageUrl = 'assets/covers/dietary-nutrition.jpg';
const String dietaryMealImageUrl = 'assets/covers/dietary-meal-food.jpg';
const String workoutManImageUrl = 'assets/covers/workout-man.jpg';
const String workoutWomanImageUrl = 'assets/covers/workout-woman.jpg';
const String workoutCalendarImageUrl = 'assets/covers/workout-calendar.jpg';
const String reportImageUrl = 'assets/covers/report-cover.jpg';
const String defaultAvatarImageUrl = 'assets/profile_icons/Avatar.png';

/// 导入的图片默认的地址前缀
/// (安卓的话指定位置.../DCIM/free-fitness/exercise-images/)下才能读到图片文件
const cusExImgPre = "/storage/emulated/0/DCIM/free-fitness/exercise-images/";

// 声明单独storage缓存的用户基本信息的key字段(全局使用当前登录的用户信息，切换用户时会修改)
class LocalStorageKey {
  // 添加一个私有构造函数以防止此类被实例化
// 例如意外调用“LocalStorageKey()”
  LocalStorageKey._();

  // 属性是静态的，因此我们可以在没有类实例的情况下使用它们
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userCode = 'user_code';
  static const String password = 'password';
  static const String gender = 'gender';
  static const String description = 'description';
}

// 缓存中存放的用户信息，方便统一查询(这个box导出也都在用，就像单例)
// final box = GetStorage();

// class CacheUser {
//   CacheUser._();

//   // 获取缓存中的用户编号(理论上进入app主页之后，就一定有一个默认的用户编号了)
//   static int userId = box.read(LocalStorageKey.userId) ?? 1;
//   static String userName = box.read(LocalStorageKey.userName) ?? "";
// }

final box = GetStorage();

class CacheUser {
  CacheUser._();

  // 获取缓存中的用户编号(理论上进入app主页之后，就一定有一个默认的用户编号了)
  static int userId = _readUserId();
  static String userName = _readUserName();
  static String userCode = _readUserCode();

  static int _readUserId() => box.read(LocalStorageKey.userId) ?? 1;
  static String _readUserName() => box.read(LocalStorageKey.userName) ?? "";
  static String _readUserCode() => box.read(LocalStorageKey.userCode) ?? "";

  static void updateUserId(int newUserId) async {
    userId = newUserId;
    await box.write(LocalStorageKey.userId, newUserId);
  }

  static void clearUserId() async {
    await box.write(LocalStorageKey.userId, null);
  }

  static void updateUserName(String newUserName) async {
    userName = newUserName;
    await box.write(LocalStorageKey.userName, newUserName);
  }

  static void updateUserCode(String newUserCode) async {
    userCode = newUserCode;
    await box.write(LocalStorageKey.userName, newUserCode);
  }
}

/// ********************************************************
/// 类声明区域
/// ********************************************************

/// 这3个类都类似，包含中文名、英文名、值
/*
class CusLabel {
  final String enLabel;
  final String cnLabel;
  final dynamic value;

  CusLabel({
    required this.enLabel,
    required this.cnLabel,
    required this.value,
  });
}

class ExerciseDefaultOption {
  final String label;
  final String? name;
  final String value;

  ExerciseDefaultOption({
    required this.label,
    this.name,
    required this.value,
  });
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

为了方便，合并成一个 CusLabel，都必须(方便取值)，value可为null。
  enLabel，String，为首字母大写的字符串，
  cnLabel，String，为中文字符串，
  value，dynamic， 当为字符串类型时，全小写且用底横线连接的英文
*/

// 自定义标签，常用来存英文、中文、全小写带下划线的英文等。
class CusLabel {
  final String enLabel;
  final String cnLabel;
  final dynamic value;

  CusLabel({
    required this.enLabel,
    required this.cnLabel,
    required this.value,
  });
}

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

// 数据库分页查询数据的时候，还需要带上一个该表的总数量
// 还可以按需补入其他属性
class CusDataResult {
  List<dynamic> data;
  int total;

  CusDataResult({
    required this.data,
    required this.total,
  });
}

/// ********************************************************
/// 枚举区
/// ********************************************************

// 餐次名称关键字(早中晚小食)，避免直接使用魔法阵
enum CusMeals {
  breakfast,
  lunch,
  dinner,
  other,
}

// 营养素枚举 CusNutrientType
enum CusNutType {
  energy,
  protein,
  totalFat,
  totalCHO,
  sodium,
  cholesterol,
  dietaryFiber,
  potassium,
  sugar,
  transFat,
  saturatedFat,
  muFat,
  puFat,
  calorie,
  bfEnergy,
  lunchEnergy,
  dinnerEnergy,
  otherEnergy,
  bfCalorie,
  lunchCalorie,
  dinnerCalorie,
  otherCalorie,
}

// 饮食报告中绘制图表的类型，是显示卡路里还是宏量素
// 卡路里就是一日四餐的摄入数据，宏量素就是碳水、脂肪、蛋白质的摄入数据
enum CusChartType {
  calory,
  macro,
}

/// ********************************************************
/// 对象区
/// ********************************************************

// 餐次的魔法值，这里有列表和对象两个
Map<CusMeals, CusLabel> mealNameMap = {
  CusMeals.breakfast: CusLabel(
    enLabel: "breakfast",
    cnLabel: '早餐',
    value: CusMeals.breakfast,
  ),
  CusMeals.lunch: CusLabel(
    enLabel: "lunch",
    cnLabel: '午餐',
    value: CusMeals.lunch,
  ),
  CusMeals.dinner: CusLabel(
    enLabel: "dinner",
    cnLabel: '晚餐',
    value: CusMeals.dinner,
  ),
  CusMeals.other: CusLabel(
    enLabel: "other",
    cnLabel: '小食',
    value: CusMeals.other,
  ),
};

// 2023-12-12
// 有特别多的地方是为了取得mealNameMap的enLabel来做判断，取值都比较麻烦
// 现在简单用这个静态类来做(以前不太会，现在可能慢慢替代那些map)
class MealLabels {
  // 添加一个私有构造函数以防止此类被实例化
  MealLabels._();
  // 属性是静态的，因此我们可以在没有类实例的情况下使用它们
  static const String enBreakfast = 'breakfast';
  static const String enLunch = 'lunch';
  static const String enDinner = 'dinner';
  static const String enOther = 'other';
  static const String cnBreakfast = '早餐';
  static const String cnLunch = '午餐';
  static const String cnDinner = '晚餐';
  static const String cnOther = "小食";
}

Map<int, CusLabel> weekdayStringMap = {
  1: CusLabel(enLabel: "Mon", cnLabel: "周一", value: "monday"),
  2: CusLabel(enLabel: "Tue", cnLabel: "周二", value: "tuesday"),
  3: CusLabel(enLabel: "Wed", cnLabel: "周三", value: "wednesday"),
  4: CusLabel(enLabel: "Thu", cnLabel: "周四", value: "thursday"),
  5: CusLabel(enLabel: "Fri", cnLabel: "周五", value: "friday"),
  6: CusLabel(enLabel: "Sat", cnLabel: "周六", value: "saturday"),
  7: CusLabel(enLabel: "Sun", cnLabel: "周日", value: "sunday"),
};

Map<CusNutType, Color> cusNutrientColors = {
  // 红到紫
  CusNutType.energy: Colors.red,
  CusNutType.protein: Colors.orange,
  CusNutType.totalFat: Colors.yellow,
  CusNutType.totalCHO: Colors.green,
  CusNutType.sodium: Colors.cyan,
  CusNutType.cholesterol: Colors.purple,
  // 其他单色
  CusNutType.dietaryFiber: Colors.pink,
  CusNutType.potassium: Colors.black,
  CusNutType.sugar: Colors.brown,
  CusNutType.transFat: Colors.indigo,
  CusNutType.dinnerEnergy: Colors.teal,
  CusNutType.puFat: Colors.lime,
  CusNutType.otherEnergy: Colors.amber,
  CusNutType.bfCalorie: Colors.grey,
  CusNutType.muFat: Colors.white,

  // 混合色
  CusNutType.saturatedFat: Colors.lightBlue,
  CusNutType.bfEnergy: Colors.deepOrange,
  CusNutType.lunchCalorie: Colors.lightGreen,
  CusNutType.dinnerCalorie: Colors.blueGrey,
  CusNutType.otherCalorie: Colors.deepPurple,

  // 憋不出来的颜色
  CusNutType.calorie: Colors.blueAccent,
  CusNutType.lunchEnergy: Colors.black45,
};

/// ********************************************************
/// 列表区
/// ********************************************************

final List<CusLabel> genderOptions = [
  CusLabel(enLabel: 'Male', cnLabel: "男", value: 'male'),
  CusLabel(enLabel: 'Female', cnLabel: "女", value: 'female'),
  CusLabel(
    enLabel: 'Thunder Fighter',
    cnLabel: "雷霆战机",
    value: 'thunder fighter',
  ),
  CusLabel(enLabel: 'Other', cnLabel: "其他", value: 'other'),
];

/// 基础活动的一些分类选项
/// 来源： https://lite.datasette.io/?json=https://github.com/yuhonas/free-exercise-db/blob/main/dist/exercises.json#/data/exercises?_facet=force
List<CusLabel> mechanicOptions = [
  CusLabel(enLabel: 'isolation', cnLabel: "孤立动作", value: 'isolation'),
  CusLabel(enLabel: 'compound', cnLabel: "复合动作", value: 'compound'),
];

List<CusLabel> forceOptions = [
  CusLabel(enLabel: 'pull', cnLabel: "拉", value: 'pull'),
  CusLabel(enLabel: 'push', cnLabel: "推", value: 'push'),
  CusLabel(enLabel: 'static', cnLabel: "静", value: 'static'),
  CusLabel(enLabel: 'other', cnLabel: "其他", value: 'other'),
];

List<CusLabel> levelOptions = [
  CusLabel(enLabel: 'beginner', cnLabel: "初级", value: 'beginner'),
  CusLabel(enLabel: 'intermediate', cnLabel: "中级", value: 'intermediate'),
  CusLabel(enLabel: 'expert', cnLabel: "专家", value: 'expert'),
];

// 锻炼是计时还是计次
List<CusLabel> countingOptions = [
  CusLabel(enLabel: 'timed', cnLabel: "计时", value: 'timed'),
  CusLabel(enLabel: 'counted', cnLabel: "计次", value: 'counted'),
];

// 这个分类除了exercise外，group、plan计划也用这个
List<CusLabel> categoryOptions = [
  CusLabel(enLabel: 'strength', cnLabel: "力量", value: 'strength'),
  CusLabel(enLabel: 'stretching', cnLabel: "拉伸", value: 'stretching'),
  CusLabel(enLabel: 'plyometrics', cnLabel: "肌肉增强", value: 'plyometrics'),
  CusLabel(enLabel: 'power lifting', cnLabel: "力量举重", value: 'powerlifting'),
  CusLabel(enLabel: 'strongman', cnLabel: "大力士", value: 'strongman'),
  CusLabel(enLabel: 'cardio', cnLabel: "有氧", value: 'cardio'),
  CusLabel(enLabel: 'anaerobic', cnLabel: "无氧", value: 'anaerobic'),
  CusLabel(enLabel: 'other', cnLabel: "其他", value: 'other'),
];

List<CusLabel> equipmentOptions = [
  CusLabel(enLabel: 'body', cnLabel: "无器械", value: 'body'),
  CusLabel(enLabel: 'body only', cnLabel: "仅身体", value: 'body only'),
  CusLabel(enLabel: 'barbell', cnLabel: "杠铃", value: 'barbell'),
  CusLabel(enLabel: 'dumbbell', cnLabel: "哑铃", value: 'dumbbell'),
  CusLabel(enLabel: 'cable', cnLabel: "缆绳", value: 'cable'),
  CusLabel(enLabel: 'kettlebells', cnLabel: "壶铃", value: 'kettlebells'),
  CusLabel(enLabel: 'bands', cnLabel: "健身带", value: 'bands'),
  CusLabel(enLabel: 'medicine ball', cnLabel: "健身实心球", value: 'medicine ball'),
  CusLabel(enLabel: 'exercise ball', cnLabel: "健身球", value: 'exercise ball'),
  CusLabel(enLabel: 'foam roll', cnLabel: "泡沫辊", value: 'foam roll'),
  CusLabel(enLabel: 'e-z curl bar', cnLabel: "e-z卷曲棒", value: 'e-z curl bar'),
  CusLabel(enLabel: 'machine', cnLabel: "机器", value: 'machine'),
  CusLabel(enLabel: 'other', cnLabel: "其他", value: 'other'),
];

List<CusLabel> standardDurationOptions = [
  CusLabel(enLabel: '1 s', cnLabel: "1 秒", value: '1'),
  CusLabel(enLabel: '2 s', cnLabel: "2 秒", value: '2'),
  CusLabel(enLabel: '3 s', cnLabel: "3 秒", value: '3'),
  CusLabel(enLabel: '4 s', cnLabel: "4 秒", value: '4'),
  CusLabel(enLabel: '5 s', cnLabel: "5 秒", value: '5'),
  CusLabel(enLabel: '6 s', cnLabel: "6 秒", value: '6'),
  CusLabel(enLabel: '7 s', cnLabel: "7 秒", value: '7'),
  CusLabel(enLabel: '8 s', cnLabel: "8 秒", value: '8'),
  CusLabel(enLabel: '9 s', cnLabel: "9 秒", value: '9'),
  CusLabel(enLabel: '10 s', cnLabel: "10 秒", value: '10'),
];

final List<CusLabel> musclesOptions = [
  CusLabel(enLabel: 'quadriceps', cnLabel: "四头肌", value: 'quadriceps'),
  CusLabel(enLabel: 'shoulders', cnLabel: "肩膀", value: 'shoulders'),
  CusLabel(enLabel: 'abdominals', cnLabel: "腹肌", value: 'abdominals'),
  CusLabel(enLabel: 'chest', cnLabel: "胸部", value: 'chest'),
  CusLabel(enLabel: 'hamstrings', cnLabel: "腘绳肌腱", value: 'hamstrings'),
  CusLabel(enLabel: 'triceps', cnLabel: "三头肌", value: 'triceps'),
  CusLabel(enLabel: 'biceps', cnLabel: "二头肌", value: 'biceps'),
  CusLabel(enLabel: 'lats', cnLabel: "背阔肌", value: 'lats'),
  CusLabel(enLabel: 'middle back', cnLabel: "中背", value: 'middle back'),
  CusLabel(enLabel: 'calves', cnLabel: "小腿肌", value: 'calves'),
  CusLabel(enLabel: 'lower back', cnLabel: "下背肌肉", value: 'lower back'),
  CusLabel(enLabel: 'forearms', cnLabel: "前臂", value: 'forearms'),
  CusLabel(enLabel: 'glutes', cnLabel: "臀肌", value: 'glutes'),
  CusLabel(enLabel: 'trapezius', cnLabel: "斜方肌", value: 'trapezius'),
  CusLabel(enLabel: 'adductors', cnLabel: "内收肌", value: 'adductors'),
  CusLabel(enLabel: 'abductors', cnLabel: "展肌", value: 'abductors'),
  CusLabel(enLabel: 'neck', cnLabel: "脖子", value: 'neck'),
  CusLabel(enLabel: 'other', cnLabel: "其他", value: 'other'),
];

List<String> cnLabelList = mealNameMap.values.map((cl) => cl.cnLabel).toList();
List<String> mealNameList = mealNameMap.values.map((cl) => cl.enLabel).toList();

// 下拉选择框使用的餐次信息(用的这个，显示更方便)
List<CusLabel> mealtimeList = [
  CusLabel(
    enLabel: mealNameMap[CusMeals.breakfast]!.enLabel,
    cnLabel: mealNameMap[CusMeals.breakfast]!.cnLabel,
    value: CusMeals.breakfast,
  ),
  CusLabel(
    enLabel: mealNameMap[CusMeals.lunch]!.enLabel,
    cnLabel: mealNameMap[CusMeals.lunch]!.cnLabel,
    value: CusMeals.lunch,
  ),
  CusLabel(
    enLabel: mealNameMap[CusMeals.dinner]!.enLabel,
    cnLabel: mealNameMap[CusMeals.dinner]!.cnLabel,
    value: CusMeals.dinner,
  ),
  CusLabel(
    enLabel: mealNameMap[CusMeals.other]!.enLabel,
    cnLabel: mealNameMap[CusMeals.other]!.cnLabel,
    value: CusMeals.other,
  ),
];

// 新增食物营养素选择单位时使用
List<CusLabel> servingTypeList = [
  CusLabel(
    enLabel: "100ml/100g",
    cnLabel: "100毫升/100克",
    value: "metric",
  ),
  CusLabel(
    enLabel: "1 serving( e.g. 1 piece)",
    cnLabel: "1 份(勺/杯/块 等)",
    value: "custom",
  ),
];

// 食物营养素列表(中文名，英文名对照，方便格式化展示之类的)
// 2023-12-13 补入 FoodNutrientTotals 类对应的简化的key作为enLabel
// 经过查看，目前就新增食物时在单份营养素填写完之后的格式化成文本；和饮食报告的营养素表格有用到。
List<CusLabel> nutrientList = [
  CusLabel(value: "energy", cnLabel: "能量(千焦)", enLabel: "energy(kj)"),
  CusLabel(value: "calorie", cnLabel: "卡路里(大卡)", enLabel: "calorie(kcal)"),
  CusLabel(value: "protein", cnLabel: "蛋白质(克)", enLabel: "protein(g)"),
  CusLabel(value: "total_fat", cnLabel: "总脂肪(克)", enLabel: "totalFat(g)"),
  CusLabel(
      value: "saturated_fat", cnLabel: "饱和脂肪(克)", enLabel: "saturatedFat(g)"),
  CusLabel(value: "trans_fat", cnLabel: "反式脂肪(克)", enLabel: "transFat(g)"),
  CusLabel(
    value: "polyunsaturated_fat",
    cnLabel: "多不饱和脂肪(克)",
    enLabel: "polyunsaturatedFat(g)",
  ),
  CusLabel(value: "pu_fat", cnLabel: "多不饱和脂肪(克)", enLabel: "puFat(g)"),
  CusLabel(
    value: "monounsaturated_fat",
    cnLabel: "单不饱和脂肪(克)",
    enLabel: "monounsaturatedFat(g)",
  ),
  CusLabel(value: "mu_fat", cnLabel: "单不饱和脂肪(克)", enLabel: "muFat(g)"),
  CusLabel(
    value: "total_carbohydrate",
    cnLabel: "总碳水化合物(克)",
    enLabel: "totalCarbohydrate(g)",
  ),
  CusLabel(value: "total_cho", cnLabel: "总碳水化合物(克)", enLabel: "totalCHO(g)"),
  CusLabel(value: "sugar", cnLabel: "糖(克)", enLabel: "sugar(g)"),
  CusLabel(
      value: "dietary_fiber", cnLabel: "膳食纤维(克)", enLabel: "dietaryFiber(g)"),
  CusLabel(value: "sodium", cnLabel: "钠(毫克)", enLabel: "sodium(mg)"),
  CusLabel(value: "potassium", cnLabel: "钾(毫克)", enLabel: "potassium(mg)"),
  CusLabel(
      value: "cholesterol", cnLabel: "胆固醇(毫克)", enLabel: "cholesterol(mg)"),
];

// 饮食日记的每日主页显示的模式(摘要和详细)
List<CusLabel> dietaryLogDisplayModeList = [
  CusLabel(enLabel: "Summary", cnLabel: "摘要", value: "summary"),
  CusLabel(enLabel: "Detailed", cnLabel: "详细", value: "detailed"),
];

// 预设可以查询的饮食记录报告选项(昨天、今天、上周、本周)
List<CusLabel> dietaryReportDisplayModeList = [
  CusLabel(enLabel: "Today", cnLabel: "今天", value: "today"),
  CusLabel(enLabel: "Yesterday", cnLabel: "昨天", value: "yesterday"),
  CusLabel(enLabel: "ThisWeek", cnLabel: "本周", value: "this_week"),
  CusLabel(enLabel: "Lastweek", cnLabel: "上周", value: "last_week"),
];

// 手记中的情绪标签选择项
List<CusLabel> diaryMoodList = [
  CusLabel(enLabel: "Joy", cnLabel: "喜悦", value: "joy"),
  CusLabel(enLabel: "Anger", cnLabel: "愤怒", value: "anger"),
  CusLabel(enLabel: "Sadness", cnLabel: "悲伤", value: "sadness"),
  CusLabel(enLabel: "Fear", cnLabel: "恐惧", value: "fear"),
  CusLabel(enLabel: "Disgust", cnLabel: "厌恶", value: "disgust"),
  CusLabel(enLabel: "Surprise", cnLabel: "惊奇", value: "surprise"),
  CusLabel(enLabel: "Envy", cnLabel: "羡慕", value: "envy"),
  CusLabel(enLabel: 'Unknown', cnLabel: "其他", value: 'other'),
];

// 手记中的分类标签选择项
List<CusLabel> diaryCategoryList = [
  CusLabel(enLabel: "Life", cnLabel: "生活", value: "life"),
  CusLabel(enLabel: "Learning", cnLabel: "学习", value: "learning"),
  CusLabel(enLabel: "Major", cnLabel: "大事", value: "major"),
  CusLabel(enLabel: "Weekly", cnLabel: "周报", value: "weekly"),
  CusLabel(enLabel: "Motion", cnLabel: "运动", value: "motion"),
  CusLabel(enLabel: "Work", cnLabel: "工作", value: "work"),
  CusLabel(enLabel: "Game", cnLabel: "游戏", value: "game"),
  CusLabel(enLabel: "Film", cnLabel: "电影", value: "film"),
  CusLabel(enLabel: "Article", cnLabel: "文章", value: "article"),
  CusLabel(enLabel: "Bill", cnLabel: "账单", value: "bill"),
  CusLabel(enLabel: "Notes", cnLabel: "备忘", value: "notes"),
  CusLabel(enLabel: "Script", cnLabel: "剧本", value: "script"),
  CusLabel(enLabel: "Emotion", cnLabel: "情感", value: "emotion"),
  CusLabel(enLabel: 'Unknown', cnLabel: "其他", value: 'other'),
];

// 导出是可下拉选择的值
List<CusLabel> exportDateList = [
  CusLabel(
    enLabel: "last 7 days",
    cnLabel: "最近7天",
    value: "seven",
  ),
  CusLabel(
    enLabel: "last 30 days",
    cnLabel: "最近30天",
    value: "thirty",
  ),
  CusLabel(
    enLabel: "all",
    cnLabel: "全部",
    value: "all",
  ),
];

/// 上传的餐食图片默认存放的文件夹
final MEAL_PHOTO_DIR = Directory('/storage/emulated/0/FreeFitness/MealPhotos');

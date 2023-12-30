// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math';

import 'package:free_fitness/models/user_state.dart';
import 'package:intl/intl.dart';

import '../../../../../common/utils/db_dietary_helper.dart';
import '../../../../../common/utils/tools.dart';
import '../../../../../models/dietary_state.dart';
import '../../../common/global/constants.dart';
import '../../../common/utils/db_diary_helper.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/db_user_helper.dart';
import '../../../models/diary_state.dart';
import '../../../models/training_state.dart';
import 'quill_samples.dart';

final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
final DBTrainingHelper _trainingHelper = DBTrainingHelper();
final DBDiaryHelper _diaryHelper = DBDiaryHelper();
final DBUserHelper _userHelper = DBUserHelper();

///
/// ---------- 饮食模块相关--------------
///

// 新增带有单份营养素的食物(标准和自定义单份营养素各一份)，返回食物编号和营养素编号列表的map
Future<Map<String, Object>> insertOneRandomFoodWithServingInfo() async {
  print("【【【插入测试数据 start-->:insertOneRandomFoodWithServingInfo ");

  var food = Food(
    brand: generateRandomString(5, 20),
    product: generateRandomString(5, 10),
    tags: [
      generateRandomString(1, 8),
      generateRandomString(1, 8),
      generateRandomString(1, 8)
    ].join(","),
    category: generateRandomString(5, 10),
    description: generateRandomString(50, 100),
    contributor: CacheUser.userName,
    gmtCreate: getCurrentDateTime(),
    isDeleted: false,
  );

  // ？？？注意，业务中好像有有订好是100g,100ml的逻辑
  var units = ["100g", '100ml'];
  var unit = units[Random().nextInt(units.length)];

  var energy = Random().nextDouble() * 3000;
  var protein = Random().nextDouble() * 100;
  var totalFat = Random().nextDouble() * 100;
  var saturatedFat = Random().nextDouble() * 30;
  var transFat = Random().nextDouble() * 30;
  var polyunsaturatedFat = Random().nextDouble() * 30;
  var monounsaturatedFat = Random().nextDouble() * 30;
  var totalCarbohydrate = Random().nextDouble() * 100;
  var sugar = Random().nextDouble() * 50;
  var dietaryFiber = Random().nextDouble() * 50;
  var sodium = Random().nextDouble() * 5000;
  var potassium = Random().nextDouble() * 5000;
  var cholesterol = Random().nextDouble() * 5000;

  // 输入标准单份营养素
  var dserving = ServingInfo(
    foodId: 1, // 这个id会在insert语句中被成功插入的food的id替代
    servingSize: 1,
    servingUnit: unit,
    energy: energy,
    protein: protein,
    totalFat: totalFat,
    saturatedFat: saturatedFat,
    transFat: transFat,
    polyunsaturatedFat: polyunsaturatedFat,
    monounsaturatedFat: monounsaturatedFat,
    totalCarbohydrate: totalCarbohydrate,
    sugar: sugar,
    dietaryFiber: dietaryFiber,
    sodium: sodium,
    potassium: potassium,
    cholesterol: cholesterol,
    contributor: CacheUser.userName,
    gmtCreate: getCurrentDateTime(),
    isDeleted: false,
  );
  // 输入标准单份营养素
  var dserving1 = ServingInfo(
    foodId: 1, // 这个id会在insert语句中被成功插入的food的id替代
    servingSize: 1,
    // 注意这里的单位，100g取1g，100ml取1ml，及删除字符串第2、3个字符。
    servingUnit: unit.substring(0, 1) + unit.substring(3),
    energy: energy / 100,
    protein: protein / 100,
    totalFat: totalFat / 100,
    saturatedFat: saturatedFat / 100,
    transFat: transFat / 100,
    polyunsaturatedFat: polyunsaturatedFat / 100,
    monounsaturatedFat: monounsaturatedFat / 100,
    totalCarbohydrate: totalCarbohydrate / 100,
    sugar: sugar / 100,
    dietaryFiber: dietaryFiber / 100,
    sodium: sodium / 100,
    potassium: potassium / 100,
    cholesterol: cholesterol / 100,
    contributor: CacheUser.userName,
    gmtCreate: getCurrentDateTime(),
    isDeleted: false,
  );

  // 自定义单份
  var dserving2 = ServingInfo(
    foodId: 1, // 这个id会在insert语句中被成功插入的food的id替代
    servingSize: 1,
    servingUnit: "只",
    energy: Random().nextDouble() * 3000,
    protein: Random().nextDouble() * 100,
    totalFat: Random().nextDouble() * 100,
    saturatedFat: Random().nextDouble() * 30,
    transFat: Random().nextDouble() * 30,
    polyunsaturatedFat: Random().nextDouble() * 30,
    monounsaturatedFat: Random().nextDouble() * 30,
    totalCarbohydrate: Random().nextDouble() * 100,
    sugar: Random().nextDouble() * 50,
    dietaryFiber: Random().nextDouble() * 50,
    sodium: Random().nextDouble() * 5000,
    potassium: Random().nextDouble() * 5000,
    cholesterol: Random().nextDouble() * 5000,
    contributor: CacheUser.userName,
    gmtCreate: getCurrentDateTime(),
    isDeleted: false,
  );

  var rst = await _dietaryHelper.insertFoodWithServingInfoList(
    food: food,
    servingInfoList: [dserving, dserving1, dserving2],
  );

  print("【【【插入测试数据 end-->:insertOneRandomFoodWithServingInfo ");

  return rst;
}

// 插入指定数量的食物和饮食记录
// 【注意】，可以指定只插入食物，不插入饮食记录条目
// 需要指定
//    foodSize 插入多少条食物数据，
//    logSize  插入多少条饮食记录数据(食物和营养素使用前面食物的)，
//    dateRange插入在距离今天多少天前的范围内(比如5,就是5天前到今天随机日期插入饮食条目)
insertDailyLogDataDemo(
  int foodSize,
  int logSize,
  int dateRange, {
  bool? onlyFood = false,
}) async {
  print("【【【 插入测试数据 start-->:insertDailyLogDataDemo ");

  Map<int, List<int>> foodServings = {};
  List<int> foodIds = [];
  // 1 插入指定数量随机食物 ,并记录每个食物对应的营养素编号列表
  for (int i = 0; i < foodSize; i++) {
    Map<String, Object> result = await insertOneRandomFoodWithServingInfo();

    int foodId = result["foodId"]! as int;
    List<int> servingIds = result["servingIds"]! as List<int>;

    // 将食物ID和对应的服务ID添加到foodServings中
    foodServings[foodId] = servingIds;

    // 将食物ID添加到foodIds中
    foodIds.add(foodId);
  }

  if (onlyFood != null && onlyFood) {
    return;
  }

  // 2 插入指定数量随机饮食记录条目
  List<DailyFoodItem> list = [];

  // 饮食记录的数据随机插入今天前后一个星期内的某一天
  var dates = getAdjacentDatesInRange(dateRange);

  for (var i = 0; i <= logSize; i++) {
    // 使用的哪一个食物
    var usedFoodId = foodIds[Random().nextInt(foodIds.length)];
    // 获取该食物拥有的营养素编号
    var usedServingIds = foodServings[usedFoodId]!;
    // 使用的哪一个单份营养素
    var usedServingId = usedServingIds[Random().nextInt(usedServingIds.length)];

    var temp = DailyFoodItem(
      // 主键数据库自增
      date: dates[Random().nextInt(dates.length)],
      mealCategory: mealNameList[Random().nextInt(mealNameList.length)],
      foodId: usedFoodId,
      servingInfoId: usedServingId,
      foodIntakeSize: Random().nextDouble() * 100,
      userId: Random().nextInt(3) + 1,
      gmtCreate: getCurrentDateTime(),
    );
    list.add(temp);
  }

  await _dietaryHelper.insertDailyFoodItemList(list);

  print("【【【 插入测试数据 end-->:insertDailyLogDataDemo ");
}

///
/// ---------- 训练模块相关--------------
///

// 新增单条测试基础动作
Future<int> insertOneRandomExercise({String? countingMode}) async {
  print("【【【 插入测试数据 start-->:insertOneRandomExercise ");

// 在模拟训练添加动作是，需要指定技术方式来显示是计时器或者计数器。没传就随机
  String temp;
  if (countingMode == null) {
    temp = countingOptions[Random().nextInt(countingOptions.length)].value;
  } else if (countingMode == "timed") {
    temp = countingOptions.first.value;
  } else {
    temp = countingOptions.last.value;
  }

  Exercise exercise = Exercise(
    exerciseCode: getRandomString(4),
    exerciseName: generateRandomString(5, 20),
    category: categoryOptions[Random().nextInt(categoryOptions.length)].value,
    level: levelOptions[Random().nextInt(levelOptions.length)].value,
    mechanic: mechanicOptions[Random().nextInt(mechanicOptions.length)].value,
    force: forceOptions[Random().nextInt(forceOptions.length)].value,
    equipment:
        equipmentOptions[Random().nextInt(equipmentOptions.length)].value,
    countingMode: temp,
    instructions: generateRandomString(300, 500),
    primaryMuscles:
        musclesOptions[Random().nextInt(musclesOptions.length)].value,
    gmtCreate: getCurrentDateTime(),
    standardDuration: Random().nextInt(3) + 1,
  );

  var rst = await _trainingHelper.insertExercise(exercise);

  print("【【【 插入测试数据 end-->:insertOneRandomExercise ");
  return rst;
}

// 新增单条测试训练数据
Future<int> _insertOneRandomGroup() async {
  print("【【【 插入测试数据 start-->:_insertOneRandomGroup ");

  var group = TrainingGroup(
    groupName: generateRandomString(5, 20),
    groupCategory:
        categoryOptions[Random().nextInt(categoryOptions.length)].value,
    groupLevel: levelOptions[Random().nextInt(levelOptions.length)].value,
    consumption: Random().nextInt(1000),
    timeSpent: Random().nextInt(100),
    description: generateRandomString(50, 500),
    gmtCreate: getCurrentDateTime(),
  );

  var rst = await _trainingHelper.insertTrainingGroup(group);

  print("【【【 插入测试数据 end-->:_insertOneRandomGroup ");

  return rst;
}

// 新增单条测试训练(返回计划编号和周期数值，按周期插入训练数量)
Future<List<int>> _insertOneRandomPlan() async {
  print("【【【 插入测试数据 start-->:_insertOneRandomPlan ");

  // 测试数据，计划周期小点
  var planPeriod = Random().nextInt(10) + 1;

  var plan = TrainingPlan(
    planCode: generateRandomString(5, 20),
    planName: generateRandomString(5, 20),
    planCategory:
        categoryOptions[Random().nextInt(categoryOptions.length)].value,
    planLevel: levelOptions[Random().nextInt(levelOptions.length)].value,
    planPeriod: planPeriod,
    description: generateRandomString(50, 500),
    gmtCreate: getCurrentDateTime(),
  );

  var planId = await _trainingHelper.insertTrainingPlan(plan);

  print("【【【 插入测试数据 end-->:_insertOneRandomPlan ");

  return [planId, planPeriod];
}

// 新增一条带动作的训练数据
Future<int> insertOneRandomGroupAndAction() async {
  print("【【【 插入测试数据 start-->:insertOneRandomGroupAndAction ");

  // 生成训练
  var groupId = await _insertOneRandomGroup();
  // 插入活动(计次和计时)
  var exerciseId1 = await insertOneRandomExercise();
  var exerciseId2 = await insertOneRandomExercise(countingMode: 'timed');

  // 主要这里的exerciseId和计时或者计次和示例数据的exercise list中要一样，否则显示不对
  var action1 = TrainingAction(
    groupId: groupId,
    exerciseId: exerciseId1,
    frequency: Random().nextInt(50),
    equipmentWeight: Random().nextInt(21).toDouble(),
  );
  var action2 = TrainingAction(
    groupId: groupId,
    exerciseId: exerciseId2,
    duration: Random().nextInt(120),
    equipmentWeight: Random().nextInt(21).toDouble(),
  );
  var action3 = TrainingAction(
    groupId: groupId,
    exerciseId: exerciseId1,
    frequency: Random().nextInt(100),
    equipmentWeight: Random().nextInt(21).toDouble(),
  );

  await _trainingHelper.insertTrainingActionList([action1, action2, action3]);

  print("【【【 插入测试数据 end-->:insertOneRandomGroupAndAction ");

  // 返回groupId供计划新增训练用
  return groupId;
}

// 【注意】新增一条带训练周期的计划数据(返回计划编号)
// 调用这个函数，计划、训练、动作、基础运动都有了
Future<int> insertOneRandomPlanHasGroup() async {
  print("【【【 插入测试数据 start-->:insertOneRandomPlanHasGroup ");

// 插入计划的基础数据
  var [planId, planPeriod] = (await _insertOneRandomPlan());

// 插入带动作列表的训练数据
  List<PlanHasGroup> phgList = [];
  for (var i = 1; i < planPeriod + 1; i++) {
    var groupId = await insertOneRandomGroupAndAction();
    var tempPhg = PlanHasGroup(planId: planId, dayNumber: i, groupId: groupId);
    phgList.add(tempPhg);
  }

  await _trainingHelper.insertPlanHasGroupList(phgList);

  print("【【【 插入测试数据 end-->:insertOneRandomPlanHasGroup ");

  return planId;
}

// 2023-12-27 插入训练日志宽表数据，展示运动报告时不需要级联查询基础表
insertTrainingDetailLogDemo() async {
  print("【【【 插入测试数据 start-->:insertTrainingDetailLogDemo ");

  /// 2023-12-27 正好是测试日志宽表，不会关联其他基础表，数据随意写就好了

  // 计划中的某一天
  var tl1 = TrainedDetailLog(
    trainedDate: getCurrentDateTime(),
    userId: Random().nextInt(3) + 1,
    // 单次记录，有计划及其训练日，就没有训练编号了；反之亦然
    planName: generateRandomString(5, 20),
    planCategory:
        categoryOptions[Random().nextInt(categoryOptions.length)].value,
    planLevel: levelOptions[Random().nextInt(levelOptions.length)].value,
    dayNumber: Random().nextInt(8) + 1,
    // 起止时间就测试插入时的1个小时
    trainedStartTime: DateFormat(constDatetimeFormat)
        .format(DateTime.now().add(const Duration(hours: -1))),
    trainedEndTime: getCurrentDateTime(),
    // 单位都是秒
    trainedDuration: 40 * 60, // 实际训练时间
    totolPausedTime: 8 * 60, // 暂停的总时间
    totalRestTime: 12 * 60, // 休息的总时间
  );

  var logId1 = await _trainingHelper.insertTrainedDetailLog(tl1);

  // 直接的某个训练
  var tl2 = TrainedDetailLog(
    trainedDate: getCurrentDateTime(),
    userId: Random().nextInt(3) + 1,
    // 单次记录，有计划及其训练日，就没有训练编号了；反之亦然
    groupName: generateRandomString(5, 20),
    groupCategory:
        categoryOptions[Random().nextInt(categoryOptions.length)].value,
    groupLevel: levelOptions[Random().nextInt(levelOptions.length)].value,
    consumption: Random().nextInt(1000),
    // 起止时间就测试插入时的1个小时
    trainedStartTime: DateFormat(constDatetimeFormat)
        .format(DateTime.now().add(const Duration(hours: -2))),
    trainedEndTime: DateFormat(constDatetimeFormat)
        .format(DateTime.now().add(const Duration(hours: -1))),
    // 单位都是秒
    trainedDuration: 30 * 60, // 实际训练时间
    totolPausedTime: 10 * 60, // 暂停的总时间
    totalRestTime: 20 * 60, // 休息的总时间
  );

  var logId2 = await _trainingHelper.insertTrainedDetailLog(tl2);

  // 前一天的日志 计划中的某一天
  var tl3 = TrainedDetailLog(
    trainedDate: DateFormat(constDatetimeFormat)
        .format(DateTime.now().add(const Duration(days: -1))),
    userId: Random().nextInt(3) + 1,
    // 单次记录，有计划及其训练日，就没有训练编号了；反之亦然
    planName: generateRandomString(5, 20),
    planCategory:
        categoryOptions[Random().nextInt(categoryOptions.length)].value,
    planLevel: levelOptions[Random().nextInt(levelOptions.length)].value,
    dayNumber: Random().nextInt(8) + 1,
    // 起止时间就测试插入时的1个小时
    trainedStartTime: DateFormat(constDatetimeFormat)
        .format(DateTime.now().add(const Duration(days: -1, hours: -1))),
    trainedEndTime: DateFormat(constDatetimeFormat)
        .format(DateTime.now().add(const Duration(days: -1))),
    // 单位都是秒
    trainedDuration: 40 * 60, // 实际训练时间
    totolPausedTime: 8 * 60, // 暂停的总时间
    totalRestTime: 12 * 60, // 休息的总时间
  );

  var logId3 = await _trainingHelper.insertTrainedDetailLog(tl3);

  print(
    "【【【 插入测试数据 end-->:insertTrainingDetailLogDemo logId: $logId1 $logId2 $logId3",
  );
}

///
/// ---------- 个人信息相关--------------
///

insertExtraUsers() async {
  print("【【【 插入测试数据 start-->:insertExtraUsers ");

  // 2023-12-09 成功进入app就有一条默认的用户了，这里测试是为了查询多个用户各自独立的强关联数据
  // 插入2个额外用户用于插入其他随机日志时能够随机查询到指定用户的数据

  var newItem1 = User(
    userId: 2,
    userName: "张三",
    userCode: "zhangsan",
    gender: "male",
    description: "测试描述",
    password: "123",
    dateOfBirth: "1994-07-02",
    height: 173,
    currentWeight: 68,
    targetWeight: 65.2,
    rdaGoal: 1500,
    proteinGoal: 85.5,
    fatGoal: 45.5,
    choGoal: 65.6,
    actionRestTime: 30,
  );

  var newItem2 = User(
    userId: 3,
    userName: "李四",
    userCode: "lisi",
    gender: "female",
    description: "nothing is unknown",
    password: "123456",
    dateOfBirth: "1994-07-02",
    height: 160,
    currentWeight: 60,
    targetWeight: 55,
    rdaGoal: 1300,
    proteinGoal: 100,
    fatGoal: 50,
    choGoal: 100,
    actionRestTime: 30,
  );

  var rst1 = await _userHelper.queryUser(userId: 2);
  var rst2 = await _userHelper.queryUser(userId: 3);

  if (rst1 == null) {
    await _userHelper.insertUserList([newItem1]);
  } else if (rst2 == null) {
    await _userHelper.insertUserList([newItem2]);
  }

  print("【【【 插入测试数据 end-->:insertExtraUsers ");
}

// 插入一个固定内容随机题目的手记
insertOneQuillDemo() async {
  print("【【【 插入测试数据 start-->:insertOneQuillDemo ");

  var quillList = [
    quillDefaultSample,
    quillTextSample,
    quillVideosSample,
    quillImagesSample,
    quillTextSample2,
  ];

  String jsonString = json.encode(
    quillList[Random().nextInt(quillList.length)],
  );

  print("富文本的内容 jsonString---------$jsonString");

  // 生成一个随机数来获取分类列表
  var tempNum = Random().nextInt(5);
  var tempMoods = [];
  for (var i = 0; i < tempNum; i++) {
    var mood = diaryMoodList[Random().nextInt(diaryMoodList.length)];
    tempMoods.add(
      box.read('language') == "en" ? mood.enLabel : mood.cnLabel,
    );
  }

  // 生成一个随机数来获取标签列表
  var tempNum2 = Random().nextInt(8);
  var tempTags = [];
  for (var i = 0; i < tempNum2; i++) {
    tempTags.add(generateRandomString(5, 10));
  }

  // 随机插入的手记在今天往前10天的随机一天中
  var dates = getAdjacentDatesInRange(10);

  var cate = diaryCategoryList[Random().nextInt(diaryCategoryList.length)];

  var tempDiary = Diary(
    date: dates[Random().nextInt(dates.length)],
    title: "测试-${generateRandomString(5, 10)}",
    content: jsonString,
    tags: tempTags.join(","),
    mood: tempMoods.join(","),
    category: box.read('language') == "en" ? cate.enLabel : cate.cnLabel,
    userId: Random().nextInt(3) + 1,
    gmtCreate: getCurrentDateTime(),
  );

  // ？？？这里应该有错误检查
  var newDiaryId = await _diaryHelper.insertDiary(tempDiary);

  print("【【【 插入测试数据 end-->:insertOneQuillDemo  newDiaryId: $newDiaryId");
}

// 插入一个固定内容随机题目的手记
insertBMIDemo({int? size = 10}) async {
  print("【【【 插入测试数据 start-->:insertBMIDemo ");

// 模拟身高， [165.0,175.0) 的一个随机数
  var tempHeight = Random().nextInt(10) + 165 + Random().nextDouble();

// 随机插入的体重记录在今天往前15天的随机一天中
  var dates = getAdjacentDatesInRange(10);

  // 一次性插入多条数据，身高是一样的，但体重稍微变化一下
  List<WeightTrend> weightTrendList = [];
  for (var i = 0; i < (size ?? 10); i++) {
    // 模拟体重， [70.0,80.0)的一个随机数，刻意的一位小数
    var tempweight = Random().nextInt(10) + 70 + Random().nextDouble();
    //  BMI = 体重(公斤) / 身高^2(米^2)
    var bmi = double.tryParse((tempweight / (tempHeight * tempHeight / 10000))
            .toStringAsFixed(2)) ??
        30.5;

    var temp = WeightTrend(
      userId: Random().nextInt(3) + 1,
      weight: tempweight,
      weightUnit: 'kg',
      height: tempHeight,
      heightUnit: 'cm',
      bmi: bmi,
      // 日期随机，带上一个插入时的time
      gmtCreate:
          "${dates[Random().nextInt(dates.length)]} ${getCurrentDateTime().split(" ")[1]}",
    );

    weightTrendList.add(temp);
  }

  // ？？？这里应该有错误检查
  List<Object?> rst = await _userHelper.insertWeightTrendList(weightTrendList);

  print("【【【 插入测试数据 end-->:insertBMIDemo List<Object?> rst: $rst");
}

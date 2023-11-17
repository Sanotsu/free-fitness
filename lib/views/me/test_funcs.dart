// ignore_for_file: avoid_print

import 'dart:math';

import 'package:intl/intl.dart';

import '../../../../common/utils/db_dietary_helper.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/dietary_state.dart';
import '../../common/global/constants.dart';
import '../../common/utils/db_training_helper.dart';
import '../../models/training_state.dart';

final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
final DBTrainingHelper _trainingHelper = DBTrainingHelper();

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
    contributor: "随机数据测试插入",
    gmtCreate: DateFormat.yMMMd().format(DateTime.now()),
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
      contributor: "随机数据测试插入",
      gmtCreate: DateTime.now().toString(),
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
    // standardDuration: "1",
    instructions: generateRandomString(300, 500),
    primaryMuscles:
        musclesOptions[Random().nextInt(musclesOptions.length)].value,
    gmtCreate: DateFormat.yMMMd().format(DateTime.now()),
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
    restInterval: Random().nextInt(50),
    consumption: Random().nextInt(1000),
    timeSpent: Random().nextInt(100),
    description: generateRandomString(50, 500),
    gmtCreate: DateFormat.yMMMd().format(DateTime.now()),
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
    gmtCreate: DateFormat.yMMMd().format(DateTime.now()),
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
    equipmentWeight: Random().nextDouble() * 50,
  );
  var action2 = TrainingAction(
    groupId: groupId,
    exerciseId: exerciseId2,
    duration: Random().nextInt(120),
    equipmentWeight: Random().nextDouble() * 50,
  );
  var action3 = TrainingAction(
    groupId: groupId,
    exerciseId: exerciseId1,
    frequency: Random().nextInt(100),
    equipmentWeight: Random().nextDouble() * 50,
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

///
/// ---------- 个人信息相关--------------
///

// 插入一条用户信息
// 因为没有缓存用户信息，逻辑中有测试数据userId=1,所以插入也只插入这一条
insertOneDietaryUser() async {
  print("【【【 插入测试数据 start-->:insertOneDietaryUser ");

  // 测试，插入先删除
  await _dietaryHelper.deleteDietaryUser(1);

  var newItem = DietaryUser(
    userId: 1,
    userName: "张三",
    userCode: "测试code",
    gender: "雷霆战机",
    description: "测试描述",
    password: "123",
    dateOfBirth: "1994-07",
    height: 173,
    currentWeight: 68,
    targetWeight: 65.2,
    rdaGoal: 1200,
    proteinGoal: 85.5,
    fatGoal: 45.5,
    choGoal: 65.6,
  );
  await _dietaryHelper.insertDietaryUserList([newItem]);
  print("【【【 插入测试数据 end-->:insertOneDietaryUser ");
}

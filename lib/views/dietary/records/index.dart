// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:free_fitness/common/global/constants.dart';
import 'package:free_fitness/models/dietary_state.dart';
import 'package:intl/intl.dart';

import '../../../common/utils/sqlite_db_helper.dart';
import '../../../common/utils/tools.dart';
import 'foods/food_detail.dart';
import 'foods/food_list.dart';

class DietaryRecords extends StatefulWidget {
  const DietaryRecords({super.key});

  @override
  State<DietaryRecords> createState() => _DietaryRecordsState();
}

class _DietaryRecordsState extends State<DietaryRecords> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  // 这个插入的数据是比较完整正规的，测试时在删除db之后可直接用
  demoInsertDailyLogData() async {
    var food1 = Food(
      brand: '永川',
      product: '豆豉',
      photos: '',
      tags: '调味品,佐料',
      category: '调味',
      contributor: '张三',
      gmtCreate: '2023-10-24 09:53:30',
    );

    var dserving1 = ServingInfo(
      foodId: 1,
      isMetric: false,
      servingSize: '一包',
      metricServingSize: 100,
      metricServingUnit: "克",
      energy: 2000,
      protein: 30,
      totalFat: 50,
      saturatedFat: 10,
      transFat: 20,
      polyunsaturatedFat: 10,
      monounsaturatedFat: 10,
      totalCarbohydrate: 20,
      sugar: 30,
      dietaryFiber: 10,
      sodium: 2,
      potassium: 20,
      cholesterol: 20,
      contributor: '李四',
      gmtCreate: '2023-10-24 09:59:15',
      updUserId: '',
      gmtModified: null,
    );

    await _dietaryHelper.insertFoodWithServingInfo(
        food: food1, servingInfo: dserving1);

    var food2 = Food(
      brand: '重庆',
      product: '烤鸭',
      photos: '',
      tags: '鸭子,烤鸭',
      category: '禽肉',
      contributor: '张三',
      gmtCreate: '2023-10-24 09:55:30',
    );

    var dserving2 = ServingInfo(
      foodId: 2,
      isMetric: false,
      servingSize: '一只',
      metricServingSize: 0,
      metricServingUnit: "",
      energy: 20000,
      protein: 300,
      totalFat: 500,
      saturatedFat: 100,
      transFat: 200,
      polyunsaturatedFat: 100,
      monounsaturatedFat: 100,
      totalCarbohydrate: 300,
      sugar: 200,
      dietaryFiber: 100,
      sodium: 20,
      potassium: 200,
      cholesterol: 200,
      contributor: '李四',
      gmtCreate: '2023-10-24 09:55:15',
      updUserId: '',
      gmtModified: null,
    );

    await _dietaryHelper.insertFoodWithServingInfo(
        food: food2, servingInfo: dserving2);

    var dserving3 = ServingInfo(
      foodId: 2,
      isMetric: true,
      servingSize: '',
      metricServingSize: 100,
      metricServingUnit: "克",
      energy: 321,
      protein: 111,
      totalFat: 222,
      saturatedFat: 12,
      transFat: 21,
      polyunsaturatedFat: 14,
      monounsaturatedFat: 41,
      totalCarbohydrate: 30,
      sugar: 20,
      dietaryFiber: 10,
      sodium: 2,
      potassium: 25,
      cholesterol: 25,
      contributor: '李四',
      gmtCreate: '2023-10-24 10:55:15',
      updUserId: '',
      gmtModified: null,
    );

    await _dietaryHelper.insertFoodWithServingInfo(servingInfo: dserving3);

    var meal1 = Meal(
      mealName: "烤鸭餐",
      description: "就是要吃烤鸭",
      contributor: "王五",
      gmtCreate: '2023-10-24 10:08:03',
    );

    var meal2 = Meal(
      mealName: "节约餐",
      description: "吃不起烤鸭",
      contributor: "王五",
      gmtCreate: '2023-10-24 10:09:03',
    );

    await _dietaryHelper.insertMeal(meal1);
    await _dietaryHelper.insertMeal(meal2);

    var mealFoodItem1 = MealFoodItem(
      mealId: 1,
      foodId: 2,
      foodIntakeSize: 100,
      servingInfoId: 3,
    );
    var mealFoodItem2 = MealFoodItem(
      mealId: 1,
      foodId: 2,
      foodIntakeSize: 1,
      servingInfoId: 2,
    );
    var mealFoodItem3 = MealFoodItem(
      mealId: 2,
      foodId: 1,
      foodIntakeSize: 200,
      servingInfoId: 1,
    );

    await _dietaryHelper.insertMealFoodItem(mealFoodItem1);
    await _dietaryHelper.insertMealFoodItem(mealFoodItem2);
    await _dietaryHelper.insertMealFoodItem(mealFoodItem3);

    var foodDailyLog = FoodDailyLog(
      date: '2023-10-24',
      breakfastMealId: 1,
      lunchMealId: 2,
      dinnerMealId: null,
      otherMealId: null,
      contributor: "马六",
      gmtCreate: '2023-10-24 10:10:10',
      gmtModified: null,
    );

    await _dietaryHelper.insertFoodDailyLogOnly(foodDailyLog);

    print("demoInsertDailyLogData------------插入执行完了");
  }

  // 这个插入是插入每日数据时，从log 到meal 到 item一次性插入完，后续可能拆分不同步骤
  oneInsertAll() async {
    var foodDailyLog = FoodDailyLog(
      // foodDailyId: 1, // 这个是自增的，不加会自增，加了会以加的值插入，重复则报错
      // date: DateTime.now().toString(), // 这里应该收缩到年月日，而不是最小单位
      date: "2023-10-24 16:32:15.617120",
      contributor: "david",
      gmtCreate: DateTime.now().toString(),
    );

    var meal = Meal(
      // mealId: 1, // 这个是自增的，不加会自增，加了会以加的值插入，重复则报错
      mealName: "20231024的早餐",
      description: "早上吃好",
      gmtCreate: DateTime.now().toString(),
    );
    var mealFoodItem = MealFoodItem(
      // mealFoodItemId: 1, // 这个是自增的，不加会自增，加了会以加的值插入，重复则报错
      mealId: 1, // 这个要真实值，这里填的插入时会被覆盖
      foodId: 2, // 用户选择真实值
      servingInfoId: 1, // 用户选择真实值
      foodIntakeSize: 200, // 用户输入真实值
    );

    var insertRst = await _dietaryHelper.insertFoodDailyLog(
      foodDailyLog,
      "breakfast",
      meal,
      mealFoodItem,
    );

    print("测试插入饮食记录的结果insertRst：$insertRst");
  }

  /// 日记录的首页应该是查询出1条数据，然后固定显示早中晚夜4个模块，不定长的是每餐的摄入item
  /// 当然，如果是该日没有任何日志，则依旧空数组
  List<FoodDailyLogRecord> fdlrList = [];
  // 用户可能切换日期，但显示的内容是一样的(这个是日期组件的值，默认是当天)
  var inputDate = "";
// 数据是否加载中
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _testInsetBrandNewOneMealFoodItem();
  }

  _testInsetBrandNewOneMealFoodItem() async {
    print("开始运行插入示例---------");

    // _dietaryHelper.deleteDb();

    // await demoInsertDailyLogData();
    // return;

    // await _dietaryHelper.queryFoodDailyLogOnly();
    // await _dietaryHelper.queryAllFoodIntakeRecords();

    if (isLoading) return;

    setState(() {
      isLoading = true;
      inputDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    });

    // 理论上，当日的只会有一条
    var temp = await _dietaryHelper.queryFoodDailyLogRecord(date: inputDate);
    // 测试
    // var temp = await _dietaryHelper.queryFoodDailyLogRecord(date: "2023-10-24");

    print("---------测试暂时没有日记数据$temp");

    setState(() {
      fdlrList = temp;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DietaryRecords'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FoodList(
                          mealtime: Mealtimes.breakfast,
                          // 这里有个问题，如果数据没加载完，这里取不到值
                          // 可以把这个按钮的加载放在数据加载完之后显示
                          fdlr: fdlrList.isNotEmpty ? fdlrList[0] : null,
                          // ？？？注意，这里应该是一个日期选择器插件选中的值
                          logDate: getCurrentDate(),
                        )),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildLoader()
          : ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                final mealType = _getMealTypeByIndex(index);
                // 如果没有日记，就没有card的展开
                final mealFoodItems = fdlrList.isNotEmpty
                    ? _getMealFoodItemsByType(mealType)
                    : null;
                return _buildMealCard(mealType, mealFoodItems);
              },
            ),
    );
  }

  Widget _buildMealCard(
    String mealType,
    MealAndMealFoodItemDetail? mealFoodItems,
  ) {
    bool showExpansionTile = mealFoodItems != null;

    var cutMeal =
        mealtimeList.firstWhere((e) => e.label == mealType.toLowerCase());
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.album),
              title: Text(mealType),
              subtitle: Text(
                '${mealFoodItems?.mealFoodItemDetailist.length}',
              ),
              trailing: IconButton(
                onPressed: () {
                  print("日记主页面点击了餐次的add --------$mealType ${cutMeal.value}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodList(
                        mealtime: cutMeal.value,
                        // 这里有个问题，如果数据没加载完，这里取不到值
                        // 可以把这个按钮的加载放在数据加载完之后显示
                        fdlr: fdlrList.isNotEmpty ? fdlrList[0] : null,
                        // ？？？注意，这里应该是一个日期选择器插件选中的值
                        logDate: getCurrentDate(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.blue),
              ),
            ),
            const Divider(),
            if (showExpansionTile)
              ExpansionTile(
                title: Text(
                  '${mealFoodItems.mealFoodItemDetailist.length}',
                ),
                children: _buildListTile(
                    cutMeal, mealFoodItems.mealFoodItemDetailist),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListTile(
      CusDropdownOption cutMeal, List<MealFoodItemDetail>? list) {
    List<Widget> temp = [
      const Divider(),
    ];

    if (list == null) return temp;

    return list.map((mealFoodItemDetail) {
      return GestureDetector(
        onTap: () async {
          print("cutMeal-----${cutMeal.label}");

          print(
            "daily log index 的 指定餐次 点击了meal food item ，跳转到food detail ---> ",
          );

          // 先获取到当前item的食物信息，再传递到food detail
          var data = await _dietaryHelper.searchFoodWithServingInfoByFoodId(
              mealFoodItemDetail.food.foodId!);

          if (data == null) {
            // 抛出异常之后已经return了
            throw Exception("有meal food id找不到 food？");
          }

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodDetail(
                foodItem: data,
                mealtime: cutMeal.value,
                // ？？？注意，这里应该是一个日期选择器插件选中的值
                logDate: getCurrentDate(),
                jumpSource: 'LOG_INDEX',
                fdlr: fdlrList.isNotEmpty ? fdlrList[0] : null,
                mfid: mealFoodItemDetail,
              ),
            ),
          );
        },
        child: Dismissible(
          key: Key(mealFoodItemDetail.hashCode.toString()),
          onDismissed: (direction) {
            setState(() {
              list.remove(mealFoodItemDetail);
            });
          },
          background: Container(
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            title: Text(
              "${mealFoodItemDetail.food.brand}-${mealFoodItemDetail.food.product}",
            ),
            subtitle: Text('${mealFoodItemDetail.mealFoodItem.foodIntakeSize}'),
            trailing: SizedBox(
              width: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${mealFoodItemDetail.mealFoodItem.foodIntakeSize * mealFoodItemDetail.servingInfo.energy} 卡卡',
                  ),
                  const Icon(Icons.star),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLoader() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Container();
    }
  }

  String _getMealTypeByIndex(int index) {
    switch (index) {
      case 0:
        return 'Breakfast';
      case 1:
        return 'Lunch';
      case 2:
        return 'Dinner';
      case 3:
        return 'Other';
      default:
        throw Exception('Invalid index');
    }
  }

  MealAndMealFoodItemDetail? _getMealFoodItemsByType(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return fdlrList[0].breakfastMealFoodItems;
      case 'Lunch':
        return fdlrList[0].lunchMealFoodItems;
      case 'Dinner':
        return fdlrList[0].dinnerMealFoodItems;
      case 'Other':
        return fdlrList[0].otherMealFoodItems;
      default:
        throw Exception('Invalid meal type');
    }
  }
}

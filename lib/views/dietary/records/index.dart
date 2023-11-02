// ignore_for_file: avoid_print

import 'dart:developer';

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

  /// 根据条件查询的日记条目数据
  List<DailyFoodItemWithFoodServing> dfiwfsList = [];
  // 用户可能切换日期，但显示的内容是一样的(这个是日期组件的值，默认是当天)
  // (日期范围，可能只在导出时才用到，一般都是单日)
  var inputDate = "";
// 数据是否加载中
  bool isLoading = false;

  // 在标题处显示当前展示的日期信息（日期选择器之后有一点自定义处理）
  var showedDate = "今天";
  // 日期选择器中选择的日期，用于构建初始值，有选择后保留选择的，以及传入子组件
  var selectedDate = DateTime.now();

  // 这个插入的数据是比较完整正规的，测试时在删除db之后可直接用
  demoInsertDailyLogData() async {
    // 1 插入2个食物和对应3个单份营养素信息
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
      servingSize: 1,
      servingUnit: "包",
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
      updateUser: '',
      gmtModified: null,
    );

    await _dietaryHelper.insertFoodWithServingInfoList(
        food: food1, servingInfoList: [dserving1]);

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
      servingSize: 1,
      servingUnit: "只",
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
      updateUser: '',
      gmtModified: null,
    );

    await _dietaryHelper.insertFoodWithServingInfoList(
        food: food2, servingInfoList: [dserving2]);

    var dserving3 = ServingInfo(
      foodId: 2,
      servingSize: 100,
      servingUnit: "克",
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
      updateUser: '',
      gmtModified: null,
    );

    await _dietaryHelper
        .insertFoodWithServingInfoList(servingInfoList: [dserving3]);

    // 2 插入两条日志记录
    var temp1 = DailyFoodItem(
      // 主键数据库自增
      date: getCurrentDate(),
      mealCategory: "breakfast",
      foodId: 2,
      servingInfoId: 3,
      foodIntakeSize: 12,
      contributor: "马六",
      gmtCreate: DateTime.now().toString(),
      updateUser: null,
      gmtModified: null,
    );

    var temp2 = DailyFoodItem(
      // 主键数据库自增
      date: getCurrentDate(),
      mealCategory: "breakfast",
      foodId: 2,
      servingInfoId: 2,
      foodIntakeSize: 5,
      contributor: "马六",
      gmtCreate: DateTime.now().toString(),
      updateUser: null,
      gmtModified: null,
    );

    var temp3 = DailyFoodItem(
      // 主键数据库自增
      date: getCurrentDate(),
      mealCategory: "lunch",
      foodId: 1,
      servingInfoId: 1,
      foodIntakeSize: 14,
      contributor: "马六",
      gmtCreate: DateTime.now().toString(),
      updateUser: null,
      gmtModified: null,
    );

    await _dietaryHelper.insertDailyFoodItemList([temp1, temp2, temp3]);

    print("demoInsertDailyLogData------------插入执行完了");
  }

  @override
  void initState() {
    super.initState();

    _queryDailyFoodItemList();
  }

  // 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryDailyFoodItemList({String? userSelectedDate}) async {
    print("开始运行查询当日饮食日记条目---------");

    // _dietaryHelper.deleteDb();

    // await demoInsertDailyLogData();
    // return;

    if (isLoading) return;

    setState(() {
      isLoading = true;
      if (userSelectedDate == null || userSelectedDate == "") {
        inputDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      } else {
        inputDate = userSelectedDate;
      }
    });

    // 理论上是查询当日的
    var temp = await _dietaryHelper.queryDailyFoodItemListWithDetail(
      startDate: inputDate,
      endDate: inputDate,
    );

    log("---------测试查询的当前日记item $temp");

    setState(() {
      dfiwfsList = temp;
      isLoading = false;
    });
  }

  // 滑动删除指定饮食日记条目
  _removeDailyFoodItem(dailyFoodItemId) async {
    await _dietaryHelper.deleteDailyFoodItem(dailyFoodItemId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 饮食记录首页的日期选择器是单日的，可以不用第三方库，简单showDatePicker就好
        // 导出之类的可以花式选择日期的再用
        title: GestureDetector(
          child: Text(showedDate),
          onTap: () {
            _selectDate(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodList(
                    mealtime: Mealtimes.breakfast,
                    // 注意，这里应该是一个日期选择器插件选中的值，格式化为固定字符串，子组件就不再处理
                    logDate: DateFormat('yyyy-MM-dd').format(selectedDate),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildLoader()
          : ListView.builder(
              itemCount: mealtimeList.length,
              itemBuilder: (BuildContext context, int index) {
                final mealtime = mealtimeList[index];
                return _buildMealCard(mealtime);
              },
            ),
    );
  }

  Widget _buildMealCard(CusDropdownOption mealtime) {
    // 从查询的日记条目中过滤当前餐次的数据
    // DailyFoodItemWithFoodServingMealItems 太长了，缩写 dfiwfsMealItems
    var dfiwfsMealItems = dfiwfsList
        .where(
          (e) => e.dailyFoodItem.mealCategory == mealtime.label,
        )
        .toList();

    // 当前餐次有条目，展开行可用
    bool showExpansionTile = dfiwfsMealItems.isNotEmpty;

    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.album),
              title: Text("${mealtime.name}"),
              subtitle: Text('${dfiwfsMealItems.length}'),
              trailing: IconButton(
                onPressed: () {
                  print("日记主页面点击了餐次的add -------- ${mealtime.value}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 主页面点击餐次的添加是新增，没有旧数据，需要餐次和日期信息
                      builder: (context) => FoodList(
                        mealtime: mealtime.value,
                        // 注意，这里应该是一个日期选择器插件选中的值，格式化为固定字符串，子组件就不再处理
                        logDate: DateFormat('yyyy-MM-dd').format(selectedDate),
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
                  '${dfiwfsMealItems.length}',
                ),
                children: _buildListTile(mealtime, dfiwfsMealItems),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListTile(
    CusDropdownOption curMeal,
    List<DailyFoodItemWithFoodServing> list,
  ) {
    List<Widget> temp = [
      const Divider(),
    ];

    if (list.isEmpty) return temp;

    return list.map((logItem) {
      var totalEnergyStr =
          '${logItem.dailyFoodItem.foodIntakeSize * logItem.servingInfo.energy} 千焦';

      var totalCalStr =
          "${(logItem.dailyFoodItem.foodIntakeSize * logItem.servingInfo.energy / oneCalToKjRatio).toStringAsFixed(2)} 大卡";

      return GestureDetector(
        onTap: () async {
          print("cutMeal-----${curMeal.label}");

          print(
            "daily log index 的 指定餐次 点击了meal food item ，跳转到food detail ---> ",
          );

          // 先获取到当前item的食物信息，再传递到food detail
          var data = await _dietaryHelper
              .searchFoodWithServingInfoByFoodId(logItem.dailyFoodItem.foodId);

          if (data == null) {
            // 抛出异常之后已经return了
            throw Exception("有meal food id找不到 food？");
          }

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              // 主页面点击item详情是修改或删除，只需要传入食物信息和item详情就好
              builder: (context) => FoodDetail(foodItem: data, dfiwfs: logItem),
            ),
          );
        },
        child: Dismissible(
          key: Key(logItem.hashCode.toString()),
          onDismissed: (direction) async {
            print("logItem-------------------$logItem");
            // 确认滑动移除之后，要重新查询当日数据构建卡片（全部重绘感觉有点浪费）
            await _removeDailyFoodItem(logItem.dailyFoodItem.dailyFoodItemId);
            _queryDailyFoodItemList();
          },
          background: Container(
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            title: Text(
              "${logItem.food.brand}-${logItem.food.product}",
            ),
            subtitle: Text('${logItem.dailyFoodItem.foodIntakeSize}'),
            trailing: SizedBox(
              width: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("$totalEnergyStr-$totalCalStr")),
                  const Expanded(child: Icon(Icons.star)),
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

  // 导航栏处点击显示日期选择器
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1994, 7),
        lastDate: DateTime(2077));

    if (!mounted) return;
    if (picked != null) {
      // 包含了月日星期，其他格式修改 MMMEd 为其他即可
      var formatDate = DateFormat('MMMEd', "zh_CN").format(picked);

      print("选择的日期、星期信息----$picked $formatDate");

      print(picked.day == DateTime.now().day);

      // 昨天今天明天三天的显示可以特殊一点，比较的话就比较对应年月日转换的字符串即可
      var today = DateTime.now();
      var todayStr = "${today.year}${today.month}${today.day}";
      var yesterdayStr = "${today.year}${today.month}${today.day - 1}";
      var tomorrowStr = "${today.year}${today.month}${today.day + 1}";
      var pickedDateStr = "${picked.year}${picked.month}${picked.day}";

      if (pickedDateStr == yesterdayStr) {
        formatDate = "昨天";
      } else if (pickedDateStr == todayStr) {
        formatDate = "今天";
      } else if (pickedDateStr == tomorrowStr) {
        formatDate = "明天";
      }

      print("格式化之后----$pickedDateStr $todayStr $yesterdayStr $tomorrowStr");

      setState(() {
        selectedDate = picked;
        showedDate = formatDate;
        _queryDailyFoodItemList(
          userSelectedDate: DateFormat('yyyy-MM-dd').format(picked),
        );
      });
    }
  }
}

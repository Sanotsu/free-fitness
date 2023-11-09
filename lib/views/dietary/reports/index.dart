// ignore_for_file: avoid_print

import 'dart:developer';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/sqlite_db_helper.dart';
import '../../../models/dietary_state.dart';

class DietaryReports extends StatefulWidget {
// 报告页面默认查看当日的，但有可能从别的页面跳转过来，并带上需要查询的日期
// ？？？注意：是否区分 日、月、周、年？
  final String? date;

  const DietaryReports({super.key, this.date});

  @override
  State<DietaryReports> createState() => _DietaryReportsState();
}

class _DietaryReportsState extends State<DietaryReports> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  /// 根据条件查询的日记条目数据
  List<DailyFoodItemWithFoodServing> dfiwfsList = [];

  /// 根据日记条目整理的营养素VO信息
  FoodNutrientVO fnVO = FoodNutrientVO.initWithZero();

  // RDA 的值应该在用户配置表里面带出来，在init的时候赋值。现在没有实现所以列个示例在这里
  int valueRDA = 0;

// 数据是否加载中
  bool isLoading = false;

  // 在标题处显示当前展示的日期信息（日期选择器之后有一点自定义处理）
  String showedDateStr = "今天";

  CusDropdownOption dropdownValue = dietaryReportDisplayModeList.first;

  @override
  void initState() {
    super.initState();

    setState(() {
      valueRDA = 1800;
      _queryDailyFoodItemList();
    });
  }

  getDateByOption(String flag) {
    var lowerFlag = flag.toLowerCase();
    var tempMap = {"startDate": "", "endDate": ""};
    String startTemp = "";
    String endTemp = "";

    switch (lowerFlag) {
      case "today":
        var temp = DateTime.now();
        startTemp = endTemp = DateFormat('yyyy-MM-dd').format(temp);
        break;
      case "yesterday":
        var temp = DateTime.now().subtract(const Duration(days: 1));
        startTemp = endTemp = DateFormat('yyyy-MM-dd').format(temp);
        break;
      case "this_week":
        DateTime now = DateTime.now();
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        DateTime endOfWeek = now.add(Duration(days: 7 - now.weekday));
        startTemp = DateFormat('yyyy-MM-dd').format(startOfWeek);
        endTemp = DateFormat('yyyy-MM-dd').format(endOfWeek);
        break;
      case "last_week":
        DateTime now = DateTime.now();
        DateTime startOfLastWeek =
            now.subtract(Duration(days: now.weekday + 6));
        DateTime endOfLastWeek = now.subtract(Duration(days: now.weekday));
        startTemp = DateFormat('yyyy-MM-dd').format(startOfLastWeek);
        endTemp = DateFormat('yyyy-MM-dd').format(endOfLastWeek);
        break;
    }

    tempMap = {"startDate": startTemp, "endDate": endTemp};
    return tempMap;
  }

  // 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryDailyFoodItemList({Map<String, String>? queryDateRange}) async {
    print("开始运行查询当日饮食日记条目---------");

    // _dietaryHelper.deleteDb();

    // await demoInsertDailyLogData();
    // return;

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 如果没有给定查询范围，就查询今天
    queryDateRange ??= {
      "startDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "endDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };

    // 理论上是默认查询当日的，有选择其他日期则查询指定日期
    var temp = await _dietaryHelper.queryDailyFoodItemListWithDetail(
      startDate: queryDateRange["startDate"],
      endDate: queryDateRange["endDate"],
    );

    print("queryDateRange--$queryDateRange ${temp.length}");

    log("---------测试查询的当前日记item $temp");

    setState(() {
      dfiwfsList = temp;
      fnVO = formatData(dfiwfsList);
      isLoading = false;
    });
  }

  formatData(List<DailyFoodItemWithFoodServing> list) {
    var tempEnergy = 0.0;
    var tempProtein = 0.0;
    var tempFat = 0.0;
    var tempCHO = 0.0;
    // 这几个在底部总计可能用到
    var tempSodium = 0.0;
    var tempCholesterol = 0.0;
    var tempPotassium = 0.0;
    var tempDietaryFiber = 0.0;
    var tempSugar = 0.0;
    var tempTransFat = 0.0;
    var tempSaturatedFat = 0.0;
    var tempPuF = 0.0;
    var tempMuF = 0.0;

    // 按营养素分类统计总量
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
      tempTransFat += foodIntakeSize * (servingInfo.transFat ?? 0);
      tempSaturatedFat += foodIntakeSize * (servingInfo.saturatedFat ?? 0);
      tempMuF += foodIntakeSize * (servingInfo.monounsaturatedFat ?? 0);
      tempPuF += foodIntakeSize * (servingInfo.polyunsaturatedFat ?? 0);
    }

    var tempCalories = tempEnergy / oneCalToKjRatio;

    var tempBreakfast = 0.0;
    var tempLunch = 0.0;
    var tempDinner = 0.0;
    var tempOther = 0.0;
    // 按餐次统计总量

    for (var e in list) {
      var foodIntakeSize = e.dailyFoodItem.foodIntakeSize;
      var servingInfo = e.servingInfo;
      if (e.dailyFoodItem.mealCategory == "breakfast") {
        tempBreakfast += foodIntakeSize * servingInfo.energy;
      } else if (e.dailyFoodItem.mealCategory == "lunch") {
        tempLunch += foodIntakeSize * servingInfo.energy;
      } else if (e.dailyFoodItem.mealCategory == "dinner") {
        tempDinner += foodIntakeSize * servingInfo.energy;
      } else if (e.dailyFoodItem.mealCategory == "other") {
        tempOther += foodIntakeSize * servingInfo.energy;
      }
    }

    print(
        "tempBreakfast,tempLunch,tempDinner,tempOther $tempBreakfast,$tempLunch,$tempDinner,$tempOther");

    FoodNutrientVO fn = FoodNutrientVO(
      energy: tempEnergy,
      calorie: tempCalories,
      protein: tempProtein,
      totalFat: tempFat,
      totalCarbohydrate: tempCHO,
      sodium: tempSodium,
      saturatedFat: tempSaturatedFat,
      transFat: tempTransFat,
      polyunsaturatedFat: tempPuF,
      monounsaturatedFat: tempMuF,
      sugar: tempSugar,
      dietaryFiber: tempDietaryFiber,
      cholesterol: tempCholesterol,
      potassium: tempPotassium,
      breakfastColories: tempBreakfast / oneCalToKjRatio,
      lunchColories: tempLunch / oneCalToKjRatio,
      dinnerColories: tempDinner / oneCalToKjRatio,
      otherColories: tempOther / oneCalToKjRatio,
    );

    return fn;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 选项卡的数量
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DietaryReports '),
          bottom: const TabBar(
            tabs: [
              Tab(text: "卡路里"),
              Tab(icon: Icon(Icons.directions_transit)),
              Tab(icon: Icon(Icons.directions_bike)),
            ],
          ),
          actions: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DropdownButton(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10),
                  ),

                  items: dietaryReportDisplayModeList
                      .map<DropdownMenuItem<CusDropdownOption>>(
                        (CusDropdownOption value) =>
                            DropdownMenuItem<CusDropdownOption>(
                          value: value,
                          child: Text(
                            value.name!,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20.sp,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  value: dropdownValue,
                  onChanged: (CusDropdownOption? newValue) {
                    setState(() {
                      // 修改下拉按钮的显示值
                      dropdownValue = newValue!;
                      var dateRange = getDateByOption(dropdownValue.value);
                      _queryDailyFoodItemList(queryDateRange: dateRange);
                    });
                  },
                  isExpanded: false,
                  underline: Container(), // 将下划线设置为空的Container
                ),
                Padding(
                  padding: EdgeInsets.only(right: 10.sp),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.flag_circle),
                  ),
                ),
              ],
            )
          ],
        ),
        body: isLoading
            ? _buildLoader()
            : Column(
                children: [
                  // buildDropdownButton(),
                  // Container(
                  //   // 整个table的背景色
                  //   color: Colors.blue,
                  //   child: TabBar(
                  //     // 指示器颜色
                  //     indicator: BoxDecoration(
                  //       color: Colors.green, // 设置选项卡指示器的颜色
                  //       borderRadius: BorderRadius.circular(4.0),
                  //     ),
                  //     tabs: const [
                  //       Tab(text: 'Tab 1'),
                  //       Tab(text: 'Tab 2'),
                  //       Tab(text: 'Tab 3'),
                  //     ],
                  //   ),
                  // ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          child: buildCalorieTabview(),
                        ),
                        // 第一个选项卡的内容
                        Center(
                            child: Text(
                                'DietaryReports index ${dfiwfsList.length}')),
                        // 第二个选项卡的内容
                        Center(child: Text('Tab 3 Content ${fnVO.calorie}')),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
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

  /// 卡路里tab页面
  /// 从上到下分别是：
  ///  1 当前选中日期范围(昨天今天上周本周)三大营养素的饼图，点击图形看具体数值；
  ///     上方显示今日RDA和已消耗的总量及其比例，超过100%红色，没超过绿色。
  ///     下方显示4餐次总共的卡数和比例。
  ///  2 食物摄入图表，日期范围一共摄入量多少种食物，每种食物多少次，每种总计多少卡
  buildCalorieTabview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// 当日主要营养素占比卡片
        _buildMealCalorieChartCard(),

        /// 食物摄入条目统计卡片
        _buildMealCalorieListCard(),
      ],
    );
  }

  _buildMealCalorieChartCard() {
    return Card(
      elevation: 10,
      child: SizedBox(
        height: 300.sp,
        child: Column(
          children: [
            ListTile(
              title: RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: '卡路里\n',
                      style: TextStyle(fontSize: 16.sp, color: Colors.black),
                    ),
                    TextSpan(
                      text: fnVO.calorie.toStringAsFixed(2),
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              subtitle: Row(
                // 让子组件分别靠左和靠右对齐
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      flex: 1,
                      child: Text(
                        "目标已达成 ${(fnVO.calorie / valueRDA * 100).toStringAsFixed(2)} %",
                        textAlign: TextAlign.left,
                      )),
                  Expanded(
                      flex: 1,
                      child: Text(
                        "目标 $valueRDA 大卡",
                        textAlign: TextAlign.right,
                      )),
                ],
              ),
            ),
            Divider(height: 5.sp, thickness: 2.sp),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 左边图例
                  Expanded(
                    flex: 2,
                    child: _buildMealCaloriePieLegend(),
                  ),
                  // 右边饼图
                  Expanded(
                    flex: 1,
                    child: _buildMealCaloriePieChart(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 日期范围餐次图例
  _buildMealCaloriePieLegend() {
    double total = fnVO.breakfastColories! +
        fnVO.lunchColories! +
        fnVO.dinnerColories! +
        fnVO.otherColories!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(Colors.grey, '早餐', fnVO.breakfastColories!, total),
        _buildLegendItem(Colors.red, '午餐', fnVO.lunchColories!, total),
        _buildLegendItem(Colors.green, '晚餐', fnVO.dinnerColories!, total),
        _buildLegendItem(Colors.blue, '小食', fnVO.otherColories!, total),
      ],
    );
  }

  // 构建单个图例条目
  Widget _buildLegendItem(
    Color color,
    String label,
    double value,
    double total,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.sp),
      child: Row(
        children: [
          Container(width: 16.sp, height: 16.sp, color: color),
          SizedBox(width: 8.sp),
          Expanded(
            child: Text(
              '$label - ${(value / total * 100).toStringAsFixed(1)}% - ${value.toStringAsFixed(2)} 大卡',
            ),
          ),
        ],
      ),
    );
  }

  // 日期范围餐次饼图
  _buildMealCaloriePieChart() {
    return SizedBox(
      height: 100.sp,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: fnVO.breakfastColories,
              color: Colors.grey,
              // title: '${percentage.toStringAsFixed(1)}%', // 将百分比显示在标题中
              // 没给指定title就默认是其value，所以有图例了就不显示标题
              showTitle: false,
            ),
            PieChartSectionData(
                value: fnVO.lunchColories, color: Colors.red, showTitle: false),
            PieChartSectionData(
                value: fnVO.dinnerColories,
                color: Colors.green,
                showTitle: false),
            PieChartSectionData(
                value: fnVO.otherColories, color: Colors.blue, showTitle: false)
          ],
        ),
      ),
    );
  }

  /// 按照每种食物统计总摄入
  _buildMealCalorieListCard() {
    Map<String, List<DailyFoodItemWithFoodServing>> splitArrays = {};

    // 先把当前日期范围的饮食记录条目按食物拆分成子列表,顺便记录总卡路里
    double totalEnergy = 0;
    for (var el in dfiwfsList) {
      // 这里的key无法存food，因为就算food的内容一样(同一个食物)，但实例都是不同的
      var foodName = "${el.food.product}(${el.food.brand})";
      splitArrays.putIfAbsent(foodName, () => []);
      splitArrays[foodName]!.add(el);

      var foodIntakeSize = el.dailyFoodItem.foodIntakeSize;
      var servingInfo = el.servingInfo;
      totalEnergy += foodIntakeSize * servingInfo.energy;
    }
    var totalCalories = totalEnergy / oneCalToKjRatio;

    // 每种食物的摄入次数和总量
    List<DataRow> tempRows = splitArrays.entries.map((entry) {
      // 累加每种食物的输入总卡路里量
      double tempEnergy = entry.value.fold(0, (prev, item) {
        var foodIntakeSize = item.dailyFoodItem.foodIntakeSize;
        var servingInfo = item.servingInfo;
        return prev + foodIntakeSize * servingInfo.energy;
      });
      var tempCalories = tempEnergy / oneCalToKjRatio;

      return DataRow(
        cells: [
          DataCell(SizedBox(width: 150.sp, child: Text(entry.key))),
          DataCell(Text(entry.value.length.toString())),
          DataCell(
            SizedBox(
              width: 80.sp,
              child: Text(
                "${tempCalories.toStringAsFixed(2)} ",
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      );
    }).toList();

    // 最后一行是食物条目累计的总量
    tempRows.add(DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 150.sp,
            child: const Text(
              "合计",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          Text(
            "x ${dfiwfsList.length}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          SizedBox(
            width: 80.sp,
            child: Text(
              "${totalCalories.toStringAsFixed(2)} ",
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ));

    return Card(
      elevation: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const ListTile(title: Text('食物摄入')),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.sp),
            child: DataTable(
              // 每一列的间隔
              columnSpacing: 10.0,
              columns: const [
                DataColumn(label: Text('食物名称')),
                DataColumn(label: Text('摄入次数'), numeric: true),
                DataColumn(label: Text('摄入(大卡)'), numeric: true),
              ],
              rows: tempRows,
            ),
          ),
        ],
      ),
    );
  }

  buildMainNutrientsPieChart() {
    return Container();
  }

  buildMainNutrientsList() {
    return Container();
  }

  buildDropdownButton() {
    return SizedBox(
      height: 50.sp,
      // 下拉框四周添加框线
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(4.0.sp)),
        ),
        child: DropdownButton(
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
          items: dietaryReportDisplayModeList
              .map<DropdownMenuItem<CusDropdownOption>>(
                (CusDropdownOption value) =>
                    DropdownMenuItem<CusDropdownOption>(
                  value: value,
                  child: Text(value.label),
                ),
              )
              .toList(),
          value: dropdownValue,
          onChanged: (CusDropdownOption? newValue) {
            setState(() {
              // 修改下拉按钮的显示值
              dropdownValue = newValue!;
              var dateRange = getDateByOption(dropdownValue.value);
              _queryDailyFoodItemList(queryDateRange: dateRange);
            });
          },
          isExpanded: false,
        ),
      ),
    );

    /*
    return SizedBox(
      width: 0.6.sw,
      height: 50.sp,
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(1.0),
            gapPadding: 0.5,
          ),
        ),
        child: DropdownButton<CusDropdownOption>(
          value: dropdownValue,
          onChanged: (CusDropdownOption? newValue) {
            setState(() {
              // 修改下拉按钮的显示值
              dropdownValue = newValue!;
              var dateRange = getDateByOption(dropdownValue.value);
              _queryDailyFoodItemList(queryDateRange: dateRange);
            });
          },
          items: dietaryReportDisplayModeList
              .map<DropdownMenuItem<CusDropdownOption>>(
                (CusDropdownOption value) =>
                    DropdownMenuItem<CusDropdownOption>(
                  value: value,
                  child: Text(value.label),
                ),
              )
              .toList(),
          // underline: Container(), // 将下划线设置为空的Container
          // icon: null, // 将图标设置为null
        ),
      ),
    );
    */
  }
}

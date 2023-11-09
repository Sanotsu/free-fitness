// ignore_for_file: avoid_print

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
  /// ？？？暂时没做 类型不同：单日的是FoodNutrientTotals，单周的是Map<String, FoodNutrientTotals>
  FoodNutrientTotals fnVO = FoodNutrientTotals();

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

    // log("---------测试查询的当前日记item $temp");

    setState(() {
      dfiwfsList = temp;

      // ？？？注意：这个判断还要改，有常量这里还是魔法值来判断
      // 不是查询昨天、今天，就是上周本周，显示的内容不一样。
      // if (dropdownValue.value == "today" ||
      //     dropdownValue.value == "yesterday") {
      //   fnVO = formatData(dfiwfsList);
      // } else {
      //   fnVO = formatWeekData(dfiwfsList);
      // }
      fnVO = formatData(dfiwfsList);
      // 这里一周7条时，应该换成柱状图，数据处理有了，图暂时没做

      isLoading = false;
    });
  }

  // 格式化饮食记录数据(单天)
  FoodNutrientTotals formatData(List<DailyFoodItemWithFoodServing> list) {
    var nt = FoodNutrientTotals();

    for (var item in list) {
      var foodIntakeSize = item.dailyFoodItem.foodIntakeSize;
      var servingInfo = item.servingInfo;
      var cate = item.dailyFoodItem.mealCategory;

      // 按餐次统计总量
      if (cate == "breakfast") {
        nt.bfEnergy += foodIntakeSize * servingInfo.energy;
      } else if (cate == "lunch") {
        nt.lunchEnergy += foodIntakeSize * servingInfo.energy;
      } else if (cate == "dinner") {
        nt.dinnerEnergy += foodIntakeSize * servingInfo.energy;
      } else if (cate == "other") {
        nt.otherEnergy += foodIntakeSize * servingInfo.energy;
      }

      // 按营养素分类统计总量
      nt.energy += foodIntakeSize * servingInfo.energy;
      nt.protein += foodIntakeSize * servingInfo.protein;
      nt.totalFat += foodIntakeSize * servingInfo.totalFat;
      nt.totalCHO += foodIntakeSize * servingInfo.totalCarbohydrate;
      nt.sodium += foodIntakeSize * servingInfo.sodium;
      nt.cholesterol += foodIntakeSize * (servingInfo.cholesterol ?? 0);
      nt.dietaryFiber += foodIntakeSize * (servingInfo.dietaryFiber ?? 0);
      nt.potassium += foodIntakeSize * (servingInfo.potassium ?? 0);
      nt.sugar += foodIntakeSize * (servingInfo.sugar ?? 0);
      nt.transFat += foodIntakeSize * (servingInfo.transFat ?? 0);
      nt.saturatedFat += foodIntakeSize * (servingInfo.saturatedFat ?? 0);
      nt.muFat += foodIntakeSize * (servingInfo.monounsaturatedFat ?? 0);
      nt.puFat += foodIntakeSize * (servingInfo.polyunsaturatedFat ?? 0);
    }

    // 对应总的卡路里输
    nt.calorie = nt.energy / oneCalToKjRatio;
    nt.bfCalorie = nt.bfEnergy / oneCalToKjRatio;
    nt.lunchCalorie = nt.lunchEnergy / oneCalToKjRatio;
    nt.dinnerCalorie = nt.dinnerEnergy / oneCalToKjRatio;
    nt.otherCalorie = nt.otherEnergy / oneCalToKjRatio;

    return nt;
  }

  // 格式化饮食记录数据(一周7填)
  Map<String, FoodNutrientTotals> formatWeekData(
      List<DailyFoodItemWithFoodServing> list) {
    // 按天拆分饮食记录条目，key是日期，value是当日的饮食记录
    Map<String, List<DailyFoodItemWithFoodServing>> dailyListMap = {};

    for (var el in dfiwfsList) {
      var dateStr = el.dailyFoodItem.date;
      dailyListMap.putIfAbsent(dateStr, () => []);
      dailyListMap[dateStr]!.add(el);
    }

    // 再按天把拆分后的饮食记录条目整理成累计营养素信息，key是日期，value是 FoodNutrientTotals 类
    Map<String, FoodNutrientTotals> tempMap = {};
    dailyListMap.forEach((key, value) {
      tempMap[key] = formatData(value);
    });

    print("查询一周的结果---$tempMap");

    return tempMap;
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
              Tab(text: "宏量素"),
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
                        SingleChildScrollView(
                          child: buildMacrosTabview(),
                        ),
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
        _buildFoodStatsPieChartCard(),

        /// 食物摄入条目统计卡片
        _buildFoodStatsListCard('食物摄入', dfiwfsList),
      ],
    );
  }

  /// 宏量macronutrients 卡片和卡路里卡片布局基本类似，可以考虑复用
  buildMacrosTabview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// 当日主要营养素占比卡片
        _buildFoodStatsPieChartCard(type: "Macros"),

        /// 食物摄入宏量统计卡片
        _buildFoodStatsListCard('宏量素摄入', dfiwfsList),
      ],
    );
  }

  /// 绘制卡路里摄入或宏量素摄入的饼图【卡片】
  _buildFoodStatsPieChartCard({String? type = "Calorie"}) {
    return Card(
      elevation: 10,
      child: SizedBox(
        height: type == "Calorie" ? 300.sp : 200.sp,
        child: Column(
          children: [
            // 是卡路里
            if (type == "Calorie")
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
                    child: type == "Calorie"
                        ? _buildMealCaloriePieLegend()
                        : _buildMacrosPieLegend(),
                  ),
                  // 右边饼图
                  Expanded(
                    flex: 1,
                    child: type == "Calorie"
                        ? _buildMealCaloriePieChart()
                        : _buildMacrosPieChart(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 绘制卡路里摄入饼图的图例
  _buildMealCaloriePieLegend() {
    double total = fnVO.bfCalorie +
        fnVO.lunchCalorie +
        fnVO.dinnerCalorie +
        fnVO.otherCalorie;

    print("total---------$total");

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(Colors.grey, '早餐', fnVO.bfCalorie, total),
        _buildLegendItem(Colors.red, '午餐', fnVO.lunchCalorie, total),
        _buildLegendItem(Colors.green, '晚餐', fnVO.dinnerCalorie, total),
        _buildLegendItem(Colors.blue, '小食', fnVO.otherCalorie, total),
      ],
    );
  }

  /// 绘制宏量素摄入的饼图的图例
  _buildMacrosPieLegend() {
    double total = fnVO.totalCHO + fnVO.totalFat + fnVO.protein;

    print("_buildMacrosPieLegend total---------$total");

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(Colors.grey, '碳水', fnVO.totalCHO, total),
        _buildLegendItem(Colors.red, '脂肪', fnVO.totalFat, total),
        _buildLegendItem(Colors.green, '蛋白质', fnVO.protein, total),
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
              value: fnVO.bfCalorie,
              color: Colors.grey,
              // title: '${percentage.toStringAsFixed(1)}%', // 将百分比显示在标题中
              // 没给指定title就默认是其value，所以有图例了就不显示标题
              showTitle: false,
            ),
            PieChartSectionData(
                value: fnVO.lunchCalorie, color: Colors.red, showTitle: false),
            PieChartSectionData(
                value: fnVO.dinnerCalorie,
                color: Colors.green,
                showTitle: false),
            PieChartSectionData(
                value: fnVO.otherCalorie, color: Colors.blue, showTitle: false)
          ],
        ),
      ),
    );
  }

  // 日期宏量素饼图
  _buildMacrosPieChart() {
    return SizedBox(
      height: 100.sp,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
                value: fnVO.totalCHO, color: Colors.grey, showTitle: false),
            PieChartSectionData(
                value: fnVO.totalFat, color: Colors.red, showTitle: false),
            PieChartSectionData(
                value: fnVO.protein, color: Colors.green, showTitle: false),
          ],
        ),
      ),
    );
  }

  /// 按照每种食物统计总卡路里摄入 或 总宏量素摄入 的列表【卡片】
  /// (两个tabview的表格结构类似，内容不同而已，可复用)
  _buildFoodStatsListCard(
    String title,
    List<DailyFoodItemWithFoodServing> dfiwfsList,
  ) {
    Map<String, List<DailyFoodItemWithFoodServing>> splitArrays = {};

    for (var el in dfiwfsList) {
      var foodName = "${el.food.product}(${el.food.brand})";
      splitArrays.putIfAbsent(foodName, () => []);
      splitArrays[foodName]!.add(el);
    }

    List<DataRow> tempRows = splitArrays.entries.map((entry) {
      var tempNt = formatData(entry.value);
      if (title == '食物摄入') {
        return DataRow(
          cells: [
            DataCell(Text(entry.key)),
            DataCell(Text(entry.value.length.toString())),
            DataCell(Text(tempNt.calorie.toStringAsFixed(2))),
          ],
        );
      } else {
        return DataRow(
          cells: [
            DataCell(Text(entry.key)),
            DataCell(Text(tempNt.totalCHO.toStringAsFixed(2))),
            DataCell(Text(tempNt.totalFat.toStringAsFixed(2))),
            DataCell(Text(tempNt.protein.toStringAsFixed(2))),
          ],
        );
      }
    }).toList();

    tempRows.add(DataRow(
      cells: [
        const DataCell(
          Text("合计", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataCell(
          Text(
            title == '食物摄入'
                ? "x ${dfiwfsList.length}"
                : fnVO.totalCHO.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          SizedBox(
            child: Text(
              title == '食物摄入'
                  ? fnVO.calorie.toStringAsFixed(2)
                  : fnVO.totalFat.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (title != '食物摄入')
          DataCell(
            SizedBox(
              child: Text(
                fnVO.protein.toStringAsFixed(2),
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
          ListTile(title: Text(title)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.sp),
            child: DataTable(
              columnSpacing: 10.0,
              columns: title == '食物摄入'
                  ? const [
                      DataColumn(label: Text('食物名称')),
                      DataColumn(label: Text('摄入次数'), numeric: true),
                      DataColumn(label: Text('摄入(大卡)'), numeric: true),
                    ]
                  : const [
                      DataColumn(label: Text('食物名称')),
                      DataColumn(label: Text('碳水(克)'), numeric: true),
                      DataColumn(label: Text('脂肪(克)'), numeric: true),
                      DataColumn(label: Text('蛋白质(克)'), numeric: true),
                    ],
              rows: tempRows,
            ),
          ),
        ],
      ),
    );
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

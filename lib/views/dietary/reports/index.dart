// ignore_for_file: avoid_print

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/user_state.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../models/dietary_state.dart';
import 'export/report_pdf_viewer.dart';
import 'week_intake_bar.dart';

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
  final DBUserHelper _userHelper = DBUserHelper();
  // 获取缓存中的用户编号(理论上进入app主页之后，就一定有一个默认的用户编号了)
  final box = GetStorage();
  int get currentUserId => box.read(LocalStorageKey.userId) ?? 1;

  /// 根据条件查询的日记条目数据(所有数据的来源，格式化成VO可以在指定函数中去做)
  List<DailyFoodItemWithFoodServing> dfiwfsList = [];

  // RDA 的值应该在用户配置表里面带出来，在init的时候赋值。现在没有实现所以列个示例在这里
  late User loginUser;
  // 如果用户没有设定，则使用预设值2250或1800
  int valueRDA = 1800;

  // 数据是否加载中
  bool isLoading = false;

  // 下拉切换的日期范围(默认今天)
  CusLabel dropdownValue = dietaryReportDisplayModeList.first;

  // 导出数据时默认选中为最近7天
  CusLabel exportValue = exportDateList.first;

  @override
  void initState() {
    super.initState();

    setState(() {
      _queryDailyFoodItemList();
    });
  }

  /// 通过下拉按钮获取统计的范围日期
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

  /// 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryDailyFoodItemList({Map<String, String>? queryDateRange}) async {
    print("开始运行查询当日饮食日记条目---------");

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 如果没有给定查询范围，就查询今天
    queryDateRange ??= {
      "startDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "endDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };

    // 理论上是默认查询当日的，有选择其他日期则查询指定日期？？？还要是登录者这个用户编号的
    var temp = (await _dietaryHelper.queryDailyFoodItemListWithDetail(
      startDate: queryDateRange["startDate"],
      endDate: queryDateRange["endDate"],
      withDetail: true,
    ) as List<DailyFoodItemWithFoodServing>);

    // 查询用户目标值
    var tempUser = await _userHelper.queryUser(userId: currentUserId);

    print("queryDateRange--$queryDateRange ${temp.length}");

    // log("---------测试查询的当前日记item $temp");

    setState(() {
      dfiwfsList = temp;

      if (tempUser != null) {
        valueRDA = tempUser.rdaGoal != null
            ? tempUser.rdaGoal!
            : tempUser.gender == "男"
                ? 2250
                : 1800;
      }

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
      if (cate == mealNameMap[CusMeals.breakfast]!.enLabel) {
        nt.bfEnergy += foodIntakeSize * servingInfo.energy;
      } else if (cate == mealNameMap[CusMeals.lunch]!.enLabel) {
        nt.lunchEnergy += foodIntakeSize * servingInfo.energy;
      } else if (cate == mealNameMap[CusMeals.dinner]!.enLabel) {
        nt.dinnerEnergy += foodIntakeSize * servingInfo.energy;
      } else if (cate == mealNameMap[CusMeals.other]!.enLabel) {
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
  // key是日期，比如2023-11-12,value是营养素VO；但如果某天没有记录，则不会有数据
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
              Tab(text: "营养素(未完)"),
            ],
          ),
          actions: [
            // 下拉按钮，切换报告的时间范围
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DropdownButton(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10),
                  ),

                  items: dietaryReportDisplayModeList
                      .map<DropdownMenuItem<CusLabel>>(
                        (CusLabel value) => DropdownMenuItem<CusLabel>(
                          value: value,
                          child: Text(
                            value.cnLabel,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20.sp,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  value: dropdownValue,
                  onChanged: (CusLabel? newValue) {
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
              ],
            ),
            IconButton(
              onPressed: () async {
                var dateSelected = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('选择日期范围'),
                      content: DropdownMenu<CusLabel>(
                        initialSelection: exportDateList.first,
                        onSelected: (CusLabel? value) {
                          setState(() {
                            exportValue = value!;
                          });
                        },
                        dropdownMenuEntries: exportDateList
                            .map<DropdownMenuEntry<CusLabel>>((CusLabel value) {
                          return DropdownMenuEntry<CusLabel>(
                            value: value,
                            label: value.cnLabel,
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: const Text('确认'),
                        ),
                      ],
                    );
                  },
                );
                // 弹窗选择导出范围不为空，且不为false，则默认是选择的日期范围
                if (dateSelected != null && dateSelected) {
                  String tempStart, tempEnd;
                  if (exportValue.value == "seven") {
                    [tempStart, tempEnd] = getStartEndDateString(7);
                  } else if (exportValue.value == "thirty") {
                    [tempStart, tempEnd] = getStartEndDateString(30);
                  } else {
                    // 导出全部就近20年吧
                    [tempStart, tempEnd] = getStartEndDateString(365 * 20);
                  }

                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportPdfViewer(
                        startDate: tempStart,
                        endDate: tempEnd,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.print),
            ),
            // Padding(
            //   padding: EdgeInsets.only(right: 10.sp),
            //   child: IconButton(
            //     onPressed: () {},
            //     icon: const Icon(Icons.flag_circle),
            //   ),
            // ),
          ],
        ),
        body: isLoading
            ? buildLoader(isLoading)
            : TabBarView(
                children: [
                  SingleChildScrollView(child: buildCalorieTabView()),
                  SingleChildScrollView(child: buildMacrosTabView()),
                  SingleChildScrollView(child: buildNutrientsTabView()),
                ],
              ),
      ),
    );
  }

  /// *******************************卡路里 tabview *****************************************
  /// 卡路里tab页面
  /// 从上到下分别是：
  ///  1 当前选中日期范围(昨天今天上周本周)三大营养素的饼图，点击图形看具体数值；
  ///     上方显示今日RDA和已消耗的总量及其比例，超过100%红色，没超过绿色(仅选择昨天、今天时)。
  ///     下方显示4餐次总共的卡数和比例(昨天今天是饼图，上周本周是柱状图)。
  ///  2 食物摄入图表，日期范围一共摄入量多少种食物，每种食物多少次，每种总计多少卡
  buildCalorieTabView() {
    // 【注意】如果是单日的（昨天、进入，则显示饼图，如果是上周、本周则是柱状图）
    List<Widget> chart = [];
    if (dropdownValue.value == "today" || dropdownValue.value == "yesterday") {
      /// 单日的卡路里标题
      chart.add(_buildCaloryCardTitle(formatData(dfiwfsList)));

      /// 当日主要营养素占比饼图卡片(默认其实就是卡路里的平涂)
      chart
          .add(_buildPieChartCard(formatData(dfiwfsList), CusChartType.calory));
    } else {
      // 当周的营养素条状图
      chart = [
        _buildBarChartCard(formatWeekData(dfiwfsList), CusChartType.calory)
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...chart,

        /// 食物摄入条目统计卡片(类型为name表示食物摄入次数)
        _buildDataTableCard(dfiwfsList, CusChartType.calory),
      ],
    );
  }

  // 卡路里tabview的标题
  _buildCaloryCardTitle(FoodNutrientTotals fntVO) {
    return ListTile(
      title: RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: '卡路里\n',
              style: TextStyle(fontSize: 16.sp, color: Colors.black),
            ),
            TextSpan(
              text: fntVO.calorie.toStringAsFixed(2),
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
                "目标已达成 ${(fntVO.calorie / valueRDA * 100).toStringAsFixed(2)} %",
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
    );
  }

  /// *******************************宏量素 tabview *****************************************

  /// 宏量macronutrients tab 页面
  buildMacrosTabView() {
    // 【注意】如果是单日的（昨天、进入，则显示饼图，如果是上周、本周则是柱状图）
    List<Widget> chart = [];
    if (dropdownValue.value == "today" || dropdownValue.value == "yesterday") {
      /// 当日主要营养素占比饼图卡片
      chart = [_buildPieChartCard(formatData(dfiwfsList), CusChartType.macro)];
    } else {
      // 当周的营养素条状图
      chart = [
        _buildBarChartCard(formatWeekData(dfiwfsList), CusChartType.macro)
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// 当日主要营养素占比卡片
        ...chart,

        /// 食物摄入宏量统计卡片
        _buildDataTableCard(dfiwfsList, CusChartType.macro),
      ],
    );
  }

  /// *******************************营养素 tabview(未完) ************************************
  /// ？？？营养素tab页面
  /// （未完，还没有实现个人配置目标，这里需要和目标营养素的差值比较）
  buildNutrientsTabView() {
    // 简单示例，等个人配置目标完成再继续
    List<DataRow> rows = [];

    var properties = formatData(dfiwfsList).toMap().entries;

    for (var entry in properties) {
      if (entry.value != 0) {
        rows.add(_buildDataRow(entry.key, entry.value.toStringAsFixed(2)));
      }
    }

    return FittedBox(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('营养素')),
          DataColumn(label: Text('摄入量'), numeric: true),
          DataColumn(label: Text('目标量'), numeric: true),
        ],
        rows: rows,
      ),
    );
  }

  DataRow _buildDataRow(String attribute, String value) {
    return DataRow(cells: [
      DataCell(Text(attribute)),
      DataCell(Text(value)),
      // 示例占位
      const DataCell(Text("1000")),
    ]);
  }

  /// -----------------复用的【饼图卡片】= 图例 + 实例 ---------------------------
  ///
  /// 绘制卡路里摄入或宏量素摄入的【饼图卡片】(包含图例legend和图chart两部分)
  _buildPieChartCard(FoodNutrientTotals fntVO, CusChartType type) {
    return Card(
      elevation: 10,
      child: SizedBox(
        height: 200.sp,
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 左边图例
                  Expanded(
                    flex: 2,
                    child: _buildPieLegend(formatData(dfiwfsList), type),
                  ),
                  // 右边饼图
                  Expanded(
                    flex: 1,
                    child: _buildPieChart(formatData(dfiwfsList), type),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 饼图的“图例”
  // 绘制卡路里摄入(type=calory)或宏量素摄入(type=macro)的饼图的图例
  _buildPieLegend(FoodNutrientTotals fntVO, CusChartType type) {
    List<Widget> legendItems = [];
    // 如果类型是卡路里 calory
    if (type == CusChartType.calory) {
      double total = fntVO.bfCalorie +
          fntVO.lunchCalorie +
          fntVO.dinnerCalorie +
          fntVO.otherCalorie;

      legendItems = [
        _buildLegendItem(Colors.grey, '早餐', fntVO.bfCalorie, total, "大卡"),
        _buildLegendItem(Colors.red, '午餐', fntVO.lunchCalorie, total, "大卡"),
        _buildLegendItem(Colors.green, '晚餐', fntVO.dinnerCalorie, total, "大卡"),
        _buildLegendItem(Colors.blue, '小食', fntVO.otherCalorie, total, "大卡"),
      ];
    } else {
      // 否则就是宏量素 macro
      double total = fntVO.totalCHO + fntVO.totalFat + fntVO.protein;

      legendItems = [
        _buildLegendItem(Colors.grey, '碳水', fntVO.totalCHO, total, "克"),
        _buildLegendItem(Colors.red, '脂肪', fntVO.totalFat, total, "克"),
        _buildLegendItem(Colors.green, '蛋白质', fntVO.protein, total, "克"),
      ];
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: legendItems,
    );
  }

  // 构建单个图例条目
  Widget _buildLegendItem(
      Color color, String label, double value, double total, String unit) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.sp),
      child: Row(
        children: [
          Container(width: 16.sp, height: 16.sp, color: color),
          SizedBox(width: 8.sp),
          Expanded(
            child: Text(
              '$label - ${(value / total * 100).toStringAsFixed(1)}% - ${value.toStringAsFixed(2)} $unit',
            ),
          ),
        ],
      ),
    );
  }

  /// 饼图的“实例”
  // 绘制卡路里摄入(type=calory)或宏量素摄入(type=macro)的饼图
  _buildPieChart(FoodNutrientTotals fntVO, CusChartType type) {
    List<PieChartSectionData> sections = [];
    if (type == CusChartType.calory) {
      sections = [
        PieChartSectionData(
          value: fntVO.bfCalorie,
          color: Colors.grey,
          // title: '${percentage.toStringAsFixed(1)}%', // 将百分比显示在标题中
          // 没给指定title就默认是其value，所以有图例了就不显示标题
          showTitle: false,
        ),
        PieChartSectionData(
            value: fntVO.lunchCalorie, color: Colors.red, showTitle: false),
        PieChartSectionData(
            value: fntVO.dinnerCalorie, color: Colors.green, showTitle: false),
        PieChartSectionData(
            value: fntVO.otherCalorie, color: Colors.blue, showTitle: false)
      ];
    } else {
      sections = [
        PieChartSectionData(
            value: fntVO.totalCHO, color: Colors.grey, showTitle: false),
        PieChartSectionData(
            value: fntVO.totalFat, color: Colors.red, showTitle: false),
        PieChartSectionData(
            value: fntVO.protein, color: Colors.green, showTitle: false),
      ];
    }

    return SizedBox(
      height: 100.sp,
      child: PieChart(PieChartData(sections: sections)),
    );
  }

  /// -----------------复用的【条状图卡片】= 图例 + 图表 ---------------------------
  ///
  /// 绘制卡路里摄入或宏量素摄入的【条状图卡片】(包含图例legend和图chart两部分)
  _buildBarChartCard(Map<String, FoodNutrientTotals> map, CusChartType type) {
    // 区分是卡路里还是宏量素，获取指定的颜色和标签
    List<Color> colors = type == CusChartType.calory
        ? [
            cusNutrientColors[CusNutType.bfCalorie]!,
            cusNutrientColors[CusNutType.lunchCalorie]!,
            cusNutrientColors[CusNutType.dinnerCalorie]!,
            cusNutrientColors[CusNutType.otherCalorie]!
          ]
        : [
            cusNutrientColors[CusNutType.totalCHO]!,
            cusNutrientColors[CusNutType.totalFat]!,
            cusNutrientColors[CusNutType.protein]!,
          ];

    List<String> labels = type == CusChartType.calory
        ? ["早餐", "午餐", "晚餐", "小食"]
        : ["碳水", "脂肪", "蛋白质"];

    // 根据颜色和标签绘制图例
    List<Widget> legendWidgets = colors
        .asMap()
        .entries
        .map((entry) => Row(
              children: [
                Container(
                  width: 14.sp,
                  height: 14.sp,
                  color: entry.value,
                ),
                Text(labels[entry.key]),
                SizedBox(width: 8.sp),
              ],
            ))
        .toList();

    // 绘制整体柱状图表
    return Card(
      elevation: 10,
      child: SizedBox(
        child: Column(
          children: [
            ListTile(
              title: Text(type == CusChartType.calory ? '食物摄入' : '宏量素摄入'),
            ),
            SizedBox(height: 10.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: legendWidgets,
            ),
            SizedBox(height: 10.sp),
            // ？？？这里的type和条状图的type要一样，避免混乱（最好是枚举）
            WeekIntakeBar(fntMap: map, type: type),
          ],
        ),
      ),
    );
  }

  /// -----------------复用的【食物摄入次数或营养素摄入的表格】 ----------------------
  ///
  /// 按照每种食物统计总卡路里摄入 或 总宏量素摄入 的列表【卡片】
  _buildDataTableCard(
    List<DailyFoodItemWithFoodServing> dfiwfsList,
    CusChartType type, // 表示统计食物摄入次数；或统计宏量摄入
  ) {
    Map<String, List<DailyFoodItemWithFoodServing>> splitArrays = {};

    // 这里不用区分是本周、上周还是今天昨天，英文这里已经是直接格式化所有记录条目成一个值，而不是按天存对应key的值的map。
    FoodNutrientTotals fntVO = formatData(dfiwfsList);

    for (var el in dfiwfsList) {
      var foodName = "${el.food.product}(${el.food.brand})";
      splitArrays.putIfAbsent(foodName, () => []);
      splitArrays[foodName]!.add(el);
    }

    List<DataRow> tempRows = splitArrays.entries.map((entry) {
      var tempNt = formatData(entry.value);
      if (type == CusChartType.calory) {
        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 0.4.sw,
                child: Text(
                  entry.key,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Text(entry.value.length.toString())),
            DataCell(Text(tempNt.calorie.toStringAsFixed(2))),
          ],
        );
      } else {
        return DataRow(
          cells: [
            // 食物名称最长占40%,超过2行就变省略号
            DataCell(
              SizedBox(
                width: 0.4.sw,
                child: Text(
                  entry.key,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
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
            type == CusChartType.calory
                ? "x ${dfiwfsList.length}"
                : fntVO.totalCHO.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          SizedBox(
            child: Text(
              type == CusChartType.calory
                  ? fntVO.calorie.toStringAsFixed(2)
                  : fntVO.totalFat.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (type == CusChartType.macro)
          DataCell(
            SizedBox(
              child: Text(
                fntVO.protein.toStringAsFixed(2),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ListTile(title: Text(type == CusChartType.calory ? '食物摄入' : '宏量素摄入')),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.sp),
            // 根据其子部件的大小调整其自身的大小(等比例缩放)，从而使得子部件能够适应父部件的大小。
            child: FittedBox(
              // 使用FittedBox来自动调整宽度
              child: DataTable(
                columnSpacing: 10.0,
                columns: type == CusChartType.calory
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
          ),
        ],
      ),
    );
  }

  /// -----------------点击下拉切换报告日期范围
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
              .map<DropdownMenuItem<CusLabel>>(
                (CusLabel value) => DropdownMenuItem<CusLabel>(
                  value: value,
                  child: Text(value.enLabel),
                ),
              )
              .toList(),
          value: dropdownValue,
          onChanged: (CusLabel? newValue) {
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
  }
}

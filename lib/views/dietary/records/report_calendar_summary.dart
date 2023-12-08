// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../models/dietary_state.dart';

/// 默认的日历显示范围，当前月的前后3个月
/// ？？？实际手记的日历显示范围的话，就第一个手记的月份，到当前月份即可
final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

class ReportCalendarSummary extends StatefulWidget {
  const ReportCalendarSummary({super.key});

  @override
  State<ReportCalendarSummary> createState() => _ReportCalendarSummaryState();
}

class _ReportCalendarSummaryState extends State<ReportCalendarSummary> {
  // 初始化或查询时加载饮食日记数据，没加载完就都是加载中
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
  final DBUserHelper _userHelper = DBUserHelper();
  // 获取缓存中的用户编号(理论上进入app主页之后，就一定有一个默认的用户编号了)
  final box = GetStorage();
  int get currentUserId => box.read(LocalStorageKey.userId) ?? 1;

  // 被选中的日期所拥有的饮食条目数据
  final ValueNotifier<List<DailyFoodItemWithFoodServing>> _selectedItems =
      ValueNotifier([]);

  // 日历中聚焦的时间(如果是日为单位，就可以具体了某个小时某分某秒了)
  DateTime _focusedDay = DateTime.now();
  // 日历中被选中的时间
  DateTime? _selectedDay;

  /// 根据条件查询的日记条目数据
  List<DailyFoodItemWithFoodServing> dfiwfsList = [];
  // 数据是否加载中
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // 初始化的时候查询当前月份的饮食条目数据
    _queryDailyFoodItemList(_focusedDay);
  }

  @override
  void dispose() {
    _selectedItems.dispose();
    super.dispose();
  }

  // 查询指定月份的饮食日志，需要传入当前月任何一天的时间即可。
  // 并且显示默认聚焦日期的饮食条目数据
  _queryDailyFoodItemList(DateTime datetime) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 查询用户目标值
    var tempUser = await _userHelper.queryUser(userId: currentUserId);
    // 当前月的起止日期
    var [startDate, endDate] = getMonthStartEndDateString(datetime);

    // 理论上是默认查询当日的，有选择其他日期则查询指定日期
    List<DailyFoodItemWithFoodServing> temp =
        (await _dietaryHelper.queryDailyFoodItemListWithDetail(
      userId: tempUser?.userId ?? 1,
      startDate: startDate,
      endDate: endDate,
      withDetail: true,
    ) as List<DailyFoodItemWithFoodServing>);

    setState(() {
      dfiwfsList = temp;

      // 初始化时设定当前选中的日期就是聚焦的日期
      _selectedDay = _focusedDay;

      _selectedItems.value = _getDialyItemsForADay(_selectedDay!);

      isLoading = false;
    });
  }

  // 获取指定某一天的饮食条目列表
  List<DailyFoodItemWithFoodServing> _getDialyItemsForADay(day) {
    return dfiwfsList
        .where(
            (e) => e.dailyFoodItem.date == DateFormat('yyyy-MM-dd').format(day))
        .toList();
  }

  // 当某一天被选中，获取该天的数据
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    print("某天被选中--------$selectedDay $focusedDay");

    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
    _selectedItems.value = _getDialyItemsForADay(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食日历表格统计'),
      ),
      body: SingleChildScrollView(
        child: isLoading
            ? buildLoader(isLoading)
            : Column(
                children: [
                  /// 日历显示每日的卡路里数量
                  SizedBox(
                    height: 0.7.sh,
                    child: TableCalendar<DailyFoodItemWithFoodServing>(
                      locale: 'zh_CN',
                      firstDay: kFirstDay,
                      lastDay: kLastDay,
                      focusedDay: _focusedDay,
                      // 显示日历标题
                      headerVisible: true,
                      // 日历标题的一些配置
                      headerStyle: const HeaderStyle(
                        // 标题居中(不显示格式化按钮的话可以设为true)
                        titleCentered: true,
                        // 不显示CalendarFormat按钮
                        formatButtonVisible: false,
                        // 控制FormatButton内的文本：true显示下一个CalendarFormat的值；false显示当前的值。
                        // formatButtonShowsNext: false,
                      ),
                      // 不显示格式化按钮的话，这个也可以不写了
                      // availableCalendarFormats: const {
                      //   CalendarFormat.month: '本月',
                      //   CalendarFormat.twoWeeks: '两周',
                      //   CalendarFormat.week: '本周',
                      // },
                      // 日历的宽度是给定父组件的1/7，有父组件高度则要把这个设为true才能铺面，否则是默认的。
                      shouldFillViewport: true,
                      // 决定哪些天需要被标记
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      // 固定为月展示形式，不变化了
                      calendarFormat: CalendarFormat.month,
                      // 不开始范围选择
                      rangeSelectionMode: RangeSelectionMode.disabled,
                      // 如果不使用这个函数，当日的数量标记是不会显示的。这也不能是异步函数
                      eventLoader: _getDialyItemsForADay,
                      // 当某天被选中后的回调
                      onDaySelected: _onDaySelected,
                      // 当日历点击标题处的上下页切换后的回调
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        // 当页面切换时，这个聚焦日期为当前页面所在月份的第一天。
                        // 页面切换后重新查询当前月的饮食记录数据
                        _queryDailyFoodItemList(focusedDay);
                      },
                      // 默认的一些日历样式配置，可以自定义日历UI
                      calendarStyle: const CalendarStyle(
                        // 不是当月的日期不显示
                        outsideDaysVisible: false,
                      ),
                      // 自定义修改日历的样式
                      calendarBuilders: CalendarBuilders(
                        // 这里可以很自定义很多样式，比如单标签多标签等等。
                        // 简单示例：每天的底部显示当天的摄入值
                        // 默认就在底部中间
                        markerBuilder: (context, date, list) {
                          if (list.isEmpty) return Container();

                          var tempCalories =
                              _formatIntakeItemListForMarker(list)
                                  .firstWhere((e) => e.label == "calorie")
                                  .value;

                          // return Container(
                          //   width: 200,
                          //   // height: 20,
                          //   color: Colors.yellow,
                          //   child: Center(
                          //     child: Text(
                          //       "${tempCalories.toStringAsFixed(1)}大卡",
                          //       maxLines: 2,
                          //       overflow: TextOverflow.ellipsis,
                          //       style: TextStyle(
                          //         color: Colors.black,
                          //         fontSize: 10.sp,
                          //       ),
                          //     ),
                          //   ),
                          // );

                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 36,
                              height: 16,
                              color: tempCalories < 2250
                                  ? Colors.green
                                  : Colors.yellow,
                              child: Center(
                                child: Text(
                                  tempCalories.toStringAsFixed(0),
                                  maxLines: 2,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(
                                    color: tempCalories < 3
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  /// 总计本月摄入量和平均到每天的摄入量
                  _buildDailyAverageCount(),

                  const SizedBox(height: 8.0),

                  /// 日历某些操作改变后，显示对应的手记内容列表
                  ValueListenableBuilder<List<DailyFoodItemWithFoodServing>>(
                    valueListenable: _selectedItems,
                    // 当_selectedEvents有变化时，这个builder才会被调用
                    builder: (context, value, _) {
                      // 如果当日没有饮食记录条目，则不显示详情
                      if (value.isEmpty) {
                        return Container();
                      }

                      var formatList = _formatIntakeItemListForMarker(value);
                      return Card(
                        elevation: 5,
                        child: _buildSelectedDayListView(value, formatList),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  /// 构建当月平均每天的摄入
  Widget _buildDailyAverageCount() {
    // 当月一共多少天有记录
    Map<String, List<DailyFoodItemWithFoodServing>> groupedByDate = {};
    for (var item in dfiwfsList) {
      if (groupedByDate.containsKey(item.dailyFoodItem.date)) {
        groupedByDate[item.dailyFoodItem.date]!.add(item);
      } else {
        groupedByDate[item.dailyFoodItem.date] = [item];
      }
    }

    var days = groupedByDate.keys.length;

    var tempList = _formatIntakeItemListForMarker(dfiwfsList);

    var totalCalorie = tempList.firstWhere((e) => e.label == "calorie").value;
    var totalProtein = tempList.firstWhere((e) => e.label == "protein").value;
    var totalFat = tempList.firstWhere((e) => e.label == "fat").value;
    var totalCho = tempList.firstWhere((e) => e.label == "cho").value;

    return Card(
      child: Column(
        children: [
          Text(
            "当月摄入统计",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
                // dataRowHeight: 10.sp,
                dataRowMinHeight: 30.sp, // 设置行高范围
                dataRowMaxHeight: 50.sp,
                headingRowHeight: 40, // 设置表头行高
                horizontalMargin: 10, // 设置水平边距
                columnSpacing: 10.sp, // 设置列间距
                columns: const [
                  DataColumn(label: Text(''), numeric: true),
                  DataColumn(label: Text('能量(大卡)'), numeric: true),
                  DataColumn(label: Text('蛋白质(克)'), numeric: true),
                  DataColumn(label: Text('脂肪(克)'), numeric: true),
                  DataColumn(label: Text('碳水(克)'), numeric: true),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(
                        Text("总计", style: TextStyle(fontSize: 14.sp)),
                      ),
                      DataCell(
                        Text(
                          totalCalorie.toStringAsFixed(2),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalProtein.toStringAsFixed(2),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalFat.toStringAsFixed(2),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalCho.toStringAsFixed(2),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(
                        Text("平均", style: TextStyle(fontSize: 14.sp)),
                      ),
                      DataCell(
                        Text(
                          (totalCalorie / days).toStringAsFixed(2),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      DataCell(
                        Text(
                          (totalProtein / days).toStringAsFixed(2),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      DataCell(
                        Text(
                          (totalFat / days).toStringAsFixed(2),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      DataCell(
                        Text(
                          (totalCho / days).toStringAsFixed(2),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ],
                  )
                ]),
          ),
        ],
      ),
    );
  }

  // 格式化带营养素详情的饮食记录条目数据列表
  List<CusNutrientInfo> _formatIntakeItemListForMarker(
    List<DailyFoodItemWithFoodServing> list,
  ) {
    var tempEnergy = 0.0;
    var tempProtein = 0.0;
    var tempFat = 0.0;
    var tempCHO = 0.0;
    // 这几个在底部总计可能用到
    var tempSodium = 0.0;
    var tempCholesterol = 0.0;
    var tempDietaryFiber = 0.0;
    var tempPotassium = 0.0;
    var tempSugar = 0.0;

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
    }

    var tempCalories = tempEnergy / oneCalToKjRatio;

    // 当日主要营养素表格数据
    return [
      CusNutrientInfo(
        label: "calorie",
        value: tempCalories,
        color: cusNutrientColors[CusNutType.calorie]!,
        name: '卡路里',
        unit: '大卡',
      ),
      CusNutrientInfo(
        label: "energy",
        value: tempEnergy,
        color: cusNutrientColors[CusNutType.energy]!,
        name: '能量',
        unit: '千焦',
      ),
      CusNutrientInfo(
        label: "protein",
        value: tempProtein,
        color: cusNutrientColors[CusNutType.protein]!,
        name: '蛋白质',
        unit: '克',
      ),
      CusNutrientInfo(
        label: "fat",
        value: tempFat,
        color: cusNutrientColors[CusNutType.totalFat]!,
        name: '脂肪',
        unit: '克',
      ),
      CusNutrientInfo(
        label: "cho",
        value: tempCHO,
        color: cusNutrientColors[CusNutType.totalCHO]!,
        name: '碳水',
        unit: '克',
      ),
      CusNutrientInfo(
        label: "dietaryFiber",
        value: tempDietaryFiber,
        color: cusNutrientColors[CusNutType.dietaryFiber]!,
        name: '膳食纤维',
        unit: '克',
      ),
      CusNutrientInfo(
        label: "sugar",
        value: tempSugar,
        color: cusNutrientColors[CusNutType.sugar]!,
        name: '糖',
        unit: '克',
      ),
      CusNutrientInfo(
        label: "sodium",
        value: tempSodium,
        color: cusNutrientColors[CusNutType.sodium]!,
        name: '钠',
        unit: '毫克',
      ),
      CusNutrientInfo(
        label: "cholesterol",
        value: tempCholesterol,
        color: cusNutrientColors[CusNutType.cholesterol]!,
        name: '胆固醇',
        unit: '毫克',
      ),
      CusNutrientInfo(
        label: "potassium",
        value: tempPotassium,
        color: cusNutrientColors[CusNutType.potassium]!,
        name: '钾',
        unit: '毫克',
      ),
    ];
  }

  /// 构建被选中当日的摄入基础信息部件
  Widget _buildSelectedDayListView(
    List<DailyFoodItemWithFoodServing> value,
    List<CusNutrientInfo> formatList,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "当日摄入总量",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildSummaryTable(formatList),
        ),
        Text(
          "详细摄入数据",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: value.length,
          itemBuilder: (context, index) {
            var food = value[index].food;
            var intakeSize = value[index].dailyFoodItem.foodIntakeSize;
            var servingUnit = value[index].servingInfo.servingUnit;

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                title: Text(
                  '食物: ${food.product} (${food.brand})',
                  style: TextStyle(fontSize: 15.sp),
                ),
                subtitle: Text(
                  '份量: ${intakeSize.toStringAsFixed(2)} x $servingUnit',
                  style: TextStyle(fontSize: 15.sp),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryTable(List<CusNutrientInfo> formatList) {
    var calorie = formatList
        .firstWhere((e) => e.label == "calorie")
        .value
        .toStringAsFixed(2);
    var protein = formatList
        .firstWhere((e) => e.label == "protein")
        .value
        .toStringAsFixed(2);
    var cho =
        formatList.firstWhere((e) => e.label == "cho").value.toStringAsFixed(2);
    var fat =
        formatList.firstWhere((e) => e.label == "fat").value.toStringAsFixed(2);

    return DataTable(
        // dataRowHeight: 10.sp,
        dataRowMinHeight: 40.sp, // 设置行高范围
        dataRowMaxHeight: 50.sp,
        headingRowHeight: 40, // 设置表头行高
        horizontalMargin: 10, // 设置水平边距
        columnSpacing: 20.sp, // 设置列间距
        columns: const [
          DataColumn(label: Text('能量(大卡)'), numeric: true),
          DataColumn(label: Text('蛋白质(克)'), numeric: true),
          DataColumn(label: Text('脂肪(克)'), numeric: true),
          DataColumn(label: Text('碳水(克)'), numeric: true),
        ],
        rows: [
          DataRow(
            cells: [
              DataCell(Text(calorie, style: TextStyle(fontSize: 14.sp))),
              DataCell(Text(protein, style: TextStyle(fontSize: 14.sp))),
              DataCell(Text(fat, style: TextStyle(fontSize: 14.sp))),
              DataCell(Text(cho, style: TextStyle(fontSize: 14.sp))),
            ],
          )
        ]);
  }
}

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/dietary_state.dart';
import 'format_tools.dart';

class ReportCalendarSummary extends StatefulWidget {
  const ReportCalendarSummary({super.key});

  @override
  State<ReportCalendarSummary> createState() => _ReportCalendarSummaryState();
}

class _ReportCalendarSummaryState extends State<ReportCalendarSummary> {
  // 初始化或查询时加载饮食日记数据，没加载完就都是加载中
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

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

    // 当前月的起止日期
    var [startDate, endDate] = getMonthStartEndDateString(datetime);

    // 理论上是默认查询当日的，有选择其他日期则查询指定日期
    List<DailyFoodItemWithFoodServing> temp =
        (await _dietaryHelper.queryDailyFoodItemListWithDetail(
      userId: CacheUser.userId,
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
        .where((e) =>
            e.dailyFoodItem.date == DateFormat(constDateFormat).format(day))
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
        title: Text(CusAL.of(context).dietaryCalendar),
      ),
      body: SingleChildScrollView(
        child: isLoading
            ? buildLoader(isLoading)
            : Column(
                children: [
                  /// 日历显示每日的卡路里数量
                  SizedBox(
                    height: 0.7.sh,
                    child: _buildTableCalendar(),
                  ),
                  SizedBox(height: 8.sp),

                  /// 总计本月摄入量和平均到每天的摄入量
                  _buildDailyAverageCount(),

                  SizedBox(height: 8.sp),

                  /// 日历某些操作改变后，显示对应的手记内容列表
                  ValueListenableBuilder<List<DailyFoodItemWithFoodServing>>(
                    valueListenable: _selectedItems,
                    // 当_selectedEvents有变化时，这个builder才会被调用
                    builder: (context, value, _) {
                      // 如果当日没有饮食记录条目，则不显示详情
                      if (value.isEmpty) {
                        return Container();
                      }

                      return Card(
                        elevation: 5,
                        child: _buildSelectedDayListView(
                          value,
                          formatIntakeItemListForMarker(context, value),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  /// 构建当月每天摄入卡路里的日历
  _buildTableCalendar() {
    return TableCalendar<DailyFoodItemWithFoodServing>(
      locale: box.read('language') == "en" ? "en_US" : 'zh_CN',
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
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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

          var tempCalories = formatIntakeItemListForMarker(context, list)
              .firstWhere((e) => e.label == "calorie")
              .value;

          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 36.sp,
              height: 16.sp,
              color: tempCalories < 2250 ? Colors.green : Colors.yellow,
              child: Center(
                child: Text(
                  tempCalories.toStringAsFixed(0),
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: tempCalories < 3 ? Colors.white : Colors.black,
                    fontSize: CusFontSizes.flagTiny,
                  ),
                ),
              ),
            ),
          );
        },
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

    var tempList = formatIntakeItemListForMarker(context, dfiwfsList);

    var totalCalorie = tempList.firstWhere((e) => e.label == "calorie").value;
    var totalProtein = tempList.firstWhere((e) => e.label == "protein").value;
    var totalFat = tempList.firstWhere((e) => e.label == "fat").value;
    var totalCho = tempList.firstWhere((e) => e.label == "cho").value;

    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CusAL.of(context).dietaryCalendarLabels('0'),
            style: TextStyle(
              fontSize: CusFontSizes.flagMedium,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
                dataRowMinHeight: 30.sp, // 设置行高范围
                dataRowMaxHeight: 50.sp,
                headingRowHeight: 40, // 设置表头行高
                horizontalMargin: 10, // 设置水平边距
                columnSpacing: 10.sp, // 设置列间距
                columns: [
                  const DataColumn(label: Text(''), numeric: true),
                  _buildDataColumn(1),
                  _buildDataColumn(2),
                  _buildDataColumn(3),
                  _buildDataColumn(4),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          CusAL.of(context).countLabels('0'),
                          style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                        ),
                      ),
                      _buildDataCell(totalCalorie),
                      _buildDataCell(totalProtein),
                      _buildDataCell(totalFat),
                      _buildDataCell(totalCho),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          CusAL.of(context).countLabels('1'),
                          style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                        ),
                      ),
                      _buildDataCell(totalCalorie / days),
                      _buildDataCell(totalProtein / days),
                      _buildDataCell(totalFat / days),
                      _buildDataCell(totalCho / days),
                    ],
                  )
                ]),
          ),
        ],
      ),
    );
  }

  // 月统计和日平均统计的表格的标题和正文的样式是一样的
  DataColumn _buildDataColumn(int i) {
    return DataColumn(
      label: Text(CusAL.of(context).foodTableMainLabels(i.toString())),
      numeric: true,
    );
  }

  DataCell _buildDataCell(double number) {
    return DataCell(
      Text(
        cusDoubleTryToIntString(number),
        style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
      ),
    );
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
          CusAL.of(context).dietaryCalendarLabels('1'),
          style: TextStyle(
            fontSize: CusFontSizes.flagMedium,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildSummaryTable(formatList),
        ),
        Text(
          CusAL.of(context).dietaryCalendarLabels('2'),
          style: TextStyle(
            fontSize: CusFontSizes.flagMedium,
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

            // return Container(
            //   margin: const EdgeInsets.symmetric(
            //     horizontal: 12.0,
            //     vertical: 4.0,
            //   ),
            //   decoration: BoxDecoration(
            //     border: Border.all(),
            //     borderRadius: BorderRadius.circular(12.sp),
            //   ),
            //   child: ListTile(
            //     title: Text(
            //       '${CusAL.of(context).foodName}: ${food.product} (${food.brand})',
            //       style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
            //     ),
            //     subtitle: Text(
            //       '${CusAL.of(context).eatableSize}: ${cusDoubleTryToIntString(intakeSize)} x $servingUnit',
            //       style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
            //     ),
            //   ),
            // );
            return Card(
              elevation: 5.sp,
              child: ListTile(
                title: Text(
                  '${CusAL.of(context).foodName}: ${food.product} (${food.brand})',
                  style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                ),
                subtitle: Text(
                  '${CusAL.of(context).eatableSize}: ${cusDoubleTryToIntString(intakeSize)} x $servingUnit',
                  style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryTable(List<CusNutrientInfo> formatList) {
    var calorie = cusDoubleTryToIntString(
      formatList.firstWhere((e) => e.label == "calorie").value,
    );
    var protein = cusDoubleTryToIntString(
      formatList.firstWhere((e) => e.label == "protein").value,
    );
    var cho = cusDoubleTryToIntString(
      formatList.firstWhere((e) => e.label == "cho").value,
    );
    var fat = cusDoubleTryToIntString(
      formatList.firstWhere((e) => e.label == "fat").value,
    );

    return DataTable(
        dataRowMinHeight: 40.sp, // 设置行高范围
        dataRowMaxHeight: 50.sp,
        headingRowHeight: 40.sp, // 设置表头行高
        horizontalMargin: 10.sp, // 设置水平边距
        columnSpacing: 20.sp, // 设置列间距
        columns: [
          _buildDataColumn(1),
          _buildDataColumn(2),
          _buildDataColumn(3),
          _buildDataColumn(4),
        ],
        rows: [
          DataRow(
            cells: [
              DataCell(Text(
                calorie,
                style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
              )),
              DataCell(Text(
                protein,
                style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
              )),
              DataCell(Text(
                fat,
                style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
              )),
              DataCell(Text(
                cho,
                style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
              )),
            ],
          )
        ]);
  }
}

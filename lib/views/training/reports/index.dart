// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/training_state.dart';
import 'export/report_pdf_viewer.dart';

class TrainingReports extends StatefulWidget {
  const TrainingReports({super.key});

  @override
  State<TrainingReports> createState() => _TrainingReportsState();
}

class _TrainingReportsState extends State<TrainingReports> {
  // 过长的字符串无法打印显示完，默认的developer库的log有时候没效果
  var log = Logger();

  // 数据是否加载中
  bool isLoading = false;

  // 默认展示哪一个tab(直接点进来可能是第一个，但跟练结束过来，可能是第二个)
  int initialIndex = 0;

  final DBTrainingHelper _trainingHelper = DBTrainingHelper();

  // 被选中的事件
  late ValueNotifier<List<TrainedDetailLog>> _selectedEvents;
  // 用于展示的日历格式(默认是当前这一个星期，可以切换为最近两个星期、当月)
  CalendarFormat _calendarFormat = CalendarFormat.week;
  // 点击两个日期变为选定日期范围
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  // 日历中聚焦的时间(如果是日为单位，就可以具体了某个小时某分某秒了)
  DateTime _focusedDay = DateTime.now();
  // 日历中被选中的时间
  DateTime? _selectedDay;
  // 范围选择时选中的日期起止
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // 初始化或查询时加载数据，没加载完就都是加载中
  late List<TrainedDetailLog> tdlList;

  // 导出数据时默认选中为最近7天
  CusLabel exportDateValue = exportDateList.first;

  @override
  void initState() {
    super.initState();

    _getEventsForInitDay();

    setState(() {
      initialIndex = 1;
    });
  }

  ///
  /// 表格日历的报告页面需要的函数
  ///

  // 初始化事件，以当前日查询对应的手记数据
  // 因为不能再改变state中用await，所以单独一个函数
  _getEventsForInitDay() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    var list = await _trainingHelper.queryTrainedDetailLog(
      userId: CacheUser.userId,
      gmtCreateSort: "DESC",
    );

    setState(() {
      tdlList = list;
      // 初始化时设定当前选中的日期就是聚焦的日期
      _selectedDay = _focusedDay;
      // 获取当前日期的事件
      _selectedEvents = ValueNotifier(_getLogsForADay(_selectedDay!));

      isLoading = false;
    });
  }

  // 获取指定某一天的手记列表
  List<TrainedDetailLog> _getLogsForADay(day) {
    // 训练记录的训练日志存入的是完整的datetime，这里只取date部分
    return tdlList
        .where((e) =>
            e.trainedDate.split(" ")[0] ==
            DateFormat(constDateFormat).format(day))
        .toList();
  }

  // 当某一天被选中时的回调
  _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    print("某天被选中--------$selectedDay $focusedDay");

    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        // 如果当前点击的日期就是已经被选中的日期，日期范围也得情况
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getLogsForADay(selectedDay);
    }
  }

  // 当某个日期被长按
  _onDayLongPressed(DateTime selectedDay, DateTime focusedDay) {
    print("日期被长按了---$selectedDay --$focusedDay");
    // 长按某一天，可以新增备注？？？
  }

  // 当日期范围被选中时
  _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    print("日期被_onRangeSelected了---$start --$end $focusedDay");

    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // 起止日期可能为null
    if (start != null && end != null) {
      // 有起止，则获取该日期范围内所有的手记数据
      _selectedEvents.value = [
        for (final d in daysInRange(start, end))
          ...(_selectedEvents.value = _getLogsForADay(d))
      ];
    } else if (start != null) {
      // 只有起，则只获取该起日期的所有手记数据
      _selectedEvents.value = _getLogsForADay(start);
    } else if (end != null) {
      // 只有止，则只获取该止日期的所有手记数据
      _selectedEvents.value = _getLogsForADay(end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.bar_chart),
              ),
              Tab(
                icon: Icon(Icons.calendar_month),
              ),
              Tab(
                icon: Icon(Icons.history),
              ),
            ],
          ),
          title: Text(CusAL.of(context).trainingReports),
          actions: [
            IconButton(
              onPressed: () async {
                var dateSelected = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(CusAL.of(context).exportRangeNote),
                      content: DropdownMenu<CusLabel>(
                        width: 0.6.sw,
                        initialSelection: exportDateList.first,
                        onSelected: (CusLabel? value) {
                          setState(() {
                            exportDateValue = value!;
                          });
                        },
                        dropdownMenuEntries: exportDateList
                            .map<DropdownMenuEntry<CusLabel>>((CusLabel value) {
                          return DropdownMenuEntry<CusLabel>(
                            value: value,
                            label: showCusLable(value),
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: Text(CusAL.of(context).cancelLabel),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: Text(CusAL.of(context).confirmLabel),
                        ),
                      ],
                    );
                  },
                );
                // 弹窗选择导出范围不为空，且不为false，则默认是选择的日期范围
                if (dateSelected != null && dateSelected) {
                  String tempStart, tempEnd;
                  if (exportDateValue.value == "seven") {
                    [tempStart, tempEnd] = getStartEndDateString(7);
                  } else if (exportDateValue.value == "thirty") {
                    [tempStart, tempEnd] = getStartEndDateString(30);
                  } else {
                    // 导出全部就近20年吧
                    [tempStart, tempEnd] = getStartEndDateString(365 * 20);
                  }

                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainedReportPdfViewer(
                        startDate: tempStart,
                        endDate: tempEnd,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.print),
            ),
          ],
        ),
        body: isLoading
            ? buildLoader(isLoading)
            : TabBarView(
                children: [
                  SingleChildScrollView(child: buildReportsView()),
                  SingleChildScrollView(child: buildHistoryView()),
                  SingleChildScrollView(child: buildRecentView()),
                ],
              ),
      ),
    );
  }

  buildReportsView() {
    // 统计的是所有的运动次数和总的运动时间
    return FutureBuilder(
      future: _trainingHelper.queryTrainedDetailLog(
        userId: CacheUser.userId,
        gmtCreateSort: "DESC",
      ),
      builder: (BuildContext context,
          AsyncSnapshot<List<TrainedDetailLog>> snapshot) {
        if (snapshot.hasData) {
          List<TrainedDetailLog> data = snapshot.data!;

          if (data.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100.sp),
                child: Text(
                  CusAL.of(context).noRecordNote,
                  style: TextStyle(fontSize: CusFontSizes.flagMedium),
                ),
              ),
            );
          }

          // TrainedDetailLog-->tlwgb
          // 计算所有训练日志的累加时间
          int totalRest =
              data.fold(0, (prevVal, tdl) => prevVal + tdl.totalRestTime);
          int totolPaused =
              data.fold(0, (prevVal, tdl) => prevVal + tdl.totolPausedTime);
          int totalTrained =
              data.fold(0, (prevVal, tdl) => prevVal + tdl.trainedDuration);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        CusAL.of(context).trainedReportLabels('0'),
                        style: TextStyle(
                          fontSize: CusFontSizes.flagMedium,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Icon(Icons.flag_outlined, size: CusIconSizes.iconMedium),
                      Text(
                        "${data.length}",
                        style: TextStyle(
                          fontSize: CusFontSizes.flagMediumBig,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    CusAL.of(context).trainedReportLabels('4'),
                    style: TextStyle(
                      fontSize: CusFontSizes.flagMedium,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(Icons.alarm, size: CusIconSizes.iconMedium),
                      Text(CusAL.of(context).trainedReportLabels('1')),
                      Text(
                        (totalTrained / 60).toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: CusFontSizes.flagMedium,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.alarm, size: CusIconSizes.iconMedium),
                      Text(CusAL.of(context).trainedReportLabels('2')),
                      Text(
                        (totalRest / 60).toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: CusFontSizes.flagMedium,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.alarm, size: CusIconSizes.iconMedium),
                      Text(CusAL.of(context).trainedReportLabels('3')),
                      Text(
                        (totolPaused / 60).toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: CusFontSizes.flagMedium,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    CusAL.of(context).trainedReportLabels('5'),
                    style: TextStyle(
                      fontSize: CusFontSizes.flagMedium,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.sp),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.sp,
                  vertical: 5.sp,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(CusAL.of(context).trainedReportLabels('6')),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        data.first.trainedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.sp,
                  vertical: 5.sp,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(CusAL.of(context).trainedReportLabels('7')),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        (data.first.planName != null)
                            ? "${data.first.planName} - ${CusAL.of(context).dayNumber(data.first.dayNumber ?? 0)}"
                            : data.first.groupName ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.sp,
                  vertical: 5.sp,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(CusAL.of(context).trainedReportLabels('8')),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "${cusDoubleTryToIntString(data.first.trainedDuration / 60)} ${CusAL.of(context).unitLabels('8')}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          /// 如果请求数据有错，显示错误信息
          return Text('${snapshot.error}');
        } else {
          return SizedBox(
            width: 50.sp,
            height: 50.sp,
            child: const CircularProgressIndicator(),
          );
        }
      },
    );
  }

  ///
  /// 绘制训练历史日历表格tab
  ///
  buildHistoryView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TableCalendar(
          locale: box.read('language') == "en" ? "en_US" : 'zh_CN',
          firstDay: kFirstDay,
          lastDay: kLastDay,
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          calendarFormat: _calendarFormat,
          rangeSelectionMode: _rangeSelectionMode,
          // 如果不使用这个函数，当日的数量标记是不会显示的。这也不能是异步函数
          eventLoader: _getLogsForADay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          // 默认的一些日历样式配置，可以自定义日历UI
          calendarStyle: const CalendarStyle(
            // 不是当月的日期不显示
            outsideDaysVisible: false,
          ),
          availableCalendarFormats: {
            CalendarFormat.month: CusAL.of(context).calenderLables("0"),
            CalendarFormat.twoWeeks: CusAL.of(context).calenderLables("1"),
            CalendarFormat.week: CusAL.of(context).calenderLables("2"),
          },
          // 自定义修改日历的样式
          calendarBuilders: CalendarBuilders(
            // 这里可以很自定义很多样式，比如单标签多标签等等。
            // 简单示例：当天的手记超过3个，就是黄底黑色；否则就是绿底白字
            markerBuilder: (context, date, list) {
              if (list.isEmpty) return Container();
              return Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 15.sp,
                  height: 15.sp,
                  color: list.length < 3 ? Colors.green : Colors.yellow,
                  child: Center(
                    child: Text(
                      "${list.length}",
                      style: TextStyle(
                        color: list.length < 3 ? Colors.white : Colors.black,
                        fontSize: CusFontSizes.flagTiny,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          onDaySelected: _onDaySelected,
          onDayLongPressed: _onDayLongPressed,
          onRangeSelected: _onRangeSelected,
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        SizedBox(height: 8.sp),
        // 日历某些操作改变后，显示对应的手记内容列表
        ValueListenableBuilder<List<TrainedDetailLog>>(
          valueListenable: _selectedEvents,
          // 当_selectedEvents有变化时，这个builder才会被调用
          builder: (context, value, _) {
            return ListView.builder(
              // 和外层的滚动只保留一个
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: value.length,
              itemBuilder: (context, index) {
                var log = value[index];

                return Card(
                  elevation: 5,
                  margin:
                      EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
                  child: Padding(
                    padding: EdgeInsets.all(10.sp),
                    child: _buildTrainedDetailLogListTile(log),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  ///
  /// 绘制最近锻炼日志tab
  ///
  buildRecentView() {
    var [start, end] = getStartEndDateString(30);

    return FutureBuilder(
      future: _trainingHelper.queryTrainedDetailLog(
        userId: CacheUser.userId,
        startDate: start,
        endDate: end,
        gmtCreateSort: "DESC",
      ),
      builder: (BuildContext context,
          AsyncSnapshot<List<TrainedDetailLog>> snapshot) {
        if (snapshot.hasData) {
          List<TrainedDetailLog> data = snapshot.data!;

          if (data.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100.sp),
                child: Text(
                  '${CusAL.of(context).lastDayLabels(30)} ${CusAL.of(context).noRecordNote}',
                  style: TextStyle(fontSize: CusFontSizes.flagMedium),
                ),
              ),
            );
          }

          // 将最近30天的记录，按天分组并排序展示。
          Map<String, List<TrainedDetailLog>> logGroupedByDate = {};
          for (var log in data) {
            // 日志的日期(不含时间)
            var temp = log.trainedDate.split(" ")[0];
            if (logGroupedByDate.containsKey(temp)) {
              logGroupedByDate[temp]!.add(log);
            } else {
              logGroupedByDate[temp] = [log];
            }
          }

          List<Widget> rst = [];
          logGroupedByDate.forEach((key, value) {
            rst.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.sp, 10.sp, 0, 10.sp),
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: CusFontSizes.itemTitle,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10.sp, 0, 10.sp, 10.sp),
                    child: Card(
                      elevation: 5,
                      child: ListView.builder(
                        // 和外层的滚动只保留一个
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: value.length,
                        itemBuilder: (context, index) {
                          var log = value[index];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index != 0)
                                Divider(height: 5.sp, thickness: 3.sp),
                              _buildTrainedDetailLogListTile(log),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          });

          return Column(
            children: [
              SizedBox(height: 10.sp),
              Text(
                CusAL.of(context).lastDayLabels(30),
                style: TextStyle(
                  fontSize: CusFontSizes.flagMediumBig,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ...rst,
            ],
          );
        } else if (snapshot.hasError) {
          /// 如果请求数据有错，显示错误信息
          return Text('${snapshot.error}');
        } else {
          return SizedBox(
            width: 50.sp,
            height: 50.sp,
            child: const CircularProgressIndicator(),
          );
        }
      },
    );
  }

  // 日历表格和最近30天记录的tab都可复用
  _buildTrainedDetailLogListTile(TrainedDetailLog log) {
    return ListTile(
      title: _buildWorkoutNameText(log),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.sp),
          _buildTileRow(
            CusAL.of(context).trainedCalendarLabels('5'),
            '${log.trainedStartTime.split(" ")[1]} ~ ${log.trainedEndTime.split(" ")[1]}',
          ),
          _buildTileRow(
            CusAL.of(context).trainedCalendarLabels('2'),
            formatSeconds(log.trainedDuration.toDouble()),
          ),
          _buildTileRow(
            CusAL.of(context).trainedCalendarLabels('3'),
            formatSeconds(log.totolPausedTime.toDouble()),
          ),
          _buildTileRow(
            CusAL.of(context).trainedCalendarLabels('4'),
            formatSeconds(log.totalRestTime.toDouble()),
          ),
        ],
      ),
    );
  }

  _buildWorkoutNameText(TrainedDetailLog log) {
    var planName = log.planName;
    return planName != null
        ? RichText(
            textAlign: TextAlign.left,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: "${CusAL.of(context).plan} ",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: "  $planName  ",
                  style: TextStyle(
                    fontSize: CusFontSizes.itemTitle,
                    color: Colors.green,
                  ),
                ),
                TextSpan(
                  text: CusAL.of(context).dayNumber(log.dayNumber ?? 0),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        : RichText(
            textAlign: TextAlign.left,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: CusAL.of(context).workout,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '  ${log.groupName}',
                  style: TextStyle(
                    fontSize: CusFontSizes.itemTitle,
                    color: Colors.green[500],
                  ),
                ),
              ],
            ),
          );
  }

  _buildTileRow(String label, String value) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label)),
        Expanded(flex: 3, child: Text(value)),
      ],
    );
  }
}

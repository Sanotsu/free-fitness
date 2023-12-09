// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../common/global/constants.dart';
import '../../common/utils/db_diary_helper.dart';
import '../../common/utils/tool_widgets.dart';
import '../../common/utils/tools.dart';
import '../../models/diary_state.dart';
import 'diary_modify_rich_text.dart';
import 'index_timeline.dart';

/// 默认的日历显示范围，当前月的前后3个月
/// ？？？实际手记的日历显示范围的话，就第一个手记的月份，到当前月份即可
final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

class DiaryTableCalendar extends StatefulWidget {
  const DiaryTableCalendar({super.key});

  @override
  State<DiaryTableCalendar> createState() => _DiaryTableCalendarState();
}

class _DiaryTableCalendarState extends State<DiaryTableCalendar> {
  final DBDiaryHelper _dbHelper = DBDiaryHelper();

  // 被选中的事件
  late ValueNotifier<List<Diary>> _selectedEvents;
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

  // 初始化或查询时加载手记数据，没加载完就都是加载中
  bool isLoading = false;
  late List<Diary> diaryList;

  @override
  void initState() {
    super.initState();
    // 获取当前日期的事件
    _getEventsForInitDay();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // 初始化事件，以当前日查询对应的手记数据
  // 因为不能再改变state中用await，所以单独一个函数
  _getEventsForInitDay() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 必须查询所有数据，否则表格日历中，比如给每个有手记的日期标识maker就做不到
    List<Diary> temp = await _dbHelper.queryDiaryByDateRange();

    print("1111当前日期查询的手记数据 _selectedDay :$_selectedDay temp $temp");
    setState(() {
      diaryList = temp;
      // 初始化时设定当前选中的日期就是聚焦的日期
      _selectedDay = _focusedDay;
      // 获取当前日期的事件
      _selectedEvents = ValueNotifier(_getDiarysForADay(_selectedDay!));

      isLoading = false;
    });
  }

  // 获取指定某一天的手记列表
  List<Diary> _getDiarysForADay(day) {
    return diaryList
        .where((e) => e.date == DateFormat(constDateFormat).format(day))
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
    }
    _selectedEvents.value = _getDiarysForADay(selectedDay);
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
          ...(_selectedEvents.value = _getDiarysForADay(d))
      ];
    } else if (start != null) {
      // 只有起，则只获取该起日期的所有手记数据
      _selectedEvents.value = _getDiarysForADay(start);
    } else if (end != null) {
      // 只有止，则只获取该止日期的所有手记数据
      _selectedEvents.value = _getDiarysForADay(end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手记日历'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IndexTimeline(),
                ),
              );
            },
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            ),
            child: const Text("时间线模式"),
          ),
          TextButton.icon(
            onPressed: () {
              print("跳转到富文本新增页面");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiaryModifyRichText(),
                ),
              ).then((value) {
                // 编辑页面返回后，重新加载手记数据
                _getEventsForInitDay();
              });
            },
            label: const Text("添加手记"),
            icon: const Icon(Icons.add),
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            ),
          )
        ],
      ),
      // 异步获取全部的手记数据，以便自定义事件时展示每日有多少的手记数量
      body: isLoading
          ? buildLoader(isLoading)
          : Column(
              children: [
                // 日历的一些配置
                TableCalendar(
                  locale: 'zh_CN',
                  firstDay: kFirstDay,
                  lastDay: kLastDay,
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  rangeStartDay: _rangeStart,
                  rangeEndDay: _rangeEnd,
                  calendarFormat: _calendarFormat,
                  rangeSelectionMode: _rangeSelectionMode,
                  // 如果不使用这个函数，当日的数量标记是不会显示的。这也不能是异步函数
                  eventLoader: _getDiarysForADay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  // 默认的一些日历样式配置，可以自定义日历UI
                  calendarStyle: const CalendarStyle(
                    // 不是当月的日期不显示
                    outsideDaysVisible: false,
                  ),
                  availableCalendarFormats: const {
                    CalendarFormat.month: '展示整月',
                    CalendarFormat.twoWeeks: '展示两周',
                    CalendarFormat.week: '展示一周',
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
                          width: 15,
                          height: 15,
                          color: list.length < 3 ? Colors.green : Colors.yellow,
                          child: Center(
                            child: Text(
                              "${list.length}",
                              style: TextStyle(
                                color: list.length < 3
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 10.sp,
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
                const SizedBox(height: 8.0),
                // 日历某些操作改变后，显示对应的手记内容列表
                Expanded(
                  child: ValueListenableBuilder<List<Diary>>(
                    valueListenable: _selectedEvents,
                    // 当_selectedEvents有变化时，这个builder才会被调用
                    builder: (context, value, _) {
                      return _buildDiaryList(value);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  _buildDiaryList(List<Diary> diarys) {
    return ListView.builder(
      itemCount: diarys.length,
      itemBuilder: (context, index) {
        var diary = diarys[index];

        // 先排除原本就是空字符串
        // var initTags = diary.tags?.split(",") ?? [];
        var initTags = (diary.tags != null && diary.tags!.trim().isNotEmpty)
            ? diary.tags!.trim().split(",")
            : [];
        // var initCategorys = diary.category?.split(",") ?? [];
        var initCategorys =
            (diary.category != null && diary.category!.trim().isNotEmpty)
                ? diary.category!.trim().split(",")
                : [];

        var initMood = diary.mood ?? "";

        var chipLength = initTags.length + initCategorys.length + 1;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0.sp),
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wrap最小高度48吧，调不了
              Wrap(
                // spacing: 5,
                alignment: WrapAlignment.spaceAround,
                children: [
                  ...[
                    buildSmallButtonTag(
                      initMood,
                      bgColor: Colors.lightBlue,
                      labelTextSize: 10.sp,
                    ),
                    // 如果标签很多，只显示2个，然后整体剩下的用一个数字代替
                    ...initCategorys
                        .map((cate) {
                          return buildSmallButtonTag(
                            cate,
                            bgColor: Colors.limeAccent,
                            labelTextSize: 10.sp,
                          );
                        })
                        .toList()
                        .sublist(
                          0,
                          initCategorys.length > 2 ? 2 : initCategorys.length,
                        ),
                    ...initTags
                        .map((tag) {
                          return buildSmallButtonTag(
                            tag,
                            bgColor: Colors.lightGreen,
                            labelTextSize: 10.sp,
                          );
                        })
                        .toList()
                        .sublist(
                          0,
                          initTags.length > 2 ? 2 : initTags.length,
                        ),
                  ],
                  if (chipLength > 5)
                    buildSmallButtonTag(
                      '+${chipLength - 5}',
                      bgColor: Colors.white,
                      labelTextSize: 10.sp,
                    ),
                ],
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DiaryModifyRichText(diaryItem: diary),
                    ),
                  ).then((value) {
                    // 编辑页面返回后，重新加载手记数据
                    _getEventsForInitDay();
                  });
                },
                title: Text(diary.title),
                subtitle: Text(
                  "上次修改时间: ${diarys[index].gmtModified ?? diarys[index].gmtCreate}",
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

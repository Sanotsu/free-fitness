// // ignore_for_file: avoid_print

// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart';

// import '../../common/utils/db_diary_helper.dart';
// import '../../common/utils/tools.dart';
// import '../../models/diary_state.dart';

// /// 默认的日历显示范围，当前月的前后3个月
// /// ？？？实际手记的日历显示范围的话，就第一个手记的月份，到当前月份即可
// final kToday = DateTime.now();
// final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
// final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

// class DiaryTableCalendarFuture extends StatefulWidget {
//   const DiaryTableCalendarFuture({super.key});

//   @override
//   State<DiaryTableCalendarFuture> createState() => _DiaryTableCalendarFutureState();
// }

// class _DiaryTableCalendarFutureState extends State<DiaryTableCalendarFuture> {
//   final DBDiaryHelper _dbHelper = DBDiaryHelper();

//   // 被选中的事件
//   late ValueNotifier<List<Diary>> _selectedEvents;
//   // 用于展示的日历格式
//   CalendarFormat _calendarFormat = CalendarFormat.month;
//   // 点击两个日期变为选定日期范围
//   RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
//   // 日历中聚焦的时间(如果是日为单位，就可以具体了某个小时某分某秒了)
//   DateTime _focusedDay = DateTime.now();
//   // 日历中被选中的时间
//   DateTime? _selectedDay;
//   // 范围选择时选中的日期起止
//   DateTime? _rangeStart;
//   DateTime? _rangeEnd;

//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();

//     // 初始化时设定当前选中的日期就是聚焦的日期
//     _selectedDay = _focusedDay;
//     // 获取当前日期的事件
//     // 不能在future builder中初始化，因为builder会在每次构建时调用，无法保证只初始化一次。
//     setState(() {
//       _getEventsForInitDay();
//     });
//   }

//   @override
//   void dispose() {
//     _selectedEvents.dispose();
//     super.dispose();
//   }

//   // 初始化事件，以当前日查询对应的手记数据
//   // 因为不能再改变state中用await，所以单独一个函数
//   _getEventsForInitDay() async {
//     if (isLoading) return;

//     setState(() {
//       isLoading = true;
//     });

//     // ？？？处理条件，使用条件查询
//     List<Diary> temp = await _dbHelper.queryDiaryByDateRange(
//       startDate: DateFormat('yyyy-MM-dd').format(_selectedDay!),
//       endDate: DateFormat('yyyy-MM-dd').format(_selectedDay!),
//     );

//     print("当前日期查询的手记数据 _selectedDay :$_selectedDay temp $temp");
//     setState(() {
//       _selectedEvents = ValueNotifier(temp);

//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('手记日历展示'),
//         actions: [
//           TextButton.icon(
//             onPressed: () {
//               print("跳转到富文本新增页面");
//             },
//             icon: const Icon(Icons.add),
//             label: const Text("添加手记"),
//             style: ButtonStyle(
//               foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
//             ),
//           )
//         ],
//       ),
//       // 异步获取全部的手记数据，以便自定义事件时展示每日有多少的手记数量
//       body: FutureBuilder<List<Diary>>(
//         future: _dbHelper.queryDiaryByDateRange(),
//         builder: (context, item) {
//           // Display error, if any.
//           if (item.hasError) {
//             return Text(item.error.toString());
//           }
//           // Waiting content.
//           if (item.data == null) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           // 'Library' is empty.
//           if (item.data!.isEmpty) {
//             return const Center(child: Text("手记!"));
//           }

//           List<Diary> diarys = item.data!;

//           print("触发了FutureBuilder------------- ");

//           onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
//             setState(() {
//               _selectedDay = null;
//               _focusedDay = focusedDay;
//               _rangeStart = start;
//               _rangeEnd = end;
//               _rangeSelectionMode = RangeSelectionMode.toggledOn;
//             });

//             // `start` or `end` could be null
//             if (start != null && end != null) {
//               _selectedEvents.value = [
//                 for (final d in daysInRange(start, end))
//                   ...(_selectedEvents.value = diarys
//                       .where(
//                           (e) => e.date == DateFormat('yyyy-MM-dd').format(d))
//                       .toList())
//               ];
//             } else if (start != null) {
//               _selectedEvents.value = diarys
//                   .where(
//                       (e) => e.date == DateFormat('yyyy-MM-dd').format(start))
//                   .toList();
//             } else if (end != null) {
//               _selectedEvents.value = diarys
//                   .where((e) => e.date == DateFormat('yyyy-MM-dd').format(end))
//                   .toList();
//             }
//           }

//           return Column(
//             children: [
//               // 日历的一些配置
//               TableCalendar(
//                 locale: 'zh_CN',
//                 firstDay: kFirstDay,
//                 lastDay: kLastDay,
//                 focusedDay: _focusedDay,
//                 selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//                 rangeStartDay: _rangeStart,
//                 rangeEndDay: _rangeEnd,
//                 calendarFormat: _calendarFormat,
//                 rangeSelectionMode: _rangeSelectionMode,

//                 // 如果不使用这个函数，当日的数量标记是不会显示的
//                 eventLoader: (day) {
//                   return diarys
//                       .where(
//                           (e) => e.date == DateFormat('yyyy-MM-dd').format(day))
//                       .toList();
//                 },
//                 startingDayOfWeek: StartingDayOfWeek.monday,
//                 // 默认的一些日历样式配置
//                 calendarStyle: const CalendarStyle(
//                   // Use `CalendarStyle` to customize the UI
//                   // 不是当月的日期不显示
//                   outsideDaysVisible: false,
//                 ),
//                 // 自定义修改日历的样式
//                 calendarBuilders: CalendarBuilders(
//                   // 为什么marker不显示？
//                   markerBuilder: (context, date, list) {
//                     if (list.isEmpty) return Container();
//                     return ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: list.length,
//                       itemBuilder: (context, index) {
//                         return Padding(
//                           padding: const EdgeInsets.all(1),
//                           child: Container(
//                             height: 3,
//                             decoration: BoxDecoration(
//                                 color: Colors.primaries[
//                                     Random().nextInt(Colors.primaries.length)]),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//                 onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
//                   if (!isSameDay(_selectedDay, selectedDay)) {
//                     setState(() {
//                       _selectedDay = selectedDay;
//                       _focusedDay = focusedDay;
//                       _rangeStart = null; // Important to clean those
//                       _rangeEnd = null;
//                       _rangeSelectionMode = RangeSelectionMode.toggledOff;
//                     });

//                     _selectedEvents.value = diarys
//                         .where((e) =>
//                             e.date ==
//                             DateFormat('yyyy-MM-dd').format(selectedDay))
//                         .toList();
//                   }
//                 },
//                 onDayLongPressed: (DateTime selectedDay, DateTime focusedDay) {
//                   print("日期被长按了---$selectedDay --$focusedDay");
//                 },
//                 onRangeSelected: onRangeSelected,
//                 onFormatChanged: (format) {
//                   if (_calendarFormat != format) {
//                     setState(() {
//                       _calendarFormat = format;
//                     });
//                   }
//                 },
//                 onPageChanged: (focusedDay) {
//                   _focusedDay = focusedDay;
//                 },
//               ),
//               const SizedBox(height: 8.0),
//               // 日历某些操作改变后，显示对应的手记内容列表
//               Expanded(
//                 child: ValueListenableBuilder<List<Diary>>(
//                   valueListenable: _selectedEvents,
//                   builder: (context, value, _) {
//                     return ListView.builder(
//                       itemCount: value.length,
//                       itemBuilder: (context, index) {
//                         return Container(
//                           margin: const EdgeInsets.symmetric(
//                             horizontal: 12.0,
//                             vertical: 4.0,
//                           ),
//                           decoration: BoxDecoration(
//                             border: Border.all(),
//                             borderRadius: BorderRadius.circular(12.0),
//                           ),
//                           child: ListTile(
//                             onTap: () => print('${value[index]}'),
//                             title: Text('${value[index].title} '),
//                             subtitle: Text(
//                                 '${value[index].gmtModified ?? value[index].gmtCreate} '),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../common/global/constants.dart';
import '../../common/utils/db_diary_helper.dart';
import '../../common/utils/tool_widgets.dart';
import '../../models/diary_state.dart';
import 'diary_modify_rich_text.dart';
import 'index.dart';

class IndexTimeline extends StatefulWidget {
  const IndexTimeline({Key? key}) : super(key: key);

  @override
  State<IndexTimeline> createState() => _IndexTimelineState();
}

class _IndexTimelineState extends State<IndexTimeline> {
  final DBDiaryHelper _dbHelper = DBDiaryHelper();

  // final _queryFormKey = GlobalKey<FormBuilderState>();

  // 展示训练列表(训练列表一次性查询所有，应该不会太多)
  List<Diary> diaryList = [];
  // 数据库中符合条件的锻炼一共有多少
  int diaryCount = 0;

  // 可以筛选训练，条件用个map来存，初始化一个空map
  Map<String, dynamic> conditionMap = {};
  int currentPage = 1; // 数据库查询的时候会从0开始offset
  int pageSize = 10;
  bool isLoading = false;

  ScrollController scrollController = ScrollController();

  // 时间线连接线的颜色
  Color borderColor = const Color.fromARGB(255, 112, 78, 78).withOpacity(0.5);

  @override
  void initState() {
    super.initState();

    loadMoreDiary();
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (isLoading) return;

    final maxScrollExtent = scrollController.position.maxScrollExtent;
    final currentPosition = scrollController.position.pixels;

    // 上滑滚动到底部加载更多数据
    if (maxScrollExtent <= currentPosition) {
      loadMoreDiary();
    }
  }

  // 加载更多
  loadMoreDiary() async {
    // 如果已经在查询数据中，则忽略此次新的查询
    if (isLoading) return;

    // 如果没在查询中，设置状态为查询中
    setState(() {
      isLoading = true;
    });

    // 等待查询结果
    CusDataResult temp;
    if (conditionMap.isEmpty) {
      temp = await _dbHelper.queryDiaryByKeyword(
        pageSize: pageSize,
        page: currentPage,
        keyword: "",
      );
    } else {
      // ？？？处理条件，使用条件查询
      temp = await _dbHelper.queryDiaryByKeyword(
        pageSize: pageSize,
        page: currentPage,
        keyword: "",
      );
    }

    List<Diary> newData = temp.data as List<Diary>;

    // 如果没有更多数据，则在底部显示
    if (newData.isEmpty) {
      // 显示 "没有更多" 的信息
      if (!mounted) return;
      scrollController.animateTo(
        scrollController.position.pixels, // 回弹的距离
        duration: const Duration(milliseconds: 1000), // 动画持续300毫秒
        curve: Curves.easeOut,
      );
    }

    // 设置查询结果
    setState(() {
      // 因为没有分页查询，所有这里直接替换已有的数组
      diaryList.addAll(newData);
      diaryCount = temp.total;
      currentPage++;
      // 重置状态为查询完成
      isLoading = false;

      print("diaryList---$diaryList");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("手记时间线"),
        actions: [
          ElevatedButton(
            onPressed: () {
              print("保留测试的旧版本主页");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiaryIndex(),
                ),
              );
            },
            child: const Text("<old>"),
          ),
        ],
      ),

      // 设置整个背景色为渐变色
      body: DecoratedBox(
        decoration: const BoxDecoration(
          // 设置渐变色
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   colors: [Colors.blue, Colors.green],
          // ),
          // 纯背景色
          color: Color.fromARGB(255, 169, 150, 184),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: _buildListArea(),
            ),
          ],
        ),
      ),
    );
  }

  _buildListArea() {
    return ListView.builder(
      itemCount: diaryList.length + 1,
      controller: scrollController,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        if (index == diaryList.length) {
          return buildLoader(isLoading);
        } else {
          // 示意图可以有多个，就去第一张好了
          var diaryItem = diaryList[index];

          // 创建时间(不使用最后修改时间是避免时间线显示出现时间不连续的尴尬)
          // var createDate = DateFormat(constDateFormat).format(
          //   DateTime.parse(diaryItem.gmtCreate ?? '1970-01-01 00:00:00'),
          // );

          var createTime = DateFormat(constTimeFormat).format(
            DateTime.parse(diaryItem.gmtCreate ?? '1970-01-01 00:00:00'),
          );
          return TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.3,
            isFirst: index == 0,
            isLast: index == diaryList.length - 1,
            indicatorStyle: IndicatorStyle(
              width: 50,
              height: 50,
              indicator: _CusIndicator(
                number: '${diaryItem.mood}',
                borderColor: borderColor,
              ),
              // 连接线是否画在图标的后面(默认是false，表示线没有画在图标后面)
              drawGap: true,
            ),
            beforeLineStyle: LineStyle(color: borderColor),
            startChild: Container(
              // 内外边距
              // padding: EdgeInsets.all(5.sp),
              margin: EdgeInsets.all(5.sp),
              // 限制盒子最低高度
              constraints: BoxConstraints(minHeight: 40.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // RichText(
                  //   textAlign: TextAlign.end,
                  //   text: TextSpan(
                  //     children: [
                  //       TextSpan(
                  //         text: '$createDate\n',
                  //         style: TextStyle(
                  //           fontSize: 15.sp, // text的默认字体大小
                  //           color: Colors.black,
                  //         ),
                  //       ),
                  //       TextSpan(
                  //         text: createTime,
                  //         style: TextStyle(
                  //           fontSize: 10.sp,
                  //           color: Colors.black,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  Text(
                    diaryItem.date,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  Text(
                    createTime,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ],
              ),
            ),
            endChild: GestureDetector(
              child: Container(
                constraints: BoxConstraints(minHeight: 80.sp),
                // 内外边距
                padding: EdgeInsets.all(2.sp),
                margin: EdgeInsets.all(2.sp),
                // color: Colors.transparent,
                // 装饰和颜色不能同时设置
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black54, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                // 不要用ListTile，很难看也很难布局
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(diaryItem.title),
                        ),
                        Expanded(
                          flex: 1,
                          child: Icon(Icons.arrow_forward, size: 16.sp),
                        ),
                      ],
                    ),
                    Wrap(
                      // 子组件横向的间距
                      // spacing: 2,
                      // 子组件纵向的间距
                      runSpacing: 5,
                      // 排布方向
                      alignment: WrapAlignment.spaceAround,
                      children: [
                        // 先排除原本就是空字符串之后再分割
                        // ...(diaryItem.category?.split(",") ?? [])
                        ...((diaryItem.category != null &&
                                    diaryItem.category!.trim().isNotEmpty)
                                ? diaryItem.category!.trim().split(",")
                                : [])
                            .map((cate) {
                          return buildTinyButtonTag(
                            cate,
                            bgColor: const Color.fromARGB(255, 125, 185, 172),
                            labelTextSize: 8.sp,
                          );
                        }).toList(),
                        // ...(diaryItem.tags?.split(",") ?? [])
                        ...((diaryItem.tags != null &&
                                    diaryItem.tags!.trim().isNotEmpty)
                                ? diaryItem.tags!.trim().split(",")
                                : [])
                            .map((tag) {
                          return buildTinyButtonTag(
                            tag,
                            bgColor: const Color.fromARGB(255, 139, 139, 132),
                            labelTextSize: 8.sp,
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (BuildContext ctx) => DiaryModifyRichText(
                      diaryItem: diaryItem,
                    ),
                  ),
                )
                    .then((value) {
                  // 编辑页面返回后，重新加载手记数据
                  setState(() {
                    currentPage = 1; // 数据库查询的时候会从0开始offset
                    pageSize = 10;
                    diaryList = [];
                  });
                  loadMoreDiary();
                });
              },
            ),
          );

          // 使用card没办法设置透明，使用body给的背景色
          // return Card(
          //   elevation: 10,
          //   color: Colors.transparent,
          //   child: GestureDetector(
          //     onTap: () {
          //       // 点击查看手记详情

          //       Navigator.of(context).push(
          //         MaterialPageRoute(
          //           builder: (BuildContext ctx) => DiaryModifyRichText(
          //             diaryItem: diaryItem,
          //           ),
          //         ),
          //       );
          //     },
          //     child: Row(
          //       children: [
          //         Expanded(
          //           flex: 9,
          //           child: ListTile(
          //             title: Text(
          //               "$index-${diaryItem.title}",
          //               overflow: TextOverflow.ellipsis,
          //               maxLines: 2,
          //               style: TextStyle(
          //                   fontSize: 16.sp, fontWeight: FontWeight.bold),
          //             ),
          //             subtitle: Text(diaryItem.date),
          //           ),
          //         ),
          //         Expanded(
          //           flex: 6,
          //           child: SizedBox(
          //             height: 80.sp,
          //             child: Padding(
          //               padding: EdgeInsets.all(5.sp),
          //               child: Image.asset(
          //                 placeholderImageUrl,
          //                 fit: BoxFit.scaleDown,
          //               ),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // );
        }
      },
    );
  }
}

// 自定义的时间线指示器养蛇
class _CusIndicator extends StatelessWidget {
  const _CusIndicator({
    Key? key,
    required this.number,
    required this.borderColor,
  }) : super(key: key);

  final String number;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(
            color: const Color.fromARGB(255, 112, 78, 78).withOpacity(0.5),
            width: 4,
          ),
        ),
      ),
      child: Center(
        // child: buildSmallButtonTag(
        //   number,
        //   bgColor: Colors.lightGreen,
        //   labelTextSize: 12.sp,
        // ),
        child: Text(
          number,
          style: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }
}

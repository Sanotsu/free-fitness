// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/global/constants.dart';
import '../../common/utils/db_diary_helper.dart';
import '../../common/utils/tool_widgets.dart';
import '../../models/diary_state.dart';

import 'diary_modify_rich_text.dart';

class DiaryIndex extends StatefulWidget {
  const DiaryIndex({super.key});

  @override
  State<DiaryIndex> createState() => _DiaryIndexState();
}

class _DiaryIndexState extends State<DiaryIndex> {
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
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("手记(模块框架)"),
      ),
      body: _buildBody(),
    );
  }

  /// 构建主体内容(是个 GridView)
  ///
  _buildBody() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(20.sp, 20.sp, 20.sp, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 100.sp,
                    child: const Text("功能1,日历框"),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 100.sp,
                    child: const Text("功能1,日记列表？"),
                  ),
                ),
              ],
            ),
          ),
          const Text(
              "正常来讲，这里显示卡片日历，有日记的日期打上标签。在日历中点击改天，可以看到改天日记的列表(如果有多的话)。然后点击某一个日历的标题，进入预览页面"),
          const Text("如果想要修改的话，在预览页面的右上角可以切换功能修改、保存等"),
          const Text("如果是指定某天要新增手记的话，直接在日历卡片选择那一天就好，直接跳转到新增手记的页面。"),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiaryModifyRichText(),
                ),
              );
            },
            child: const Text("正常应该是富文本编辑手记"),
          ),
          _buildListArea(),
        ],
      ),
    );
  }

  _buildListArea() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: diaryList.length + 1,
      controller: scrollController,
      itemBuilder: (context, index) {
        if (index == diaryList.length) {
          return buildLoader(isLoading);
        } else {
          // 示意图可以有多个，就去第一张号了
          var diaryItem = diaryList[index];

          return Card(
            elevation: 10,
            child: GestureDetector(
              onTap: () {
                // 点击查看手记详情

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext ctx) => DiaryModifyRichText(
                      diaryItem: diaryItem,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: ListTile(
                      title: Text(
                        "$index-${diaryItem.title}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(diaryItem.date),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 80.sp,
                      child: Padding(
                        padding: EdgeInsets.all(5.sp),
                        child: Image.asset(
                          placeholderImageUrl,
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

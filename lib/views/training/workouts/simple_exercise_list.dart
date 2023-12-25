// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/training_state.dart';

///
/// 2023-12-22
/// 只有 action list 新增动作会先跳到本页面，点击了某个exercise之后，把该exercise带回到action list页面进行添加。
/// 所以本页面只需要简单显示exercise列表信息即可
///
class SimpleExerciseList extends StatefulWidget {
  const SimpleExerciseList({super.key});

  @override
  State<SimpleExerciseList> createState() => _SimpleExerciseListState();
}

class _SimpleExerciseListState extends State<SimpleExerciseList> {
  final DBTrainingHelper _dbHelper = DBTrainingHelper();

// 存锻炼已经加载了的列表
  List<Exercise> exerciseItems = [];
  // 数据库中符合条件的锻炼一共有多少
  int exerciseCount = 0;

  int currentPage = 1; // 数据库查询的时候会从0开始offset
  int pageSize = 10;
  bool isLoading = false;
  ScrollController scrollController = ScrollController();

  // 查询条件输入框控制器
  final queryTextController = TextEditingController();
  // 输入的条件查询关键字
  String queryConditon = "";

  @override
  void initState() {
    super.initState();
    _loadData();
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    queryTextController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (isLoading) return;

    final maxScrollExtent = scrollController.position.maxScrollExtent;
    final currentPosition = scrollController.position.pixels;

    // 上滑滚动到底部加载更多数据
    if (maxScrollExtent <= currentPosition) {
      _loadData();
    }
  }

  // 加载更多
  // 组件初始化的时候就加载最初第一页的10条
  Future<void> _loadData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 查询结果是个动态的list和该表的总数据，使用list要转型
    var temp = await _dbHelper.queryExerciseByKeyword(
      pageSize: pageSize,
      page: currentPage,
      keyword: queryConditon,
    );

    List<Exercise> newData = temp.data as List<Exercise>;

    // 如果没有更多数据，则在底部显示回弹一下
    if (newData.isEmpty) {
      if (!mounted) return;
      scrollController.animateTo(
        scrollController.position.pixels, // 回弹的距离
        duration: const Duration(milliseconds: 1000), // 动画持续300毫秒
        curve: Curves.easeOut,
      );
    }

    // 查到新数据，更新现有数据列表和当前页码
    setState(() {
      exerciseItems.addAll(newData);
      exerciseCount = temp.total;
      currentPage++;
      isLoading = false;
    });
  }

  // 定义查询回调函数，参数为查询条件的值
  void handleQuery(String query) {
    // 处理查询条件的值
    print(query); // 示例：打印查询条件的值

    // 有变动查询条件，则重新开始查询
    setState(() {
      queryConditon = query;
      exerciseItems.clear();
      exerciseCount = 0;
      currentPage = 1;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: CusAL.of(context).actionConfigLabel('2'),
                style: TextStyle(fontSize: CusFontSizes.pageTitle),
              ),
              TextSpan(
                text: "\n${CusAL.of(context).itemCount(exerciseCount)}",
                style: TextStyle(fontSize: CusFontSizes.pageAppendix),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Card(elevation: 5, child: _buildQueryRow()),
          Expanded(child: _buildListArea()),
        ],
      ),
    );
  }

  _buildQueryRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.all(10.sp),
            child: TextField(
              // 设置文本大小
              style: TextStyle(fontSize: CusFontSizes.searchInputMedium),
              decoration: InputDecoration(
                // 四周带上边框
                border: const OutlineInputBorder(),
                // 设置输入框大小
                contentPadding: EdgeInsets.all(10.sp),
                // 占位符文本
                hintText: CusAL.of(context).queryKeywordHintText(
                  CusAL.of(context).exercise,
                ),
              ),
              controller: queryTextController,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                // 点击查询按钮时收起键盘
                FocusScope.of(context).unfocus();
                // 执行条件查询
                handleQuery(queryTextController.text);
              },
              child: const Icon(Icons.search),
            ),
          ),
        ),
      ],
    );
  }

  _buildListArea() {
    return ListView.builder(
      itemCount: exerciseItems.length + 1,
      controller: scrollController,
      itemBuilder: (context, index) {
        if (index == exerciseItems.length) {
          return buildLoader(isLoading);
        } else {
          var exerciseItem = exerciseItems[index];
          return Card(
            elevation: 10,
            child: GestureDetector(
              onTap: () {
                // 在这里添加你想要执行的点击事件逻辑
                Navigator.pop(context, exerciseItem);
              },
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: ListTile(
                      title: Text(
                        "$index-${exerciseItem.exerciseName}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: CusFontSizes.itemTitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${getCusLabelText(
                          exerciseItem.countingMode,
                          countingOptions,
                        )} ${getCusLabelText(
                          exerciseItem.level ?? '',
                          levelOptions,
                        )}',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 80.sp,
                      child: Padding(
                        padding: EdgeInsets.all(5.sp),
                        child: buildExerciseImageCarouselSlider(exerciseItem),
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

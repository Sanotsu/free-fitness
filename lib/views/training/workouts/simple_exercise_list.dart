// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/training_state.dart';

class SimpleExerciseList extends StatefulWidget {
  // 进此页面的来源有两个，返回的页面也会不一样
  //    1 group list -> new group -> simple exercise list -> action config => new action list
  //    2 action list -> add new item -> simple exercise list -> action config => origin action list
  final String source;

  const SimpleExerciseList({super.key, required this.source});

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

  String placeholderImageUrl = 'assets/images/no_image.png';

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

    // 模拟加载耗时一秒，以明显看到加载圈（实际用删除）
    await Future.delayed(const Duration(milliseconds: 100));

    // 如果没有更多数据，则在底部显示
    if (newData.isEmpty) {
      // 显示 "没有更多" 的信息
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(child: Text("没有更多")),
          duration: Duration(seconds: 2),
        ),
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
        title: const Text('SimpleExerciseList'),
      ),
      body: Column(
        children: [
          const Center(
            child: Text(
              'SimpleExerciseList. 添加action的时候，先要选择exercise。这里就最简单名称搜索，显示名称（代号）和动作示意图.点击这个的list的某一个，跳转到action配置页面',
            ),
          ),
          // 整个查询区域都带上边框
          // Container(
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey), // 设置边框样式
          //     borderRadius: BorderRadius.circular(10), // 设置圆角
          //   ),
          //   child:
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: TextField(
                    // 设置文本大小
                    style: TextStyle(fontSize: 12.sp),
                    decoration: const InputDecoration(
                      // 四周带上边框
                      border: OutlineInputBorder(),
                      // 设置输入框大小
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      // 占位符文本
                      hintText: '输入动作名称或代号关键字',
                    ),
                    controller: queryTextController,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(child: Text('共$exerciseCount条')),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min, // 根据需要调整
                      children: [
                        Icon(Icons.search), // 图标
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // ),
          Expanded(
            child: ListView.builder(
              itemCount: exerciseItems.length + 1,
              controller: scrollController,
              itemBuilder: (context, index) {
                if (index == exerciseItems.length) {
                  return buildLoader(isLoading);
                } else {
                  // 示意图可以有多个，就去第一张号了
                  var exerciseItem = exerciseItems[index];
                  var imageUrl = exerciseItem.images?.split(",")[0] ?? "";

                  return Card(
                    elevation: 10,
                    child: GestureDetector(
                      onTap: () {
                        // 在这里添加你想要执行的点击事件逻辑
                        print('Row clicked--widget.source ${widget.source}');

                        Navigator.pop(
                          context,
                          {"selectedExerciseItem": exerciseItem},
                        );
                      },
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 1,
                            child: Icon(
                              Icons.add_circle_outline_outlined,
                              color: Colors.grey,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: ListTile(
                              title: Text(
                                "$index-${exerciseItem.exerciseName}",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(exerciseItem.countingMode),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 100.sp,
                              child: Image.file(
                                File(imageUrl),
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  return Image.asset(
                                    placeholderImageUrl,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // SizedBox(height: 20.sp),
        ],
      ),
    );
  }
}

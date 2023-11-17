// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/training_state.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../me/test_funcs.dart';
import 'exercise_detail.dart';
import 'exercise_modify_form.dart';
import 'exercise_query.dart';

class TrainingExercise extends StatefulWidget {
  const TrainingExercise({super.key});

  @override
  State<TrainingExercise> createState() => _TrainingExerciseState();
}

class _TrainingExerciseState extends State<TrainingExercise> {
  final DBTrainingHelper _dbHelper = DBTrainingHelper();

// 存锻炼加载了的列表
  List<Exercise> exerciseItems = [];
  int currentPage = 1; // 数据库查询的时候会从0开始offset
  int pageSize = 10;
  bool isLoading = false;
  ScrollController scrollController = ScrollController();

  Map<String, dynamic>? queryConditon;

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

  Future<void> _loadData() async {
    print("进入了_loadData");

    // _dietaryHelper.deleteDb();

    // return;

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    List<Exercise> newData = await searchExercise();

    print("newDatanewDatanewData=$newData");

    // 模拟加载耗时一秒，以明显看到加载圈（实际用删除）
    await Future.delayed(const Duration(milliseconds: 200));

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

    setState(() {
      exerciseItems.addAll(newData);
      currentPage++;
      isLoading = false;
    });
  }

  removeExerciseById(id) async {
    await _dbHelper.deleteExercise(id);
    _loadData();
  }

  // 如果是有用户的查询条件，则使用查询条件进行查询（查询条件表单返回的值）；如果没有，则默认查询所有
  Future<List<Exercise>> searchExercise() async {
    if (queryConditon == null) {
      print("queryConditon is null");

      // 总数量放在这里不优雅，但会更新，还行
      return await _dbHelper.queryExercise(
        pageSize: pageSize,
        page: currentPage,
      );
    } else {
      print("queryConditon i不是s null $queryConditon");

      // 从 queryMap 中获取对应的值
      int? exerciseId = queryConditon?['exercise_id'];
      String? exerciseCode = queryConditon?['exercise_code'];
      String? exerciseName = queryConditon?['exercise_name'];
      String? force = queryConditon?['force'];
      String? level = queryConditon?['level'];
      String? mechanic = queryConditon?['mechanic'];
      String? equipment = queryConditon?['equipment'];
      String? category = queryConditon?['category'];
      String? primaryMuscle = queryConditon?['primary_muscles'];

      return await _dbHelper.queryExercise(
        exerciseId: exerciseId,
        exerciseCode: exerciseCode,
        exerciseName: exerciseName,
        force: force,
        level: level,
        mechanic: mechanic,
        equipment: equipment,
        category: category,
        primaryMuscle: primaryMuscle,
        pageSize: pageSize,
        page: currentPage,
      );
    }
  }

// 测试新增基础活动的示例
  _demoAddRandomExercise() async {
    insertOneRandomExercise();

    // 有新增数据，也重新开始查询
    setState(() {
      exerciseItems.clear();
      currentPage = 1;
    });
    _loadData();
  }

  // 定义回调函数，参数为查询条件的值
  void handleQuery(Map<String, dynamic> query) {
    // 处理查询条件的值
    print(query); // 示例：打印查询条件的值

    // 有变动查询条件，则重新开始查询
    setState(() {
      queryConditon = query;
      exerciseItems.clear();
      currentPage = 1;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('WorkoutDiscovers'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add),
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            ),
            onPressed: () async {
              if (!mounted) return;
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext ctx) {
                    return const ExerciseModifyForm();
                  },
                ),
              );

              // 如果新增基础活动成功，会有指定返回值。这里拿到之后，加载最新的活动列表

              print(
                  'exerciseModifiedexerciseModifiedexerciseModified--$result');
              // ？？？2023-11-05 这里的新增和下面的展开详情的修改之后返回列表页面，都可以考虑直接重新加载页面，不管子组件返回值
              if (result != null) {
                setState(() {
                  exerciseItems.clear();
                  // ？？？新增之后重新开始，修改的话有必要吗？
                  currentPage = 1;
                });
                _loadData();
              }
            },
            label: const Text('新增'),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Expanded(
            //   child: SizedBox(
            //     height: 0.1.sh,
            //     child: const ExerciseQueryForm(),
            //   ),
            // ),
            ExerciseQueryForm(
              onQuery: handleQuery,
            ),

            /// 显示查询结果的基础活动缩略卡片
            Center(
              child: Column(
                children: [
                  Text("Exercise 当前结果共 ${exerciseItems.length} 条"),
                  TextButton(
                    onPressed: _demoAddRandomExercise,
                    child: const Text('AddRndExercise'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                itemCount: exerciseItems.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 3, // 主轴和纵轴的比例
                ),
                controller: scrollController,
                itemBuilder: (context, index) {
                  if (index == exerciseItems.length) {
                    return buildLoader(isLoading);
                  } else {
                    print("xxxxxxxxxxx");
                    print(exerciseItems[index].images?.split(","));

                    // 示意图可以有多个，就去第一张号了
                    var exerciseItem = exerciseItems[index];
                    var imageUrl = exerciseItem.images?.split(",")[0] ?? "";

                    return Dismissible(
                      key: Key(exerciseItem.exerciseCode),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 20.0.sp),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      // ---实际删除应该有弹窗，删除时还要检查删除者是否为创建者，这里只是测试左滑删除卡片

                      confirmDismiss: (DismissDirection direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Remove Exercise"),
                              content: const Text(
                                  "Are you sure you want to remove this item?"),
                              actions: <Widget>[
                                ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Yes")),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("No"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        setState(() {
                          // _dbHelper.deleteExercise(exerciseItem.exerciseId!);
                          // futureHandler = _dbHelper.queryExercise();
                          exerciseItems.removeAt(index);

                          removeExerciseById(exerciseItem.exerciseId!);
                        });

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已删除该项'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },

                      child: Card(
                        child: InkWell(
                          onTap: () {
                            // 处理点击事件的逻辑
                            print("------ tap in card");
                            showModalBottomSheet(
                              context: context,
                              // 设置滚动控制为true，子部件设置dialog的高度才有效，不然固定在9/16左右无法更多。
                              isScrollControlled: true,
                              builder: (BuildContext context) {
                                return ExerciseDetailDialog(
                                  exerciseItems: exerciseItems,
                                  exerciseIndex: index,
                                );
                              },
                            ).then((value) {
                              print("-------sdsdd $value");
                              // 修改exercise之后，重新加载列表
                              if (value != null) {
                                setState(() {
                                  exerciseItems.clear();
                                  currentPage = 1;
                                });
                                _loadData();
                              }
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 0.4.sw,
                                height: 0.3.sh,
                                child: Image.file(
                                  File(imageUrl),
                                  errorBuilder: (BuildContext context,
                                      Object exception,
                                      StackTrace? stackTrace) {
                                    return Image.asset(
                                      placeholderImageUrl,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              // SizedBox(width: 0.1.sw),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(10.sp),
                                      child: Text(
                                        "$index-${exerciseItem.exerciseId}-${exerciseItem.exerciseName}",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    _buildCardPadding(
                                      "级别：",
                                      exerciseItem.level ?? "",
                                      levelOptions,
                                    ),
                                    _buildCardPadding(
                                      "类型：",
                                      exerciseItem.category,
                                      categoryOptions,
                                    ),
                                    // _buildCardPadding(
                                    //   "器械：",
                                    //   exerciseItem.equipment ?? "",
                                    //   equipmentOptions,
                                    // ),
                                    _buildCardPadding(
                                      "计量：",
                                      exerciseItem.countingMode,
                                      countingOptions,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildCardPadding(
    String prefix,
    String item,
    List<CusLabel> options,
  ) {
    var label = options
        .firstWhere(
          (element) => element.value == item,
          orElse: () => CusLabel(cnLabel: '无数据', value: '', enLabel: 'No Data'),
        )
        .cnLabel;

    return Padding(
      padding: EdgeInsets.only(left: 10.sp),
      child: Text(
        prefix + label,
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }
}

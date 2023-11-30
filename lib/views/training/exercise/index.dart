// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/training_state.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';

import 'exercise_detail.dart';
import 'exercise_json_import.dart';
import 'exercise_modify.dart';
import 'exercise_query_form.dart';

class TrainingExercise extends StatefulWidget {
  const TrainingExercise({super.key});

  @override
  State<TrainingExercise> createState() => _TrainingExerciseState();
}

class _TrainingExerciseState extends State<TrainingExercise> {
  final DBTrainingHelper _dbHelper = DBTrainingHelper();

  // 存锻炼加载了的列表
  List<Exercise> exerciseItems = [];
  // 锻炼的总数(查询时则为符合条件的总数，默认一页只有10条，看不到总数量)
  int itemsCount = 0;
  int currentPage = 1; // 数据库查询的时候会从0开始offset
  int pageSize = 10;
  bool isLoading = false;
  // 页面滚动控制器
  ScrollController scrollController = ScrollController();
  // 查询条件
  Map<String, dynamic>? queryConditon;

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  // 滚动到最底部加载更多数据
  _scrollListener() {
    if (isLoading) return;

    final maxScrollExtent = scrollController.position.maxScrollExtent;
    final currentPosition = scrollController.position.pixels;

    // 上滑滚动到底部加载更多数据
    if (maxScrollExtent <= currentPosition) {
      _loadExerciseData();
    }
  }

  // 加载更多数据(一次10条，有初始值)
  _loadExerciseData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    CusDataResult temp = await _searchExercise();
    List<Exercise> newData = temp.data as List<Exercise>;

    // 模拟加载耗时一秒，以明显看到加载圈（实际用删除）
    // await Future.delayed(const Duration(milliseconds: 200));

    // 如果没有更多数据，则在底部显示
    if (newData.isEmpty) {
      // 显示 "没有更多" 的信息
      // if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Center(child: Text("没有更多")),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
      // 如果没有更多数据就回弹一下
      scrollController.animateTo(
        scrollController.position.pixels - 100, // 回弹的距离
        duration: const Duration(milliseconds: 300), // 动画持续300毫秒
        curve: Curves.easeOut,
      );
    }

    setState(() {
      exerciseItems.addAll(newData);
      itemsCount = temp.total;
      currentPage++;
      isLoading = false;
    });
  }

  // 如果是有用户的查询条件，则使用查询条件进行查询（查询条件表单返回的值）；如果没有，则默认查询所有
  _searchExercise() async {
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

  // 定义查询表单点击确认的回调函数，参数为查询条件的值
  _handleQuery(Map<String, dynamic> query) {
    // 处理查询条件的值
    print(query); // 示例：打印查询条件的值

    // 有变动查询条件，则重新开始查询
    setState(() {
      queryConditon = query;
      exerciseItems.clear();
      currentPage = 1;
      _loadExerciseData();
    });
  }

  // 从数据库移除指定基础活动
  _removeExerciseById(id) async {
    await _dbHelper.deleteExercise(id);
    _loadExerciseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '动作库    ', style: TextStyle(fontSize: 20.sp)),
              TextSpan(
                text: "共 $itemsCount 条",
                style: TextStyle(fontSize: 12.sp),
              ),
            ],
          ),
        ),
        actions: [
          /// 导入json文件
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseJsonImport(),
                ),
              ).then((value) {
                setState(() {
                  exerciseItems.clear();
                  currentPage = 1;
                });
                _loadExerciseData();
              });
            },
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            ),
            icon: const Icon(Icons.import_export),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 30.sp),
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            ),
            onPressed: () async {
              if (!mounted) return;
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext ctx) {
                    return const ExerciseModify();
                  },
                ),
              );

              // 如果新增基础活动成功，会有指定返回值。这里拿到之后，加载最新的活动列表
              // ？？？2023-11-05 这里的新增和下面的展开详情的修改之后返回列表页面，都可以考虑直接重新加载页面，不管子组件返回值
              if (result != null) {
                setState(() {
                  exerciseItems.clear();
                  // ？？？新增之后重新开始，修改的话有必要吗？
                  currentPage = 1;
                });
                _loadExerciseData();
              }
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            /// 上方的条件查询区域
            ExerciseQueryForm(onQuery: _handleQuery),

            /// 运动的数据列表
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
                    // 示意图可以有多个，就取第一张好了
                    var exerciseItem = exerciseItems[index];

                    // 向左滑可删除指定行
                    return Dismissible(
                      key: Key(exerciseItem.exerciseCode),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 20.0.sp),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),

                      // 左滑显示删除确认弹窗，？？？删除时还要检查删除者是否为创建者，这里只是测试左滑删除卡片
                      confirmDismiss: (DismissDirection direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("删除确认"),
                              content: const Text("确认要删除该动作？删除后不可恢复！"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("确定"),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("取消"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      // 确认删除时的操作
                      onDismissed: (direction) {
                        setState(() {
                          // 确认要删除后，先从列表中移除，然后从数据库删除
                          exerciseItems.removeAt(index);
                          _removeExerciseById(exerciseItem.exerciseId!);
                        });

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已删除该项'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      // 实际展示的基础活动列表
                      child: _buildExerciseItemCard(index),
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

  // 构建单个基础活动的卡片信息
  _buildExerciseItemCard(int index) {
    var exerciseItem = exerciseItems[index];

    return Card(
      child: InkWell(
        onTap: () {
          // 点击卡片，弹窗显示基础活动的基本信息
          showModalBottomSheet(
            context: context,
            // 设置滚动控制为true，子部件设置dialog的高度才有效，不然固定在9/16左右无法更多。
            isScrollControlled: true,
            builder: (BuildContext context) => ExerciseDetailDialog(
              exerciseItems: exerciseItems,
              exerciseIndex: index,
            ),
          ).then((value) {
            // 修改exercise之后，重新加载列表
            if (value != null) {
              setState(() {
                exerciseItems.clear();
                currentPage = 1;
              });
              _loadExerciseData();
            }
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 0.4.sw,
              height: 0.3.sh,
              child: buildExerciseImage(exerciseItem),
            ),

            // SizedBox(width: 0.1.sw),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(10.sp),
                    child: Text(
                      "${index + 1} ${exerciseItem.exerciseName}",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _propertyText("级别：", exerciseItem.level ?? "", levelOptions),
                  _propertyText("类型：", exerciseItem.category, categoryOptions),
                  _propertyText(
                      "器械：", exerciseItem.equipment ?? "", equipmentOptions),
                  _propertyText(
                      "计量：", exerciseItem.countingMode, countingOptions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _propertyText(String prefix, String item, List<CusLabel> options) {
    // 数据库存的是英文，这里找到对应的中文显示
    var label = options
        .firstWhere(
          (element) => element.value == item,
          orElse: () => CusLabel(cnLabel: '无数据', enLabel: 'No Data', value: ''),
        )
        .cnLabel;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: 10.sp),
        child: Text(prefix + label, style: TextStyle(fontSize: 12.sp)),
      ),
    );
  }
}

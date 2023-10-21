// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/training_state.dart';
import 'package:intl/intl.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/sqlite_db_helper.dart';
import '../../../common/utils/tools.dart';
import 'exercise_modify_form.dart';
import 'exercise_query.dart';

class TrainingExercise extends StatefulWidget {
  const TrainingExercise({super.key});

  @override
  State<TrainingExercise> createState() => _TrainingExerciseState();
}

class _TrainingExerciseState extends State<TrainingExercise> {
  final DBTrainHelper _dbHelper = DBTrainHelper();
  late Future<List<Exercise>> futureHandler;

  int totalSize = 0;

  Map<String, dynamic>? queryConditon;

  String placeholderImageUrl = 'assets/images/no_image.png';

  @override
  void initState() {
    super.initState();
    futureHandler = searchExercise();
  }

  removeExerciseById(id) async {
    await _dbHelper.deleteExercise(id);
    futureHandler = searchExercise();
  }

  // 如果是有用户的查询条件，则使用查询条件进行查询（查询条件表单返回的值）；如果没有，则默认查询所有
  searchExercise() {
    if (queryConditon == null) {
      print("queryConditon is null");

      // 总数量放在这里不优雅，但会更新，还行
      return _dbHelper.queryExercise().then((List<Exercise> result) {
        setState(() {
          totalSize = result.length;
        });
        return result;
      });
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

      return _dbHelper
          .queryExercise(
        exerciseId: exerciseId,
        exerciseCode: exerciseCode,
        exerciseName: exerciseName,
        force: force,
        level: level,
        mechanic: mechanic,
        equipment: equipment,
        category: category,
        primaryMuscle: primaryMuscle,
      )
          .then((List<Exercise> result) {
        setState(() {
          totalSize = result.length;
        });
        return result;
      });
    }
  }

// 测试新增基础活动的示例
  _demoAddRandomExercise() async {
    // _dbHelper.deleteDb();

    // return;

    Exercise exercise = Exercise(
      exerciseCode: getRandomString(4),
      exerciseName: generateRandomString(5, 50),
      category: categoryOptions[Random().nextInt(categoryOptions.length)].value,
      level: levelOptions[Random().nextInt(levelOptions.length)].value,
      mechanic: mechanicOptions[Random().nextInt(mechanicOptions.length)].value,
      force: forceOptions[Random().nextInt(forceOptions.length)].value,
      equipment:
          equipmentOptions[Random().nextInt(equipmentOptions.length)].value,
      // standardDuration: "1",
      gmtCreate: DateFormat.yMMMd().format(DateTime.now()),
    );

    await _dbHelper.insertExercise(exercise);
    print("触发了【随机】插入按钮");
    setState(() {
      futureHandler = searchExercise();
    });
  }

  // 定义回调函数，参数为查询条件的值
  void handleQuery(Map<String, dynamic> query) {
    // 处理查询条件的值
    // 可以在这里进行其他操作，如发送网络请求等
    print(query); // 示例：打印查询条件的值

    setState(() {
      queryConditon = query;
      futureHandler = searchExercise();
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
              if (result != null) {
                setState(() {
                  futureHandler = searchExercise();
                });
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
                  Text("Exercise 查询结果共 $totalSize 条"),
                  TextButton(
                    onPressed: _demoAddRandomExercise,
                    child: const Text('AddRndExercise'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Exercise>>(
                future: futureHandler,
                builder: (context, item) {
                  // FutureBuilder的builder回调函数在两种情况下会被触发。
                  // 第一次是在FutureBuilder的初始化阶段，即在将FutureBuilder挂载到视图树上时。
                  // 此时，FutureBuilder的future参数被传递给了futureHandler，并开始执行异步查询。
                  // 在这个阶段，builder回调函数会被触发一次，从而构建出等待控件或预加载内容。

                  // 第二次是在异步查询结果准备好之后，需要重新构建子组件来显示新的数据。
                  // 在这个阶段，builder回调函数会被再次触发，从而使用查询结果更新构建的子组件。
                  print("-----------触发了FutureBuilder");
                  // Display error, if any.
                  if (item.hasError) {
                    return Text(item.error.toString());
                  }
                  // Waiting content.
                  if (item.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // 'Library' is empty.
                  if (item.data!.isEmpty) {
                    return const Center(child: Text("暂无Exercise!"));
                  }

                  // 得到查询的歌手列表
                  List<Exercise> exerciseList = item.data!;

                  print("exerciseList----------$exerciseList");

                  return GridView.builder(
                    itemCount: exerciseList.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 3, // 主轴和纵轴的比例
                    ),
                    itemBuilder: (context, index) {
                      print("xxxxxxxxxxx");
                      print(exerciseList[index].images?.split(","));

                      // 示意图可以有多个，就去第一张号了
                      var exerciseItem = exerciseList[index];
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
                            exerciseList.removeAt(index);

                            removeExerciseById(exerciseItem.exerciseId!);
                            futureHandler = searchExercise();
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
                                        exerciseItem.exerciseName,
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
                                      "耗时：",
                                      exerciseItem.standardDuration ?? "",
                                      standardDurationOptions,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
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
    List<ExerciseDefaultOption> options,
  ) {
    var label = options
        .firstWhere(
          (element) => element.value == item,
          orElse: () => ExerciseDefaultOption(label: 'No Data', value: ''),
        )
        .label;

    return Padding(
      padding: EdgeInsets.only(left: 10.sp),
      child: Text(
        prefix + label,
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }
}

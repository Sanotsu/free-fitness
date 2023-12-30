// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
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

  // 查询表单的key
  final _queryFormKey = GlobalKey<FormBuilderState>();
  // 可以筛选训练，条件用个map来存，初始化一个空map
  Map<String, dynamic> conditionMap = {};

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

  // 加载更多
  // 组件初始化的时候就加载最初第一页的10条
  Future<void> _loadData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    print("查询数据中的条件$conditionMap");

    // 查询结果是个动态的list和该表的总数据，使用list要转型
    CusDataResult temp;
    if (conditionMap.isEmpty) {
      // 没有查询条件就默认查询所有
      temp = await _dbHelper.queryExerciseByKeyword(
        pageSize: pageSize,
        page: currentPage,
        keyword: "",
      );
    } else {
      // 有其他条件，就条件查询
      temp = await _dbHelper.queryExercise(
        pageSize: pageSize,
        page: currentPage,
        level: conditionMap["level"],
        exerciseName: conditionMap["exercise_name"],
        category: conditionMap["category"],
      );
    }

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
          FormBuilder(
            key: _queryFormKey,
            child: Card(
              elevation: 5.sp,
              child: Column(
                children: [_buildQueryAreaRow(), SizedBox(height: 10.sp)],
              ),
            ),
          ),
          Expanded(child: _buildListArea()),
        ],
      ),
    );
  }

  _buildQueryAreaRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: cusFormBuilerTextField(
                      "exercise_name",
                      labelText: CusAL.of(context).workoutQuerys('0'),
                    ),
                  ),
                  SizedBox(
                    width: 50.sp,
                    height: 36.sp,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _queryFormKey.currentState?.reset();
                          // 2023-12-12 不知道为什么，reset对下拉选中的没有效，所以手动清除
                          _queryFormKey.currentState?.fields['category']
                              ?.didChange(null);
                          _queryFormKey.currentState?.fields['level']
                              ?.didChange(null);

                          // 重置后重新查询
                          conditionMap = {};
                          currentPage = 1;
                          exerciseItems.clear();
                          exerciseCount = 0;
                          _loadData();
                        });
                        // 如果有键盘就收起键盘
                        FocusScope.of(context).focusedChild?.unfocus();
                      },
                      child: Text(
                        CusAL.of(context).resetLabel,
                        style: TextStyle(
                          fontSize: CusFontSizes.pageAppendix,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: cusFormBuilerDropdown(
                      "category",
                      categoryOptions,
                      labelText: CusAL.of(context).workoutQuerys('1'),
                    ),
                  ),
                  Expanded(
                    child: cusFormBuilerDropdown(
                      "level",
                      levelOptions,
                      labelText: CusAL.of(context).workoutQuerys('2'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 50.sp,
          alignment: Alignment.center,
          child: IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).primaryColor),
            onPressed: () {
              if (_queryFormKey.currentState!.saveAndValidate()) {
                setState(() {
                  conditionMap = _queryFormKey.currentState!.value;

                  // 重新查询的结果要全部替换掉之前的结果
                  currentPage = 1;
                  exerciseItems.clear();
                  exerciseCount = 0;
                  _loadData();
                });
              }
              // 如果有键盘就收起键盘
              FocusScope.of(context).focusedChild?.unfocus();
            },
          ),
        )
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

          List<String> imageList =
              (exerciseItem.images?.trim().isNotEmpty == true)
                  ? exerciseItem.images!.split(",")
                  : [];

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
                        "${index + 1}-${exerciseItem.exerciseName}",
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
                        child: buildImageCarouselSlider(imageList),
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

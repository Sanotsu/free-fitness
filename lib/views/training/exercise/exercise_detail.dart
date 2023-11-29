// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/views/training/exercise/exercise_modify.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../models/training_state.dart';
import 'exercise_detail_more.dart';

class ExerciseDetailDialog extends StatefulWidget {
  final List<Exercise> exerciseItems;
  final int exerciseIndex;

  const ExerciseDetailDialog({
    Key? key,
    required this.exerciseItems,
    required this.exerciseIndex,
  }) : super(key: key);

  @override
  State<ExerciseDetailDialog> createState() => _ExerciseDetailDialogState();
}

class _ExerciseDetailDialogState extends State<ExerciseDetailDialog> {
  final DBTrainingHelper _dbHelper = DBTrainingHelper();
  // 当前索引
  int _currentIndex = 0;
  // 当前列表总数量
  int _totalSize = 0;
  // 当前基础活动数据
  late Exercise _currentItem;
  // 当前基础活动列表
  late List<Exercise> _currentItems;

  // 基础活动修改页面返回的标志(如果是进入了详情页面，这个值依旧为空)
  String? modifiedFlag;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.exerciseIndex;
    _currentItems = widget.exerciseItems;
    _currentItem = _currentItems[_currentIndex];
    _totalSize = _currentItems.length;
  }

  @override
  Widget build(BuildContext context) {
    // exercise详情弹窗占屏幕高度的80%
    double screenHeight = MediaQuery.of(context).size.height;
    double desiredHeight = screenHeight * 0.8;
    print("desiredHeight=====$screenHeight $desiredHeight $_totalSize");

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        Navigator.pop(context, modifiedFlag);
      },
      child: SizedBox(
        height: desiredHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // 从上到下依次为关闭按钮、图片、动作名称及其技术要点、详情和修改按钮、翻页按钮
          children: [
            // ？？？关闭按钮考虑和下面的修改和详情放一起，但3个按钮怎么排都显示很奇怪
            // _buildCloseButton(),
            SizedBox(
                height: 40.sp,
                child: buildCloseButton(
                  context,
                  popValue: modifiedFlag,
                )),
            Expanded(flex: 2, child: buildImageArea(context, _currentItem)),
            Expanded(
              flex: 3,
              child: buildTitleAndDescription(
                _buildMoreAndEditButton(),
                _currentItem.instructions ?? "",
              ),
            ),
            // 单独一行放在底部。这个有指定高度，尽量不那么高
            // buildMoreAndEditButtonRow(),
            // Expanded(flex: 1, child: _buildPageButton()),
            // 固定高度更好看
            SizedBox(height: 60.sp, child: _buildPageButton())
          ],
        ),
      ),
    );
  }

  // 更多和修改按钮
  _buildMoreAndEditButton() {
    return SizedBox(
      height: 40.sp,
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Text(
              '${_currentIndex + 1} -${_currentItem.exerciseName}',
              // 限制只显示一行，多的用省略号
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: 20.sp),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                child: Text("详情", style: TextStyle(fontSize: 12.sp)),
                onPressed: () {
                  // 可以考虑不关详情弹窗
                  // Navigator.of(context).pop(); // 关闭详情弹窗
                  // 跳转到详情页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetailMore(
                        exerciseItem: _currentItem,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextButton(
              child: Text("修改", style: TextStyle(fontSize: 12.sp)),
              onPressed: () async {
                // 跳转到修改表单
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciseModify(item: _currentItem),
                  ),
                );

                // 修改成功后返回，不再关闭弹窗，保留逻辑和点击了详情按钮返回当前弹窗一样；
                // 但是把修改返回的标志在点击关闭弹窗和返回按钮时继续返回到父组件；
                // 同时修改后应该看到该行的新数据，所以这里要重新查询数据。
                var exercise = await _dbHelper.queryExerciseById(
                  _currentItem.exerciseId!,
                );

                setState(() {
                  modifiedFlag = result;
                  _currentItem = exercise;
                  _currentItems[_currentIndex] = exercise;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // 单独一行放在底部
  buildMoreAndEditButtonRow() {
    return SizedBox(
      height: 40.sp,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.blue, size: 20.sp),
            onPressed: () {
              // 可以考虑不关详情弹窗
              // Navigator.of(context).pop(); // 关闭详情弹窗
              // 跳转到详情页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailMore(
                    exerciseItem: _currentItem,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue, size: 20.sp),
            onPressed: () async {
              // 跳转到修改表单
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseModify(item: _currentItem),
                ),
              );

              // 修改成功后返回，不再关闭弹窗，保留逻辑和点击了详情按钮返回当前弹窗一样；
              // 但是把修改返回的标志在点击关闭弹窗和返回按钮时继续返回到父组件；
              // 同时修改后应该看到该行的新数据，所以这里要重新查询数据。
              var exercise = await _dbHelper.queryExerciseById(
                _currentItem.exerciseId!,
              );

              setState(() {
                modifiedFlag = result;
                _currentItem = exercise;
                _currentItems[_currentIndex] = exercise;
              });
            },
          ),
          // IconButton(
          //   icon: Icon(Icons.close, color: Colors.blue, size: 20.sp),
          //   onPressed: () {
          //     Navigator.of(context).pop(modifiedFlag); // 关闭弹窗
          //   },
          // )
        ],
      ),
    );
  }

  // 分页按钮行
  _buildPageButton() {
    return Container(
      color: const Color.fromARGB(255, 1, 191, 155),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 30.sp,
                color: _currentIndex > 0
                    ? Colors.blue
                    : const Color.fromARGB(255, 128, 222, 204),
              ),
              onPressed: () {
                setState(() {
                  if (_currentIndex > 0) {
                    _currentIndex--;
                    _currentItem = _currentItems[_currentIndex];
                  }
                });
              },
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 20.0.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
                children: <TextSpan>[
                  // 索引是从0开始，显示从1开始
                  TextSpan(
                    text: '${_currentIndex + 1}',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '/$_totalSize',
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.arrow_forward,
                size: 30.sp,
                color: _currentIndex < _currentItems.length - 1
                    ? Colors.blue
                    : const Color.fromARGB(255, 128, 222, 204),
              ),
              onPressed: () {
                setState(() {
                  if (_currentIndex < _currentItems.length - 1) {
                    _currentIndex++;
                    _currentItem = _currentItems[_currentIndex];
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

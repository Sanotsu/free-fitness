// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/global/constants.dart';
import '../../../models/training_state.dart';

class ActionDetailDialog extends StatefulWidget {
  final List<ActionDetail> adItems;
  final int adIndex;

  const ActionDetailDialog({
    Key? key,
    required this.adItems,
    required this.adIndex,
  }) : super(key: key);

  @override
  State<ActionDetailDialog> createState() => _ActionDetailDialogState();
}

class _ActionDetailDialogState extends State<ActionDetailDialog> {
  String placeholderImageUrl = 'assets/images/no_image.png';

  int _currentIndex = 0;
  int _totalSize = 0;
  late ActionDetail _currentItem;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.adIndex;
    _currentItem = widget.adItems[_currentIndex];
    _totalSize = widget.adItems.length;
  }

  @override
  Widget build(BuildContext context) {
    // exercise详情弹窗占屏幕高度的80%
    double screenHeight = MediaQuery.of(context).size.height;
    double desiredHeight = screenHeight * 0.8;
    print("desiredHeight=====$screenHeight $desiredHeight $_totalSize");

    return SizedBox(
      height: desiredHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // 从上到下依次为关闭按钮、图片、动作名称及其技术要点、翻页按钮
        children: [
          SizedBox(height: 40.sp, child: buildCloseButton(context)),
          Expanded(
            flex: 2,
            child: buildImageArea(context, _currentItem.exercise),
          ),
          Expanded(child: _buildCountArea()),
          Expanded(
            flex: 3,
            child: buildTitleAndDescription(
              SizedBox(
                height: 40.sp,
                child: Text(
                  '$_currentIndex -${_currentItem.exercise.exerciseName}',
                  // 限制只显示一行
                  maxLines: 1,
                  //设置文字溢出时的处理方式，多的用省略号
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 20.sp),
                  textAlign: TextAlign.left,
                ),
              ),
              _currentItem.exercise.instructions ?? "",
            ),
          ),
          Expanded(flex: 1, child: _buildPageButton()),
        ],
      ),
    );
  }

  _buildCountArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          color: Colors.white,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              (_currentItem.exercise.countingMode ==
                      countingOptions.first.value)
                  ? '时长 ${_currentItem.action.duration} 秒'
                  : '重复 ${_currentItem.action.frequency} 次',
              style: TextStyle(fontSize: 24.sp),
            ),
          ),
        ),
        _currentItem.action.equipmentWeight != null
            ? Container(
                color: Colors.white,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    '器械 ${_currentItem.action.equipmentWeight!.toStringAsFixed(2)} kg',
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
              )
            : Container(),
      ],
    );
  }

// ======== ？？？这个翻页部件，action config dialog和exercise detail的弹窗也有。
// 因为有状态改变，估计要回调函数之类的，暂时不知道怎么抽出来复用
  _buildPageButton() {
    return Container(
      color: const Color.fromARGB(255, 1, 191, 155),
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
                  _currentItem = widget.adItems[_currentIndex];
                }
              });
            },
          ),
          // 索引从0开始，显示从1开始
          // Text(
          //   '${_currentIndex + 1} / $_totalSize',
          //   style: TextStyle(
          //     fontSize: 24.sp,
          //     fontWeight: FontWeight.w400,
          //   ),
          // ),
          RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: 20.0.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.w400),
              children: <TextSpan>[
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
              color: _currentIndex < widget.adItems.length - 1
                  ? Colors.blue
                  : const Color.fromARGB(255, 128, 222, 204),
            ),
            onPressed: () {
              setState(() {
                if (_currentIndex < widget.adItems.length - 1) {
                  _currentIndex++;
                  _currentItem = widget.adItems[_currentIndex];
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

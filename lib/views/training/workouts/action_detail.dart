// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/global/constants.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/training_state.dart';

class ActionDetailDialog extends StatefulWidget {
  final List<ActionDetail> adItems;
  final int adIndex;

  const ActionDetailDialog({
    super.key,
    required this.adItems,
    required this.adIndex,
  });

  @override
  State<ActionDetailDialog> createState() => _ActionDetailDialogState();
}

class _ActionDetailDialogState extends State<ActionDetailDialog> {
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

    return SizedBox(
      height: desiredHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // 从上到下依次为关闭按钮、图片、动作名称及其技术要点、翻页按钮
        children: [
          SizedBox(height: 40.sp, child: buildCloseButton(context)),
          Expanded(
            flex: 2,
            child: _buildExerciseImageArea(_currentItem.exercise),
          ),
          Expanded(flex: 1, child: _buildCountArea()),
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
                  style: TextStyle(
                    fontSize: CusFontSizes.pageTitle,
                    fontWeight: FontWeight.bold,
                  ),
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

  // 动作的图片
  _buildExerciseImageArea(Exercise item) {
    List<String> imageList =
        (item.images?.trim().isNotEmpty == true) ? item.images!.split(",") : [];
    return buildImageCarouselSlider(imageList);
  }

  _buildCountArea() {
    // 两行
    // return Padding(
    //   padding: EdgeInsets.only(left: 0.2.sw),
    //   child: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     crossAxisAlignment: CrossAxisAlignment.center,
    //     children: [
    //       Expanded(
    //         child: Row(
    //           children: [
    //             Expanded(
    //               child: Text(
    //                 (_currentItem.exercise.countingMode ==
    //                         countingOptions.first.value)
    //                     ? CusAL.of(context).actionDetailLabel('0')
    //                     : CusAL.of(context).actionDetailLabel('1'),
    //                 style: TextStyle(fontSize: 20.sp),
    //               ),
    //             ),
    //             Expanded(
    //               child: Text(
    //                 (_currentItem.exercise.countingMode ==
    //                         countingOptions.first.value)
    //                     ? '${_currentItem.action.duration}'
    //                     : '${_currentItem.action.frequency}',
    //                 style: TextStyle(fontSize: 20.sp),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //       if (_currentItem.action.equipmentWeight != null)
    //         Expanded(
    //           child: Row(
    //             children: [
    //               Expanded(
    //                 child: Text(
    //                   CusAL.of(context).actionDetailLabel('2'),
    //                   style: TextStyle(fontSize: 20.sp),
    //                 ),
    //               ),
    //               Expanded(
    //                 child: Text(
    //                   cusDoubleTryToIntString(
    //                       _currentItem.action.equipmentWeight!),
    //                   style: TextStyle(fontSize: 20.sp),
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //     ],
    //   ),
    // );

    // 1行
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: 10.sp),
            child: Text(
              (_currentItem.exercise.countingMode ==
                      countingOptions.first.value)
                  ? '${CusAL.of(context).actionDetailLabel('0')} ${_currentItem.action.duration}'
                  : '${CusAL.of(context).actionDetailLabel('1')} ${_currentItem.action.frequency}',
              style: TextStyle(fontSize: CusFontSizes.flagMedium),
              textAlign: TextAlign.end,
            ),
          ),
        ),
        if (_currentItem.action.equipmentWeight != null)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.sp),
              child: Text(
                '${CusAL.of(context).actionDetailLabel('2')} ${cusDoubleTryToIntString(_currentItem.action.equipmentWeight!)}',
                style: TextStyle(fontSize: CusFontSizes.flagMedium),
                textAlign: TextAlign.start,
              ),
            ),
          ),
      ],
    );
  }

// ======== ？？？这个翻页部件，action config dialog和exercise detail的弹窗也有。
// 因为有状态改变，估计要回调函数之类的，暂时不知道怎么抽出来复用
  _buildPageButton() {
    return Container(
      color: CusColors.pageChangeBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: CusIconSizes.iconBig,
              color: _currentIndex > 0
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
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
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: CusFontSizes.pageTitle,
                color: Theme.of(context).shadowColor,
                fontWeight: FontWeight.bold,
              ),
              children: <TextSpan>[
                TextSpan(
                  // 索引从0开始，显示从1开始
                  text: '${_currentIndex + 1}',
                  style: TextStyle(
                    fontSize: CusFontSizes.flagBig,
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
              size: CusIconSizes.iconBig,
              color: _currentIndex < widget.adItems.length - 1
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
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

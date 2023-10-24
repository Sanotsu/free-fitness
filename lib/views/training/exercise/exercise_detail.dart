// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/training_state.dart';

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
  String placeholderImageUrl = 'assets/images/no_image.png';

  int _currentIndex = 0;
  int _totalSize = 0;
  late Exercise _currentItem;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.exerciseIndex;
    _currentItem = widget.exerciseItems[_currentIndex];
    _totalSize = widget.exerciseItems.length;
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
        children: [
          Container(
            // 预设的图片背景色一般是白色，所以这里也设置为白色，看起来一致
            color: Colors.white,
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.blue),
                onPressed: () {
                  Navigator.of(context).pop(); // 关闭弹窗
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              // 预设的图片背景色一般是白色，所以这里也设置为白色，看起来一致
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10.sp),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Hero(
                              tag: 'imageTag',
                              child: Image.file(
                                File(_currentItem.images?.split(",")[0] ?? ""),
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  return Image.asset(
                                    placeholderImageUrl,
                                    fit: BoxFit.scaleDown,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Hero(
                      tag: 'imageTag',
                      child: Image.file(
                        File(_currentItem.images?.split(",")[0] ?? ""),
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Image.asset(
                            placeholderImageUrl,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),

                  // Image.file(
                  //   File(_currentItem.images?.split(",")[0] ?? ""),
                  //   errorBuilder: (BuildContext context, Object exception,
                  //       StackTrace? stackTrace) {
                  //     return Image.asset(
                  //       placeholderImageUrl,
                  //       fit: BoxFit.cover,
                  //     );
                  //   },
                  // ),
                ),
              ),
            ),
          ),

          /// 关闭按钮悬浮在图片上方的写法
          // Expanded(
          //   flex: 2,
          //   child: Container(
          //     // 预设的图片背景色一般是白色，所以这里也设置为白色，看起来一致
          //     // color: Colors.white,
          //     color: const Color.fromARGB(255, 239, 243, 244),
          //     child: Stack(
          //       alignment: Alignment.topLeft,
          //       children: [
          //         Center(
          //           child: Image.file(
          //             File(_currentItem.images?.split(",")[0] ?? ""),
          //             errorBuilder: (BuildContext context, Object exception,
          //                 StackTrace? stackTrace) {
          //               return Image.asset(
          //                 placeholderImageUrl,
          //                 fit: BoxFit.cover,
          //               );
          //             },
          //           ),
          //         ),
          //         Align(
          //           alignment: Alignment.topRight,
          //           child: IconButton(
          //             icon: const Icon(Icons.close),
          //             onPressed: () {
          //               Navigator.of(context).pop(); // 关闭弹窗
          //             },
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          Expanded(
            flex: 3,
            child: Container(
              // color: const Color.fromARGB(206, 241, 243, 243),
              color: const Color.fromARGB(255, 239, 243, 244),
              // color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(10.sp),
                child: Container(
                  padding: EdgeInsets.only(bottom: 20.sp), // 添加底部内边距
                  child: ListTile(
                    title: Text(
                      '$_currentIndex -${_currentItem.exerciseName}',
                      style: TextStyle(fontSize: 20.sp),
                    ),
                    subtitle: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Text(
                        _currentItem.instructions ?? "",
                        overflow: TextOverflow.clip, // 设置文字溢出时的处理方式
                      ),
                    ),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
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
                          _currentItem = widget.exerciseItems[_currentIndex];
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
                      color: _currentIndex < widget.exerciseItems.length - 1
                          ? Colors.blue
                          : const Color.fromARGB(255, 128, 222, 204),
                    ),
                    onPressed: () {
                      setState(() {
                        if (_currentIndex < widget.exerciseItems.length - 1) {
                          _currentIndex++;
                          _currentItem = widget.exerciseItems[_currentIndex];
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

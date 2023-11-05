// // ignore_for_file: avoid_print

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import '../../../common/global/constants.dart';
// import '../../../models/training_state.dart';

// class ExerciseDetailMore extends StatefulWidget {
//   final Exercise exerciseItem;

//   const ExerciseDetailMore({super.key, required this.exerciseItem});

//   @override
//   State<ExerciseDetailMore> createState() => _ExerciseDetailMoreState();
// }

// class _ExerciseDetailMoreState extends State<ExerciseDetailMore> {
//   String placeholderImageUrl = 'assets/images/no_image.png';

//   late Exercise _currentItem;

//   @override
//   void initState() {
//     super.initState();
//     _currentItem = widget.exerciseItem;

//     print("_currentItem------------$_currentItem");
//   }

//   // 根据数据库值显示对应标签
//   _genMuscleText(String? muscleStr) {
//     if (muscleStr == null) {
//       return "";
//     }
//     List<String> selectedValues = muscleStr.split(',');
//     String labelText = "";

//     for (String selectedValue in selectedValues) {
//       for (ExerciseDefaultOption option in musclesOptions) {
//         if (option.value == selectedValue) {
//           labelText += "${option.label}, ";
//           break;
//         }
//       }
//     }

//     if (labelText.isNotEmpty) {
//       // 去掉最后一个逗号和空格
//       labelText = labelText.substring(0, labelText.length - 2);
//     }

//     return labelText;
//   }

//   _genOptionLabel(List<ExerciseDefaultOption> options, String label) {
//     return options.where((e) => e.value == label).first.label;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('ExerciseDetailMore'),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 顶部图片
//             Image.file(
//               File(_currentItem.images?.split(",")[0] ?? ""),
//               errorBuilder: (BuildContext context, Object exception,
//                   StackTrace? stackTrace) {
//                 return Image.asset(
//                   placeholderImageUrl,
//                   fit: BoxFit.scaleDown,
//                 );
//               },
//             ),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16.0.sp),
//               child: ListTile(
//                 title: const Text("代号"),
//                 trailing: Text(
//                   _currentItem.exerciseCode,
//                   style:
//                       TextStyle(fontSize: 24.0.sp, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16.0.sp),
//               child: ListTile(
//                 title: const Text("名称"),
//                 trailing: Text(_currentItem.exerciseName),
//               ),
//             ),
//             ListTile(
//               title: const Text("主要肌肉"),
//               trailing: Text(
//                 _genMuscleText(_currentItem.primaryMuscles),
//                 style: TextStyle(fontSize: 16.0.sp),
//               ),
//             ),
//             ListTile(
//               title: const Text("次要肌肉"),
//               trailing: Text(
//                 _genMuscleText(_currentItem.secondaryMuscles),
//                 style: TextStyle(fontSize: 16.0.sp),
//               ),
//             ),
//             ListTile(
//               title: const Text("发力方式"),
//               trailing: Text(
//                 _currentItem.force != null
//                     ? _genOptionLabel(forceOptions, _currentItem.force!)
//                     : "",
//                 style: TextStyle(fontSize: 16.0.sp),
//               ),
//             ),
//             ListTile(
//               title: const Text("级别"),
//               trailing: Text(
//                 _currentItem.force != null
//                     ? _genOptionLabel(levelOptions, _currentItem.level!)
//                     : "",
//                 style: TextStyle(fontSize: 16.0.sp),
//               ),
//             ),
//             ListTile(
//               title: const Text("基础活动类别"),
//               trailing: Text(
//                 _currentItem.force != null
//                     ? _genOptionLabel(mechanicOptions, _currentItem.mechanic!)
//                     : "",
//                 style: TextStyle(fontSize: 16.0.sp),
//               ),
//             ),
//             ListTile(
//               title: const Text("所需器械"),
//               trailing: Text(
//                 _currentItem.force != null
//                     ? _genOptionLabel(equipmentOptions, _currentItem.equipment!)
//                     : "",
//                 style: TextStyle(fontSize: 16.0.sp),
//               ),
//             ),
//             ListTile(
//               title: const Text("分类"),
//               trailing: Text(
//                 _currentItem.force != null
//                     ? _genOptionLabel(categoryOptions, _currentItem.category)
//                     : "",
//                 style: TextStyle(fontSize: 16.0.sp),
//               ),
//             ),
//             ListTile(
//               title: const Text("是否用户上传"),
//               trailing: Text(
//                 "${_currentItem.isCustom}",
//                 style: TextStyle(fontSize: 16.0.sp),
//               ),
//             ),
//             Text(
//               "${_currentItem.instructions}",
//               style: TextStyle(fontSize: 16.0.sp),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../models/training_state.dart';

class ExerciseDetailMore extends StatefulWidget {
  final Exercise exerciseItem;

  const ExerciseDetailMore({super.key, required this.exerciseItem});

  @override
  State<ExerciseDetailMore> createState() => _ExerciseDetailMoreState();
}

class _ExerciseDetailMoreState extends State<ExerciseDetailMore> {
  String placeholderImageUrl = 'assets/images/no_image.png';

  late Exercise _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.exerciseItem;
  }

  // 根据数据库值从预设选项中显示对应标签
  _getOptionLabel(String? value, List<ExerciseDefaultOption> options) {
    if (value == null) {
      return "";
    }
    for (ExerciseDefaultOption option in options) {
      if (option.value == value) {
        return option.label;
      }
    }
    return "";
  }

  // 肌肉这个有多项，所以从预设选项中显示对应标签略有不同
  _genMuscleOptionLabel(String? muscleStr) {
    if (muscleStr == null) {
      return "";
    }
    List<String> selectedValues = muscleStr.split(',');
    List<String> selectedLabels = [];

    for (String selectedValue in selectedValues) {
      String selectedLabel = _getOptionLabel(selectedValue, musclesOptions);
      if (selectedLabel.isNotEmpty) {
        selectedLabels.add(selectedLabel);
      }
    }

    return selectedLabels.join(", ");
  }

  _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.0.sp),
          child: Text(label),
        ),
        Padding(
          padding: EdgeInsets.only(right: 16.0.sp),
          child: Text(
            value,
            style: TextStyle(fontSize: 16.0.sp),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExerciseDetailMore'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部图片
            Image.file(
              File(_currentItem.images?.split(",")[0] ?? ""),
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return Image.asset(
                  placeholderImageUrl,
                  fit: BoxFit.scaleDown,
                );
              },
            ),
            SizedBox(
              height: 16.0.sp,
            ),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: [
                _buildTableRow(
                  "代号",
                  _currentItem.exerciseCode,
                ),
                _buildTableRow(
                  "名称",
                  _currentItem.exerciseName,
                ),
                _buildTableRow(
                  "发力方式",
                  _getOptionLabel(_currentItem.force, forceOptions),
                ),
                _buildTableRow(
                  "级别",
                  _getOptionLabel(_currentItem.level, levelOptions),
                ),
                _buildTableRow(
                  "基础活动类别",
                  _getOptionLabel(_currentItem.mechanic, mechanicOptions),
                ),
                _buildTableRow(
                  "所需器械",
                  _getOptionLabel(_currentItem.equipment, equipmentOptions),
                ),
                _buildTableRow(
                  "分类",
                  _getOptionLabel(_currentItem.category, categoryOptions),
                ),
                _buildTableRow(
                  "主要肌肉",
                  _genMuscleOptionLabel(_currentItem.primaryMuscles),
                ),
                _buildTableRow(
                  "次要肌肉",
                  _genMuscleOptionLabel(_currentItem.secondaryMuscles),
                ),
                _buildTableRow(
                  "是否用户上传",
                  "${_currentItem.isCustom}",
                ),
              ],
            ),
            SizedBox(
              height: 16.0.sp,
            ),
            Padding(
              padding: EdgeInsets.all(16.0.sp),
              child: Text(
                "基础活动要点",
                style: TextStyle(fontSize: 24.0.sp),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.sp),
              child: Text(
                "${_currentItem.instructions}",
                style: TextStyle(fontSize: 16.0.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

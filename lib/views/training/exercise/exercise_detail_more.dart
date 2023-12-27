// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/global/constants.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/training_state.dart';

class ExerciseDetailMore extends StatefulWidget {
  final Exercise exerciseItem;

  const ExerciseDetailMore({super.key, required this.exerciseItem});

  @override
  State<ExerciseDetailMore> createState() => _ExerciseDetailMoreState();
}

class _ExerciseDetailMoreState extends State<ExerciseDetailMore> {
  // 当前基础活动详情数据
  late Exercise _item;

  @override
  void initState() {
    super.initState();
    _item = widget.exerciseItem;
  }

  // 根据数据库值从预设选项中显示对应标签
  _getLabel(String? value, List<CusLabel> options) {
    // 没有传值，返回空字符串
    if (value == null) return "";

    var curLang = box.read('language');
    for (CusLabel option in options) {
      if (option.value == value) {
        return curLang == 'en' ? option.enLabel : option.cnLabel;
      }
    }
    // 有传值但对应的列表中找不到，也返回空字符串
    return "";
  }

  // 肌肉这个有多项，所以从预设选项中显示对应标签略有不同
  _genMuscleOptionLabel(String? muscleStr) {
    if (muscleStr == null || muscleStr.trim().isEmpty) {
      return "";
    }
    List<String> selectedValues = muscleStr.split(',');
    List<String> selectedLabels = [];

    for (String selectedValue in selectedValues) {
      String selectedLabel = _getLabel(selectedValue, musclesOptions);
      if (selectedLabel.isNotEmpty) {
        selectedLabels.add(selectedLabel);
      }
    }

    return selectedLabels.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CusAL.of(context).exerciseDetail),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部图片(滚动显示)
            Padding(
              padding: EdgeInsets.all(10.sp),
              child: SizedBox(
                height: 0.3.sh,
                child: buildExerciseImageCarouselSlider(_item),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0.sp),
              child: Text(
                CusAL.of(context).moreDetail,
                style: TextStyle(fontSize: CusFontSizes.itemTitle),
              ),
            ),

            ...buildTableData(),
          ],
        ),
      ),
    );
  }

  buildTableData() {
    return [
      Padding(
        padding: EdgeInsets.all(10.sp),
        child: Table(
          // 设置表格边框
          border: TableBorder.all(color: Theme.of(context).primaryColor),
          // 设置每列的宽度占比
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildTableRow(
              CusAL.of(context).exerciseQuerys('1'),
              _item.exerciseCode,
            ),
            _buildTableRow(
              CusAL.of(context).exerciseQuerys('2'),
              _item.exerciseName,
            ),
            _buildTableRow(
              CusAL.of(context).exerciseQuerys('3'),
              _getLabel(_item.level, levelOptions),
            ),
            _buildTableRow(
              CusAL.of(context).exerciseQuerys('4'),
              _getLabel(_item.mechanic, mechanicOptions),
            ),
            _buildTableRow(
              CusAL.of(context).exerciseQuerys('5'),
              _getLabel(_item.category, categoryOptions),
            ),
            _buildTableRow(
              CusAL.of(context).exerciseQuerys('6'),
              _getLabel(_item.equipment, equipmentOptions),
            ),
            _buildTableRow(
              CusAL.of(context).exerciseQuerys('7'),
              _getLabel(_item.countingMode, countingOptions),
            ),
            _buildTableRow(
              CusAL.of(context).exerciseLabels('0'),
              _getLabel(_item.force, forceOptions),
            ),
            _buildTableRow(
              CusAL.of(context).exerciseLabels('1'),
              _getLabel(
                _item.standardDuration.toString(),
                standardDurationOptions,
              ),
            ),
            _buildTableRow(
              CusAL.of(context).exerciseLabels('2'),
              _genMuscleOptionLabel(_item.primaryMuscles),
            ),
            _buildTableRow(
              CusAL.of(context).exerciseLabels('3'),
              _genMuscleOptionLabel(_item.secondaryMuscles),
            ),
            _buildTableRow(
              CusAL.of(context).exerciseLabels('4'),
              _item.instructions ?? "",
            ),
            _buildTableRow(
              CusAL.of(context).exerciseLabels('5'),
              _item.ttsNotes ?? "",
            ),
            _buildTableRow(
              CusAL.of(context).exerciseLabels('7'),
              (_item.isCustom != null && _item.isCustom == true)
                  ? CusAL.of(context).boolLabels('0')
                  : CusAL.of(context).boolLabels('1'),
            ),
          ],
        ),
      ),
    ];
  }

  // 构建表格行数据
  _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            label,
            style: TextStyle(
              fontSize: CusFontSizes.pageContent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            value,
            style: TextStyle(
              fontSize: CusFontSizes.pageSubContent,
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

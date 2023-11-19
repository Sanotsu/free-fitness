// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/tool_widgets.dart';
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

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    _item = widget.exerciseItem;
  }

  // 根据数据库值从预设选项中显示对应标签
  _getCnLabel(String? value, List<CusLabel> options) {
    if (value == null) {
      return "";
    }
    for (CusLabel option in options) {
      if (option.value == value) {
        return option.cnLabel;
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
      String selectedLabel = _getCnLabel(selectedValue, musclesOptions);
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
        title: const Text('动作详情'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部图片(有多张也显示第一张)
            Padding(
              padding: EdgeInsets.all(10.sp),
              child: SizedBox(
                height: 0.3.sh,
                child: Image.file(
                  File(_item.images?.split(",")[0] ?? ""),
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace? stackTrace) {
                    return Image.asset(placeholderImageUrl,
                        fit: BoxFit.scaleDown);
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0.sp),
              child: Text(
                "更多详情",
                style: TextStyle(fontSize: 16.0.sp),
              ),
            ),

            // const Text('Table 样式'),
            ...buildTableData(),

            // const Text('ListTile 样式'),
            // ...buildListTileData(),
            // const Text('Form 样式'),
            // buildFormData(),
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
          border: TableBorder.all(), // 设置表格边框
          // 设置每列的宽度占比
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(3),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildTableRow("代号", _item.exerciseCode),
            _buildTableRow("名称", _item.exerciseName),
            _buildTableRow("发力", _getCnLabel(_item.force, forceOptions)),
            _buildTableRow(
                "计数", _getCnLabel(_item.countingMode, countingOptions)),
            _buildTableRow("级别", _getCnLabel(_item.level, levelOptions)),
            _buildTableRow("类别", _getCnLabel(_item.mechanic, mechanicOptions)),
            _buildTableRow(
                "器械", _getCnLabel(_item.equipment, equipmentOptions)),
            _buildTableRow("分类", _getCnLabel(_item.category, categoryOptions)),
            _buildTableRow("主要肌肉", _genMuscleOptionLabel(_item.primaryMuscles)),
            _buildTableRow(
                "次要肌肉", _genMuscleOptionLabel(_item.secondaryMuscles)),
            _buildTableRow(
              "用户上传",
              (_item.isCustom != null && _item.isCustom == 'true') ? '是' : '否',
            ),
            _buildTableRow("技术要点", _item.instructions ?? ""),
            _buildTableRow("语言提示", _item.ttsNotes ?? ""),
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
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            value,
            style: TextStyle(fontSize: 14.0.sp, color: Colors.grey),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  buildListTileData() {
    return [
      _buildListTile("代号", _item.exerciseCode),
      _buildListTile("名称", _item.exerciseName),
      _buildListTile("发力", _getCnLabel(_item.force, forceOptions)),
      _buildListTile("计数", _getCnLabel(_item.countingMode, countingOptions)),
      _buildListTile("级别", _getCnLabel(_item.level, levelOptions)),
      _buildListTile("类别", _getCnLabel(_item.mechanic, mechanicOptions)),
      _buildListTile("器械", _getCnLabel(_item.equipment, equipmentOptions)),
      _buildListTile("分类", _getCnLabel(_item.category, categoryOptions)),
      _buildListTile("主要肌肉", _genMuscleOptionLabel(_item.primaryMuscles)),
      _buildListTile("次要肌肉", _genMuscleOptionLabel(_item.secondaryMuscles)),
      _buildListTile(
        "用户上传",
        (_item.isCustom != null && _item.isCustom == 'true') ? '是' : '否',
      ),
      _buildListTile("技术要点", _item.instructions ?? ""),
      _buildListTile("语言提示", _item.ttsNotes ?? ""),
    ];
  }

  _buildListTile(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Padding(
        padding: EdgeInsets.only(left: 30.sp),
        child: Text(subtitle),
      ),
    );
  }

  buildFormData() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          /// 代号和名称

          cusFormBuilerTextField(
            "exercise_name",
            labelText: '*名称',
            initialValue: _item.exerciseName,
            isReadOnly: true,
          ),
          cusFormBuilerTextField(
            "exercise_code",
            labelText: '*代号',
            initialValue: _item.exerciseCode,
            isReadOnly: true,
          ),

          /// 级别和类别（单选）
          cusFormBuilerTextField(
            "level",
            labelText: '*级别',
            initialValue: _getCnLabel(_item.level, levelOptions),
            isReadOnly: true,
          ),
          cusFormBuilerTextField(
            "counting_mode",
            labelText: '*计数',
            initialValue: _getCnLabel(_item.countingMode, countingOptions),
            isReadOnly: true,
          ),

          cusFormBuilerTextField(
            "force",
            labelText: '*发力',
            initialValue: _getCnLabel(_item.force, forceOptions),
            isReadOnly: true,
          ),

          cusFormBuilerTextField(
            "category",
            labelText: '*分类',
            initialValue: _getCnLabel(_item.category, categoryOptions),
            isReadOnly: true,
          ),
          cusFormBuilerTextField(
            "mechanic",
            labelText: '*类别',
            initialValue: _getCnLabel(_item.mechanic, mechanicOptions),
            isReadOnly: true,
          ),

          cusFormBuilerTextField(
            "equipment",
            labelText: '器械',
            initialValue: _getCnLabel(_item.equipment, equipmentOptions),
            isReadOnly: true,
          ),
          cusFormBuilerTextField(
            "standard_duration",
            labelText: '标准动作耗时',
            initialValue:
                _getCnLabel(_item.standardDuration, standardDurationOptions),
            isReadOnly: true,
          ),

          const SizedBox(height: 10),
          //  要点(简介这个动作步骤)
          cusFormBuilerTextField(
            "instructions",
            labelText: '*技术要点',
            initialValue: _item.instructions,
            maxLines: 5,
            isReadOnly: true,
          ),

          const SizedBox(height: 10),
          // 语音提醒文本
          cusFormBuilerTextField(
            "tts_notes",
            labelText: '语音提示要点',
            initialValue: _item.ttsNotes ?? "",
            maxLines: 5,
            isReadOnly: true,
          ),
        ],
      ),
    );
  }
}

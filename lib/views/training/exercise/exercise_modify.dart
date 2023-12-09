// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:sqflite/sqflite.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../models/training_state.dart';

/// 基础活动变更表单（希望新增、修改可通用）
class ExerciseModify extends StatefulWidget {
  final Exercise? item;

  const ExerciseModify({Key? key, this.item}) : super(key: key);

  @override
  State<ExerciseModify> createState() => _ExerciseModifyState();
}

class _ExerciseModifyState extends State<ExerciseModify> {
  final DBTrainingHelper _dbHelper = DBTrainingHelper();

  // 这个表单用到了3个库，flutter_form_builder、form_builder_file_picker、multi_select_flutter
  // multi_select_flutter不和前者通用，所以其下拉选择框单独使用key来获取值和验证状态等
  final _formKey = GlobalKey<FormBuilderState>();
  final _multiPrimarySelectKey = GlobalKey<FormFieldState>();
  final _multiSecondarySelectKey = GlobalKey<FormFieldState>();

  // 把预设的基础活动选项列表转化为 MultiSelectDialogField 支持的列表
  final _muscleItems = musclesOptions
      .map<MultiSelectItem<CusLabel>>(
          (opt) => MultiSelectItem<CusLabel>(opt, opt.cnLabel))
      .toList();

  // 被选中的主要、次要肌肉
  var selectedPrimaryMuscles = [];
  var selectedSecondaryMuscles = [];

  // 如果有传入item，则表示要修改数据
  Exercise? updateTarget;
  // 数据库存入的是图片地址拼接的字符串，要转回平台文件列表
  List<PlatformFile>? exerciseImages;

  @override
  void initState() {
    super.initState();

    setState(() {
      print("修改表单的item ${widget.item}");

      if (widget.item != null) {
        updateTarget = widget.item;
        // 有图片地址，显示图片
        if (updateTarget?.images != null && updateTarget?.images != "") {
          exerciseImages = convertStringToPlatformFiles(updateTarget!.images!);
        }
        // 有主要肌肉，显示主要肌肉
        if (updateTarget?.primaryMuscles != null &&
            updateTarget?.primaryMuscles != "") {
          selectedPrimaryMuscles =
              _genSelectedMuscleOptions(updateTarget?.primaryMuscles);
        }
        // 有次要肌肉，显示次要肌肉
        if (updateTarget?.secondaryMuscles != null &&
            updateTarget?.secondaryMuscles != "") {
          selectedSecondaryMuscles =
              _genSelectedMuscleOptions(updateTarget?.secondaryMuscles);
        }
      }
    });
  }

  // 根据数据库拼接的字符串值转回对应选项
  List<CusLabel> _genSelectedMuscleOptions(String? muscleStr) {
    if (muscleStr == null) {
      return [];
    }

    print("muscleStr-------------$muscleStr");
    List<String> selectedValues = muscleStr.split(',');

    List<CusLabel> selectedLabels = [];

    for (String selectedValue in selectedValues) {
      for (CusLabel option in musclesOptions) {
        if (option.value == selectedValue) {
          selectedLabels.add(option);
        }
      }
    }

    print("selectedLabels-------------$selectedLabels");

    return selectedLabels;
  }

  _saveNewExercise() async {
    var flag1 = _multiPrimarySelectKey.currentState?.validate();
    var flag2 = _multiSecondarySelectKey.currentState?.validate();
    var flag3 = _formKey.currentState!.saveAndValidate();

    // 如果表单验证都通过了，保存数据到数据库，并返回上一页
    if (flag1! && flag2! && flag3) {
      var temp = _formKey.currentState;
      // ？？？2023-10-15 这里取值是不是刻意直接使用temp而不是按照每个栏位名称呢
      Exercise exercise = Exercise(
        exerciseCode: temp?.fields['exercise_code']?.value,
        exerciseName: temp?.fields['exercise_name']?.value,
        force: temp?.fields['force']?.value,
        level: temp?.fields['level']?.value,
        mechanic: temp?.fields['mechanic']?.value,
        equipment: temp?.fields['equipment']?.value,
        countingMode: temp?.fields['counting_mode']?.value,
        standardDuration:
            int.tryParse(temp?.fields['standard_duration']?.value) ?? 1,
        instructions: temp?.fields['instructions']?.value,
        ttsNotes: temp?.fields['tts_notes']?.value,
        category: temp?.fields['category']?.value,
        primaryMuscles: selectedPrimaryMuscles.isNotEmpty
            ? selectedPrimaryMuscles.map((opt) => opt.value).toList().join(',')
            : null,
        secondaryMuscles: selectedSecondaryMuscles.isNotEmpty
            ? (selectedSecondaryMuscles)
                .map((opt) => opt.value)
                .toList()
                .join(',')
            : null,
        images: (temp?.fields['images']?.value != null) &&
                temp?.fields['images']?.value != ""
            ? (temp?.fields['images']?.value as List<PlatformFile>)
                .map((e) => e.path)
                .toList()
                .join(",")
            : null,

        ///
        isCustom: true,
        contributor: CacheUser.userName,
        // 时间都存时间戳，显示的时候再格式化
        gmtCreate: getCurrentDateTime(),
      );

      // 修改和新增有一小部分栏位不同
      if (updateTarget != null) {
        // 如果是修改
        exercise.gmtModified = DateTime.now().millisecondsSinceEpoch.toString();
        exercise.exerciseId = updateTarget?.exerciseId;
      } else {
        // 如果是新增
        exercise.gmtCreate = DateTime.now().millisecondsSinceEpoch.toString();
      }

      print(
          "==========进入修改1111exercise了 $selectedPrimaryMuscles $selectedSecondaryMuscles $exercise");
      try {
        if (updateTarget != null) {
          print("==========进入修改exercise了");
          await _dbHelper.updateExercise(exercise);
        } else {
          await _dbHelper.insertExercise(exercise);
        }
        if (mounted) {
          var snackBar = SnackBar(
            content: Text(updateTarget != null ? '修改成功 ' : '新增成功'),
            duration: const Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Navigator.pop(context, 'exerciseModified');
        }
      } catch (e) {
        // 或者显示一个SnackBar
        var errorMessage = "数据插入数据库失败";
        if (e is DatabaseException) {
          // 这里可以直接去sqlite的结果代码 e.getResultCode()，
          // 具体代码含义参看文档： https://www.sqlite.org/rescode.html

          /// 它默认有判断是否是哪种错误，常见的唯一值重复还可以指定检查哪个栏位重复。
          var prefix = "ff_exercise.";
          if (e.isUniqueConstraintError("${prefix}exercise_code")) {
            errorMessage = '【基础活动代号】已存在。';
          } else if (e.isUniqueConstraintError("${prefix}exercise_name")) {
            errorMessage = '【基础活动名称】已存在。';
          }
        }

        // 在底部显示错误信息
        var snackBar = SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 只能接收一个子组件滚动组件
    return Scaffold(
      appBar: AppBar(
        title: Text("${updateTarget != null ? '修改' : '新增'}基础活动"),
        elevation: 0,
        actions: [
          MaterialButton(
            color: Theme.of(context).colorScheme.secondary,
            onPressed: _saveNewExercise,
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Card(
        elevation: 10.sp,
        child: Padding(
          padding: EdgeInsets.all(10.sp),
          child: SingleChildScrollView(
            // 创建表单
            child: FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  /// 代号和名称
                  ///

                  cusFormBuilerTextField(
                    "exercise_name",
                    labelText: '*名称',
                    initialValue: updateTarget?.exerciseName,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: '名称不可为空'),
                    ]),
                  ),
                  cusFormBuilerTextField(
                    "exercise_code",
                    labelText: '*代号',
                    initialValue: updateTarget?.exerciseCode,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: '代号不可为空'),
                    ]),
                  ),

                  /// 级别和类别（单选）
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "level",
                          levelOptions,
                          labelText: '*级别',
                          initialValue: updateTarget?.level,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: '级别不可为空')
                          ]),
                        ),
                      ),
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "counting_mode",
                          countingOptions,
                          labelText: '*计数',
                          initialValue: updateTarget?.countingMode,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: '计数不可为空')
                          ]),
                        ),
                      ),
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "force",
                          forceOptions,
                          labelText: '*发力',
                          initialValue: updateTarget?.force,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: '发力不可为空')
                          ]),
                        ),
                      ),
                    ],
                  ),
                  // 分类和类别
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "category",
                          categoryOptions,
                          labelText: '*分类',
                          initialValue: updateTarget?.category,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: '分类不可为空')
                          ]),
                        ),
                      ),
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "mechanic",
                          mechanicOptions,
                          labelText: '*类别',
                          initialValue: updateTarget?.mechanic,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: '类别不可为空')
                          ]),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "equipment",
                          equipmentOptions,
                          labelText: '器械',
                          initialValue: updateTarget?.equipment,
                        ),
                      ),
                      Flexible(
                        child: cusFormBuilerDropdown(
                          "standard_duration",
                          standardDurationOptions,
                          labelText: '标准动作耗时',
                          initialValue: updateTarget?.standardDuration,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.sp),
                  // 主要肌肉(多选)
                  _buildModifyMultiSelectDialogField(
                    key: _multiPrimarySelectKey,
                    items: _muscleItems,
                    initialValue: selectedPrimaryMuscles,
                    labelText: "*主要肌肉",
                    hintText: "选择主要肌肉",
                    validator: (values) {
                      if (values == null || values.isEmpty) {
                        return "至少选择一个锻炼的主要肌肉";
                      }
                      return null;
                    },
                    onConfirm: (results) {
                      selectedPrimaryMuscles = results;
                    },
                  ),

                  // 次要肌肉(多选)
                  SizedBox(height: 10.sp),
                  _buildModifyMultiSelectDialogField(
                    key: _multiSecondarySelectKey,
                    items: _muscleItems,
                    initialValue: selectedSecondaryMuscles,
                    labelText: "次要肌肉",
                    hintText: "选择次要肌肉",
                    onConfirm: (results) {
                      selectedSecondaryMuscles = results;
                    },
                  ),

                  const SizedBox(height: 10),
                  //  要点(简介这个动作步骤)
                  cusFormBuilerTextField(
                    "instructions",
                    labelText: '*技术要点',
                    initialValue: updateTarget?.instructions,
                    maxLines: 5,
                    isOutline: true,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: '技术要点不可为空'),
                    ]),
                  ),

                  const SizedBox(height: 10),
                  // 语音提醒文本
                  cusFormBuilerTextField(
                    "tts_notes",
                    labelText: '语音提示要点',
                    initialValue: updateTarget?.ttsNotes,
                    maxLines: 5,
                    isOutline: true,
                  ),

                  const SizedBox(height: 10),
                  // 上传活动示例图片（静态图或者gif）
                  _buildFilePicker(
                    'images',
                    initialValue: exerciseImages,
                    labelText: "演示图片",
                    hintText: "图片上传",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _buildFilePicker(
    String name, {
    List<PlatformFile>? initialValue,
    String? labelText,
    String? hintText, // 可不传提示语
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.sp),
      child: FormBuilderFilePicker(
        name: name,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(fontSize: 16.sp),
        ),
        initialValue: initialValue,
        maxFiles: null,
        allowMultiple: true,
        previewImages: true,
        onChanged: (val) => debugPrint(val.toString()),
        typeSelectors: [
          TypeSelector(
            type: FileType.image,
            selector: Row(
              children: <Widget>[
                const Icon(Icons.file_upload),
                Text(
                  hintText ?? '',
                  style: TextStyle(fontSize: 16.sp),
                ),
              ],
            ),
          )
        ],
        customTypeViewerBuilder: (children) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: children,
        ),
        onFileLoading: (val) {
          debugPrint(val.toString());
        },
      ),
    );
  }

  // 构建下拉多选弹窗模块栏位(主要为了样式统一)
  _buildModifyMultiSelectDialogField({
    required List<MultiSelectItem<dynamic>> items,
    GlobalKey<FormFieldState<dynamic>>? key,
    List<dynamic> initialValue = const [],
    String? labelText,
    String? hintText,
    String? Function(List<dynamic>?)? validator,
    required void Function(List<dynamic>) onConfirm,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.sp),
      child: MultiSelectDialogField(
        key: key,
        items: items,
        // ？？？？ 好像是不带validator用了这个初始值就会报错
        initialValue: initialValue,
        title: Text(hintText ?? ''),
        selectedColor: Colors.blue,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        buttonIcon: const Icon(Icons.fitness_center, color: Colors.blue),
        buttonText: Text(
          labelText ?? "",
          style: TextStyle(color: Colors.blue[800], fontSize: 16),
        ),
        searchable: true,
        validator: validator,
        onConfirm: onConfirm,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/training_state.dart';

/// 基础活动变更表单（希望新增、修改可通用）
class ExerciseModify extends StatefulWidget {
  final Exercise? item;

  const ExerciseModify({super.key, this.item});

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
    // 如果为空或者空字符串，返回空列表
    if (muscleStr == null || muscleStr.isEmpty || muscleStr.trim().isEmpty) {
      return [];
    }

    List<String> selectedValues = muscleStr.split(',');
    List<CusLabel> selectedLabels = [];

    for (String selectedValue in selectedValues) {
      for (CusLabel option in musclesOptions) {
        if (option.value == selectedValue) {
          selectedLabels.add(option);
        }
      }
    }

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

      try {
        // 有旧基础活动信息就是修改；没有就是新增
        if (updateTarget != null) {
          await _dbHelper.updateExercise(exercise);
        } else {
          await _dbHelper.insertExercise(exercise);
        }
        if (mounted) {
          // 2023-12-21 不报错就当作修改成功，直接返回
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (!mounted) return;
        // 2023-12-21 插入失败上面弹窗显示
        commonExceptionDialog(
          context,
          CusAL.of(context).exceptionWarningTitle,
          e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 只能接收一个子组件滚动组件
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${updateTarget != null ? CusAL.of(context).eidtLabel('') : CusAL.of(context).addLabel('')}${CusAL.of(context).exerciseLabel}",
          style: TextStyle(fontSize: CusFontSizes.pageTitle),
        ),
        elevation: 0,
        actions: [
          IconButton(onPressed: _saveNewExercise, icon: const Icon(Icons.save))
          // TextButton(
          //   onPressed: _saveNewExercise,
          //   child: Text(
          //     CusAL.of(context).saveLabel,
          //     style: TextStyle(
          //       color: Theme.of(context).primaryColor,
          //     ),
          //   ),
          // )
        ],
      ),
      body: Card(
        elevation: 10.sp,
        child: Padding(
          padding: EdgeInsets.all(10.sp),
          child: SingleChildScrollView(
            // 创建表单
            child: _buildFormBuilder(),
          ),
        ),
      ),
    );
  }

  _buildFormBuilder() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          /// 代号和名称
          cusFormBuilerTextField(
            "exercise_name",
            labelText: '*${CusAL.of(context).exerciseQuerys('2')}',
            initialValue: updateTarget?.exerciseName,
            validator: FormBuilderValidators.required(),
          ),
          cusFormBuilerTextField(
            "exercise_code",
            labelText: '*${CusAL.of(context).exerciseQuerys('1')}',
            initialValue: updateTarget?.exerciseCode,
            validator: FormBuilderValidators.required(),
          ),

          /// 级别和类别（单选）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(
                child: cusFormBuilerDropdown(
                  "level",
                  levelOptions,
                  labelText: '*${CusAL.of(context).exerciseQuerys('3')}',
                  initialValue: updateTarget?.level,
                  validator: FormBuilderValidators.required(),
                ),
              ),
              Flexible(
                child: cusFormBuilerDropdown(
                  "counting_mode",
                  countingOptions,
                  labelText: '*${CusAL.of(context).exerciseQuerys('7')}',
                  initialValue: updateTarget?.countingMode,
                  validator: FormBuilderValidators.required(),
                ),
              ),
              Flexible(
                child: cusFormBuilerDropdown(
                  "force",
                  forceOptions,
                  labelText: '*${CusAL.of(context).exerciseLabels('0')}',
                  initialValue: updateTarget?.force,
                  validator: FormBuilderValidators.required(),
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
                  labelText: '*${CusAL.of(context).exerciseQuerys('5')}',
                  initialValue: updateTarget?.category,
                  validator: FormBuilderValidators.required(),
                ),
              ),
              Flexible(
                child: cusFormBuilerDropdown(
                  "mechanic",
                  mechanicOptions,
                  labelText: '*${CusAL.of(context).exerciseQuerys('4')}',
                  initialValue: updateTarget?.mechanic,
                  validator: FormBuilderValidators.required(),
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
                  labelText: CusAL.of(context).exerciseQuerys('6'),
                  initialValue: updateTarget?.equipment,
                ),
              ),
              Flexible(
                child: cusFormBuilerDropdown(
                  "standard_duration",
                  standardDurationOptions,
                  labelText: CusAL.of(context).exerciseLabels('1'),
                  initialValue: updateTarget?.standardDuration.toString(),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.sp),
          // 主要肌肉(多选)
          _buildModifyMultiSelectDialogField(
            key: _multiPrimarySelectKey,
            items: musclesOptions,
            initialValue: selectedPrimaryMuscles,
            labelText: "*${CusAL.of(context).exerciseLabels('2')}",
            validator: FormBuilderValidators.required(),
            onConfirm: (results) {
              selectedPrimaryMuscles = results;
              // 从肌肉多选框弹窗回来不聚焦
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),

          // 次要肌肉(多选)
          SizedBox(height: 10.sp),
          _buildModifyMultiSelectDialogField(
            key: _multiSecondarySelectKey,
            items: musclesOptions,
            initialValue: selectedSecondaryMuscles,
            labelText: CusAL.of(context).exerciseLabels('3'),
            onConfirm: (results) {
              selectedSecondaryMuscles = results;
              // 从肌肉多选框弹窗回来不聚焦
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),

          const SizedBox(height: 10),
          //  要点(简介这个动作步骤)
          cusFormBuilerTextField(
            "instructions",
            labelText: '*${CusAL.of(context).exerciseLabels('4')}',
            initialValue: updateTarget?.instructions,
            maxLines: 5,
            isOutline: true,
            validator: FormBuilderValidators.required(),
          ),

          const SizedBox(height: 10),
          // 语音提醒文本
          // 2023-12-30 这个栏位目前无实际意义
          // cusFormBuilerTextField(
          //   "tts_notes",
          //   labelText: CusAL.of(context).exerciseLabels('5'),
          //   initialValue: updateTarget?.ttsNotes,
          //   maxLines: 5,
          //   isOutline: true,
          // ),

          const SizedBox(height: 10),
          // 上传活动示例图片（静态图或者gif）
          _buildFilePicker(
            'images',
            initialValue: exerciseImages,
            labelText: CusAL.of(context).exerciseLabels('6'),
            hintText: CusAL.of(context).imageUploadLabel,
          ),
        ],
      ),
    );
  }

  // 图片文件选择器
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
          labelStyle: TextStyle(fontSize: CusFontSizes.flagSmall),
          // 设置透明底色
          filled: true,
          fillColor: Colors.transparent,
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
                  style: TextStyle(fontSize: CusFontSizes.flagSmall),
                ),
              ],
            ),
          )
        ],
        customTypeViewerBuilder: (children) =>
            Row(mainAxisAlignment: MainAxisAlignment.end, children: children),
        onFileLoading: (val) {
          debugPrint(val.toString());
        },
      ),
    );
  }

  // 构建下拉多选弹窗模块栏位(主要为了样式统一)
  _buildModifyMultiSelectDialogField({
    required List<CusLabel> items,
    GlobalKey<FormFieldState<dynamic>>? key,
    List<dynamic> initialValue = const [],
    String? labelText,
    String? hintText,
    String? Function(List<dynamic>?)? validator,
    required void Function(List<dynamic>) onConfirm,
  }) {
    // 把预设的基础活动选项列表转化为 MultiSelectDialogField 支持的列表
    final muscleItems = musclesOptions
        .map<MultiSelectItem<CusLabel>>(
            (opt) => MultiSelectItem<CusLabel>(opt, showCusLable(opt)))
        .toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.sp),
      child: MultiSelectDialogField(
        key: key,
        items: muscleItems,
        // ？？？？ 好像是不带validator用了这个初始值就会报错
        initialValue: initialValue,
        title: Text(hintText ?? ''),
        // selectedColor: Colors.blue,
        decoration: BoxDecoration(
          // color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.all(Radius.circular(5.sp)),
          border: Border.all(
            width: 2.sp,
            color: Theme.of(context).disabledColor,
          ),
        ),
        // buttonIcon: const Icon(Icons.fitness_center, color: Colors.blue),
        buttonIcon: const Icon(Icons.fitness_center),
        buttonText: Text(
          labelText ?? "",
          style: TextStyle(
            // color: Colors.blue[800],
            fontSize: CusFontSizes.pageContent,
          ),
        ),
        // searchable: true,
        validator: validator,
        onConfirm: onConfirm,
        cancelText: Text(CusAL.of(context).cancelLabel),
        confirmText: Text(CusAL.of(context).confirmLabel),
      ),
    );
  }
}

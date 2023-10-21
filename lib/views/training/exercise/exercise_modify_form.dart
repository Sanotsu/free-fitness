import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:sqflite/sqflite.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/sqlite_db_helper.dart';
import '../../../models/training_state.dart';

/// 基础活动变更表单（希望新增、修改可通用）
class ExerciseModifyForm extends StatefulWidget {
  const ExerciseModifyForm({Key? key}) : super(key: key);

  @override
  State<ExerciseModifyForm> createState() => _ExerciseModifyFormState();
}

class _ExerciseModifyFormState extends State<ExerciseModifyForm> {
  final DBTrainHelper _dbHelper = DBTrainHelper();

  // 这个表单用到了3个库，flutter_form_builder、form_builder_file_picker、multi_select_flutter
  // multi_select_flutter不和前者通用，所以其下拉选择框单独使用key来获取值和验证状态等
  final _formKey = GlobalKey<FormBuilderState>();
  final _multiPrimarySelectKey = GlobalKey<FormFieldState>();
  final _multiSecondarySelectKey = GlobalKey<FormFieldState>();

  // 把预设的基础活动选项列表转化为 MultiSelectDialogField 支持的列表
  final _muscleItems = musclesOptions
      .map<MultiSelectItem<ExerciseDefaultOption>>(
          (opt) => MultiSelectItem<ExerciseDefaultOption>(opt, opt.label))
      .toList();

  // 被选中的主要、次要肌肉
  var selectedPrimaryMuscles = [];
  var selectedSecondaryMuscles = [];

  // 把预设的基础活动选项列表转化为 FormBuilderDropdown 支持的列表
  _genItems(List<ExerciseDefaultOption> options) {
    return options
        .map((option) => DropdownMenuItem(
              alignment: AlignmentDirectional.centerStart,
              value: option.value,
              child: Text(option.label),
            ))
        .toList();
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
        standardDuration: temp?.fields['standard_duration']?.value,
        instructions: temp?.fields['instructions']?.value,
        ttsNotes: temp?.fields['tts_notes']?.value,
        category: temp?.fields['category']?.value,
        primaryMuscles: selectedPrimaryMuscles.isNotEmpty
            ? selectedPrimaryMuscles.map((opt) => opt.value).toList().join(',')
            : '',
        secondaryMuscles: selectedSecondaryMuscles.isNotEmpty
            ? (selectedSecondaryMuscles as List<ExerciseDefaultOption>)
                .map((opt) => opt.value)
                .toList()
                .join(',')
            : '',
        images: (temp?.fields['images']?.value as List<PlatformFile>)
            .map((e) => e.path)
            .toList()
            .join(","),

        ///
        isCustom: 'true',
        contributor: "程序去获取设备登入者",
        // 时间都存时间戳，显示的时候再格式化
        gmtCreate: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      try {
        await _dbHelper.insertExercise(exercise);

        if (mounted) {
          var snackBar = const SnackBar(
            content: Text("新增成功"),
            duration: Duration(seconds: 3),
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
        title: const Text("新增基础活动"),
        elevation: 0,
        actions: [
          MaterialButton(
            color: Theme.of(context).colorScheme.secondary,
            onPressed: _saveNewExercise,
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          // 创建表单
          child: FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                // 代号和名称
                FormBuilderTextField(
                  name: 'exercise_code',
                  decoration: const InputDecoration(labelText: '*代号'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: '代号不可为空'),
                  ]),
                ),
                FormBuilderTextField(
                  name: 'exercise_name',
                  decoration: const InputDecoration(labelText: '*名称'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: '名称不可为空'),
                  ]),
                ),

                // 级别和类别（单选）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: FormBuilderDropdown<String>(
                        name: 'level',
                        decoration: const InputDecoration(
                          labelText: '*级别',
                          hintText: '选择级别',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '级别不可为空')
                        ]),
                        items: _genItems(levelOptions),
                        valueTransformer: (val) => val?.toString(),
                      ),
                    ),
                    Flexible(
                      child: FormBuilderDropdown<String>(
                        name: 'force',
                        decoration: const InputDecoration(
                          labelText: '发力方式',
                          hintText: '选择发力方式',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '发力方式不可为空')
                        ]),
                        items: _genItems(forceOptions),
                        valueTransformer: (val) => val?.toString(),
                      ),
                    )
                  ],
                ),
                // 分类和类别
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 分类（单选）
                    Flexible(
                      child: FormBuilderDropdown<String>(
                        name: 'category',
                        decoration: const InputDecoration(
                          labelText: '*分类',
                          hintText: '选择分类',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '分类不可为空')
                        ]),
                        items: _genItems(categoryOptions),
                        valueTransformer: (val) => val?.toString(),
                      ),
                    ),
                    Flexible(
                      child: FormBuilderDropdown<String>(
                        name: 'mechanic',
                        decoration: const InputDecoration(
                          labelText: '*类别',
                          hintText: '选择类别',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '类别不可为空')
                        ]),
                        items: _genItems(mechanicOptions),
                        valueTransformer: (val) => val?.toString(),
                      ),
                    )
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: FormBuilderDropdown<String>(
                        name: 'equipment',
                        decoration: const InputDecoration(
                          labelText: '所需器械',
                          hintText: '选择所需器械',
                        ),
                        items: _genItems(equipmentOptions),
                        valueTransformer: (val) => val?.toString(),
                      ),
                    ),
                    Flexible(
                      child: FormBuilderDropdown<String>(
                        name: 'standard_duration',
                        decoration: const InputDecoration(
                          labelText: '标准动作耗时',
                          hintText: '选择标准动作耗时',
                        ),
                        items: _genItems(standardDurationOptions),
                        valueTransformer: (val) => val?.toString(),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 10.sp),
                // 主要肌肉(多选)
                MultiSelectDialogField(
                  key: _multiPrimarySelectKey,
                  items: _muscleItems,
                  title: const Text("选择主要肌肉"),
                  selectedColor: Colors.blue,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    border: Border.all(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                  buttonIcon: const Icon(
                    Icons.fitness_center,
                    color: Colors.blue,
                  ),
                  buttonText: Text(
                    "*主要肌肉",
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16,
                    ),
                  ),
                  searchable: true,
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
                MultiSelectChipField(
                  key: _multiSecondarySelectKey,
                  items: _muscleItems,
                  initialValue: const [],
                  title: const Text("次要肌肉"),
                  headerColor: Colors.blue.withOpacity(0.5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 1.8),
                  ),
                  selectedChipColor: Colors.blue.withOpacity(0.5),
                  selectedTextStyle: TextStyle(color: Colors.blue[800]),
                  onTap: (values) {
                    selectedSecondaryMuscles = values;
                  },
                ),

                //  要点(简介这个动作步骤)
                FormBuilderTextField(
                  name: 'instructions',
                  decoration: const InputDecoration(labelText: '*技术要点'),
                  maxLines: 5,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: '技术要点不可为空'),
                  ]),
                ),
                // 语音提醒文本
                FormBuilderTextField(
                  name: 'tts_notes',
                  decoration: const InputDecoration(labelText: '语音提示要点'),
                ),

                const SizedBox(height: 10),
                // 上传活动示例图片（静态图或者gif）
                FormBuilderFilePicker(
                  name: 'images',
                  decoration: const InputDecoration(labelText: '演示图片'),
                  maxFiles: null,
                  allowMultiple: true,
                  previewImages: true,
                  onChanged: (val) => debugPrint(val.toString()),
                  typeSelectors: const [
                    TypeSelector(
                      type: FileType.image,
                      selector: Row(
                        children: <Widget>[
                          Icon(Icons.file_upload),
                          Text('图片上传'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

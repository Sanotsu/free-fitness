// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/tool_widgets.dart';

class ExerciseQueryForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onQuery; // 定义回调函数属性

  const ExerciseQueryForm({super.key, required this.onQuery});

  @override
  State<ExerciseQueryForm> createState() => _ExerciseQueryFormState();
}

class _ExerciseQueryFormState extends State<ExerciseQueryForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  // 默认只展示精简查询条件
  bool _showAdvancedOptions = false;

  // 点击查询按钮时，把条件表单的数据返回父组件
  void _submitForm() {
    if (_formKey.currentState!.saveAndValidate()) {
      // 获取查询条件的值
      Map<String, dynamic>? query = _formKey.currentState!.value;

      // 调用回调函数，将查询条件的值传递给上层调用的组件
      widget.onQuery(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          _genSimpleQueryArea(),
          // _showAdvancedOptions 为true时,部件显示;为false,部件折叠,显示时选中的值折叠后依旧保留
          _genMoreQueryArea(),
        ],
      ),
    );
  }

  // 默认的简单首行，下拉选择锻炼部位和一些按钮
  _genSimpleQueryArea() {
    return Card(
      elevation: 5.sp,
      child: Padding(
        padding: EdgeInsets.all(5.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              // FormBuilderDropdown需要指定外部容器大小，或者放在类似expanded中自动扩展
              child: FormBuilderDropdown(
                name: "primary_muscles",
                isDense: true, // 默认就是紧凑型
                decoration: InputDecoration(
                  labelText: "锻炼部位",
                  hintText: "选择锻炼部位",
                  hintStyle: TextStyle(fontSize: 14.sp),
                  isDense: true, // 边框没有默认是紧凑型
                  // 调整内边距
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 5.sp,
                    vertical: 5.sp,
                  ),
                  // 这是下划线，如果要四周包裹，用 OutlineInputBorder
                  border: const OutlineInputBorder(),
                ),
                items: genDropdownMenuItems(
                  musclesOptions,
                  textSize: 16.sp,
                ),
                valueTransformer: (val) => val?.toString(),
              ),
            ),
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showAdvancedOptions = !_showAdvancedOptions;
                  });
                },
                child: Text(
                  _showAdvancedOptions ? '收起' : '更多',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: () {
                  // todo 如果有高级查询条件被选择，但是被折叠了，点击重置是不会清除的。
                  setState(() {
                    _formKey.currentState!.reset();
                  });
                },
                child: Text('重置', style: TextStyle(fontSize: 12.sp)),
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                onPressed: _showHintDialog,
                icon: Icon(Icons.warning, size: 16.sp, color: Colors.black),
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: const Text('查询'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 展开更多查询条件
  _genMoreQueryArea() {
    // 如果不展开更多查询条件，返回空数组
    if (!_showAdvancedOptions) return Container();

    // 否则，展示更多查询条件
    return Card(
        elevation: 5.sp,
        child: Padding(
            padding: EdgeInsets.all(10.sp),
            child: Column(
              children: [
                // 更多查询条件
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text("代号"),
                    Flexible(
                      child: _buildTextField("exercise_code", hintText: "输入代号"),
                    ),
                    const Text("名称"),
                    Flexible(
                      child: _buildTextField("exercise_name", hintText: "输入名称"),
                    ),
                  ],
                ),
                // 级别和类别（单选）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text("级别"),
                    Flexible(
                      child: _buildQueryDropdown(
                        "level",
                        levelOptions,
                        hintText: "选择级别",
                      ),
                    ),
                    const Text("类型"),
                    Flexible(
                      child: _buildQueryDropdown(
                        "mechanic",
                        mechanicOptions,
                        hintText: "选择类型",
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text("分类"),
                    Flexible(
                      child: _buildQueryDropdown(
                        "category",
                        categoryOptions,
                        hintText: "选择分类",
                      ),
                    ),
                    const Text("器械"),
                    Flexible(
                      child: _buildQueryDropdown(
                        "equipment",
                        equipmentOptions,
                        hintText: "选择器械",
                      ),
                    ),
                  ],
                ),
              ],
            )));
  }

  /// 以下下拉选择框和文本输入框的主要目的都是尽量紧凑
  // 构建查询表单的下拉选择框
  Widget _buildQueryDropdown(
    String name,
    List<CusLabel> options, {
    String? labelText,
    String? hintText,
    double? optionFontSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.sp),
      child: FormBuilderDropdown(
        name: name,
        isDense: true, // 默认就是紧凑型
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          isDense: true, // 边框没有默认是紧凑型
          // 调整内边距，使得下拉框更紧凑
          contentPadding: EdgeInsets.symmetric(horizontal: 5.sp, vertical: 5),
          // 这是下划线，如果要四周包裹，用OutlineInputBorder
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
        items: genDropdownMenuItems(options, textSize: optionFontSize),
        valueTransformer: (val) => val?.toString(),
      ),
    );
  }

  // 构建查询表单的文本输入框
  Widget _buildTextField(
    String name, {
    String? hintText, // 可不传提示语
    String? labelText, // 可不传栏位标签，在输入框前面有就行
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.sp),
      child: FormBuilderTextField(
        name: name,
        decoration: InputDecoration(
          isDense: true, // 边框没有默认是紧凑型
          labelText: labelText,
          hintText: hintText,
          // 调整内边距，使得下拉框更紧凑
          contentPadding: EdgeInsets.symmetric(horizontal: 5.sp, vertical: 5),
        ),
      ),
    );
  }

  // 显示重置按钮的逻辑文本
  void _showHintDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('重置查询条件，如果选中高级选项后折叠，需要展开后再重置，否则高级条件值会保留。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}

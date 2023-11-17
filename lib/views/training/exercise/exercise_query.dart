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
  bool _showAdvancedOptions = false;

  void _submitForm() {
    print("进入了条件查询 ${_formKey.currentState!.value}");

    if (_formKey.currentState!.saveAndValidate()) {
      // 获取查询条件的值
      Map<String, dynamic>? query = _formKey.currentState!.value;

      // 如果不是展开的条件框，则查询条件只有默认的少数
      // 2023-10-18 注意，查询表单收起来如果不保留已被选中的值，下拉加载更多的条件就没了。
      // 所以这里暂时保持所有查询条件不过滤了，嫌太多就用户自行重置，以便加载更多时条件正确。
      // if (!_showAdvancedOptions) {
      //   String? selectedValue = query['primary_muscles'];

      //   // 这里这样写是因为使用query.clear()再赋值没有效果，原因不明。
      //   query = null;
      //   if (query == null) {
      //     query = {};
      //     query['primary_muscles'] = selectedValue;
      //   }
      // }

      // 调用回调函数，将查询条件的值传递给上层调用的组件
      widget.onQuery(query);
    }

    // print("查询条件表单点击了");
    // debugPrint(_formKey.currentState?.value.toString());
    // if (_formKey.currentState!.validate()) {
    //   print("查询条件表单认证通过了${genDropdownMenuItems(levelOptions)}");

    //   print(_formKey.currentState?.fields['exercise_code']?.value);
    //   print(_formKey.currentState?.fields['exercise_name']?.value);
    //   print(_formKey.currentState?.fields['level']?.value);
    //   print(_formKey.currentState?.fields['mechanic']?.value);
    //   print(_formKey.currentState?.fields['category']?.value);
    //   // 执行查询操作
    //   Map<String, dynamic> formData = _formKey.currentState!.value;
    //   print(formData); // 输出查询条件
    // }
  }

// 在重置更多查询条件时,只能一个个表单栏位进行重置
// 否则,在先展开高级条件后有选择内容,但又缩回最小条件后,此次重置是不会重置高级条件中的值
  _resetAdvancedOptions() {
//     // 注意,这里的栏位和高级查询中的name的字符串一致
//     // 填写所有要重置的字段名称
//     List<String> fieldNames = [
//       'exercise_code',
//       'exercise_name',
//       'level',
//       'mechanic',
//       'category',
//       'equipment'
//     ];

// // 在重置表单时循环处理字段
//     for (var fieldName in fieldNames) {
//       print("进入了重置表单函数$fieldName");
//       _formKey.currentState!.fields[fieldName]?.didChange(null);
//     }

//     _formKey.currentState!.fields['level']?.reset();

    print("进入了重置表单函数 befor ${_formKey.currentState!.value}");

    if (_showAdvancedOptions) {
      _formKey.currentState!.reset();
    } else {
      _showAdvancedOptions = true;
      _formKey.currentState!.fields['exercise_code']?.didChange('');
      _formKey.currentState!.fields['exercise_name']?.didChange('');
      _formKey.currentState!.fields['level']?.didChange(null);
      _formKey.currentState!.fields['mechanic']?.didChange(null);
      _formKey.currentState!.fields['category']?.didChange(null);
      _formKey.currentState!.fields['equipment']?.didChange(null);
      _formKey.currentState!.reset();
      _showAdvancedOptions = false;

      print("进入了重置表单函数 after ${_formKey.currentState!.value}");
    }

    // setState(() {
    //   _showAdvancedOptions = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 5,
                  child: FormBuilderDropdown(
                    name: 'primary_muscles',
                    decoration: const InputDecoration(
                      labelText: '部位',
                      hintText: '选择训练部位',
                    ),
                    items: genDropdownMenuItems(musclesOptions),
                    valueTransformer: (val) => val?.toString(),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                    },
                    icon: Icon(
                      _showAdvancedOptions
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20.sp,
                      color: Colors.blue,
                    ),
                  ),

                  // TextButton(
                  //   onPressed: () {
                  //     setState(() {
                  //       _showAdvancedOptions = !_showAdvancedOptions;
                  //     });
                  //   },
                  //   child: Text(
                  //     _showAdvancedOptions ? '更少' : '更多',
                  //     style: TextStyle(fontSize: 12.sp),
                  //   ),
                  // ),
                ),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _resetAdvancedOptions();
                      });
                    },
                    icon: Icon(Icons.refresh, size: 20.sp, color: Colors.blue),
                  ),
                  // TextButton(
                  //   onPressed: () {
                  //     // 因为默认的时候就是只显示更少的查询框,所以重置时先还原查询条件为更少,再清空,
                  //     // 避免有高级查询条件选中但因为折叠而没有重置掉的问题.
                  //     setState(() {
                  //       _resetAdvancedOptions();
                  //     });
                  //   },
                  //   child: Text(
                  //     '重置',
                  //     style: TextStyle(fontSize: 12.sp),
                  //   ),
                  // ),
                ),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    onPressed: _showHintDialog,
                    icon: const Icon(
                      Icons.help_outline,
                      size: 16,
                      color: Colors.black,
                    ),
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
          // _showAdvancedOptions 为true时,部件显示;为false,部件折叠,显示时选中的值折叠后依旧保留
          if (_showAdvancedOptions) ...[
            // 更多查询条件
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: FormBuilderTextField(
                    name: 'exercise_code',
                    decoration: const InputDecoration(labelText: '代号'),
                  ),
                ),
                Flexible(
                  child: FormBuilderTextField(
                    name: 'exercise_name',
                    decoration: const InputDecoration(labelText: '名称'),
                  ),
                ),
              ],
            ),
            // 级别和类别（单选）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: FormBuilderDropdown(
                    name: 'level',
                    decoration: const InputDecoration(
                      labelText: '级别',
                      hintText: '选择级别',
                    ),
                    items: genDropdownMenuItems(levelOptions),
                    valueTransformer: (val) => val?.toString(),
                  ),
                ),
                Flexible(
                  child: FormBuilderDropdown(
                    name: 'mechanic',
                    decoration: const InputDecoration(
                      labelText: '类别',
                      hintText: '选择类别',
                    ),
                    items: genDropdownMenuItems(mechanicOptions),
                    valueTransformer: (val) => val?.toString(),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 分类（单选）
                Flexible(
                  child: FormBuilderDropdown(
                    name: 'category',
                    decoration: const InputDecoration(
                      labelText: '*分类',
                      hintText: '选择分类',
                    ),
                    items: genDropdownMenuItems(categoryOptions),
                    valueTransformer: (val) => val?.toString(),
                  ),
                ),
                Flexible(
                  child: FormBuilderDropdown(
                    name: 'equipment',
                    decoration: const InputDecoration(
                      labelText: '所需器械',
                      hintText: '选择所需器械',
                    ),
                    items: genDropdownMenuItems(equipmentOptions),
                    valueTransformer: (val) => val?.toString(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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

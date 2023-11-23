// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:free_fitness/common/global/constants.dart';

import '../../models/diary_state.dart';

/// 使用富文本编辑器的比较麻烦，先用简单的表单来实现编辑页面即可
/// TODO  2023-11-23 实际这个表单的效果还不如使用富文本的，这个组件先暂停
class DiaryModifyForm extends StatefulWidget {
// 如果有传手记的内容过来，则可能是修改；如果此时为只读，那又变成预览；没有传手记，那就是新增。

  final Diary? diaryItem;

  const DiaryModifyForm({super.key, this.diaryItem});

  @override
  State<DiaryModifyForm> createState() => _DiaryModifyFormState();
}

class _DiaryModifyFormState extends State<DiaryModifyForm> {
// 用于显示的手记数据
  late Diary item;

  // 处理类型
  // 如果没有传手记过来，则应该是新增，这里默认就是。
  // 如果有传手记过来，则是预览。
  // 如果有传手记过来，然后点击了修改按钮，则是修改。
  String handleType = "adding"; // adding reading modifying

  final _formKey = GlobalKey<FormBuilderState>();

  // 手动输入标签的文本框控制器，和存放标签的数组
  final _tagTextController = TextEditingController();
  // 这里是标签的初始值，实际用时可以为空数组或空字符串
  List<String> _tags = ["手记"];
  // 分类和心情的初始值
  String initMood = "喜悦";
  List<String> initCategorys = ["生活"];

  @override
  void initState() {
    super.initState();

    print("是否有传入手记数据 widget.diaryItem:${widget.diaryItem}");
    setState(() {
      if (widget.diaryItem != null) {
        print("initState handleType :$handleType");
        handleType = "reading";
        // 添加上各个标签默认值
        _tags = widget.diaryItem!.tags!.split(",").toList();
        initMood = widget.diaryItem!.mood!.split(",").toList().first;
        initCategorys = widget.diaryItem!.category!.split(",").toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print("handleType :$handleType");

    return Scaffold(
      appBar: AppBar(
        title: const Text("编辑手记表单表单示例"),
        actions: [
          // 如果是预览的状态，显示修改按钮
          if (handleType == "reading")
            TextButton(
              onPressed: () {
                setState(() {
                  handleType = "modifying";
                });
              },
              child: const Text(
                "修改",
                style: TextStyle(color: Colors.white),
              ),
            ),
          // 如果是新增中或者修改中，显示保存按钮
          if (handleType == "adding" || handleType == "modifying")
            TextButton(
              // 点击了保存，把数据存入db，这里都变为预览状态
              onPressed: () {
                setState(() {
                  handleType = "reading";
                });
              },
              child: const Text(
                "保存",
                style: TextStyle(color: Colors.white),
              ),
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildForm(),
          ],
        ),
      ),
    );
  }

  _buildForm() {
    return GestureDetector(
      // 点击空白处收起键盘
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.sp),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(elevation: 3, child: buildTagSelectExpansionTile()),
              Card(elevation: 3, child: buildTitleTextRow()),
              Card(elevation: 3, child: buildContentText()),
              // _buildInputTagsArea(),
            ],
          ),
        ),
      ),
    );
  }

  // 这些选项都是FormBuilderChipOption类型
  List<FormBuilderChipOption<String>> _moodChipOptions() {
    return diaryMoodList
        .map((e) => FormBuilderChipOption(value: e.cnLabel))
        .toList();
  }

  List<FormBuilderChipOption<String>> _categoryChipOptions() {
    return diaryCategoryList
        .map((e) => FormBuilderChipOption(value: e.cnLabel))
        .toList();
  }

  // 分类多选行
  _buildMultiSelectRow(
    String title,
    String name,
    List<FormBuilderChipOption> options, {
    List<Object>? initialValue,
    Function(List<dynamic>?)? onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Center(child: Text(title)),
        // 这个可以单选选，表现类似 radio
        Expanded(
          child: FormBuilderFilterChip(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            // decoration: const InputDecoration(labelText: '这里可以多选:'),
            name: name,
            initialValue: initialValue,
            // 选项列表
            options: options,
            // 标签被选中时的颜色
            selectedColor: Colors.blue,
            // 选项列表中文字样式
            labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            // 标签的内边距
            labelPadding: EdgeInsets.all(1.sp),
            // // 设置标签的形状样式(四个圆角为5的方形,默认是圆形)
            // shape: RoundedRectangleBorder(
            //   borderRadius: BorderRadius.circular(5.0),
            //   // 边框是宽度为1的灰色
            //   // side: BorderSide(color: Colors.grey, width: 1.sp),
            // ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // 心情单选行
  _buildSingleSelectRow(
    String title,
    String name,
    List<FormBuilderChipOption> options, {
    Object? initialValue,
    Function(dynamic)? onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Center(child: Text(title)),
        // 这个可以单选选，表现类似 radio
        Expanded(
          child: FormBuilderChoiceChip(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            // decoration: const InputDecoration(labelText: '这里只能单选:'),
            name: name,
            initialValue: initialValue,
            // 选项列表
            options: options,
            // 标签被选中时的颜色
            selectedColor: Colors.blue,
            // 选项列表中文字样式
            labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            // 标签的内边距
            labelPadding: EdgeInsets.all(1.sp),
            // 设置标签的形状样式(四个圆角为5的方形,默认是圆形)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
              // 边框是宽度为1的灰色
              // side: BorderSide(color: Colors.grey, width: 1.sp),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // 2023-11-22 没有成功，还是用原本的输入框吧
  buildTagUserFormBuilder() {
    // 当用户输入以下列表中的符号时，自动切分成标签。
    // List<String> endingSymbols = [',', '，', ';', "；", "。"];
    return [
      Padding(
        padding: EdgeInsets.all(10.sp),
        child: FormBuilderTextField(
          name: 'tags',
          initialValue: "",
          style: TextStyle(fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: '输入标签(输入逗号或分号自动分割)',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          keyboardType: TextInputType.multiline,
          onChanged: (value) {
            if (_formKey.currentState?.saveAndValidate() ?? false) {
              // ？？？永远不会中断和重置，到最后堆栈溢出，暂时不清楚细节。
              if (value != null && value != "") {
                print("tags-------------$value");

                // for (var symbol in endingSymbols) {
                //   if (value.endsWith(symbol)) {
                //     final cleanedTag = value
                //         .replaceAll(RegExp('[${endingSymbols.join()}]'), '')
                //         .trim();

                //     _tags.add(cleanedTag);
                // _formKey.currentState!.fields['tags']?.didChange(null);
                // _formKey.currentState!.fields['tags']?.reset();
                // _formKey.currentState!.fields['tags']?.didChange("");
                //     break;
                //   }
                // }
                print("tags1111---- ${_formKey.currentState!.fields['tags']}");
              }
            }
          },
        ),
      ),
      Wrap(
        spacing: 8,
        children: _tags.map((tag) {
          return Chip(
            label: Text(tag),
            onDeleted: () {
              setState(() {
                _tags.remove(tag);
              });
            },
          );
        }).toList(),
      ),
    ];
  }

  // 用户指定输入标签，用逗号分割
  _buildInputTagsArea() {
    // 当用户输入以下列表中的符号时，自动切分成标签。
    List<String> endingSymbols = [',', '，', ';', "；", "。"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(5.sp),
          child: TextField(
            controller: _tagTextController,
            decoration: InputDecoration(
                hintText: '  输入标签(输入逗号或分号自动分割)',
                contentPadding: EdgeInsets.symmetric(vertical: 2.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                )),
            onChanged: (value) {
              for (var symbol in endingSymbols) {
                // 如果输入标签分隔符，自动添加标签。
                if (value.endsWith(symbol)) {
                  final cleanedTag = value
                      .replaceAll(RegExp('[${endingSymbols.join()}]'), '')
                      .trim();

                  setState(() {
                    _tags.add(cleanedTag);
                  });
                  _tagTextController.clear();
                  break;
                }
              }
            },
          ),
        ),
        Wrap(
          spacing: 8,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() {
                  _tags.remove(tag);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // 折叠展开各个标签分类选择
  buildTagSelectExpansionTile() {
    return ExpansionTile(
      title: const Text('展开选择心情、分类和标签'),
      leading: const Icon(Icons.tag, color: Colors.green),
      backgroundColor: Colors.white,
      initiallyExpanded: false, // 是否默认展开
      children: <Widget>[
        // 这个只能单选，表现类似 radio
        _buildSingleSelectRow(
          "心情",
          "mood",
          _moodChipOptions(),
          initialValue: initMood,
        ),
        // 这个可以多选，表现类似 checkbox
        _buildMultiSelectRow(
          "分类",
          "category",
          _categoryChipOptions(),
          initialValue: initCategorys,
        ),

        // 手动输入标签，逗号和分号自动切分
        _buildInputTagsArea(),
      ],
    );
  }

  // 标题输入区域
  buildTitleTextRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Expanded(
          flex: 1,
          child: Center(
            child: Text("标题", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          flex: 5,
          child: FormBuilderTextField(
            name: 'title',
            initialValue: "",
            style: TextStyle(fontSize: 16.sp),
            // maxLines: 3,
            readOnly: handleType == "reading",
            decoration: InputDecoration(
              hintText: '一句话也好，哪怕想记的不多。',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10.sp),
              border: handleType == "reading"
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
            ),
            keyboardType: TextInputType.text, // 将键盘类型设置为默认的文本输入类型
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: '标题不能为空'),
            ]),
            onChanged: (value) {
              if (_formKey.currentState?.validate() != true) {
                return;
              }
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  // 正文输入区域
  // 如果没有输入正文，保存时把标题存到正文来，不要求一定需要输入正文。
  buildContentText() {
    return FormBuilderTextField(
      name: 'content',
      initialValue: "",
      maxLines: 18,
      readOnly: handleType == "reading",
      decoration: InputDecoration(
        // labelText: '内容',
        hintText: 'So, what are we gonna write today?',
        isDense: true,
        border: handleType == "reading"
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
      ),
      keyboardType: TextInputType.text,
      onChanged: (value) {
        if (_formKey.currentState?.validate() != true) {
          return;
        }
        setState(() {});
      },
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/diary_state.dart';

import '../../common/global/constants.dart';
import '../../common/utils/db_diary_helper.dart';
import '../../common/utils/tool_widgets.dart';
import '../../common/utils/tools.dart';

///
/// 2023-11-23 不是很完善，但基本能用。
/// ？？？quill还是不太会用。
/// ？？？title和content默认为空字符串，依旧可以保存。如果一直保存，则很多空日记。
///
/// 2023-11-25 好像文本输入框和富文本输入框无法共存，只要聚焦了文本输入框，
/// 即便点击了收起键盘，还是会自动聚焦，弹窗键盘
///
///
class NewDiaryModifyRichText extends StatefulWidget {
  // 传入的手记数据(修改或预览时会传，新增时不会)
  final Diary? diaryItem;

  const NewDiaryModifyRichText({super.key, this.diaryItem});

  @override
  State<NewDiaryModifyRichText> createState() => _NewDiaryModifyRichTextState();
}

class _NewDiaryModifyRichTextState extends State<NewDiaryModifyRichText> {
  final DBDiaryHelper _dbHelper = DBDiaryHelper();

  final QuillController _controller = QuillController.basic();

  // 手动输入标签的文本框控制器，和存放标签的数组
  final _tagTextController = TextEditingController();
  // 这里是标签的初始值，实际用时可以为空数组或空字符串
  List<String> initTags = ["手记"];
  // 分类和心情的初始值
  String initMood = "喜悦";
  List<String> initCategorys = ["生活"];

  // 手记的题目
  final _titleTextController = TextEditingController();
  String initTitle = "";

  // 可以多次保存，新增时没有手机编号，所以首次保存会返回手记编号，后续再保存其实就是修改了.
  // 默认是没有(如果直接是传过来修改的，那就是传过来的值，在init的时候和其他内容一起初始化)
  int? initDiaryId;
  // 上一次保存的时间(如果没有自动保存，显示上次保存时间即可)
  String? lastSavedTime;

  // 如果是新增手记，则默认是编辑状态；如果是有传入手记，默认是只读状态，只有点击了编辑按钮之后才是编辑状态。
  bool isEditing = true;

  // 富文本编辑框上面的工具栏是否展开
  bool isQuillToolbarExpanded = false;

  // 标题编辑框上面的工具栏是否展开
  bool istTitleExpanded = true;

  @override
  void initState() {
    super.initState();

    // 如果有传初始手记数据，则需要初始化
    if (widget.diaryItem != null) {
      initFormatData(widget.diaryItem!);
    }
  }

  // 除了初始化的时候，如果要重置修改，也可能需要调用这个函数
  // ？？？但修改已经保存过几次，再重置也不会是上次保存的结果了。
  // 所以本次修改不管保存了多少次，点击重置之后都恢复到最初传过来的这个数据，还是查询数据库现存的数据？
  initFormatData(Diary item) {
    setState(() {
      // ？？？这里应该考虑转型失败的问题
      var diaryContent = json.decode(item.content);
      _controller.document = Document.fromJson(diaryContent);

      initTitle = item.title;
      _titleTextController.text = initTitle;
      initMood = item.mood ?? "";
      initCategorys = item.category?.split(",").toList() ?? [];
      initTags = item.tags?.split(",").toList() ?? [];
      initDiaryId = item.diaryId;

      lastSavedTime = item.gmtModified ?? item.gmtCreate;

      isEditing = false;
    });
  }

  _handleSaveButtonClick() async {
    FocusScope.of(context).requestFocus(FocusNode());

    print("点击了保存按钮--------------数据分别为:");
    print("tags----------$initTags");
    print("initMood----------$initMood");
    print("initCategorys----------$initCategorys");
    print("富文本的内容toPlainText----------${_controller.document.toPlainText()}");

    var delta = _controller.document.toDelta();
    print("富文本的内容toDelta----------${_controller.document.toDelta()}");

    final rawJson = delta.toJson();
    String jsonString = json.encode(rawJson);

    print("富文本的内容 rawJson---------$rawJson");
    print("富文本的内容 jsonString---------$jsonString");
    print("题目 initTitle---------$initTitle");

    var tempDiary = Diary(
      date: getCurrentDate(),
      title: initTitle,
      content: jsonString,
      tags: initTags.join(","),
      category: initCategorys.join(","),
      mood: initMood,
      userId: 1, // ？？？实际用户的编号
    );

    // ？？？这里应该有错误检查
    // 如果是新增
    if (initDiaryId == null) {
      print("新增手记-------$initDiaryId");

      tempDiary.gmtCreate = getCurrentDateTime();
      var newDiaryId = await _dbHelper.insertDiary(tempDiary);

      setState(() {
        initDiaryId = newDiaryId;
      });
    } else {
      print("修改手记-------$initDiaryId");

      // 如果是修改
      tempDiary.diaryId = initDiaryId;
      tempDiary.gmtModified = getCurrentDateTime();
      await _dbHelper.updateDiary(tempDiary);
    }

    print("initDiaryId---$initDiaryId");

    setState(() {
      isEditing = !isEditing;
      isQuillToolbarExpanded = false;
      // ？？？应该是取上面新增或保存时的时间，但者差距不大，先这样
      lastSavedTime = getCurrentDateTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvoked: (didPop) async {
        print("didPop-----------$didPop");
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);

        // 如果在编辑中点击返回，则弹窗提示返回会丢失未修改的内容
        if (isEditing) {
          // 如果确认弹窗点击确认返回true，否则返回false
          final bool? shouldPop = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("关闭"),
                content: const Text("当前处于编辑状态，继续返回将丢失未保存的内容，确认返回?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: const Text('确认'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('取消'),
                  ),
                ],
              );
            },
          ); // 只有当对话框返回true 才 pop(返回上一层)
          if (shouldPop ?? false) {
            // 如果还有可以关闭的导航，则继续pop
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              // 如果已经到头来，则关闭应用程序
              SystemNavigator.pop();
            }
          }
        } else {
          // 不在编辑中可以返回
          // 如果还有可以关闭的导航，则继续pop
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            // 如果已经到头来，则关闭应用程序
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: (initDiaryId != null) ? '手记' : '新增手记',
                  style: TextStyle(fontSize: 20.sp),
                ),
                if (lastSavedTime != null)
                  TextSpan(
                    text: "\n上次修改: $lastSavedTime",
                    style: TextStyle(fontSize: 12.sp),
                  ),
              ],
            ),
          ),
          actions: [
            if (!isEditing)
              IconButton(
                onPressed: () {
                  setState(() {
                    isEditing = !isEditing;
                  });
                },
                icon: const Icon(Icons.edit_document),
              ),

            // ？？？点击保存时直接存入数据库还是缓存？是否定时10分钟自动保存？保存后是否记录每次修改记录？
            // 试试保存的话，如何确定唯一id，日期+标题吗？
            if (isEditing)
              IconButton(
                onPressed: () {
                  print("？？？重置是恢复到第一次传过来的手记数据，还是从数据库查询最后一次保存的数据？");
                  setState(() {
                    isEditing = !isEditing;
                  });
                },
                icon: const Icon(Icons.refresh),
              ),
            if (isEditing)
              IconButton(
                onPressed: _handleSaveButtonClick,
                icon: const Icon(Icons.save),
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                _buildTitleAndTags(),
                buildRichTextArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildTitleAndTags() {
    return Card(
      elevation: 3,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        // title: const Text("展示标题"),
        title: buildTitleArea(),
        backgroundColor: Colors.white,
        initiallyExpanded: istTitleExpanded, // 是否默认展开
        onExpansionChanged: (isExpanded) {
          setState(() {
            istTitleExpanded = isExpanded;
          });
        },
        children: <Widget>[
          // buildTitleArea(),
          ...buildTagsArea(),
        ],
      ),
    );
  }

  /// 主体从上到下应该是:标题、各项标签选择折叠框、富文本工具框、富文本编辑器。
  /// 当在预览时，只有：标题、标签、富文本编辑器，都是只读
  buildTitleArea() {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 当处于编辑时才显示标签
          // 后面这个不折叠才显示，是临时解决点击了收起键盘后还是会重新聚焦输入框而又弹出键盘的问题
          if (isEditing && istTitleExpanded)
            const Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "标题",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Expanded(
            flex: 5,
            child: TextField(
              controller: _titleTextController,
              // 后面这个折叠收起来让它只读，是临时解决点击了收起键盘后还是会重新聚焦输入框而又弹出键盘的问题
              readOnly: !isEditing || (isEditing && !istTitleExpanded),
              // readOnly: !isEditing,
              maxLines: 2,
              // 预览时居中，编辑时靠左
              textAlign: isEditing ? TextAlign.start : TextAlign.center,
              decoration: InputDecoration(
                hintText: ' 一句话标题也好，哪怕想写的不多^~^',
                contentPadding: EdgeInsets.symmetric(vertical: 2.sp),
                // 预览时不显示边框
                border: isEditing
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      )
                    : InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  initTitle = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // 预览时显示各个标签
  buildTagsArea() {
    // 标签、心情、分类不同样式显示
    return [
      if (isEditing) ...buildTagSelectArea(),
      if (!isEditing)
        // 这个更小
        Wrap(
          spacing: 5,
          children: [
            ...initTags.map((tag) {
              return buildSmallButtonTag(
                tag,
                bgColor: Colors.lightGreen,
                labelTextSize: 12.sp,
              );
            }).toList(),
            ...initCategorys.map((cate) {
              return buildSmallButtonTag(
                cate,
                bgColor: Colors.limeAccent,
                labelTextSize: 12.sp,
              );
            }).toList(),
            buildSmallButtonTag(
              initMood,
              bgColor: Colors.lightBlue,
              labelTextSize: 12.sp,
            ),
          ],
        ),
    ];
  }

  // 编辑时各个标签分类选择
  buildTagSelectArea() {
    return [
      // 这个只能单选，表现类似 radio
      _buildSingleSelectRow(
        "心情",
        "mood",
        _moodChipOptions(),
        initialValue: initMood,
        onChanged: (value) {
          print("_buildSingleSelectRow value------------$value");
          setState(() {
            initMood = value;
          });
        },
      ),
      // 这个可以多选，表现类似 checkbox
      _buildMultiSelectRow(
        "分类",
        "category",
        _categoryChipOptions(),
        initialValue: initCategorys,
        onChanged: (value) {
          setState(() {
            initCategorys = value?.map((v) => v.toString()).toList() ?? [];
          });
        },
      ),

      // 手动输入标签，逗号和分号自动切分
      _buildInputTagsArea(),
    ];
  }

  // 富文本编辑预览区域
  buildRichTextArea() {
    return SizedBox(
      height: isQuillToolbarExpanded ? 1.2.sh : 0.65.sh,
      width: 1.sw,
      child: QuillProvider(
        configurations: QuillConfigurations(
          controller: _controller,
          sharedConfigurations: const QuillSharedConfigurations(
            locale: Locale('zh', 'CN'),
          ),
        ),
        child: Column(
          children: [
            // 在编辑状态下才显示工具栏
            if (isEditing)
              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(3.sp),
                  child: ExpansionTile(
                    title: const Text('展开富文本编辑工具栏'),
                    leading: const Icon(Icons.tag, color: Colors.green),
                    backgroundColor: Colors.white,
                    initiallyExpanded: isQuillToolbarExpanded, // 是否默认展开
                    onExpansionChanged: (isExpanded) {
                      setState(() {
                        isQuillToolbarExpanded = isExpanded;
                      });
                    },
                    children: <Widget>[
                      QuillToolbar(
                        configurations: QuillToolbarConfigurations(
                          // 默认有嵌入：视频、图片、摄像头、多媒体，也可以指定
                          embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                          // embedButtons: FlutterQuillEmbeds.toolbarButtons(
                          //   imageButtonOptions:
                          //       const QuillToolbarImageButtonOptions(),
                          // ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(5.sp),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isEditing ? Colors.grey : Colors.white),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.white,
                  ),
                  child: QuillEditor.basic(
                    configurations: QuillEditorConfigurations(
                      autoFocus: false,
                      // 后面这个标题不折叠不让编辑富文本，是临时解决标题输入框点击了收起键盘后还是会重新聚焦输入框而又弹出键盘的问题
                      // readOnly: !isEditing,
                      readOnly: !isEditing || (isEditing && istTitleExpanded),
                      scrollable: true,
                      expands: true,

                      padding: EdgeInsets.all(5.sp),
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  ///
  /// 来源自 diary_modify_form
  ///

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
            // 后面这个折叠收起来让它只读，是临时解决点击了收起键盘后还是会重新聚焦输入框而又弹出键盘的问题
            readOnly: !isEditing || (isEditing && !istTitleExpanded),
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
                    initTags.add(cleanedTag);
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
          children: initTags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () {
                setState(() {
                  initTags.remove(tag);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

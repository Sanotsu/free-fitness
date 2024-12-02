import 'dart:convert';

import 'package:flutter/foundation.dart';
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
import '../../layout/themes/cus_font_size.dart';
import '../../models/cus_app_localizations.dart';

///
/// 2023-11-23 不是很完善，但基本能用。
/// ？？？quill还是不太会用。
/// ？？？title和content默认为空字符串，依旧可以保存。如果一直保存，则很多空日记。
///
/// 2023-11-25 好像文本输入框和富文本输入框无法共存，只要聚焦了文本输入框，
/// 即便点击了收起键盘，还是会自动聚焦，弹窗键盘
///
/// 2023-11-27 修复了文本输入框和富文本输入框聚焦冲突的问题
///

class DiaryModifyRichText extends StatefulWidget {
  // 传入的手记数据(修改或预览时会传，新增时不会)
  final Diary? diaryItem;

  const DiaryModifyRichText({super.key, this.diaryItem});

  @override
  State<DiaryModifyRichText> createState() => _DiaryModifyRichTextState();
}

class _DiaryModifyRichTextState extends State<DiaryModifyRichText> {
  final DBDiaryHelper _dbHelper = DBDiaryHelper();

  // 使用formbuilder管理的心情和分类多选表单组件在重置数据时需要表单key
  final _formKey = GlobalKey<FormBuilderState>();

  // 富文本编辑器的控制器
  final QuillController _controller = QuillController.basic();

  // 页面添加了滚动条
  final ScrollController _scrollController = ScrollController();

  /// 2023-11-27
  /// 因为同时存在标题和标签输入框textField、富文本输入框 quillEditor.
  /// 在我点击了标题或者标签之后，再点击富文本，焦点会重新聚焦到textField而不是quillEditor。
  /// 为了解决这个问题，给他们三者都添加对应的focusNode，
  ///     这样，在点击富文本的时候，手动让textField失去聚焦，手动让quillEditor获得焦点，以便正确修改。
  /// 又因为点击textField时能够正确获取焦点，所以不用手动在点击textField时让quillEditor失去焦点。
  final quillFocusNode = FocusNode();
  final tagTextFocusNode = FocusNode();
  final titleTextFocusNode = FocusNode();

  // 手动输入标签的文本框控制器，和存放标签的数组
  final _tagTextController = TextEditingController();
  // 这里是标签的初始值，实际用时可以为空数组或空字符串
  List<String> initTags = [];
  // 分类和心情的初始值
  String initCategory = "";
  List<String> initMoods = [];

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

  @override
  void initState() {
    super.initState();

    // 如果有传初始手记数据，则需要初始化
    if (widget.diaryItem != null) {
      initFormatData(widget.diaryItem!);
    }
  }

  @override
  void dispose() {
    quillFocusNode.dispose();
    tagTextFocusNode.dispose();
    titleTextFocusNode.dispose();
    _tagTextController.dispose();
    _titleTextController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
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
      initCategory = item.category ?? "";
      // 先排除原本的数据就是一个空字符串，因此空字符串用逗号分割后是还有一个空字符串的字符串列表
      initMoods = (item.mood != null && item.mood!.trim().isNotEmpty)
          ? item.mood!.trim().split(",")
          : [];

      initTags = (item.tags != null && item.tags!.trim().isNotEmpty)
          ? item.tags!.trim().split(",")
          : [];
      initDiaryId = item.diaryId;

      lastSavedTime = item.gmtModified ?? item.gmtCreate;

      isEditing = false;
      // 2024-07-06 现在编辑文本是否只读在控制器配置了，需要要先改是否修改，再修改控制器
      _controller.readOnly = !isEditing;
    });
  }

  // 新增手记时，在没有保存的情况下点击重置，则不将修改状态改为false，只是清空当前的内容；只有点击返回时才退出当前页面。
  resetInitData() {
    // 标签清空(心情可以多选，分类只能单选)
    _formKey.currentState?.fields['mood']?.didChange([]);
    _formKey.currentState?.fields['category']?.didChange("");
    initTags = [];
    _tagTextController.text = "";

    // 标题清空
    _titleTextController.text = "";
    // 富文本正文清空
    _controller.clear();

    // 输入框的焦点也先全部取消
    quillFocusNode.unfocus();
    tagTextFocusNode.unfocus();
    // titleTextFocusNode.unfocus();
    // ？？？这样才失去焦点，上面那样还会聚焦？？？
    FocusScope.of(context).requestFocus(titleTextFocusNode);
  }

  _handleSaveButtonClick() async {
    FocusScope.of(context).requestFocus(FocusNode());

    // 没有标题则不行
    if (initTitle.isEmpty) {
      return showSnackMessage(
        context,
        CusAL.of(context).requiredErrorText(CusAL.of(context).diaryLables("2")),
      );
    }

    var delta = _controller.document.toDelta();
    final rawJson = delta.toJson();
    String jsonString = json.encode(rawJson);

    var tempDiary = Diary(
      date: getCurrentDate(),
      title: initTitle,
      content: jsonString,
      // ？？？中英文显示文字不一样，存入数据库字符也不一样，暂时不区分处理了
      tags: initTags.isEmpty ? "" : initTags.join(","),
      category: initCategory,
      mood: initMoods.isEmpty ? "" : initMoods.join(","),
      userId: CacheUser.userId,
    );

    try {
      // ？？？这里应该有错误检查
      // 如果是新增
      if (initDiaryId == null) {
        tempDiary.gmtCreate = getCurrentDateTime();
        var newDiaryId = await _dbHelper.insertDiary(tempDiary);

        if (!mounted) return;
        setState(() {
          initDiaryId = newDiaryId;
        });
      } else {
        // 如果是修改
        tempDiary.diaryId = initDiaryId;
        tempDiary.gmtCreate = widget.diaryItem?.gmtCreate;
        tempDiary.gmtModified = getCurrentDateTime();
        await _dbHelper.updateDiary(tempDiary);
      }

      if (!mounted) return;
      setState(() {
        isEditing = !isEditing;
        // 2024-07-06 现在编辑文本是否只读在控制器配置了，需要要先改是否修改，再修改控制器
        _controller.readOnly = !isEditing;
        isQuillToolbarExpanded = false;
        // ？？？应该是取上面新增或保存时的时间，但者差距不大，先这样
        lastSavedTime = getCurrentDateTime();
      });
    } catch (e) {
      // 弹出报错提示框
      if (!mounted) return;

      commonExceptionDialog(
        context,
        CusAL.of(context).exceptionWarningTitle,
        e.toString(),
      );

      // 中止操作
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        // 点击了返回，就先取消所有焦点
        tagTextFocusNode.unfocus();
        titleTextFocusNode.unfocus();
        quillFocusNode.unfocus();

        final NavigatorState navigator = Navigator.of(context);

        // 如果在编辑中点击返回，则弹窗提示返回会丢失未修改的内容
        if (isEditing) {
          // 如果确认弹窗点击确认返回true，否则返回false
          final bool? shouldPop = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(CusAL.of(context).closeLabel),
                content: const Text("当前处于编辑状态，继续返回将丢失未保存的内容，确认返回?"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text(CusAL.of(context).cancelLabel),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: Text(CusAL.of(context).confirmLabel),
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
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: (initDiaryId == null)
                      ? CusAL.of(context).addLabel(CusAL.of(context).diary)
                      : isEditing
                          ? CusAL.of(context).eidtLabel(CusAL.of(context).diary)
                          : CusAL.of(context).diary,
                  style: TextStyle(fontSize: CusFontSizes.pageTitle),
                ),
                if (lastSavedTime != null)
                  TextSpan(
                    text: "\n${CusAL.of(context).lastModified}: $lastSavedTime",
                    style: TextStyle(fontSize: CusFontSizes.pageAppendix),
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
                    // 2024-07-06 现在编辑文本是否只读在控制器配置了，需要要先改是否修改，再修改控制器
                    _controller.readOnly = !isEditing;
                  });
                },
                icon: const Icon(Icons.edit_document),
              ),

            // ？？？点击保存时直接存入数据库还是缓存？是否定时10分钟自动保存？保存后是否记录每次修改记录？
            // 试试保存的话，如何确定唯一id，日期+标题吗？
            if (isEditing)
              IconButton(
                onPressed: () async {
                  // ？？？重置是恢复到第一次传过来的手记数据，还是从数据库查询最后一次保存的数据？
                  // 2023-11-27 暂时恢复到上一次修改后的数据(先查询当前编号最新的手记并更新到当前数据中)
                  if (initDiaryId != null) {
                    // 正常来讲这个查询有结果就是一个数据的数组，在helper的时候就这样判断？
                    var temp = await _dbHelper.queryDiaryById(initDiaryId!);

                    // 能查到结果，将其数据格式化显示
                    if (temp.isNotEmpty) {
                      if (!mounted) return;
                      setState(() {
                        initFormatData(temp.first);
                      });
                    }
                  } else {
                    // ？？？如果是新增时的撤销，那就退出当前页面，还是清空已有数据但还是修改状态？？
                    if (!mounted) return;
                    setState(() {
                      // 2023-11-27 暂时先清空已有数据，并保持编辑状态；再点击退出时才手动退出
                      resetInitData();
                    });
                    // Navigator.of(context).pop();
                  }
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
        body: Scrollbar(
          thickness: 10.sp,
          // 设置交互模式后，滚动条和手势滚动方向才一致
          interactive: true,
          radius: Radius.circular(5.sp),
          // 不设置这个，滚动条默认不显示，在滚动时才显示
          thumbVisibility: true,
          // trackVisibility: true,
          // 滚动条默认在右边，要改在左边就配合Transform进行修改(此例没必要)
          // 刻意预留一点空间给滚动条
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(5.sp, 5.sp, 10.sp, 5.sp),
                child: Column(
                  children: [
                    _buildTitleAndTags(),
                    buildRichTextArea(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 标题和标签选择放在一个折叠栏中，方便修改正文时折叠起来能显示更多内容
  _buildTitleAndTags() {
    return Card(
      elevation: 2.sp,
      child: ExpansionTile(
        title: buildTitleArea(),
        tilePadding: EdgeInsets.symmetric(horizontal: 5.sp),
        childrenPadding: EdgeInsets.zero,
        // 2023-12-26 固定白色，在深色主题就看不到字了
        // backgroundColor: Colors.white,
        // 如果是编辑状态，默认展开；否则预览时不展开
        // initiallyExpanded: isEditing ? true : false, // 是否默认展开
        initiallyExpanded: true,
        children: <Widget>[
          FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...buildTagsArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 主体从上到下应该是:标题和各项标签选择折叠框、富文本工具框折叠框、富文本编辑器。
  /// 当在预览时，只有：标题、标签、富文本编辑器，都是只读
  buildTitleArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: TextField(
            controller: _titleTextController,
            readOnly: !isEditing,
            maxLines: !isEditing ? 1 : 2,
            // 预览时居中，编辑时靠左
            textAlign: isEditing ? TextAlign.start : TextAlign.center,
            decoration: InputDecoration(
              hintText: CusAL.of(context).diaryTitleNote,
              contentPadding: EdgeInsets.symmetric(vertical: 2.sp),
              // 预览时不显示边框
              border: isEditing
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.sp),
                    )
                  : InputBorder.none,
              // 设置透明底色
              filled: true,
              fillColor: Colors.transparent,
            ),
            onChanged: (value) {
              setState(() {
                initTitle = value;
              });
            },
          ),
        ),
      ],
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
          spacing: 5.sp,
          children: [
            ...initTags.map((tag) {
              return buildSmallButtonTag(
                tag,
                bgColor: CusColors.tagTinyTagBg,
                labelTextSize: CusFontSizes.flagTiny,
              );
            }),
            ...initMoods.map((mood) {
              return buildSmallButtonTag(
                mood,
                bgColor: CusColors.moodTinyTagBg,
                labelTextSize: CusFontSizes.flagTiny,
              );
            }),
            buildSmallButtonTag(
              initCategory,
              bgColor: CusColors.cateTinyTagBg,
              labelTextSize: CusFontSizes.flagTiny,
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
        "分类",
        "category",
        _categoryChipOptions(),
        initialValue: initCategory,
        onChanged: (value) {
          setState(() {
            initCategory = value;
          });
        },
      ),
      // 这个可以多选，表现类似 checkbox
      _buildMultiSelectRow(
        "心情",
        "mood",
        _moodChipOptions(),
        initialValue: initMoods,
        onChanged: (value) {
          setState(() {
            initMoods = value?.map((v) => v.toString()).toList() ?? [];
          });
        },
      ),

      // 手动输入标签，逗号和分号自动切分
      _buildInputTagsArea(),
    ];
  }

  // 富文本编辑预览区域
  buildRichTextArea() {
    return GestureDetector(
      onTap: () {
        /// 不这样手动跳转，编辑时焦点可能会冲突
        // 清除textField的文本框焦点
        tagTextFocusNode.unfocus();
        titleTextFocusNode.unfocus();
        // 设置焦点到quillEditor
        FocusScope.of(context).requestFocus(quillFocusNode);
      },
      child: SizedBox(
        // 2023-11-27 实测富文本工具栏展开时该Card高度为242,折叠时66，
        // 所以展开时这个外层box加一个176让编辑区域显示高度一致。

        // 默认的0.75sh，是(状态栏+appbar+标题折叠后)大概480, 剩下高度(1-480/1920)=0.75.
        // 所以实际使用时，可以大概在(1.sh-480/1.sh)=>？？？但实际显示不太对，不是这样算的？？？
        height: isQuillToolbarExpanded ? (0.75.sh + 176.sp) : 0.75.sh,
        width: 1.sw,
        child: Column(
          children: [
            // 在编辑状态下才显示工具栏
            if (isEditing)
              Card(
                elevation: 2.sp,
                child: ExpansionTile(
                  title: Text(CusAL.of(context).richTextToolNote),
                  leading: const Icon(Icons.tag, color: Colors.green),
                  // 2023-12-26 固定白色，在深色主题就看不到字了
                  // backgroundColor: Colors.white,
                  initiallyExpanded: isQuillToolbarExpanded, // 是否默认展开
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      isQuillToolbarExpanded = isExpanded;
                    });
                  },
                  children: <Widget>[
                    // 如果工具栏简单点就这样

                    SizedBox(
                      width: 1.sw,
                      child: QuillToolbar.simple(
                        controller: _controller,
                        configurations: const QuillSimpleToolbarConfigurations(
                            // 这几个默认没开启
                            // showSmallButton: true,
                            // showAlignmentButtons: true,
                            // showDirection: true,
                            ),
                      ),
                    ),

                    /// 使用自定义工具栏的话，那些功能需要自己添加。
                    // 比如要嵌入：视频、图片、摄像头、多媒体，需要自己指定
                    // 具体参看 https://github.com/singerdmx/flutter-quill/blob/master/example/lib/screens/quill/my_quill_toolbar.dart#L103
                    // 我这里只保留多媒体文件的几个
                    QuillToolbar(
                      configurations: QuillToolbarConfigurations(
                        sharedConfigurations: QuillSharedConfigurations(
                          locale: box.read('language') == 'system'
                              ? null
                              : Locale(box.read('language')),
                        ),
                      ),
                      child: QuillToolbar(
                        configurations: const QuillToolbarConfigurations(),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                            children: [
                              QuillToolbarImageButton(
                                controller: _controller,
                              ),
                              QuillToolbarCameraButton(
                                controller: _controller,
                              ),
                              QuillToolbarVideoButton(
                                controller: _controller,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 编辑框
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(5.sp),
                child: DecoratedBox(
                  // 边框在编辑时显示灰色，预览时显示透明(假装没有)
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isEditing ? Colors.grey : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(8.sp),
                    // 2023-12-26 固定白色，在深色主题就看不到字了
                    // color: Colors.white,
                  ),
                  child: QuillEditor.basic(
                    focusNode: quillFocusNode,
                    controller: _controller,
                    configurations: QuillEditorConfigurations(
                      autoFocus: false,
                      scrollable: true,
                      expands: true,
                      padding: EdgeInsets.all(5.sp),
                      embedBuilders: kIsWeb
                          ? FlutterQuillEmbeds.editorWebBuilders()
                          : FlutterQuillEmbeds.editorBuilders(),
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

  // 这些选项都是FormBuilderChipOption类型
  List<FormBuilderChipOption<String>> _categoryChipOptions() {
    return diaryCategoryList
        .map(
          (e) => FormBuilderChipOption(value: showCusLableMapLabel(context, e)),
        )
        .toList();
  }

  List<FormBuilderChipOption<String>> _moodChipOptions() {
    return diaryMoodList
        .map(
          (e) => FormBuilderChipOption(value: showCusLableMapLabel(context, e)),
        )
        .toList();
  }

  // 心情多选行
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
            decoration: const InputDecoration(
              // 设置透明底色
              filled: true,
              fillColor: Colors.transparent,
            ),
            name: name,
            initialValue: initialValue,
            // 选项列表
            options: options,
            // 标签被选中时的颜色
            selectedColor: Colors.blue,
            // 不显示选中图标
            showCheckmark: false,
            // 选项列表中文字样式
            labelStyle: TextStyle(
              fontSize: CusFontSizes.flagTiny,
              fontWeight: FontWeight.w500,
            ),
            // 标签的内边距
            labelPadding: EdgeInsets.all(1.sp),
            // // 设置标签的形状样式(四个圆角为5的方形,默认是圆形)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1.sp),
              // 边框是宽度为1的灰色
              // side: BorderSide(color: Colors.grey, width: 1.sp),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // 分类单选行
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
            decoration: const InputDecoration(
              // 设置透明底色
              filled: true,
              fillColor: Colors.transparent,
            ),
            name: name,
            initialValue: initialValue,
            // 选项列表
            options: options,
            // 标签被选中时的颜色
            selectedColor: Colors.blue,
            // 选项列表中文字样式
            labelStyle: TextStyle(
              fontSize: CusFontSizes.flagTiny,
              fontWeight: FontWeight.w500,
            ),
            // 标签的内边距
            labelPadding: EdgeInsets.all(1.sp),
            // 设置标签的形状样式(四个圆角为5的方形,默认是圆形)
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
            focusNode: tagTextFocusNode,
            controller: _tagTextController,
            readOnly: !isEditing,
            decoration: InputDecoration(
              hintText: CusAL.of(context).diaryTagsNote,
              contentPadding: EdgeInsets.symmetric(vertical: 2.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.sp),
              ),
              // 设置透明底色
              filled: true,
              fillColor: Colors.transparent,
            ),
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
          spacing: 8.sp,
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

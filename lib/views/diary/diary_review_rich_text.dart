import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../models/diary_state.dart';

///
/// 暂时没用，预览和修改都在modify rich text 组件中
///
class DiaryReviewRichText extends StatefulWidget {
// 传入的手记数据
  final Diary diaryItem;
  const DiaryReviewRichText({super.key, required this.diaryItem});

  @override
  State<DiaryReviewRichText> createState() => _DiaryReviewRichTextState();
}

class _DiaryReviewRichTextState extends State<DiaryReviewRichText> {
  final QuillController _controller = QuillController.basic();

  @override
  void initState() {
    super.initState();

    setState(() {
      // ？？？这里应该考虑转型失败的问题
      var diaryContent = json.decode(widget.diaryItem.content);
      _controller.document = Document.fromJson(diaryContent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich Text Preview'),
      ),
      body: SingleChildScrollView(
        child: QuillProvider(
          configurations: QuillConfigurations(
            controller: _controller,
            sharedConfigurations: const QuillSharedConfigurations(
              locale: Locale('zh', 'CN'),
            ),
          ),
          child: QuillEditor.basic(
            configurations: const QuillEditorConfigurations(
              readOnly: true,
              scrollable: true,
            ),
          ),
        ),
      ),
    );
  }
}

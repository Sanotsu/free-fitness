import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/constants.dart';
import '../../../../models/ai/ai_ui_message.dart';

/// 2026-08-27 AI 消息气泡(自 dietary/ai_suggestion/widgets/message_item.dart 迁移泛化)
///
/// 相比旧版新增：
/// - user 消息支持多图(≤4张)网格显示，点击全屏预览；
/// - assistant 气泡底部小字显示模型快照与状态(已终止/出错)；
class MessageItem extends StatelessWidget {
  final AiUiMessage message;
  // 流式响应时，数据是逐步增加的，如果还在响应中加个加载圈
  final bool? isBotThinking;

  const MessageItem({
    super.key,
    required this.message,
    this.isBotThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    // 根据是否是用户输入调整文本内容布局
    bool isFromUser = message.isFromUser;

    // 如果是用户输入，头像显示在右边
    CrossAxisAlignment crossAlignment = isFromUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    // 所有的文字颜色，暂定用户蓝色AI黑色
    Color textColor = isFromUser ? Colors.blue : Theme.of(context).hintColor;

    // 上游(聊天页)已统一传入绝对路径(新发送的图与历史图都经过 ai_images 根目录拼接)
    var imageAbsPaths = message.imageLocalPaths;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像，展示机器和用户用于区分即可
        // 如果是AI回复的，头像在前面；用户发的，头像在Row最后面
        if (!isFromUser)
          CircleAvatar(
            radius: 18.sp,
            backgroundColor: Colors.grey,
            child: const Icon(Icons.code),
          ),
        SizedBox(width: 3.sp), // 头像和文本之间的间距
        // 消息内容
        Expanded(
          child: Column(
            crossAxisAlignment: crossAlignment,
            children: [
              // 时间戳
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.sp),
                child: Text(
                  DateFormat(constDatetimeFormat).format(message.dateTime),
                  style: TextStyle(fontSize: 12.sp, color: textColor),
                ),
              ),

              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(5.sp),

                  /// 根据markdown格式化显示内容
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 用户消息的图片网格(点击全屏预览)
                        if (imageAbsPaths.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 5.sp),
                              child: Wrap(
                                spacing: 5.sp,
                                runSpacing: 5.sp,
                                children: imageAbsPaths
                                    .map((p) => _buildImageThumb(context, p))
                                    .toList(),
                              ),
                            ),
                          ),

                        // 显示推理内容
                        if (message.reasoningContent != null &&
                            message.reasoningContent!.isNotEmpty)
                          _buildThinkingProcess(),

                        // 显示对话正文内容
                        GptMarkdown(
                          message.content,
                          style: TextStyle(color: textColor),
                        ),
                        // 如果是流式加载中，显示一个加载圈
                        if (message.role != "user" && isBotThinking == true)
                          SizedBox(
                            width: 16.sp,
                            height: 16.sp,
                            child: CircularProgressIndicator(strokeWidth: 2.sp),
                          ),

                        // assistant 消息的模型快照与状态小字
                        if (message.role == "assistant" && !isFromUser)
                          _buildModelFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 如果是用户发的，头像在Row最后面
        if (isFromUser)
          CircleAvatar(
            radius: 18.sp,
            backgroundColor: Colors.lightBlue,
            child: const Icon(Icons.person),
          ),
      ],
    );
  }

  // 图片缩略图(点击弹窗全屏预览)
  Widget _buildImageThumb(BuildContext context, String path) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Image.file(
                File(path),
                errorBuilder: (_, _, _) =>
                    Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown),
              ),
            );
          },
        );
      },
      child: Image.file(
        File(path),
        width: 64.sp,
        height: 64.sp,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          placeholderImageUrl,
          width: 64.sp,
          height: 64.sp,
          fit: BoxFit.scaleDown,
        ),
      ),
    );
  }

  // assistant 气泡底部：模型快照 + 状态标识
  Widget _buildModelFooter() {
    var isEn = box.read('language') == 'en';

    var statusLabel = switch (message.status) {
      'aborted' => isEn ? ' · aborted' : ' · 已终止',
      'error' => isEn ? ' · error' : ' · 出错',
      _ => '',
    };

    if ((message.modelName ?? '').isEmpty && statusLabel.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 3.sp),
      child: Text(
        "${message.modelName ?? ''}$statusLabel",
        style: TextStyle(fontSize: 10.sp, color: Colors.grey),
      ),
    );
  }

  // DS 的 R 系列有深度思考部分，单独展示
  Widget _buildThinkingProcess() {
    final thinkingColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          message.content.trim().isEmpty ? '思考中' : '已深度思考',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24),
            // 使用RepaintBoundary渲染深度思考内容，利用缓存机制提高性能
            child: RepaintBoundary(
              child: GptMarkdown(
                message.reasoningContent!,
                style: TextStyle(color: thinkingColor, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../../common/global/constants.dart';
import '../../../../../models/paid_llm/llm_chat.dart';

class MessageItem extends StatelessWidget {
  final ChatMessage message;

  const MessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // 根据是否是用户输入跳转文本内容布局
    bool isFromUser = message.role == 'user';

    // 如果是用户输入，头像显示在右边
    CrossAxisAlignment crossAlignment =
        isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    // 所有的文字颜色，暂定用户蓝色AI黑色
    // Color textColor = isFromUser ? Colors.blue : Colors.black;
    Color textColor = isFromUser ? Colors.blue : Theme.of(context).hintColor;

    /// 这里暂时不考虑外边框的距离，使用时在外面加padding之类的
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像，展示机器和用户用于区分即可
        // 如果是AI回复的，头像在前面；用户发的，头像在Row最后面
        if (!isFromUser)
          CircleAvatar(
            radius: 18.sp,
            backgroundColor: Colors.grey,
            child: const Icon(Icons.code), // Icons.bolt/lightbulb
          ),
        SizedBox(width: 3.sp), // 头像和文本之间的间距
        // 消息内容
        Expanded(
          child: Column(
            crossAxisAlignment: crossAlignment,
            children: [
              // 这里可以根据需要添加时间戳等
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.sp),
                child: Text(
                  DateFormat(constDatetimeFormat).format(message.dateTime),
                  // 根据来源设置不同颜色
                  style: TextStyle(fontSize: 12.sp, color: textColor),
                ),
              ),
              // 如果是占位的消息，则显示装圈圈
              if (message.isPlaceholder == true)
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(5.sp),
                    child: Row(
                      crossAxisAlignment: crossAlignment,
                      children: [
                        Text(
                          message.content,
                          style: const TextStyle(color: Colors.black),
                        ),
                        SizedBox(
                          height: 20.sp,
                          width: 20.sp,
                          child: const CircularProgressIndicator(),
                        ),
                      ],
                    ),
                  ),
                ),

              // 如果不是占位的消息，则正常显示
              if (message.isPlaceholder != true)
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(5.sp),

                    /// 这里考虑根据 格式等格式化显示内容
                    child: SingleChildScrollView(
                      child: MarkdownBody(
                        data: message.content,
                        selectable: true,
                        // 设置Markdown文本全局样式
                        styleSheet: MarkdownStyleSheet(
                          // 普通段落文本颜色(假定用户输入就是普通段落文本)
                          p: TextStyle(color: textColor),
                          // ... 其他级别的标题样式
                          // 可以继续添加更多Markdown元素的样式
                        ),
                      ),
                      // Text(
                      //   message.text,
                      //   // 根据来源设置不同颜色
                      //   style: TextStyle(color: textColor),
                      // ),
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
}

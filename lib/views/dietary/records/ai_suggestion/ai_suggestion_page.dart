// ignore_for_file: avoid_print,

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/paid_llm/common_chat_model_spec.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/paid_llm_apis.dart';
import '../../../../common/global/constants.dart';
import '../../../../models/paid_llm/common_chat_completion_state.dart';
import '../../../../models/paid_llm/llm_chat.dart';
import 'widgets/message_item.dart';

class OneChatScreen extends StatefulWidget {
  final String intakeInfo;
  const OneChatScreen({super.key, required this.intakeInfo});

  @override
  State createState() => _OneChatScreenState();
}

class _OneChatScreenState extends State<OneChatScreen> {
  // 人机对话消息滚动列表
  final ScrollController _scrollController = ScrollController();

  // 用户输入的文本控制器
  final TextEditingController _userInputController = TextEditingController();
  // 用户输入的内容（当不是AI在思考、且输入框有非空文字时才可以点击发送按钮）
  String userInput = "";

  // AI是否在思考中(如果是，则不允许再次发送)
  bool isBotThinking = false;

  /// 2024-06-11 默认使用流式请求，更快;但是同样的问题，流式使用的token会比非流式更多
  /// 2024-06-15 限时限量的可能都是收费的，本来就慢，所以默认就流式，不用切换
  /// 2024-06-20 流式使用的token太多了，还是默认更省的
  bool isStream = false;

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  List<ChatMessage> messages = [
    // 预设第一个role为system，指定系统角色
    ChatMessage(
      messageId: const Uuid().v4(),
      content: "你是一名资深且优秀的营养学、健康学、养生学专家。",
      role: "system",
      dateTime: DateTime.now(),
      isPlaceholder: false,
    ),
  ];

  // 等待AI响应时的占位的消息，在构建真实对话的list时要删除
  var placeholderMessage = ChatMessage(
    messageId: "placeholderMessage",
    content: "努力思考中(等待越久,回复内容越多)  ",
    role: "assistant",
    dateTime: DateTime.now(),
    isPlaceholder: true,
  );

  @override
  void initState() {
    super.initState();

    // 这是在表单初始化之后再提问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendMessage(widget.intakeInfo);
    });
  }

  // 这个发送消息实际是将对话文本添加到对话列表中
  // 但是在用户发送消息之后，需要等到AI响应，成功响应之后将响应加入对话中
  _sendMessage(String text, {String role = "user", CCUsage? usage}) {
    // 发送消息的逻辑，这里只是简单地将消息添加到列表中
    var temp = ChatMessage(
      messageId: const Uuid().v4(),
      content: text,
      role: role,
      dateTime: DateTime.now(),
      promptTokens: usage?.promptTokens, // prompt 使用的token数(输入)
      completionTokens: usage?.completionTokens, // 内容生成的token数(输出)
      totalTokens: usage?.totalTokens,
    );

    setState(() {
      // AI思考和用户输入是相反的(如果角色是用户，那就是在等到机器回复了)
      isBotThinking = (role == "user");

      messages.add(temp);

      _userInputController.clear();
      // 滚动到ListView的底部
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );

      // 如果是用户发送了消息，则开始等到AI响应(如果不是用户提问，则不会去调用接口)
      if (role == "user") {
        // 如果是用户输入时，在列表中添加一个占位的消息，以便思考时的装圈和已加载的消息可以放到同一个list进行滑动
        // 一定注意要记得AI响应后要删除此占位的消息
        placeholderMessage.dateTime = DateTime.now();
        messages.add(placeholderMessage);

        // 获取大模型应答
        _getLlmResponse();
      }
    });
  }

  // 根据不同的平台、选中的不同模型，调用对应的接口，得到回复
  // 虽然返回的响应通用了，但不同的平台和模型实际取值还是没有抽出来的
  _getLlmResponse() async {
    // 将已有的消息处理成Ernie支出的消息列表格式(构建查询条件时要删除占位的消息)
    List<CCMessage> msgs = messages
        .where((e) => e.isPlaceholder != true)
        .map((e) => CCMessage(
              content: e.content,
              role: e.role,
            ))
        .toList();

    // 等待请求响应
    // 这里一定要确保存在模型名称，因为要作为http请求参数
    List<CCRespBody> temp = await getChatResp(
      ApiPlatform.lingyiwanwu,
      msgs,
      model: ccmSpecList[CCM.YiSpark]!.model,
    );

    // 得到回复后要删除表示加载中的占位消息
    setState(() {
      messages.removeWhere((e) => e.isPlaceholder == true);
    });

    // 得到AI回复之后，添加到列表中，也注明不是用户提问
    var tempText = temp.map((e) => e.customReplyText).join();
    if (temp.isNotEmpty && temp.first.error?.code != null) {
      tempText = """接口报错，请检查网络或稍后重试:
\ncode: ${temp.first.error?.code} 
\ntype: ${temp.first.error?.type} 
\nmessage: ${temp.first.error?.message}
""";
    }

    // 每次对话的结果流式返回，所以是个列表，就需要累加起来
    int inputTokens = 0;
    int outputTokens = 0;
    int totalTokens = 0;
    for (var e in temp) {
      inputTokens += e.usage?.promptTokens ?? 0;
      outputTokens += e.usage?.completionTokens ?? 0;
      totalTokens += e.usage?.totalTokens ?? 0;
    }
    // 里面的promptTokens和completionTokens是百度这个特立独行的，在上面拼到一起了
    var a = CCUsage(
      promptTokens: inputTokens,
      completionTokens: outputTokens,
      totalTokens: totalTokens,
    );

    _sendMessage(tempText, role: "assistant", usage: a);
  }

  /// 最后一条大模型回复如果不满意，可以重新生成(中间的不行，因为后续的问题是关联上下文的)
  /// 2024-06-20 限量的要计算token数量，所以不让重新生成(？？？但实际也没做累加的token的逻辑)
  regenerateLatestQuestion() {
    setState(() {
      // 将最后一条消息删除，并添加占位消息，重新发送
      messages.removeLast();
      placeholderMessage.dateTime = DateTime.now();
      messages.add(placeholderMessage);

      _getLlmResponse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          box.read('language') == "en"
              ? "AI Dietary Health Analysis"
              : '问答式饮食健康分析',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 显示对话消息主体
            buildChatListArea(),

            /// 显示输入框和发送按钮
            const Divider(),
            buildUserSendArea(),
          ],
        ),
      ),
    );
  }

  /// 构建对话列表主体
  buildChatListArea() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController, // 设置ScrollController
        // reverse: true, // 反转列表，使新消息出现在底部
        itemCount: messages.length,
        itemBuilder: (context, index) {
          // 构建MessageItem
          return Padding(
            padding: EdgeInsets.all(5.sp),
            child: Column(
              children: [
                // 如果是最后一个回复的文本，使用打字机特效
                // if (index == messages.length - 1)
                //   TypewriterText(text: messages[index].text),

                // 如果是预设的system信息，则不显示
                if (messages[index].role != "system")
                  MessageItem(message: messages[index]),

                // 如果是大模型回复，可以有一些功能按钮
                if (messages[index].role == "assistant")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 其中，是大模型最后一条回复，则可以重新生成
                      // 注意，还要排除占位消息
                      if ((index == messages.length - 1) &&
                          messages[index].isPlaceholder != true)
                        TextButton(
                          onPressed: () {
                            regenerateLatestQuestion();
                          },
                          child: const Text("重新生成"),
                        ),
                      //
                      // 如果不是等待响应才可以点击复制该条回复
                      if (messages[index].isPlaceholder != true)
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: messages[index].content),
                            );

                            EasyLoading.showToast(
                              "已复制到剪贴板",
                              duration: const Duration(seconds: 3),
                              toastPosition: EasyLoadingToastPosition.center,
                            );
                          },
                          icon: Icon(Icons.copy, size: 20.sp),
                        ),
                      // 如果不是等待响应才显示token数量
                      if (messages[index].isPlaceholder != true)
                        Text(
                          "tokens 输入:${messages[index].promptTokens} 输出:${messages[index].completionTokens} 总计:${messages[index].totalTokens}",
                          style: TextStyle(fontSize: 10.sp),
                        ),
                      SizedBox(width: 10.sp),
                    ],
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  /// 用户发送消息的区域
  buildUserSendArea() {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _userInputController,
              decoration: InputDecoration(
                hintText: '可以向我提问，获取健康饮食相关建议',
                hintStyle: TextStyle(fontSize: 15.sp, color: Colors.grey),
                border: const OutlineInputBorder(), // 添加边框
              ),
              maxLines: 5,
              minLines: 1,
              onChanged: (String? text) {
                if (text != null) {
                  setState(() {
                    userInput = text.trim();
                  });
                }
              },
            ),
          ),
          IconButton(
            // 如果AI正在响应，或者输入框没有任何文字，不让点击发送
            onPressed: isBotThinking || userInput.isEmpty
                ? null
                : () {
                    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
                    FocusScope.of(context).unfocus();

                    // 用户发送消息
                    _sendMessage(userInput);

                    // 发送完要清空记录用户输的入变量
                    setState(() {
                      userInput = "";
                    });
                  },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

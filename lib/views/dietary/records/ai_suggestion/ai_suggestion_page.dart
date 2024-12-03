import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/paid_llm/common_chat_model_spec.dart';
import 'package:uuid/uuid.dart';

import '../../../../apis/paid_llm_apis.dart';
import '../../../../common/components/dialog_widgets.dart';
import '../../../../common/global/constants.dart';
import '../../../../common/utils/tool_widgets.dart';
import '../../../../models/cus_app_localizations.dart';
import '../../../../models/paid_llm/common_chat_completion_state.dart';
import '../../../../models/paid_llm/llm_chat.dart';
import 'widgets/message_item.dart';

class OneChatScreen extends StatefulWidget {
  // 初始的对话提示词(如果是营养摄入时点击，则只有这个)
  final String intakeInfo;
  // 如果是在餐次相册中分析指定图片，则除了提示词，还需要图片
  // 因为这里还需要展示图片，所以传入图片地址即可
  final String? imageUrl;

  const OneChatScreen({super.key, required this.intakeInfo, this.imageUrl});

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

  // 默认进入对话页面应该就是啥都没有，然后根据这空来显示预设对话
  // 2024-12-03 不再需要占位的，是因为请求中时 http 客户端有加载中弹窗
  List<ChatMessage> messages = [
    // 预设第一个role为system，指定系统角色
    ChatMessage(
      messageId: const Uuid().v4(),
      content: box.read('language') == "en"
          ? "You are a senior and excellent expert in nutrition, health, and wellness."
          : "你是一名资深且优秀的营养学、健康学、养生学专家。",
      role: "system",
      dateTime: DateTime.now(),
    ),
  ];

  // 如果是图片分析，还需要传入参数，图片base64
  String? imageBase64String;
  // 图像理解就第一次需要传图片
  bool? isFirstSendImage;

  // 2024-12-03 虽然暂时有这个设定，但没有切换的地方。所以总是流式响应
  bool isStream = true;

  // 当前正在响应的api返回流(放在全局为了可以手动取消)
  StreamWithCancel<CCRespBody> respStream = StreamWithCancel.empty();

  @override
  void initState() {
    super.initState();

    // 这是在表单初始化之后再提问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initSend();
    });
  }

  // 2024-07-12 如果是餐次相册的图片分析，那么进入这个页面需要先处理图片数据
  initSend() async {
    if (widget.imageUrl != null) {
      var selectedImage = File(widget.imageUrl!);
      try {
        // 可能会出现不存在的图片路径，那边这里转base64就会报错，那么就返回上一页了
        var tempBase64Str = base64Encode((await selectedImage.readAsBytes()));

        if (!mounted) return;
        setState(() {
          imageBase64String = "data:image/jpeg;base64,$tempBase64Str";

          // 初始化时设定需要发送图片
          isFirstSendImage = true;
          _sendMessage(widget.intakeInfo);
          // 初始化提交之后，就不再发送图片了
          isFirstSendImage = false;
        });
      } catch (e) {
        // 图片数据不能转base64,就弹窗提示，并返回上一页
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                box.read('language') == "en" ? "Exception" : "异常提示",
              ),
              content: Text(
                e.toString(),
                style: TextStyle(fontSize: 15.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(box.read('language') == "en" ? "confirm" : "确认"),
                ),
              ],
            );
          },
        ).then((value) {
          if (!mounted) return;
          Navigator.of(context).pop();
        });
      }
    } else {
      _sendMessage(widget.intakeInfo);
    }
  }

  // 在用户输入或者AI响应后，需要把对话列表滚动到最下面
  // 调用时放在状态改变函数中
  chatListScrollToBottom() {
    // 每收到一点新的响应文本，就都滚动到ListView的底部
    // 注意：ai响应的消息卡片下方还有一行功能按钮，这里滚动了那个还没显示的话是看不到的
    // 所以滚动到最大还加一点高度（大于实际功能按钮高度也没问题）
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      curve: Curves.easeOut,
      // 注意：sse的间隔比较短，这个滚动也要快一点
      duration: const Duration(milliseconds: 50),
    );
  }

  // 2024-12-02 改为仅用户可以发送消息，AI响应直接在响应函数中处理
  _sendMessage(String text, {CCUsage? usage}) {
    setState(() {
      messages.add(ChatMessage(
        messageId: const Uuid().v4(),
        content: text,
        role: "user",
        dateTime: DateTime.now(),
        promptTokens: usage?.promptTokens, // prompt 使用的token数(输入)
        completionTokens: usage?.completionTokens, // 内容生成的token数(输出)
        totalTokens: usage?.totalTokens,
      ));

      _userInputController.clear();
      // 滚动到ListView的底部
      chatListScrollToBottom();

      // 获取大模型应答
      _getLlmResponse();
    });
  }

  // 得到模型响应
  _getLlmResponse() async {
    // 在调用前，不会设置响应状态
    if (isBotThinking) return;
    setState(() {
      isBotThinking = true;
    });

    // 将已有的消息处理成支持的消息列表格式(构建查询条件时要删除占位的消息)
    List<CCMessage> msgs = messages
        .map((e) => CCMessage(content: e.content, role: e.role))
        .toList();

    // 如果是图片，图片要单独处理下
    if (imageBase64String != null) {
      msgs = messages
          .map((e) => CCMessage(
                content: (e.role == "assistant" || e.role == "system")
                    ? e.content
                    : isFirstSendImage == true
                        ? [
                            {
                              "type": "image_url",
                              "image_url": {"url": imageBase64String}
                            },
                            {"type": "text", "text": e.content},
                          ]
                        : [
                            {"type": "text", "text": e.content}
                          ],
                role: e.role,
              ))
          .toList();
    }

    // 流式响应处理
    StreamWithCancel<CCRespBody> stream;
    if (imageBase64String != null) {
      stream = await getChatRespStream(
        ApiPlatform.lingyiwanwu,
        msgs,
        model: ccmSpecList[CCM.YiVision]!.model,
        stream: isStream,
      );
    } else {
      stream = await getChatRespStream(
        ApiPlatform.lingyiwanwu,
        msgs,
        model: ccmSpecList[CCM.YiSpark]!.model,
        stream: isStream,
      );
    }

    // 保存流以便可以取消
    if (!mounted) return;
    setState(() {
      respStream = stream;
    });

    ChatMessage? csMsg = ChatMessage(
      messageId: const Uuid().v4(),
      role: "assistant",
      content: "",
      dateTime: DateTime.now(),
    );

    setState(() {
      messages.add(csMsg!);
    });

    respStream.stream.listen(
      (crb) {
        // 如果返回了[DONE]，则表示响应结束
        if ((crb.customReplyText ?? "").contains('[DONE]')) {
          setState(() {
            csMsg = null;
            isBotThinking = false;
          });
        } else {
          // 为了每次有消息都能更新页面状态
          setState(() {
            isBotThinking = true;
          });

          // 更新响应文本
          // 2024-11-04 讯飞星火，虽然成功返回，还是会有message栏位，其他的是出错了才有该栏位
          // 所以需要判断该errorMsg的值
          if ((crb.error != null)) {
            csMsg?.content += """后台响应报错:
          \n\n错误代码: ${crb.error?.code}
          \n\n错误原因: ${crb.error?.message}
          """;

            if (!mounted) return;
            setState(() {
              csMsg = null;
              isBotThinking = false;
            });
          } else {
            csMsg?.content += crb.customReplyText ?? "";
          }

          // 更新token信息
          csMsg?.promptTokens = (crb.usage?.promptTokens ?? 0);
          csMsg?.completionTokens = (crb.usage?.completionTokens ?? 0);
          csMsg?.totalTokens = (crb.usage?.totalTokens ?? 0);

          chatListScrollToBottom();
        }
      },
      onDone: () {
        // 如果是流式响应，最后一条会带有[DNOE]关键字，所以在上面处理最后响应结束的操作
        // 如果不是流式，响应流就只有1条数据，那么就只有在这里才能得到流结束了，所以需要在这里完成后的操作
        // 但是如果是流式，还在这里处理结束操作的话会出问题(实测在数据还在推送的时候，这个ondone就触发了)
        if (!isStream) {
          if (!mounted) return;
          // 流式响应结束了，就保存数据到db，并重置流式变量和aip响应标志
          setState(() {
            csMsg = null;
            isBotThinking = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;
        commonExceptionDialog(context, "异常提示", error.toString());
      },
    );
  }

  /// 最后一条大模型回复如果不满意，可以重新生成(中间的不行，因为后续的问题是关联上下文的)
  /// 2024-06-20 限量的要计算token数量，所以不让重新生成(？？？但实际也没做累加的token的逻辑)
  regenerateLatestQuestion() {
    setState(() {
      // 将最后一条消息删除，并添加占位消息，重新发送
      messages.removeLast();

      // 2024-12-03 如果删除最后一条，消息列表只剩2条了(system和user)，
      // 那表明其实是初始化的提问，需要带上图片
      if (messages.length <= 2) {
        messages.clear();
        initSend();
      } else {
        _getLlmResponse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          CusAL.of(context).aiSuggestionTitle,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        // 允许子控件（如TextField）接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          unfocusHandle();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 如果是图片分析，在顶部展示图片
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: SizedBox(
                    width: 100.sp,
                    child: buildImageCarouselSlider([widget.imageUrl!]),
                  ),
                ),
              ),

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
                // 如果是预设的system信息，则不显示
                if (messages[index].role != "system")
                  MessageItem(
                    message: messages[index],
                    // 只有最后一个才显示圈圈
                    isBotThinking:
                        index == messages.length - 1 ? isBotThinking : false,
                  ),

                // 如果是大模型回复且回复完了，可以有一些功能按钮
                if (messages[index].role == "assistant" &&
                    isBotThinking != true)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 其中，是大模型最后一条回复，则可以重新生成
                      // 注意，还要排除占位消息
                      if ((index == messages.length - 1))
                        TextButton(
                          onPressed: () {
                            regenerateLatestQuestion();
                          },
                          child: Text(CusAL.of(context).regeneration),
                        ),
                      //

                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: messages[index].content),
                          );

                          EasyLoading.showToast(
                            CusAL.of(context).copiedHint,
                            duration: const Duration(seconds: 3),
                            toastPosition: EasyLoadingToastPosition.center,
                          );
                        },
                        icon: Icon(Icons.copy, size: 20.sp),
                      ),

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
                hintText: CusAL.of(context).aiSuggestionHint,
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

          // 如果是API响应中，可以点击终止
          isBotThinking
              ? IconButton(
                  onPressed: () async {
                    await respStream.cancel();
                    if (!mounted) return;
                    setState(() {
                      _userInputController.clear();
                      chatListScrollToBottom();
                      isBotThinking = false;
                    });
                  },
                  icon: const Icon(Icons.stop),
                )
              : IconButton(
                  // 如果AI正在响应，或者输入框没有任何文字，不让点击发送
                  onPressed: isBotThinking || userInput.isEmpty
                      ? null
                      : () {
                          // 失去焦点，从而收起键盘。
                          unfocusHandle();

                          // 用户发送消息
                          _sendMessage(userInput);

                          // 发送完要清空记录用户输的入变量
                          if (!mounted) return;
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

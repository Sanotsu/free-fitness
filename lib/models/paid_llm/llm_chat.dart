import 'dart:convert';

import 'package:intl/intl.dart';

import '../../common/global/constants.dart';

///
/// 用于构建对话列表的“对话信息类”
/// 尽量和大模型API返回的栏位一致
///
class ChatMessage {
  final String messageId; // 每个消息有个ID方便整个对话列表的保存？？？
  DateTime dateTime; // 时间
  // 之前是 isFromUser 是否来自用户，但角色有3种：system、user、assistant
  // 所以改判断，role!=user就不是来自用户
  final String role;
  final String content; // 文本内容
  // 有可能对话存在输入图片(假如后续一个用户对话中存在图片切来切去，就最后每个问答来回都存上图片)
  final String? imageUrl;
  final bool? isPlaceholder; // 是否是等待响应时的占位消息
  /// 2024-06-15 限时限量有token限制，所以存放每次对话的token消耗
  final int? promptTokens; // 输入的token数
  final int? completionTokens; // 输出的token数
  final int? totalTokens;

  ChatMessage({
    required this.messageId,
    required this.dateTime,
    required this.role,
    required this.content,
    this.imageUrl,
    this.isPlaceholder,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'date_time': dateTime,
      'role': role,
      'content': content,
      'image_url': imageUrl,
      'is_placeholder': isPlaceholder,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_tokens': totalTokens,
    };
  }

// fromMap 一般是数据库读取时用到
// fromJson 一般是从接口或者其他文本转换时用到
//    2024-06-03 使用parse而不是tryParse就可能会因为格式不对抛出异常
//    但是存入数据不对就是逻辑实现哪里出了问题。使用后者默认值也不知道该使用哪个。
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['message_id'] as String,
      dateTime: DateTime.tryParse(map['date_time']) ?? DateTime.now(),
      role: map['role'] as String,
      content: map['content'] as String,
      imageUrl: map['image_url'] as String?,
      isPlaceholder: bool.tryParse(map['is_placeholder']),
      promptTokens: int.tryParse(map['prompt_tokens']),
      completionTokens: int.tryParse(map['completion_tokens']),
      totalTokens: int.tryParse(map['total_tokens']),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        messageId: json["message_id"],
        dateTime: DateTime.parse(json["date_time"]),
        role: json["role"],
        content: json["content"],
        imageUrl: json["image_url"],
        isPlaceholder: bool.tryParse(json["is_placeholder"]),
        promptTokens: int.tryParse(json["prompt_tokens"]),
        completionTokens: int.tryParse(json["completion_tokens"]),
        totalTokens: int.tryParse(json["total_tokens"]),
      );

  Map<String, dynamic> toJson() => {
        "message_id": messageId,
        "date_time": dateTime,
        "role": role,
        "content": content,
        "image_url": imageUrl,
        "is_placeholder": isPlaceholder,
        "prompt_tokens": promptTokens,
        "completion_tokens": completionTokens,
        "total_tokens": totalTokens,
      };

  @override
  String toString() {
    // 2024-06-03 这个对话会被作为string存入数据库，然后再被读取转型为ChatMessage。
    // 所以需要是个完整的json字符串，一般fromMap时可以处理
    return '''
    {
     "message_id": "$messageId", 
     "date_time": "$dateTime", 
     "role": "$role", 
     "content": ${jsonEncode(content)}, 
     "image_url": "$imageUrl", 
     "is_placeholder":"$isPlaceholder",
     "prompt_tokens":"$promptTokens",
     "completion_tokens":"$completionTokens",
     "total_tokens":"$totalTokens"
    }
    ''';
  }
}

/// 对话记录 这个是存入sqlite的表对应的模型
// 一次对话记录需要一个标题，首次创建的时间，然后包含很多的对话消息
class ChatSession {
  final String uuid;
  // 因为该栏位需要可修改，就不能为final了
  String title;
  final DateTime gmtCreate;
  // 因为该栏位需要可修改，就不能为final了
  List<ChatMessage> messages;
  // 2024-06-01 大模型名称也要记一下，说不定后续要存API的原始返回内容复用
  // 2024-06-20 这里记录的是自定义的模型名（类似 PlatformLLM.baiduErnieSpeed8KFREE）
  // 因为后续查询历史记录可能会用此栏位来过滤
  final String llmName; // 使用的大模型名称需要记一下吗？
  // 2024-06-06 记录了大模型名称，也记一下使用在哪个云平台
  final String? cloudPlatformName;

  /// 图像理解也是对话记录，所以增加一个类别
  String chatType; // aigc\image2text\text2image
  // ？？？2024-06-14 在图像理解中可以复用对话，存放被理解的图片的base64字符串
  // base64在memoryImage中可能会因为重复渲染而一闪一闪，还是存图片地址好了
  // i2t => image to text
  String? i2tImagePath;

  ChatSession({
    required this.uuid,
    required this.title,
    required this.gmtCreate,
    required this.messages,
    required this.llmName,
    this.cloudPlatformName,
    this.i2tImagePath,
    required this.chatType,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      uuid: map['uuid'] as String,
      title: map['title'] as String,
      gmtCreate: DateTime.tryParse(map['gmt_create']) ?? DateTime.now(),
      messages: (jsonDecode(map['messages'] as String) as List<dynamic>)
          .map((messageMap) =>
              ChatMessage.fromMap(messageMap as Map<String, dynamic>))
          .toList(),
      llmName: map['llm_name'] as String,
      cloudPlatformName: map['yun_platform_name'] as String?,
      i2tImagePath: map['i2t_image_path'] as String?,
      chatType: map['chat_type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'title': title,
      'gmt_create': DateFormat(constDatetimeFormat).format(gmtCreate),
      'messages': messages.toString(),
      'llm_name': llmName,
      'yun_platform_name': cloudPlatformName,
      'chat_type': chatType,
      'i2t_image_path': i2tImagePath,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        uuid: json["uuid"],
        messages: List<ChatMessage>.from(
          json["messages"].map((x) => ChatMessage.fromJson(x)),
        ),
        title: json["title"],
        gmtCreate: json["gmt_create"],
        llmName: json["llm_name"],
        cloudPlatformName: json["yun_platform_name"],
        chatType: json["chat_type"],
        i2tImagePath: json["i2t_image_path"],
      );

  Map<String, dynamic> toJson() => {
        "uuid": uuid,
        "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
        "title": title,
        "gmt_create": gmtCreate,
        "llm_name": llmName,
        "yun_platform_name": cloudPlatformName,
        "i2t_image_path": i2tImagePath,
        'chat_type': chatType,
      };

  @override
  String toString() {
    return '''
    ChatSession { 
      "uuid": $uuid,
      "title": $title,
      "gmtCreate": $gmtCreate,
      "llmName": $llmName,
      "cloudPlatformName": $cloudPlatformName,
      'chatType': $chatType,
      "i2tImageBase64": ${(i2tImagePath != null && i2tImagePath!.length > 10) ? i2tImagePath?.substring(0, 10) : i2tImagePath},
      "messages": $messages
    }
    ''';
  }
}

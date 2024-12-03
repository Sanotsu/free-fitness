import 'dart:convert';

/// 2024-07-08 零一万物 API 的入参出参
///
/// 所以这里减少数量，就使用最简单的，下划线连接模式的入参和出参
/// CC对应ChatCompletions => CCMessage = ChatCompletionsMessage
///
class CCMessage<T> {
  String role;
  // 注意，图像理解的话，这个还需要是比较复杂的数组(String或VisionContent)
  T content;

  CCMessage({required this.role, required this.content});

  factory CCMessage.fromRawJson(String str) =>
      CCMessage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CCMessage.fromJson(Map<String, dynamic> json) =>
      CCMessage(role: json["role"], content: json["content"]);

  Map<String, dynamic> toJson() => {"role": role, "content": content};
}

///
/// delta和message是否类似，不过role和content都可选
/// 第一条只有role，中间的只有content，最后一条两者都没有，就只`{}`
///
class CCDelta {
  String? role;
  String? content;
  List<CCQuote>? quote;

  CCDelta({
    this.role,
    this.content,
    this.quote,
  });

  // 从字符串转
  factory CCDelta.fromRawJson(String str) => CCDelta.fromJson(json.decode(str));
  // 转为字符串
  String toRawJson() => json.encode(toJson());

  factory CCDelta.fromJson(Map<String, dynamic> json) =>
      CCDelta(role: json["role"], content: json["content"]);

  Map<String, dynamic> toJson() => {"role": role, "content": content};
}

///
/// 如果模型支持实时搜索信息，返回值中会有quote引用字段属性
///
class CCQuote {
  // 引用编号、地址、标题
  int? num;
  String? url;
  String? title;

  CCQuote({this.num, this.url, this.title});

  factory CCQuote.fromRawJson(String str) => CCQuote.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CCQuote.fromJson(Map<String, dynamic> json) => CCQuote(
        num: int.tryParse(json["num"] ?? "1"),
        url: json["url"],
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {"num": num, "url": url, "title": title};
}

///
/// 对话的token消耗
///
class CCUsage {
  int? promptTokens;
  int? completionTokens;
  int? totalTokens;

  CCUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  factory CCUsage.fromJson(Map<String, dynamic> json) => CCUsage(
        promptTokens: json["prompt_tokens"],
        completionTokens: json["completion_tokens"],
        totalTokens: json["total_tokens"],
      );

  Map<String, dynamic> toJson() => {
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
     "promptTokens": "$promptTokens", 
     "completionTokens": $completionTokens, 
     "totalTokens": "$totalTokens"
    }
    ''';
  }
}

///
/// 响应的结果主体
/// 如果使用RAG(检索增强生成)模型，会有引用的返回
///
class CCChoice {
  int? index;
  CCMessage? message;
  CCDelta? delta;
  List<CCQuote>? quote;
  String? finishReason;

  CCChoice({
    this.index,
    this.message,
    this.delta,
    this.quote,
    this.finishReason,
  });

  factory CCChoice.fromJson(Map<String, dynamic> json) => CCChoice(
        index: json["index"],
        message: json["message"] == null
            ? null
            : CCMessage.fromJson(json["message"] as Map<String, dynamic>),
        delta: json["delta"] == null
            ? null
            : CCDelta.fromJson(json["delta"] as Map<String, dynamic>),
        quote: json["quote"] == null
            ? []
            : List<CCQuote>.from(
                (json["quote"]! as List).map((x) => CCQuote.fromJson(x)),
              ),
        finishReason: json["finish_reason"],
      );

  Map<String, dynamic> toJson() => {
        "index": index,
        "message": message?.toJson(),
        "delta": delta?.toJson(),
        "quote": quote == null
            ? []
            : List<dynamic>.from(quote!.map((x) => x.toJson())),
        "finish_reason": finishReason,
      };
}

///
/// ============================================================================
/// 对话传参，都是最小的、必传的，其他都预设(一般人也不会调)
///  注意，都使用非流式的回复
///=============================================================================

CCReqBody cCReqBodyFromJson(String str) => CCReqBody.fromJson(json.decode(str));

String cCReqBodyToJson(CCReqBody data) => json.encode(data.toJson());

class CCReqBody {
  // 显示指定模型名称(百度的带在url里面，其他两个在body里面)
  String? model;
  // 一个由历史消息组成的列表，由系统消息、用户消息和模型消息组成。
  List<CCMessage> messages;
  // 是否获取流式输出。
  bool? stream;
  // 控制生成结果的发散性和集中性。数值越小，越集中；数值越大，越发散。
  double? temperature;
  // 控制生成结果的随机性。数值越小，随机性越弱；数值越大，随机性越强。
  double? topP;
  // 指定模型在生成内容时token的最大数量，它定义了生成的上限，但不保证每次都会产生到这个数量。
  int? maxTokens;

  CCReqBody({
    this.model,
    required this.messages,
    this.stream = false,
    this.temperature = 0.7,
    this.topP = 0.7,
    this.maxTokens = 2048,
  });

  factory CCReqBody.fromRawJson(String str) =>
      CCReqBody.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CCReqBody.fromJson(Map<String, dynamic> json) => CCReqBody(
        model: json["model"],
        messages: List<CCMessage>.from(
          ((json["messages"]) as List).map((x) => CCMessage.fromJson(x)),
        ),
        stream: json["stream"] ?? false,
        temperature: double.tryParse(json["temperature"] ?? '0.7'),
        topP: double.tryParse(json["top_p"] ?? '0.7'),
        maxTokens: int.tryParse(json["max_tokens"] ?? '2048'),
      );

  Map<String, dynamic> toJson() => {
        "model": model,
        "messages": messages,
        "stream": stream,
        "temperature": temperature,
        "top_p": topP,
        "max_tokens": maxTokens,
      };
}

///
/// 对话模型的响应
///
/*
/// 零一万物的出参
{
  "id": "cmpl-c730301f",
  "object": "chat.completion",
  "created": 7825887,
  "model": "yi-large",
  "usage": {
    "completion_tokens": 65,
    "prompt_tokens": 15,
    "total_tokens": 80
  },
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! My name is Yi, ……"
      },
      "finish_reason": "stop"
    }
  ]
}
*/
CCRespBody ccRespBodyFromJson(String str) =>
    CCRespBody.fromJson(json.decode(str));

String ccRespBodyToJson(CCRespBody data) => json.encode(data.toJson());

class CCRespBody {
  // 本轮对话的 ID。
  String? id;
  // 回包类型：chat.completion：多轮对话返回
  String? object;
  // 创建的 Unix 时间戳，单位为秒
  int? created;
  // 使用的模型名
  String? model;
  // 回复内容的主体
  List<CCChoice>? choices;
  // token统计信息
  CCUsage? usage;

  /// ========================
  /// 自定义的内容
  RespError? error;

  /// 2024-06-06 3个不同的搞成一样的显示文本，我现在是需要用到显示的值，其他的都暂时不考虑
  String? customReplyText;

  CCRespBody({
    this.id,
    this.object,
    this.created,
    this.model,
    this.choices,
    this.usage,
    this.error,
    String? customReplyText,
  }) : customReplyText = customReplyText ?? _generatecusText(choices);

  // 自定义的响应文本(比如流式返回最后是个[DONE]没法转型，但可以自行设定；而正常响应时可以从其他值中得到)
  static String _generatecusText(List<CCChoice>? choices) {
    // 非流式的
    if (choices != null && choices.isNotEmpty && choices[0].message != null) {
      return choices[0].message?.content ?? "";
    }
    // 流式的
    if (choices != null && choices.isNotEmpty && choices[0].delta != null) {
      return choices[0].delta?.content ?? "";
    }

    return '';
  }

  factory CCRespBody.fromJson(Map<String, dynamic> json) {
    return CCRespBody(
      id: json["id"],
      object: json["object"],
      created: json["created"],
      model: json["model"],
      choices: json["choices"] == null
          ? []
          : List<CCChoice>.from(
              json["choices"]!.map((x) => CCChoice.fromJson(x)),
            ),
      usage: json["usage"] == null ? null : CCUsage.fromJson(json["usage"]),
      error: json["error"] == null ? null : RespError.fromJson(json["error"]),
      customReplyText: json['customReplyText'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "created": created,
        "model": model,
        "choices": choices == null
            ? []
            : List<dynamic>.from(choices!.map((x) => x.toJson())),
        "usage": usage?.toJson(),
        "error": error?.toJson(),
        "customReplyText": customReplyText,
      };
}

/// 零一万物报错返回的是一个结构体
class RespError {
  String code;
  String message;
  String? type;
  dynamic param;

  RespError({
    required this.code,
    required this.message,
    this.type,
    this.param,
  });

  factory RespError.fromJson(Map<String, dynamic> json) => RespError(
        code: json["code"],
        message: json["message"],
        type: json["type"],
        param: json["param"],
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "message": message,
        "type": type,
        "param": param,
      };
}

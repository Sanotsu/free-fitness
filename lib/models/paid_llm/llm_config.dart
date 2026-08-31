import 'dart:convert';

///
/// 2026-08-27 用户自定义的 OpenAI 兼容大模型配置模型
///
/// 设计要点(详见 AI_MODULE_PLAN.md §2.2)：
/// - 一个配置 = 平台+地址+AK+模型名 完整独立成档，用户可存任意多套，无"启用"概念；
/// - 多模态已是主流，不再区分文本/视觉模型，仅用 supportsVision 元数据标记
///   该模型是否支持图片输入(纯文本模型如 deepseek-chat 置 false)；
/// - extraParams 为用户填写的 JSON 对象，发请求时浅合并进请求体顶层，
///   用于覆盖采样参数或追加平台私有参数(如 enable_thinking/reasoning_effort)；
///
class LlmConfig {
  // uuid，配置的唯一标识(用于"上次使用"记忆与会话快照关联)
  String id;
  // 用户起的名字，如 "硅基流动-Qwen"、"DeepSeek"
  String name;
  // 完整 endpoint，如 https://api.siliconflow.cn/v1/chat/completions
  String baseUrl;
  // 平台的 API Key
  String apiKey;
  // 唯一模型名，如 Qwen/Qwen2.5-VL-32B-Instruct(多模态) 或 deepseek-chat(纯文本)
  String model;
  // 模型能力元数据：是否支持视觉理解(图片输入)；false 时图片场景被门禁拦截
  bool supportsVision;
  // 高级自定义参数(JSON 对象)，浅合并进请求体
  Map<String, dynamic>? extraParams;
  // 列表排序("第一个"即此序最前者)
  int sortOrder;

  LlmConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.supportsVision = true,
    this.extraParams,
    this.sortOrder = 0,
  });

  /// 配置完整性：三要素均非空才可用(门禁判定用)
  bool get isComplete =>
      baseUrl.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      model.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'supportsVision': supportsVision,
      'extraParams': extraParams,
      'sortOrder': sortOrder,
    };
  }

  factory LlmConfig.fromMap(Map<String, dynamic> map) {
    return LlmConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      baseUrl: map['baseUrl'] as String,
      apiKey: map['apiKey'] as String,
      model: map['model'] as String,
      supportsVision: map['supportsVision'] as bool? ?? true,
      extraParams: map['extraParams'] == null
          ? null
          : Map<String, dynamic>.from(map['extraParams'] as Map),
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  LlmConfig copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    bool? supportsVision,
    Map<String, dynamic>? extraParams,
    int? sortOrder,
  }) {
    return LlmConfig(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      supportsVision: supportsVision ?? this.supportsVision,
      extraParams: extraParams ?? this.extraParams,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// 校验 extraParams 字符串是否为合法 JSON 对象
  /// 返回 null 表示合法(并顺带解析出 Map)；否则返回错误提示
  static Map<String, dynamic>? parseExtraParams(String? text) {
    if (text == null || text.trim().isEmpty) return {};
    final decoded = json.decode(text.trim());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('必须是 JSON 对象 {}');
    }
    return decoded;
  }

  /// 这些键由程序控制(模型/消息/流式)，用户 JSON 中的同名键合并时忽略
  static const reservedKeys = {'model', 'messages', 'stream'};

  /// 将 extraParams 浅合并进基础请求体(OpenAI body 参数均为顶层键，无需深合并)；
  /// model/messages/stream 为程序控制字段，忽略用户同名键；其余用户值优先覆盖。
  static Map<String, dynamic> mergeExtraParams(
    Map<String, dynamic> base,
    Map<String, dynamic>? extra,
  ) {
    if (extra == null || extra.isEmpty) return base;
    final merged = Map<String, dynamic>.from(base);
    for (var entry in extra.entries) {
      if (reservedKeys.contains(entry.key)) continue;
      merged[entry.key] = entry.value;
    }
    return merged;
  }

  @override
  String toString() {
    return 'LlmConfig{id: $id, name: $name, baseUrl: $baseUrl, model: $model, '
        'supportsVision: $supportsVision, extraParams: $extraParams, sortOrder: $sortOrder}';
  }
}

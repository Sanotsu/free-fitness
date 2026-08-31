/// 2026-08-27 AI 聊天页的 UI 消息模型
///
/// 与落库模型 AiMessage 分离：
/// - imageLocalPaths 存用于显示的本地【绝对路径】(发送时复制进应用私有目录)；
/// - status 为 null 表示流式响应中(显示加载圈)；
/// - token 统计字段沿用旧版对话页的展示习惯；
class AiUiMessage {
  final String role; // 'user' | 'assistant'
  String content;
  String? reasoningContent;
  final List<String> imageLocalPaths;
  String? modelName;
  String? status; // null(流式中) | 'done' | 'aborted' | 'error'
  final DateTime dateTime;

  // token 统计(assistant 消息)
  int? promptTokens;
  int? completionTokens;
  int? totalTokens;

  AiUiMessage({
    required this.role,
    required this.content,
    this.reasoningContent,
    this.imageLocalPaths = const [],
    this.modelName,
    this.status,
    DateTime? dateTime,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  }) : dateTime = dateTime ?? DateTime.now();

  bool get isFromUser => role == 'user';

  // 该消息是否携带图片(门禁/请求组装时判断)
  bool get hasImage => imageLocalPaths.isNotEmpty;
}

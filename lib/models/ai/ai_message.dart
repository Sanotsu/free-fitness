/// 2026-08-27 AI 对话消息(ff_ai_message 表对应的模型)
///
/// role 仅 user/assistant(system 由角色动态生成，不落库)；
/// image_paths 为用户消息附图的应用私有目录【相对路径，逗号分隔，最多4张】；
/// model_name 为 assistant 消息的模型快照；
/// status: done(正常结束) / aborted(手动终止) / error(请求出错)。
class AiMessage {
  int? messageId; // 自增的，可以不传
  int conversationId;
  String role;
  String content;
  String? imagePaths;
  String? modelName;
  String? status;
  String? gmtCreate;

  AiMessage({
    this.messageId,
    required this.conversationId,
    required this.role,
    required this.content,
    this.imagePaths,
    this.modelName,
    this.status,
    this.gmtCreate,
  });

  /// 多图字段沿用项目惯例：逗号分隔字符串(同 ff_diary.photos)
  List<String> get imageList => imagePaths == null || imagePaths!.trim().isEmpty
      ? []
      : imagePaths!.trim().split(',');

  static String joinImagePaths(List<String> paths) => paths.join(',');

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'image_paths': imagePaths,
      'model_name': modelName,
      'status': status,
      'gmt_create': gmtCreate,
    };
  }

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      messageId: map['message_id'] as int?,
      conversationId: map['conversation_id'] as int,
      role: map['role'] as String,
      content: (map['content'] ?? '') as String,
      imagePaths: map['image_paths'] as String?,
      modelName: map['model_name'] as String?,
      status: map['status'] as String?,
      gmtCreate: map['gmt_create'] as String?,
    );
  }

  @override
  String toString() {
    return 'AiMessage{id: $messageId, conv: $conversationId, role: $role, '
        'content: ${content.length}字, images: ${imageList.length}, model: $modelName, status: $status}';
  }
}

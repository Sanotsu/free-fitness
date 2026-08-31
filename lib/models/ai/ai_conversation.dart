/// 2026-08-27 AI 会话(ff_ai_conversation 表对应的模型)
///
/// 一个会话关联一个角色(role_key 只存 key，角色内容动态解析)；
/// config_id/config_name/model_name 为使用时的快照(配置删除后仅展示用)。
/// biz_type/biz_key 为业务场景关联(同一天饮食/同一训练组等)：
/// 同一业务对象按 (biz_type,biz_key) 复用同一会话；
/// 2026-08-28 是否重调大模型改由 biz_hash 数据指纹判定——
/// 入口对"参与分析的业务数据"做 FNV-1a 指纹(不含 prompt 模板文案)，
/// 与库中指纹不一致(数据变更过/旧会话无指纹)才追加新分析，
/// 追加后回写最新指纹，避免"首条文本比对"因 prompt 模板演进永久失配。
class AiConversation {
  int? conversationId; // 自增的，可以不传
  String title; // 默认取首条用户消息前 20 字，可改名
  String roleKey; // 内置角色 key 或 c_{role_id}；找不到时兜底通用助手
  String? configId; // 当前使用配置 id(快照)
  String? configName; // 配置名称快照
  String? modelName; // 模型名快照(最后一条消息所用)
  String? gmtCreate, gmtModified;

  // 业务场景关联(自由对话为 null)
  String?
  bizType; // 'diet_intake' | 'meal_photo' | 'training_group' | 'training_plan'
  String? bizKey; // 对象键：日期/日期+餐次/训练组id/计划id
  String? bizHash; // 业务数据指纹(最近一次分析时的数据状态)

  AiConversation({
    this.conversationId,
    required this.title,
    required this.roleKey,
    this.configId,
    this.configName,
    this.modelName,
    this.gmtCreate,
    this.gmtModified,
    this.bizType,
    this.bizKey,
    this.bizHash,
  });

  /// 是否为业务场景会话
  bool get isBizConversation => bizType != null && bizKey != null;

  Map<String, dynamic> toMap() {
    return {
      'conversation_id': conversationId,
      'title': title,
      'role_key': roleKey,
      'config_id': configId,
      'config_name': configName,
      'model_name': modelName,
      'gmt_create': gmtCreate,
      'gmt_modified': gmtModified,
      'biz_type': bizType,
      'biz_key': bizKey,
      'biz_hash': bizHash,
    };
  }

  factory AiConversation.fromMap(Map<String, dynamic> map) {
    return AiConversation(
      conversationId: map['conversation_id'] as int?,
      title: (map['title'] ?? '') as String,
      roleKey: map['role_key'] as String,
      configId: map['config_id'] as String?,
      configName: map['config_name'] as String?,
      modelName: map['model_name'] as String?,
      gmtCreate: map['gmt_create'] as String?,
      gmtModified: map['gmt_modified'] as String?,
      bizType: map['biz_type'] as String?,
      bizKey: map['biz_key'] as String?,
      bizHash: map['biz_hash'] as String?,
    );
  }

  @override
  String toString() {
    return 'AiConversation{id: $conversationId, title: $title, roleKey: $roleKey, '
        'config: $configName, model: $modelName, biz: $bizType/$bizKey}';
  }
}

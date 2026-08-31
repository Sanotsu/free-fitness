/// 2026-08-27 用户自定义 AI 角色(ff_ai_role 表对应的模型)
///
/// 用户可自行添加"角色名称 + 角色设定(system prompt)"的角色，
/// 内置角色不在此表；展示 key 为 c_{role_id}。
class AiCustomRole {
  int? roleId; // 自增的，可以不传
  String name;
  String systemPrompt;
  String? gmtCreate, gmtModified;

  AiCustomRole({
    this.roleId,
    required this.name,
    required this.systemPrompt,
    this.gmtCreate,
    this.gmtModified,
  });

  /// 会话表/角色注册表中使用的展示 key
  String get roleKey => 'c_$roleId';

  Map<String, dynamic> toMap() {
    return {
      'role_id': roleId,
      'name': name,
      'system_prompt': systemPrompt,
      'gmt_create': gmtCreate,
      'gmt_modified': gmtModified,
    };
  }

  factory AiCustomRole.fromMap(Map<String, dynamic> map) {
    return AiCustomRole(
      roleId: map['role_id'] as int?,
      name: map['name'] as String,
      systemPrompt: map['system_prompt'] as String,
      gmtCreate: map['gmt_create'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  @override
  String toString() {
    return 'AiCustomRole{roleId: $roleId, name: $name, systemPrompt: $systemPrompt}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../core/apis/llm_apis.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/tool_widgets.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/paid_llm/common_chat_completion_state.dart';
import '../../../models/paid_llm/llm_config.dart';
import '../../../services/llm_config_service.dart';

/// 常见 OpenAI 兼容平台的快速填充预设(点击 chips 预填地址/推荐模型/视觉开关)
class _PlatformPreset {
  final String label;
  final String baseUrl;
  final String model;
  final bool supportsVision;

  const _PlatformPreset(
    this.label,
    this.baseUrl,
    this.model,
    this.supportsVision,
  );
}

const List<_PlatformPreset> _presets = [
  _PlatformPreset(
    '阿里百炼',
    'https://{WorkspaceId}.cn-beijing.maas.aliyuncs.com/compatible-mode/v1/chat/completions',
    'qwen3.8-flash',
    true,
  ),
  _PlatformPreset(
    'DeepSeek',
    'https://api.deepseek.com/chat/completions',
    'deepseek-v4-flash',
    false,
  ),
  _PlatformPreset(
    '智谱',
    'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    'glm-5.3-flash',
    true,
  ),
  _PlatformPreset(
    'OpenAI',
    'https://api.openai.com/v1/chat/completions',
    'gpt-5.6-luna',
    true,
  ),
];

/// 2026-08-27 大模型配置编辑页
///
/// 一个配置 = 平台地址+AK+模型名 完整独立成档；
/// supportsVision 为模型能力元数据(主流模型多为多模态默认开，
/// 纯文本模型如 deepseek-chat 请关闭)；
/// extraParams 为高级 JSON 参数，发请求时浅合并进请求体
/// (model/messages/stream 为程序控制字段会被忽略)。
class ModifyLlmConfig extends StatefulWidget {
  // 编辑已有配置时传入；新增时为 null
  final LlmConfig? config;

  const ModifyLlmConfig({super.key, this.config});

  @override
  State<ModifyLlmConfig> createState() => _ModifyLlmConfigState();
}

class _ModifyLlmConfigState extends State<ModifyLlmConfig> {
  final _formKey = GlobalKey<FormBuilderState>();
  final LlmConfigService _configService = LlmConfigService();

  // 是否正在测试连接
  bool _isTesting = false;

  // 表单是否有改动(2026-08-27：无改动不显示保存按钮)
  bool _dirty = false;

  // 密钥是否隐藏(2026-08-28：默认隐藏，输入框尾部眼睛图标切换，
  // 便于用户核对实际使用的 AK 是哪一个)
  bool _obscureKey = true;

  // 当前编辑目标(进入时来自 widget.config；新增态首次保存后指向已落档实例，
  // 之后再点保存走 update 不再重复 add，标题也随之切换为"编辑")
  LlmConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.config;
    _configService.load();
  }

  // 用当前表单内容构建一个 LlmConfig(校验失败返回 null)
  LlmConfig? _buildConfigFromForm() {
    if (!_formKey.currentState!.saveAndValidate()) return null;

    var values = _formKey.currentState!.value;

    Map<String, dynamic>? extra;
    var extraText = (values['extraParams'] as String?)?.trim() ?? '';
    if (extraText.isNotEmpty) {
      try {
        extra = LlmConfig.parseExtraParams(extraText);
      } on FormatException {
        return null;
      }
    }

    // 2026-08-28 统一去前后空格再落档/测试：尾行空格等不可见字符
    // 会造成请求失败但用户难以自查
    return LlmConfig(
      id: _currentConfig?.id ?? const Uuid().v4(),
      name: (values['name'] as String).trim(),
      baseUrl: (values['baseUrl'] as String).trim(),
      apiKey: (values['apiKey'] as String).trim(),
      model: (values['model'] as String).trim(),
      supportsVision: values['supportsVision'] as bool? ?? true,
      extraParams: extra,
      sortOrder: _currentConfig?.sortOrder ?? 0,
    );
  }

  // 保存配置(2026-08-27 改版：保存后停留在本页可继续调整，按返回键才离开；
  // 新增态首次保存后切换为编辑态，后续保存均走 update)
  Future<void> _save() async {
    var config = _buildConfigFromForm();
    if (config == null) return;

    if (_currentConfig == null) {
      await _configService.add(config);
    } else {
      await _configService.update(config);
    }

    if (!mounted) return;
    setState(() {
      _currentConfig = config;
      _dirty = false;
    });
    ToastUtils.showToast(CusAL.of(context).llmConfigSaved);
  }

  // 删除当前配置(仅编辑已有配置时；与列表页右滑删除共用确认语义)
  Future<void> _delete() async {
    var config = _currentConfig!;

    var confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(CusAL.of(context).tipsTitle),
          content: Text(CusAL.of(context).llmConfigDeleteNote(config.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(CusAL.of(context).cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(CusAL.of(context).confirmLabel),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await _configService.delete(config.id);

    if (!mounted) return;
    Navigator.pop(context);
  }

  // 测试连接：发一条最小文本请求验证 AK/URL/模型连通性
  Future<void> _testConnection() async {
    var config = _buildConfigFromForm();
    if (config == null) {
      ToastUtils.showToast(CusAL.of(context).llmConfigFixForm);
      return;
    }

    setState(() {
      _isTesting = true;
    });

    String result;
    try {
      var stream = await getChatRespStream(config, [
        CCMessage(role: 'user', content: CusAL.of(context).llmConfigPingText),
      ], stream: false);

      var resp = await stream.stream.first;
      result = resp.error != null
          ? "${resp.error?.code}${resp.error?.message}"
          : "${resp.customReplyText}";
    } catch (e) {
      result = e.toString();
    }

    if (!mounted) return;
    setState(() {
      _isTesting = false;
    });

    if (!context.mounted) return;
    commonExceptionDialog(
      context,
      CusAL.of(context).llmConfigTestResult,
      result.isEmpty ? CusAL.of(context).llmConfigEmptyReply : result,
    );
  }

  // 测试视觉：发送1x1最小图片请求，探测模型是否支持图片输入
  Future<void> _testVision() async {
    var config = _buildConfigFromForm();
    if (config == null) return;

    setState(() {
      _isTesting = true;
    });

    // 1x1 透明 PNG
    var tinyPng =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

    String result;
    try {
      var stream = await getChatRespStream(config, [
        CCMessage(
          role: 'user',
          content: [
            {
              "type": "image_url",
              "image_url": {"url": "data:image/png;base64,$tinyPng"},
            },
            {"type": "text", "text": CusAL.of(context).llmConfigVisionPingText},
          ],
        ),
      ], stream: false);

      var resp = await stream.stream.first;
      result = resp.error != null
          ? "${resp.error?.code}${resp.error?.message}"
          : resp.customReplyText ?? '';
    } catch (e) {
      result = e.toString();
    }

    if (!mounted) return;
    setState(() {
      _isTesting = false;
    });

    if (!context.mounted) return;
    var ok = !result.contains('Exception') && result.isNotEmpty;
    // await 前捕获，避免跨异步间隙使用 context
    var l10n = CusAL.of(context);
    commonExceptionDialog(
      context,
      l10n.llmConfigVisionTest,
      ok ? l10n.llmConfigVisionOk(result) : l10n.llmConfigVisionFail(result),
    );
  }

  // 快速填充预设
  void _applyPreset(_PlatformPreset preset) {
    _formKey.currentState?.patchValue({
      'baseUrl': preset.baseUrl,
      'model': preset.model,
      'supportsVision': preset.supportsVision,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentConfig == null
              ? CusAL.of(context).llmConfigPageAdd
              : CusAL.of(context).llmConfigPageEdit,
        ),
        actions: [
          // 删除入口：编辑已有配置时提供(新增态无此按钮)
          if (_currentConfig != null)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: CusAL.of(context).deleteLabel,
            ),
          // 保存按钮：仅表单有改动时显示；保存后留在本页(按钮随之隐藏)
          if (_dirty && !_isTesting)
            TextButton(
              onPressed: _save,
              child: Text(
                CusAL.of(context).saveLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isTesting
          ? Center(child: CircularProgressIndicator(strokeWidth: 2.sp))
          : SingleChildScrollView(
              padding: EdgeInsets.all(10.sp),
              child: FormBuilder(
                key: _formKey,
                initialValue: {
                  'name': _currentConfig?.name ?? '',
                  'baseUrl': _currentConfig?.baseUrl ?? '',
                  'apiKey': _currentConfig?.apiKey ?? '',
                  'model': _currentConfig?.model ?? '',
                  'supportsVision': _currentConfig?.supportsVision ?? true,
                  'extraParams': _currentConfig?.extraParams == null
                      ? ''
                      : _extraParamsToText(_currentConfig!.extraParams!),
                },
                // 任一字段变化即标记有改动(含快速填充 chips 的 patchValue)
                onChanged: () {
                  if (!_dirty) {
                    setState(() {
                      _dirty = true;
                    });
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 常见平台快速填充
                    Text(
                      CusAL.of(context).llmConfigQuickFill,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    Wrap(
                      spacing: 6.sp,
                      children: _presets
                          .map(
                            (p) => ActionChip(
                              label: Text(p.label),
                              onPressed: () => _applyPreset(p),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: 10.sp),

                    FormBuilderTextField(
                      name: 'name',
                      decoration: InputDecoration(
                        labelText: CusAL.of(context).llmConfigFieldName,
                        hintText: CusAL.of(context).llmConfigFieldNameHint,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? CusAL.of(context).llmConfigRequired
                          : null,
                    ),
                    FormBuilderTextField(
                      name: 'baseUrl',
                      decoration: InputDecoration(
                        labelText: CusAL.of(context).llmConfigFieldUrl,
                        hintText: 'https://api.xxx.com/v1/chat/completions',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return CusAL.of(context).llmConfigRequired;
                        }
                        var uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                          return CusAL.of(context).llmConfigInvalidUrl;
                        }
                        return null;
                      },
                    ),
                    FormBuilderTextField(
                      name: 'apiKey',
                      obscureText: _obscureKey,
                      decoration: InputDecoration(
                        labelText: CusAL.of(context).llmConfigFieldKey,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKey
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureKey = !_obscureKey;
                            });
                          },
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? CusAL.of(context).llmConfigRequired
                          : null,
                    ),
                    FormBuilderTextField(
                      name: 'model',
                      decoration: InputDecoration(
                        labelText: CusAL.of(context).llmConfigFieldModel,
                        hintText: CusAL.of(context).llmConfigFieldModelHint,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? CusAL.of(context).llmConfigRequired
                          : null,
                    ),

                    FormBuilderSwitch(
                      name: 'supportsVision',
                      title: Text(
                        CusAL.of(context).llmConfigFieldVision,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        CusAL.of(context).llmConfigFieldVisionNote,
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),

                    FormBuilderTextField(
                      name: 'extraParams',
                      maxLines: 4,
                      minLines: 2,
                      decoration: InputDecoration(
                        labelText: CusAL.of(context).llmConfigFieldExtra,
                        hintText:
                            '{ "temperature": 0.3, "enable_thinking": true }',
                        helperText: CusAL.of(context).llmConfigFieldExtraNote,
                        helperStyle: TextStyle(fontSize: 11.sp),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        try {
                          LlmConfig.parseExtraParams(v);
                          return null;
                        } on FormatException {
                          return CusAL.of(context).llmConfigInvalidJson;
                        }
                      },
                    ),
                    SizedBox(height: 15.sp),

                    // 测试连接
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testConnection,
                            icon: const Icon(Icons.wifi_tethering),
                            label: Text(
                              CusAL.of(context).llmConfigTestConnection,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.sp),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testVision,
                            icon: const Icon(Icons.visibility),
                            label: Text(CusAL.of(context).llmConfigTestVision),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.sp),
                  ],
                ),
              ),
            ),
    );
  }

  // extraParams Map 转可读文本(键值对逐行展示)
  String _extraParamsToText(Map<String, dynamic> map) {
    var sb = StringBuffer('{\n');
    var i = 0;
    for (var e in map.entries) {
      sb.write('  "${e.key}": ${e.value is String ? '"${e.value}"' : e.value}');
      if (i < map.length - 1) sb.write(',');
      sb.write('\n');
      i++;
    }
    sb.write('}');
    return sb.toString();
  }
}

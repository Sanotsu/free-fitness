import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/apis/llm_apis.dart';
import '../../../core/constants/constants.dart';
import '../../../core/storage/db_ai_helper.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/tool_widgets.dart';
import '../../../core/utils/tools.dart';
import '../../../models/ai/ai_conversation.dart';
import '../../../models/ai/ai_custom_role.dart';
import '../../../models/ai/ai_message.dart';
import '../../../models/ai/ai_role.dart';
import '../../../models/ai/ai_ui_message.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/paid_llm/common_chat_completion_state.dart';
import '../../../models/paid_llm/llm_config.dart';
import '../../../services/llm_config_service.dart';
import 'manage_roles.dart';
import 'widgets/message_item.dart';

/// 2026-08-27 通用 AI 聊天页(自 OneChatScreen 迁移泛化)
/// 2026-08-28 暂时改为1张
///
/// 一体化布局：左侧侧边栏(对话历史/新对话/管理角色) + AppBar下方固定模型选择条
/// + 中间消息列表(流式追加/多图显示) + 下方输入区(图片上传≤4张+文本)。
///
/// 所有 AI 入口(全局悬浮按钮/运动饮食模块内快捷入口)统一收口到本页：
/// - 新对话：传 roleKey(+可选 firstMessage/imagePaths 业务上下文)；
/// - 续聊：传 conversationId(侧边栏点历史进入)。
class AiChatScreen extends StatefulWidget {
  // 新对话时关联的角色 key(内置 key 或 c_{role_id})
  final String roleKey;
  // 业务上下文首条消息(自由对话时为 null，等用户输入)
  final String? firstMessage;
  // 业务图片场景的附图(本地路径，最多4张)
  final List<String> imagePaths;
  // 续聊已有会话(侧边栏点历史进入时)
  final int? conversationId;

  /// 2026-08-27 业务场景关联(同一业务对象复用同一会话)：
  /// 传入后先按 (bizType,bizKey) 查已有会话——
  /// 2026-08-28 是否重调大模型由 bizHash 数据指纹判定：
  /// - 存在且指纹一致 → 直接打开查看，不重复调用大模型；
  /// - 存在但指纹不一致(数据变更过/旧会话无指纹) → 追加"数据已更新"新分析并回写指纹；
  /// - 不存在 → 新建会话(仍为首条消息发送时才落库)。
  final String? bizType;
  final String? bizKey;
  // 业务数据指纹(入口对参与分析的数据做 FNV-1a，与 prompt 模板文案无关)
  final String? bizHash;

  const AiChatScreen({
    super.key,
    this.roleKey = 'assistant',
    this.firstMessage,
    this.imagePaths = const [],
    this.conversationId,
    this.bizType,
    this.bizKey,
    this.bizHash,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final DBAiHelper _dbHelper = DBAiHelper();
  final LlmConfigService _configService = LlmConfigService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _userInputController = TextEditingController();

  // 当前会话(新对话时仅内存占位，首条消息发送才真正落库，见 _ensureConversation)
  // 声明时给占位实例，避免异步初始化完成前 build 访问报错(conversationId 为 null 即未就绪)
  AiConversation _conversation = AiConversation(
    title: '',
    roleKey: 'assistant',
  );

  // 角色(内置 + 自定义)
  List<AiCustomRole> _customRoles = [];
  late AiRole _currentRole;

  // 当前使用的模型配置(可中途切换)
  LlmConfig? _currentConfig;

  // 会话消息(UI 层；请求组装与渲染都用它，落库时机见 _finalizeAssistant)
  List<AiUiMessage> uiMessages = [];

  // 用户输入内容(非空才可点发送)
  String userInput = "";
  // AI 是否在思考中(是则不允许再次发送)
  bool isBotThinking = false;
  // 是否在加载历史会话
  bool isLoading = false;

  // 当前正在响应的api返回流(放在全局为了可以手动取消)
  StreamWithCancel<CCRespBody> respStream = StreamWithCancel.empty();

  // 本轮待发送的图片 base64(发送请求时消费一次即清空，历史消息重发不带图)
  List<String> _pendingImageBase64 = [];
  // 首轮图片的 base64 副本(仅供"重新生成"首轮时复用)
  List<String> _firstRoundImageBase64 = [];

  // 输入区已选择的图片(本地路径，最多4张)
  List<String> _selectedImages = [];

  // 暂时改为1，因为有些模型好像不支持多张图片，后续看情况是否实际使用4
  final supporttedImagesCount = 4;

  // 应用私有目录中 ai_images 的根目录(懒加载)
  String? _aiImagesRoot;

  // 2026-08-27 l10n 短别名(UI 文案全部走 ARB)；
  // _useEnData 用于 AiRole 双语"数据"的变体选择(非 zh 语言回退英文档)
  AppLocalizations get _l10n => CusAL.of(context);
  bool get _useEnData => Localizations.localeOf(context).languageCode != 'zh';

  @override
  void initState() {
    super.initState();

    _currentRole = fallbackAiRole;
    _initScreen();
  }

  // 初始化：加载配置/角色/会话数据
  Future<void> _initScreen() async {
    setState(() {
      isLoading = true;
    });

    await _configService.load();
    await _loadCustomRoles();

    // 外部存储私有目录下的 ai_images 根目录
    var externalDir = await getExternalStorageDirectory();
    _aiImagesRoot = externalDir == null
        ? null
        : "${externalDir.path}/ai_images";

    // 标记本次进入是否需要在已有会话中追加"数据已更新"上下文
    var needContextUpdate = false;

    if (widget.conversationId != null) {
      // 续聊已有会话(侧边栏点历史进入)
      var conv = await _dbHelper.queryConversationById(widget.conversationId!);
      if (conv != null) {
        _conversation = conv;
        _currentRole = resolveAiRole(conv.roleKey, customRoles: _customRoles);
        await _loadHistoryMessages();
      } else {
        // 会话已被删除，按新对话处理
        await _createNewConversation(widget.roleKey);
      }
    } else if (widget.bizType != null && widget.bizKey != null) {
      // 业务入口：同一业务对象优先复用已有会话
      var conv = await _dbHelper.queryConversationByBiz(
        widget.bizType!,
        widget.bizKey!,
      );
      if (conv != null) {
        _conversation = conv;
        _currentRole = resolveAiRole(conv.roleKey, customRoles: _customRoles);
        await _loadHistoryMessages();

        // 2026-08-28 比对数据指纹(而非首条消息文本)：
        // prompt 模板演进/文案调整不会影响指纹，只有业务数据真变了才重析；
        // 旧会话无指纹(本次功能升级前创建)视为已更新，触发一次并回写
        needContextUpdate =
            widget.bizHash != null && conv.bizHash != widget.bizHash;
      } else {
        await _createNewConversation(widget.roleKey);
      }
    } else {
      await _createNewConversation(widget.roleKey);
    }

    // 选中的模型配置(图片场景需视觉配置；入口已门禁，这里兜底再选一次)
    _currentConfig = _configService.pickConfig(
      needVision: widget.imagePaths.isNotEmpty,
    );

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });

    // 首次进入的业务入口：新会话发送首条上下文；已有会话但内容已更新则追加更新消息
    if ((widget.firstMessage != null || widget.imagePaths.isNotEmpty) &&
        _conversation.conversationId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initSend();
      });
    } else if (needContextUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendUpdatedContext();
      });
    }
  }

  // 业务数据变更后在同一会话追加"数据已更新"的新上下文(附最新数据的完整消息)
  Future<void> _sendUpdatedContext() async {
    // 2026-08-28 先回写最新指纹作为后续比较基准：
    // 若不回写，旧指纹永久失配会导致每次进入都重复调用大模型
    _conversation.bizHash = widget.bizHash;
    await _dbHelper.updateConversation(_conversation);

    var header = "${_l10n.aiChatDataUpdated}\n\n";

    await _sendMessageWithImages(
      "$header${widget.firstMessage}",
      List<String>.from(widget.imagePaths),
    );
  }

  // 加载自定义角色并刷新当前会话角色的解析(自定义角色可能被编辑过)
  Future<void> _loadCustomRoles() async {
    _customRoles = await _dbHelper.queryCustomRoles();
    if (_conversation.roleKey.isNotEmpty) {
      _currentRole = resolveAiRole(
        _conversation.roleKey,
        customRoles: _customRoles,
      );
    }
  }

  // 创建新会话(仅内存占位，不落库：
  // 用户可能反复点角色新建却什么都不输入，真实会话记录至少要有一条用户消息
  // 才在 _ensureConversation 中创建，避免对话历史堆积大量空会话)
  Future<void> _createNewConversation(String roleKey) async {
    _currentRole = resolveAiRole(roleKey, customRoles: _customRoles);

    var picked = _configService.pickConfig();
    _conversation = AiConversation(
      title: '',
      roleKey: roleKey,
      configId: picked?.id,
      configName: picked?.name,
      modelName: picked?.model,
      gmtCreate: getCurrentDateTime(),
      gmtModified: getCurrentDateTime(),
      // 业务场景关联(业务入口传入；首次落库时随会话保存)
      bizType: widget.bizType,
      bizKey: widget.bizKey,
      bizHash: widget.bizHash,
    );
  }

  // 首次真正发送消息时才把会话落库(此后 conversationId 恒非空)
  Future<void> _ensureConversation() async {
    if (_conversation.conversationId != null) return;

    // 用当前生效配置补全快照(新建时可能还没选配置或已切换)
    var config = _currentConfig;
    if (config != null) {
      _conversation.configId = config.id;
      _conversation.configName = config.name;
      _conversation.modelName = config.model;
    }

    _conversation.conversationId = await _dbHelper.insertConversation(
      _conversation,
    );
  }

  // 从 db 加载历史消息转为 UI 消息(附图转为绝对路径显示)
  Future<void> _loadHistoryMessages() async {
    var msgs = await _dbHelper.queryMessagesByConversation(
      _conversation.conversationId!,
    );

    uiMessages = msgs.map((m) {
      var images = m.imageList
          .map((rel) => _absImagePath(rel))
          .whereType<String>()
          .toList();
      return AiUiMessage(
        role: m.role,
        content: m.content,
        imageLocalPaths: images,
        modelName: m.modelName,
        status: m.status,
        dateTime: DateTime.tryParse(m.gmtCreate ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  // 相对路径转绝对路径(图片不存在则返回 null)
  String? _absImagePath(String rel) =>
      _aiImagesRoot == null ? null : "$_aiImagesRoot/$rel";

  // 业务入口首条发送(图片压缩转 base64 后发送)
  Future<void> _initSend() async {
    if (widget.firstMessage == null && widget.imagePaths.isEmpty) return;

    await _sendMessageWithImages(
      widget.firstMessage ?? '',
      List<String>.from(widget.imagePaths),
    );
  }

  // 滚动到消息列表底部(ai响应的消息卡片下方还有功能按钮行，多滚一点)
  // 2026-08-27 修复：hasClients 防护(空会话ListView与builder切换间隙controller可能无挂载)；
  // 且此方法绝不能在 setState 闭包内调用——闭包抛异常会中断 markNeedsBuild 导致界面不刷新
  void chatListScrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      curve: Curves.easeOut,
      // sse的间隔比较短，滚动要快一点
      duration: const Duration(milliseconds: 50),
    );
  }

  /// 发送带图片的消息(图片先复制进应用私有目录再落库，历史可回看)
  Future<void> _sendMessageWithImages(
    String text,
    List<String> localImagePaths,
  ) async {
    if (isBotThinking) return;

    // 图片目录以会话id命名，先确保会话已真实创建
    await _ensureConversation();

    // 复制图片到 ai_images/{conversationId}/ 下(相对路径入库)
    var relPaths = <String>[];
    for (var path in localImagePaths.take(supporttedImagesCount)) {
      var rel = await _copyImageToAiDir(path);
      if (rel != null) relPaths.add(rel);
    }

    // 压缩转 base64 供本轮请求使用(仅本轮发送，历史重发不带图)
    var base64List = <String>[];
    for (var rel in relPaths) {
      try {
        var b64 = await ImageCompressor.compressAndConvertImage(
          File(_absImagePath(rel)!),
        );
        if (b64 != null) base64List.add("data:image/jpeg;base64,$b64");
      } catch (_) {
        // 单张图片处理失败不影响其他图片
      }
    }

    await _sendMessage(
      text,
      dbImageRelPaths: relPaths,
      imageBase64: base64List,
    );
  }

  // 复制图片到应用私有目录，返回相对路径(convId/uuid.jpg)
  Future<String?> _copyImageToAiDir(String sourcePath) async {
    try {
      var source = File(sourcePath);
      if (!await source.exists()) return null;

      var root = _aiImagesRoot;
      if (root == null) return null;

      var convDir = Directory("$root/${_conversation.conversationId}");
      if (!await convDir.exists()) {
        await convDir.create(recursive: true);
      }

      var ext = sourcePath.contains('.')
          ? '.${sourcePath.split('.').last}'
          : '.jpg';
      var targetPath = "${convDir.path}/${const Uuid().v4()}$ext";

      // 检查文件是否已存在(已存在则不要复制，否则文件会损坏)
      if (!(await File(targetPath).exists())) {
        await source.copy(targetPath);
      }
      return "${_conversation.conversationId}/${targetPath.split('/').last}";
    } catch (_) {
      return null;
    }
  }

  /// 用户发送消息：立即落库 user 消息，然后请求大模型应答
  Future<void> _sendMessage(
    String text, {
    List<String> dbImageRelPaths = const [],
    List<String> imageBase64 = const [],
  }) async {
    if (isBotThinking) return;
    if (_currentConfig == null) {
      ToastUtils.showToast(_l10n.aiChatNoConfig);
      return;
    }

    // 首条消息生成会话标题(截20字)
    var isFirstUserMsg = uiMessages.where((m) => m.isFromUser).isEmpty;
    if (isFirstUserMsg && text.trim().isNotEmpty) {
      _conversation.title = text.trim().length > 20
          ? text.trim().substring(0, 20)
          : text.trim();
    }

    // 首条消息发送时才真正创建会话记录(空会话不落库)
    await _ensureConversation();

    // user 消息立即落库(流式期间只渲染不写库，assistant 在结束时落库)
    var userMsg = AiMessage(
      conversationId: _conversation.conversationId!,
      role: 'user',
      content: text,
      imagePaths: AiMessage.joinImagePaths(dbImageRelPaths),
      gmtCreate: getCurrentDateTime(),
    );
    await _dbHelper.insertMessage(userMsg);
    await _touchConversation();

    // 首轮图片保留一份副本，供"重新生成"首轮时复用
    if (isFirstUserMsg && imageBase64.isNotEmpty) {
      _firstRoundImageBase64 = List<String>.from(imageBase64);
    }

    setState(() {
      uiMessages.add(
        AiUiMessage(
          role: 'user',
          content: text,
          imageLocalPaths: dbImageRelPaths
              .map(_absImagePath)
              .whereType<String>()
              .toList(),
        ),
      );
      _pendingImageBase64 = List<String>.from(imageBase64);
      _userInputController.clear();
      userInput = "";
      _selectedImages = [];
    });

    // 滚动必须在 setState 闭包外(闭包内抛异常会中断本次界面刷新)
    chatListScrollToBottom();

    await _getLlmResponse();
  }

  // 刷新会话的修改时间(侧边栏按此倒序)
  Future<void> _touchConversation() async {
    _conversation.gmtModified = getCurrentDateTime();
    await _dbHelper.updateConversation(_conversation);
  }

  /// 得到模型响应(流式)
  Future<void> _getLlmResponse() async {
    if (isBotThinking) return;
    setState(() {
      isBotThinking = true;
    });

    // system 由当前角色动态生成 + 历史(旧图消息仅保留文字) + 本轮待发图片挂在最后一条user上
    var msgs = <CCMessage>[
      CCMessage(role: 'system', content: _currentRole.systemPrompt(_useEnData)),
    ];

    var lastIndex = uiMessages.length - 1;
    for (var i = 0; i < uiMessages.length; i++) {
      var m = uiMessages[i];
      if (m.isFromUser && i == lastIndex && _pendingImageBase64.isNotEmpty) {
        // 本轮带图：OpenAI 视觉消息格式(image_url 数组 + text)
        msgs.add(
          CCMessage(
            role: 'user',
            content: [
              for (var b64 in _pendingImageBase64)
                {
                  "type": "image_url",
                  "image_url": {"url": b64},
                },
              {"type": "text", "text": m.content},
            ],
          ),
        );
      } else {
        msgs.add(CCMessage(role: m.role, content: m.content));
      }
    }

    // 图片仅本轮发送，消费后清空
    _pendingImageBase64 = [];

    StreamWithCancel<CCRespBody> stream;
    try {
      stream = await getChatRespStream(_currentConfig!, msgs, stream: true);
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, _l10n.aiChatException, e.toString());
      setState(() {
        isBotThinking = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      respStream = stream;
    });

    var assistantMsg = AiUiMessage(
      role: 'assistant',
      content: "",
      reasoningContent: "",
      modelName: _currentConfig!.model,
    );

    setState(() {
      uiMessages.add(assistantMsg);
    });

    respStream.stream.listen(
      (crb) {
        if (!mounted) return;

        // 返回[DONE]表示响应正常结束
        if ((crb.customReplyText ?? "").contains('[DONE]')) {
          _finalizeAssistant(assistantMsg, 'done');
        } else if ((crb.customReplyText ?? "").contains('[手动终止]')) {
          // 手动取消的结束标志：按"已终止"状态落库
          _finalizeAssistant(assistantMsg, 'aborted');
        } else {
          // 带error栏位的是出错的正常返回(结构化错误归一化展示)
          if (crb.error != null) {
            assistantMsg.content += "${crb.error?.code}${crb.error?.message}";
            _finalizeAssistant(assistantMsg, 'error');
          } else {
            assistantMsg.content += crb.customReplyText ?? "";
            assistantMsg.reasoningContent =
                (assistantMsg.reasoningContent ?? '') +
                (crb.cusReasoningContent ?? "");

            // 内容有变化，触发重绘流式追加
            setState(() {});
          }

          // 更新token信息
          assistantMsg.promptTokens = crb.usage?.promptTokens;
          assistantMsg.completionTokens = crb.usage?.completionTokens;
          assistantMsg.totalTokens = crb.usage?.totalTokens;

          chatListScrollToBottom();
        }
      },
      onDone: () {
        if (!mounted) return;
        // 流式响应最后一条带[DONE]已处理；这里兜底未正常结束的场景
        if (assistantMsg.status == null) {
          _finalizeAssistant(assistantMsg, 'done');
        }
      },
      onError: (error) {
        if (!mounted) return;
        assistantMsg.content += "\n\n$error";
        _finalizeAssistant(assistantMsg, 'error');
        commonExceptionDialog(context, _l10n.aiChatException, error.toString());
      },
    );
  }

  /// 流结束/取消/出错时统一收口：assistant 消息落库 + 刷新会话快照
  void _finalizeAssistant(AiUiMessage msg, String status) {
    if (msg.status != null) return;
    msg.status = status;

    _dbHelper
        .insertMessage(
          AiMessage(
            conversationId: _conversation.conversationId!,
            role: 'assistant',
            content: msg.content,
            modelName: msg.modelName,
            status: status,
            gmtCreate: getCurrentDateTime(),
          ),
        )
        .then((_) async {
          _conversation.modelName = msg.modelName;
          _conversation.gmtModified = getCurrentDateTime();
          await _dbHelper.updateConversation(_conversation);
        });

    if (!mounted) return;
    setState(() {
      isBotThinking = false;
    });
  }

  /// 重新生成最后一条大模型回复(中间的不行，因为后续问题是关联上下文的)
  void regenerateLatestQuestion() {
    if (isBotThinking || uiMessages.isEmpty) return;
    if (uiMessages.last.role != 'assistant') return;

    setState(() {
      // 删除最后一条 assistant 消息(仅UI层；db 该条在 finalize 时已落库，重新生成也保留历史)
      uiMessages.removeLast();

      // 如果删完只剩最初那条 user 消息(即首轮)，重新生成时带上首轮图片
      if (uiMessages.length == 1 && _firstRoundImageBase64.isNotEmpty) {
        _pendingImageBase64 = List<String>.from(_firstRoundImageBase64);
      }

      _getLlmResponse();
    });
  }

  // ================ 模型选择条 ================

  // 打开模型切换 BottomSheet(候选=全部完整配置；当前项高亮)
  void _showConfigSelector() {
    var candidates = _configService.configs.where((e) => e.isComplete).toList();
    if (candidates.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(10.sp),
                child: Text(
                  _l10n.aiChatSwitchModel,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...candidates.map((c) {
                return ListTile(
                  leading: Icon(
                    c.id == _currentConfig?.id
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: c.id == _currentConfig?.id
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                  title: Text(c.name),
                  subtitle: Text(
                    "${c.model}\n${Uri.tryParse(c.baseUrl)?.host ?? c.baseUrl}",
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  isThreeLine: true,
                  trailing: c.supportsVision
                      ? Tooltip(
                          message: _l10n.aiChatVisionTag,
                          child: Icon(Icons.visibility, size: 18.sp),
                        )
                      : null,
                  onTap: () {
                    _switchConfig(c);
                    Navigator.pop(context);
                  },
                );
              }),
              SizedBox(height: 10.sp),
            ],
          ),
        );
      },
    );
  }

  // 切换模型：记忆"上次使用"，从下一条消息起生效
  void _switchConfig(LlmConfig config) {
    // 切到不支持视觉的模型时，清空已选图片
    if (!config.supportsVision && _selectedImages.isNotEmpty) {
      _selectedImages = [];
      ToastUtils.showToast(_l10n.aiChatModelNoVision);
    }

    _configService.rememberLastConfigId(config.id);
    setState(() {
      _currentConfig = config;
      _conversation.configId = config.id;
      _conversation.configName = config.name;
      _conversation.modelName = config.model;
    });
    _dbHelper.updateConversation(_conversation);
  }

  // ================ 图片选择 ================

  // 从相册选择图片(最多4张，与已选合并计算)
  Future<void> _pickImages() async {
    var remain = supporttedImagesCount - _selectedImages.length;
    if (remain <= 0) {
      ToastUtils.showToast(_l10n.aiChatImageLimit);
      return;
    }

    try {
      final picker = ImagePicker();
      var picked = await picker.pickMultiImage();
      if (picked.isEmpty) return;

      if (!mounted) return;
      setState(() {
        for (var f in picked.take(remain)) {
          _selectedImages.add(f.path);
        }
      });
    } catch (e) {
      if (!mounted) return;
      commonExceptionDialog(context, _l10n.aiChatException, e.toString());
    }
  }

  // ================ 会话管理 ================

  // 修改会话标题
  Future<void> _renameConversation() async {
    var controller = TextEditingController(text: _conversation.title);
    var newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_l10n.aiChatRename),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(CusAL.of(context).cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(CusAL.of(context).confirmLabel),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _conversation.title = newName;
      });
      await _dbHelper.updateConversation(_conversation);
    }
  }

  // 清空当前会话消息(保留会话本身)
  Future<void> _clearMessages() async {
    var confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(CusAL.of(context).tipsTitle),
          content: Text(CusAL.of(context).aiChatClearNote),
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

    await _dbHelper.deleteMessagesByConversation(_conversation.conversationId!);
    if (!mounted) return;
    setState(() {
      uiMessages = [];
      _firstRoundImageBase64 = [];
    });
  }

  // 删除当前会话(级联删消息与图片目录)并返回上一页
  Future<void> _deleteConversation() async {
    var confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(CusAL.of(context).tipsTitle),
          content: Text(CusAL.of(context).aiChatDeleteNote),
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

    await _deleteConversationCompletely(_conversation.conversationId!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // 删除会话的完整清理(消息/会话/图片目录)
  Future<void> _deleteConversationCompletely(int conversationId) async {
    await _dbHelper.deleteMessagesByConversation(conversationId);
    await _dbHelper.deleteConversationById(conversationId);

    var root = _aiImagesRoot;
    if (root != null) {
      var dir = Directory("$root/$conversationId");
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  // 打开自定义角色管理页(返回后刷新角色)
  Future<void> _openManageRoles() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageRolesPage()),
    );
    await _loadCustomRoles();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    // 新会话未发消息时从未落库(见 _ensureConversation)，无需清理

    _scrollController.dispose();
    _userInputController.dispose();
    super.dispose();
  }

  // ================ UI 构建 ================

  @override
  Widget build(BuildContext context) {
    var title = _conversation.title.isEmpty
        ? _currentRole.name(_useEnData)
        : _conversation.title;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // 收起键盘再开侧边栏
            unfocusHandle();
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: GestureDetector(
          onTap: _renameConversation,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') {
                _renameConversation();
              } else if (value == 'clear') {
                _clearMessages();
              } else if (value == 'delete') {
                _deleteConversation();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'rename', child: Text(_l10n.aiChatRename)),
              PopupMenuItem(
                value: 'clear',
                child: Text(_l10n.aiChatClearMessages),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(_l10n.aiChatDeleteConversation),
              ),
            ],
          ),
        ],
      ),
      // 左侧侧边栏(会话历史/新对话/管理角色)；key 变化时重建以刷新历史列表
      drawer: Drawer(
        child: _AiDrawerWidget(
          key: ValueKey(
            'ai_drawer_${_conversation.conversationId}_${uiMessages.length}',
          ),
          currentConversationId: _conversation.conversationId,
          customRoles: _customRoles,
          onNewChatByRole: (roleKey) {
            // 2026-08-28 切换新对话=替换当前聊天页(而非叠栈)：
            // 返回键直接回到入口页(主页/饮食日记等)，不会逐层退回历史页面
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => AiChatScreen(roleKey: roleKey),
              ),
            );
          },
          onOpenManageRoles: _openManageRoles,
          onDeleteConversation: _deleteConversationCompletely,
        ),
      ),
      body: GestureDetector(
        // 允许子控件(如TextField)接收点击事件
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击空白处可以移除焦点，关闭键盘
          unfocusHandle();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// AppBar 下方固定模型选择条(不放 AppBar：避免与其他操作/长名称冲突)
            _buildModelBar(),

            /// 显示对话消息主体
            buildChatListArea(),

            /// 已选图片缩略图(可删除)
            if (_selectedImages.isNotEmpty) _buildSelectedImagesArea(),

            /// 显示输入框和发送按钮
            const Divider(),
            buildUserSendArea(),
          ],
        ),
      ),
    );
  }

  // 固定模型选择条：左侧角色标识，右侧当前配置·模型(点击切换)
  Widget _buildModelBar() {
    var configName = _currentConfig?.name ?? _l10n.aiChatNoConfigName;
    var modelName = _currentConfig?.model ?? "";

    return Material(
      color: Theme.of(context).secondaryHeaderColor,
      child: InkWell(
        onTap: _showConfigSelector,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
          child: Row(
            children: [
              Icon(_currentRole.icon, size: 18.sp),
              SizedBox(width: 4.sp),
              Text(
                _currentRole.name(_useEnData),
                style: TextStyle(fontSize: 13.sp),
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: Text(
                  "$configName·$modelName",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建对话列表主体(空会话时显示角色建议问题气泡)
  Expanded buildChatListArea() {
    // 空会话：显示角色建议问题(点击即作为首条消息发送)
    if (!isLoading && uiMessages.isEmpty) {
      return Expanded(
        child: ListView(
          controller: _scrollController,
          children: [
            Padding(
              padding: EdgeInsets.all(10.sp),
              child: Text(
                _l10n.aiChatAskWith(_currentRole.name(_useEnData)),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            _buildSuggestedQuestions(),
          ],
        ),
      );
    }

    return Expanded(
      child: isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2.sp))
          : ListView.builder(
              controller: _scrollController,
              itemCount: uiMessages.length,
              itemBuilder: (context, index) {
                var message = uiMessages[index];

                return Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: Column(
                    children: [
                      MessageItem(
                        message: message,
                        // 只有最后一个才显示加载圈
                        isBotThinking: index == uiMessages.length - 1
                            ? isBotThinking
                            : false,
                      ),

                      // 大模型回复完成后的功能按钮行(重新生成/复制/token统计)
                      if (message.role == "assistant" && !isBotThinking)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // 最后一条回复可以重新生成
                            if (index == uiMessages.length - 1)
                              TextButton(
                                onPressed: regenerateLatestQuestion,
                                child: Text(_l10n.aiChatRegenerate),
                              ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: message.content),
                                );
                                ToastUtils.showToast(
                                  _l10n.aiChatCopied,
                                  duration: const Duration(seconds: 3),
                                  align: Alignment.center,
                                );
                              },
                              icon: Icon(Icons.copy, size: 20.sp),
                            ),
                            if (message.totalTokens != null)
                              Text(
                                _l10n.aiChatTokenUsage(
                                  message.promptTokens ?? 0,
                                  message.completionTokens ?? 0,
                                  message.totalTokens ?? 0,
                                ),
                                style: TextStyle(fontSize: 10.sp),
                              ),
                            SizedBox(width: 10.sp),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // 空会话的角色建议问题气泡(点击即作为首条消息发送)
  Widget _buildSuggestedQuestions() {
    var questions = _currentRole.suggestedQuestions(_useEnData);
    if (questions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: questions
          .map(
            (q) => Padding(
              padding: EdgeInsets.all(5.sp),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  label: Text(q, style: TextStyle(fontSize: 13.sp)),
                  onPressed: () {
                    _sendMessage(q);
                  },
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // 已选图片缩略图区(可删除)
  Widget _buildSelectedImagesArea() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      child: SizedBox(
        height: 70.sp,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedImages.length,
          itemBuilder: (context, index) {
            var path = _selectedImages[index];
            return Padding(
              padding: EdgeInsets.all(3.sp),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _previewImage(path),
                    child: Image.file(
                      File(path),
                      width: 64.sp,
                      height: 64.sp,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset(
                        placeholderImageUrl,
                        fit: BoxFit.scaleDown,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(1.sp),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 点击图片全屏预览
  void _previewImage(String path) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Image.file(
            File(path),
            errorBuilder: (_, _, _) =>
                Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown),
          ),
        );
      },
    );
  }

  /// 用户发送消息的区域
  Padding buildUserSendArea() {
    return Padding(
      padding: EdgeInsets.all(5.sp),
      child: Row(
        children: [
          // 仅视觉模型显示图片上传入口
          if (_currentConfig?.supportsVision == true)
            IconButton(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              tooltip: _l10n.aiChatAddImage,
            ),
          Expanded(
            child: TextField(
              controller: _userInputController,
              decoration: InputDecoration(
                hintText: _l10n.aiChatInputHint,
                hintStyle: TextStyle(fontSize: 15.sp, color: Colors.grey),
                border: const OutlineInputBorder(),
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
          SizedBox(width: 5.sp),

          // 如果是API响应中，可以点击终止
          isBotThinking
              ? IconButton(
                  onPressed: () async {
                    await respStream.cancel();
                  },
                  icon: const Icon(Icons.stop),
                )
              : IconButton(
                  // AI响应中或没有任何输入(文本和图片都空)时不让点击发送
                  onPressed:
                      isBotThinking ||
                          (userInput.isEmpty && _selectedImages.isEmpty)
                      ? null
                      : () {
                          // 失去焦点，从而收起键盘
                          unfocusHandle();

                          if (_selectedImages.isNotEmpty) {
                            // 带图发送
                            var images = List<String>.from(_selectedImages);
                            var text = userInput;
                            _sendMessageWithImages(text, images);
                          } else {
                            _sendMessage(userInput);
                          }
                        },
                  icon: const Icon(Icons.send),
                ),
        ],
      ),
    );
  }
}

///
/// 侧边栏(左侧 Drawer)：
/// 顶部"新对话"角色选择区 + "管理角色"入口；下方会话历史列表(按修改时间倒序)。
/// 通过 ValueKey 变化触发重建，保证每次打开/发消息后列表最新。
///
class _AiDrawerWidget extends StatefulWidget {
  final int? currentConversationId;
  final List<AiCustomRole> customRoles;
  final void Function(String roleKey) onNewChatByRole;
  final Future<void> Function() onOpenManageRoles;
  final Future<void> Function(int conversationId) onDeleteConversation;

  const _AiDrawerWidget({
    super.key,
    required this.currentConversationId,
    required this.customRoles,
    required this.onNewChatByRole,
    required this.onOpenManageRoles,
    required this.onDeleteConversation,
  });

  @override
  State<_AiDrawerWidget> createState() => _AiDrawerWidgetState();
}

class _AiDrawerWidgetState extends State<_AiDrawerWidget> {
  final DBAiHelper _dbHelper = DBAiHelper();

  List<AiConversation> conversations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    var temp = await _dbHelper.queryConversationList();
    if (!mounted) return;
    setState(() {
      conversations = temp;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 2026-08-27 UI 文案走 ARB；角色"数据"的双语变体按实际 locale 选择(非 zh 回退英文)
    var l10n = CusAL.of(context);
    var useEnData = Localizations.localeOf(context).languageCode != 'zh';

    // 全部角色(内置 + 自定义)
    var roles = [
      ...builtinAiRoles,
      ...widget.customRoles.map((c) => AiRole.fromCustom(c)),
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12.sp),
            child: Text(
              l10n.aiChatTitle,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),

          // 新对话区标题行 + "管理角色"入口
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.sp),
            child: Row(
              children: [
                Text(
                  l10n.aiChatNewChat,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.onOpenManageRoles();
                  },
                  icon: Icon(Icons.manage_accounts, size: 18.sp),
                  label: Text(
                    l10n.aiChatManageRoles,
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ],
            ),
          ),

          /// 角色选择区(占上方约1/3，可滚动)：
          /// 角色数量多时固定比例滚动，避免挤占下方对话历史区域
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
              child: Wrap(
                spacing: 6.sp,
                runSpacing: 6.sp,
                children: roles
                    .map(
                      (r) => ActionChip(
                        avatar: Icon(r.icon, size: 16.sp),
                        label: Text(
                          r.name(useEnData),
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onNewChatByRole(r.key);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          Divider(height: 12.sp),

          // 会话历史区(占下方约2/3)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.sp),
                  child: Text(
                    l10n.aiChatHistory,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            width: 20.sp,
                            height: 20.sp,
                            child: CircularProgressIndicator(strokeWidth: 2.sp),
                          ),
                        )
                      : conversations.isEmpty
                      ? Center(
                          child: Text(
                            l10n.aiChatNoHistory,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadConversations,
                          child: ListView.builder(
                            itemCount: conversations.length,
                            itemBuilder: (context, index) {
                              var conv = conversations[index];
                              var role = resolveAiRole(
                                conv.roleKey,
                                customRoles: widget.customRoles,
                              );

                              return ListTile(
                                leading: Icon(role.icon),
                                dense: true,
                                title: Text(
                                  conv.title.isEmpty
                                      ? role.name(useEnData)
                                      : conv.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  "${role.name(useEnData)} · ${conv.gmtModified ?? ''}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11.sp),
                                ),
                                trailing:
                                    conv.conversationId ==
                                        widget.currentConversationId
                                    ? Icon(
                                        Icons.location_on,
                                        size: 16.sp,
                                        color: Theme.of(context).primaryColor,
                                      )
                                    : IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 18.sp,
                                        ),
                                        onPressed: () async {
                                          var confirmed =
                                              await showDialog<bool>(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                      CusAL.of(
                                                        context,
                                                      ).tipsTitle,
                                                    ),
                                                    content: Text(
                                                      CusAL.of(
                                                        context,
                                                      ).aiChatDeleteShort,
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: Text(
                                                          CusAL.of(
                                                            context,
                                                          ).cancelLabel,
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: Text(
                                                          CusAL.of(
                                                            context,
                                                          ).confirmLabel,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                          if (confirmed != true) return;
                                          await widget.onDeleteConversation(
                                            conv.conversationId!,
                                          );
                                          await _loadConversations();
                                        },
                                      ),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (conv.conversationId !=
                                      widget.currentConversationId) {
                                    // 2026-08-28 切换历史会话=替换当前聊天页(而非叠栈)：
                                    // 无论切换多少次，返回键都直接回到入口页
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AiChatScreen(
                                          roleKey: conv.roleKey,
                                          conversationId: conv.conversationId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

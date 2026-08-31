import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/constants/constants.dart';
import '../models/cus_app_localizations.dart';
import '../models/paid_llm/llm_config.dart';
import '../views/me/llm_config/modify_config.dart';

///
/// 2026-08-27 大模型配置的统一读写入口
///
/// - 持久化：GetStorage(key: llm_configs 存 `List<LlmConfig>` 的 JSON 串，
///   llm_last_config_id 存"上次使用"记忆)；
/// - 多配置存管，无"启用"概念，使用时按规则智能选中(见 pickFromList)；
/// - 配置变更通过 ValueNotifier 通知(配置页/聊天页监听刷新)；
///
class LlmConfigService {
  // 单例模式
  static final LlmConfigService _instance = LlmConfigService._createInstance();
  factory LlmConfigService() => _instance;
  LlmConfigService._createInstance();

  static const String storageKeyConfigs = 'llm_configs';
  static const String storageKeyLastConfigId = 'llm_last_config_id';

  // 配置列表变更通知
  final ValueNotifier<List<LlmConfig>> configsNotifier = ValueNotifier([]);

  // 上次通知给监听者的规范化 JSON 快照(load 用于判断"内容是否真的变了")
  String? _lastNotifyJson;

  List<LlmConfig> get configs => configsNotifier.value;

  /// 从 GetStorage 加载配置列表(应用启动或配置页/聊天页进入时调用)
  ///
  /// 2026-08-27 修正：本方法常被各页面 initState 同步调用(GetStorage 读取是同步的，
  /// 整个方法体会跑在调用方的 build 阶段)，之前直接给 notifier 赋值会在 build 期
  /// 同步 notifyListeners → 其他页面的 ValueListenableBuilder 抛出
  /// "setState/markNeedsBuild called during build"。
  /// 现在两层防护：
  /// 1. 解码结果与上次通知内容一致时直接返回，不产生任何无谓的通知；
  /// 2. 内容确有变化也通过 scheduleMicrotask 把赋值挪出当前 build 帧
  ///    (微任务先于 load() 的 await 续体执行，不影响"load 后立取 configs"的用法)。
  Future<void> load() async {
    List<LlmConfig> temp = [];
    String? raw = box.read(storageKeyConfigs);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        var decoded = json.decode(raw);
        // 兼容旧版本存成 List 的情况
        List list = decoded is List ? decoded : [];
        temp = list
            .map((e) => LlmConfig.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        // 数据损坏时不抛错，按空配置处理
        temp = [];
      }
    }
    temp.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    var snapshot = json.encode(temp.map((e) => e.toMap()).toList());
    if (snapshot == _lastNotifyJson) return;

    _lastNotifyJson = snapshot;
    scheduleMicrotask(() => configsNotifier.value = temp);
  }

  /// 持久化当前列表
  Future<void> _persist() async {
    var list = List<LlmConfig>.from(configs)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    var snapshot = json.encode(list.map((e) => e.toMap()).toList());
    await box.write(storageKeyConfigs, snapshot);
    // 写库的内容即最新快照，避免随后的 load() 误判"有变化"再次通知
    _lastNotifyJson = snapshot;
  }

  /// 新增配置(自动排到列表末尾)
  Future<void> add(LlmConfig config) async {
    var temp = List<LlmConfig>.from(configs);
    config.sortOrder = temp.length;
    temp.add(config);
    configsNotifier.value = temp;
    await _persist();
  }

  /// 修改配置(id 不变)
  Future<void> update(LlmConfig config) async {
    var temp = List<LlmConfig>.from(configs);
    for (var i = 0; i < temp.length; i++) {
      if (temp[i].id == config.id) {
        temp[i] = config;
        break;
      }
    }
    configsNotifier.value = temp;
    await _persist();
  }

  /// 删除配置(同时清理"上次使用"记忆)
  Future<void> delete(String id) async {
    configsNotifier.value = configs.where((e) => e.id != id).toList();
    if (getLastConfigId() == id) {
      await box.remove(storageKeyLastConfigId);
    }
    await _persist();
  }

  /// 上移/下移排序(dir: -1 上移，1 下移)
  Future<void> moveOrder(String id, int dir) async {
    var temp = List<LlmConfig>.from(configs)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    var index = temp.indexWhere((e) => e.id == id);
    var target = index + dir;
    if (index < 0 || target < 0 || target >= temp.length) return;
    var t = temp[index];
    temp[index] = temp[target];
    temp[target] = t;
    for (var i = 0; i < temp.length; i++) {
      temp[i].sortOrder = i;
    }
    configsNotifier.value = temp;
    await _persist();
  }

  String? getLastConfigId() => box.read(storageKeyLastConfigId) as String?;

  Future<void> rememberLastConfigId(String id) async {
    await box.write(storageKeyLastConfigId, id);
  }

  /// 智能选中(纯函数便于单测)：
  /// 1. 过滤掉三要素不完整的配置；图片场景再过滤 supportsVision=false；
  /// 2. 候选为空返回 null；
  /// 3. 候选只有 1 个直接选中；多个则优先"上次使用过的"，否则列表第一个；
  static LlmConfig? pickFromList(
    List<LlmConfig> list,
    String? lastId, {
    bool needVision = false,
  }) {
    var candidates = list.where((e) => e.isComplete).toList();
    if (needVision) {
      candidates = candidates.where((e) => e.supportsVision).toList();
    }
    if (candidates.isEmpty) return null;

    for (var e in candidates) {
      if (e.id == lastId) return e;
    }

    candidates.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return candidates.first;
  }

  /// 运行时选中(会自动记忆为"上次使用")
  LlmConfig? pickConfig({bool needVision = false}) {
    var picked = pickFromList(
      configs,
      getLastConfigId(),
      needVision: needVision,
    );
    if (picked != null) {
      rememberLastConfigId(picked.id);
    }
    return picked;
  }

  // ===================== 备份恢复支持 =====================

  /// 导出全部配置(供全量备份 zip 使用)
  List<Map<String, dynamic>> exportMaps() {
    return configs.map((e) => e.toMap()).toList();
  }

  /// 整体覆盖恢复(重复恢复同一备份无重复数据)
  Future<void> importMaps(List<Map<String, dynamic>> maps) async {
    var temp = maps.map((e) => LlmConfig.fromMap(e)).toList();
    for (var i = 0; i < temp.length; i++) {
      temp[i].sortOrder = i;
    }
    _lastNotifyJson = null; // 恢复内容可能相同也可能不同，强制下一次 load 重新通知
    configsNotifier.value = temp;
    await _persist();
  }
}

///
/// 统一的门禁函数(需求核心)：
/// 所有 AI 入口(全局悬浮按钮/运动饮食模块内快捷入口)调用；
/// - 未配置任何模型 → 弹窗引导去配置页，返回 null；
/// - 图片场景但没有视觉配置 → 单独提示，返回 null；
/// - 校验通过 → 返回智能选中的配置；
///
Future<LlmConfig?> ensureLlmConfigured(
  BuildContext context, {
  bool needVision = false,
}) async {
  var svc = LlmConfigService();
  await svc.load();

  // load 是异步间隙，之后再用 context 需要挂载检查
  if (!context.mounted) return null;

  // 完全没有任何可用配置
  if (svc.pickConfig(needVision: false) == null) {
    var goConfig = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(CusAL.of(context).tipsTitle),
          content: Text(CusAL.of(context).llmGateNoKey),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(CusAL.of(context).cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(CusAL.of(context).llmGateGoConfig),
            ),
          ],
        );
      },
    );
    if (goConfig == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ModifyLlmConfig()),
      );
    }
    return null;
  }

  // 有文本配置，但图片场景没有视觉配置
  if (needVision && svc.pickConfig(needVision: true) == null) {
    var goConfig = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(CusAL.of(context).tipsTitle),
          content: Text(CusAL.of(context).llmGateNoVision),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(CusAL.of(context).cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(CusAL.of(context).llmGateGoConfig),
            ),
          ],
        );
      },
    );
    if (goConfig == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ModifyLlmConfig()),
      );
    }
    return null;
  }

  return svc.pickConfig(needVision: needVision);
}

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:toastification/toastification.dart';

import '../../models/cus_app_localizations.dart';

class TtsEngineHelper {
  static const String _selectedEngineKey = 'selected_tts_engine';
  static final GetStorage _storage = GetStorage();

  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isWeb => kIsWeb;

  /// 检查TTS引擎并处理选择逻辑
  /// 返回值：true表示可以继续跟练，false表示用户主动取消(仅多引擎选择被取消时)
  /// 2026-08-28 无TTS引擎不再中断跟练：语音只是增强体验，跟练本身不依赖TTS
  static Future<bool> checkAndSelectTtsEngine(BuildContext context) async {
    if (!context.mounted) return false;

    final FlutterTts flutterTts = FlutterTts();

    try {
      // 获取可用的TTS引擎列表
      List<dynamic>? engines;
      if (isAndroid) {
        engines = await flutterTts.getEngines;

        debugPrint("可用TTS引擎: $engines");

        flutterTts.getVoices.then((value) => debugPrint("所有语音 $value"));
      }

      if (!context.mounted) return false;

      // 如果是iOS或其他平台，或者Android上没有引擎列表
      if (engines == null || engines.isEmpty) {
        // 尝试获取默认引擎来检查是否有TTS支持
        var defaultEngine = await flutterTts.getDefaultEngine;

        if (!context.mounted) return false;

        if (defaultEngine == null) {
          // 2026-08-28 无TTS引擎(或平台不支持)：静默放行，跟练本身不依赖语音。
          // "无引擎"提示统一由跟练页 initTts 负责——入口可能有多个，跟练页只有一个
          return true;
        } else {
          // 有默认引擎，显示信息并继续
          _showEngineInfoToast(context, defaultEngine);
          return true;
        }
      }

      // Android平台有引擎列表
      // 首先检查是否已经有保存的引擎选择
      String? savedEngine = getSelectedEngine();
      if (savedEngine != null && engines.contains(savedEngine)) {
        // 使用已保存的引擎
        await flutterTts.setEngine(savedEngine);
        if (!context.mounted) return true;
        _showEngineInfoToast(context, savedEngine);
        return true;
      }

      if (engines.length == 1) {
        // 只有一个引擎
        String engineName = engines.first.toString();
        await _setSelectedEngine(engineName);
        await flutterTts.setEngine(engineName);

        if (!context.mounted) return true;
        _showEngineInfoToast(context, engineName);
        return true;
      } else {
        // 多个引擎，需要用户选择
        String? selectedEngine = await _showEngineSelectionDialog(
          context,
          engines,
        );
        if (selectedEngine != null) {
          await _setSelectedEngine(selectedEngine);
          await flutterTts.setEngine(selectedEngine);
          return true;
        } else {
          return false; // 用户取消选择
        }
      }
    } catch (e) {
      debugPrint('TTS引擎检查出错: $e');
      // 出错时显示警告但允许继续
      if (context.mounted) {
        _showEngineWarningToast(context);
      }
      return true;
    }
  }

  /// 获取已保存的TTS引擎
  static String? getSelectedEngine() {
    return _storage.read(_selectedEngineKey);
  }

  /// 保存选定的TTS引擎
  static Future<void> _setSelectedEngine(String engineName) async {
    await _storage.write(_selectedEngineKey, engineName);
  }

  /// 清除已保存的TTS引擎设置（用于重新选择）
  static Future<void> clearSelectedEngine() async {
    await _storage.remove(_selectedEngineKey);
  }

  /// 应用已保存的TTS引擎设置
  static Future<void> applySelectedEngine(FlutterTts flutterTts) async {
    if (isAndroid) {
      String? selectedEngine = getSelectedEngine();
      if (selectedEngine != null) {
        try {
          await flutterTts.setEngine(selectedEngine);
        } catch (e) {
          debugPrint('应用TTS引擎设置失败: $e');
        }
      }
    }
  }

  /// 显示TTS引擎信息提示
  static void _showEngineInfoToast(BuildContext context, String engineName) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      title: Text(CusAL.of(context).ttsEngineInfo(engineName)),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  /// 显示TTS引擎警告提示
  static void _showEngineWarningToast(BuildContext context) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      title: Text(CusAL.of(context).ttsEngineCheckFail),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  /// 显示TTS引擎选择对话框
  static Future<String?> _showEngineSelectionDialog(
    BuildContext context,
    List<dynamic> engines,
  ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(CusAL.of(context).selectTtsEngine),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(CusAL.of(context).multipleTtsEnginesFound),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: engines.length > 4 ? 200 : null,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: engines.length,
                  itemBuilder: (context, index) {
                    String engineName = engines[index].toString();
                    return Card(
                      child: ListTile(
                        title: Text(
                          engineName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        onTap: () {
                          Navigator.of(context).pop(engineName);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(CusAL.of(context).cancelLabel),
            ),
          ],
        );
      },
    );
  }
}

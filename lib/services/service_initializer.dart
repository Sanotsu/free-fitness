import 'package:flutter/foundation.dart';

import '../core/utils/toast_utils.dart';
import '../core/widgets/import_progress_overlay.dart';
import 'exercise_importer_service.dart';
import 'food_importer_service.dart';

/// 服务初始化类，负责初始化应用需要的各种服务
class ServiceInitializer {
  static final ServiceInitializer _instance = ServiceInitializer._internal();
  factory ServiceInitializer() => _instance;

  ServiceInitializer._internal();

  final ExerciseImporterService _exerciseImporter = ExerciseImporterService();
  final FoodImporterService _foodImporter = FoodImporterService();

  /// 初始化所有服务
  Future<void> initializeServices(String languageCode) async {
    // 导入期间显示带进度的浮层(进度由两个导入服务通过 ImportProgressCenter 上报)
    final closeOverlay = showImportProgressOverlay();

    try {
      // 可以根据传入的languageCode，初始化不同的数据，注意，初始化后指定了数据，后续切换UI的语言时，数据不会跟着变化

      // 初始化内置运动数据
      await _exerciseImporter.importEmbeddedExercises(languageCode);

      // 初始化内置食品数据
      await _foodImporter.importEmbeddedFoods(languageCode);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('初始化服务时出错: $e');
      }
      ToastUtils.showError(
        languageCode == 'zh' ? '初始化服务时出错' : 'Error initializing services',
      );
    } finally {
      closeOverlay();
    }
  }
}

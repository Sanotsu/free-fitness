import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import '../core/storage/db_training_helper.dart';
import '../core/utils/import_progress.dart';
import '../core/utils/toast_utils.dart';
import '../core/utils/tools.dart';
import '../core/constants/constants.dart';
import '../models/custom_exercise.dart';
import '../models/training_state.dart';

/// 负责在应用初始化时导入内置的基础动作数据
class ExerciseImporterService {
  final DBTrainingHelper _dbHelper = DBTrainingHelper();
  final box = GetStorage();

  static const String _embeddedEnExerciseJsonPath =
      'assets/datasets/free-exercise-db-en.json';
  static const String _embeddedZhExerciseJsonPath =
      'assets/datasets/free-exercise-db-zh.json';

  static const String imagePerfix =
      'https://raw.githubusercontent.com/Sanotsu/free-exercise-db-chinese/refs/heads/main/exercises/';

  /// 检查并导入内置的基础动作数据
  Future<void> importEmbeddedExercises(String languageCode) async {
    // (注意：本服务直接按固定文件名加载 json，不依赖 AssetManifest 枚举)
    bool isZh = languageCode == 'zh';

    try {
      // 检查是否已经导入过
      bool alreadyImported = _checkIfAlreadyImported();
      if (alreadyImported) {
        if (kDebugMode) {
          debugPrint('基础动作数据已经导入过，跳过导入步骤');
        }
        return;
      }

      // 读取内置的JSON文件
      final String jsonData = await rootBundle.loadString(
        isZh ? _embeddedZhExerciseJsonPath : _embeddedEnExerciseJsonPath,
      );
      final List<dynamic> exerciseList = json.decode(jsonData);

      // 转换为CustomExercise对象列表
      final List<CustomExercise> customExercises = exerciseList
          .map((json) => CustomExercise.fromJson(json))
          .toList();

      // 逐条入库并上报进度(每10条刷新一次，避免过于频繁地重建UI)
      int total = customExercises.length;
      int importedCount = 0;
      String title = isZh ? '正在初始化“基础动作”数据' : "Initializing Exercise Data";

      for (int i = 0; i < total; i++) {
        bool success = await _saveSingleExercise(customExercises[i]);
        if (success) importedCount++;

        if ((i + 1) % 10 == 0 || i + 1 == total) {
          ImportProgressCenter.update(
            ImportProgress(
              title: title,
              detail: isZh
                  ? '已写入数据库 $importedCount 条'
                  : '$importedCount records saved',
              current: i + 1,
              total: total,
            ),
          );
        }
      }

      // 标记为已导入
      _markAsImported();

      ToastUtils.showSuccess(
        isZh
            ? '成功导入 $importedCount 条基础动作数据'
            : "Successfully imported $importedCount exercises",
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      ToastUtils.showError(
        isZh ? '导入基础动作数据时出错: $e' : 'Error importing exercise data: $e',
      );
    } finally {
      ImportProgressCenter.update(null);
    }
  }

  /// 检查是否已经导入过数据
  bool _checkIfAlreadyImported() {
    // 使用GetStorage检查是否已导入
    return box.read(LocalStorageKey.exerciseDataImported) == true;
  }

  /// 标记数据已经导入
  void _markAsImported() {
    // 使用GetStorage标记已导入
    box.write(LocalStorageKey.exerciseDataImported, true);
  }

  /// 将单个CustomExercise转换为Exercise并保存到数据库，返回是否成功
  Future<bool> _saveSingleExercise(CustomExercise cusExercise) async {
    // 将CustomExercise转换为Exercise
    var exercise = Exercise(
      // json文件的id就是代号
      exerciseCode: cusExercise.code ?? cusExercise.id ?? '',
      exerciseName: cusExercise.name ?? "",
      category: cusExercise.category ?? "",

      force: cusExercise.force,
      level: cusExercise.level,
      mechanic: cusExercise.mechanic,
      equipment: cusExercise.equipment,
      primaryMuscles: cusExercise.primaryMuscles?.join(","),
      secondaryMuscles: cusExercise.secondaryMuscles?.join(","),
      instructions: cusExercise.instructions?.join("\n\n"),
      // 直接使用我github地址，使用网络图片
      images:
          cusExercise.images?.map((e) => imagePerfix + e).toList().join(",") ??
          placeholderImageUrl,
      // 这几个原json没有的
      countingMode: cusExercise.countingMode ?? countingOptions.first.value,
      standardDuration: int.tryParse(cusExercise.standardDuration ?? "1") ?? 1,
      ttsNotes: cusExercise.ttsNotes,
      isCustom: false,
      contributor: "system",
      gmtCreate: getCurrentDateTime(),
    );

    try {
      // 将基础动作数据插入数据库
      await _dbHelper.insertExercise(exercise);
      return true;
    } catch (e) {
      // 如果是唯一约束错误，则跳过
      if (kDebugMode) {
        debugPrint('导入基础动作数据时出错 (${cusExercise.id}): $e');
      }
      return false;
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import '../core/storage/db_training_helper.dart';
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
    dynamic closeToast;

    try {
      // 检查是否已经导入过
      bool alreadyImported = _checkIfAlreadyImported();
      if (alreadyImported) {
        if (kDebugMode) {
          print('基础动作数据已经导入过，跳过导入步骤');
        }
        return;
      }

      closeToast = ToastUtils.showLoading(
        languageCode == 'zh'
            ? '正在初始化“基础动作”数据...'
            : "Initializing Exercise Data...",
        Alignment.center,
      );

      // 读取内置的JSON文件
      final String jsonData = await rootBundle.loadString(
        languageCode == 'zh'
            ? _embeddedZhExerciseJsonPath
            : _embeddedEnExerciseJsonPath,
      );
      final List<dynamic> exerciseList = json.decode(jsonData);

      // 转换为CustomExercise对象列表
      final List<CustomExercise> customExercises = exerciseList
          .map((json) => CustomExercise.fromJson(json))
          .toList();

      // 转换为Exercise对象列表并保存到数据库
      await _saveExercisesToDatabase(customExercises);

      // 标记为已导入
      _markAsImported();

      ToastUtils.showSuccess(
        '成功导入 ${customExercises.length} 条基础动作数据',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      ToastUtils.showError('导入基础动作数据时出错: $e');
    } finally {
      if (closeToast != null) {
        closeToast();
      }
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

  /// 将CustomExercise列表转换为Exercise对象并保存到数据库
  Future<void> _saveExercisesToDatabase(
    List<CustomExercise> customExercises,
  ) async {
    // 处理每个运动记录
    for (var cusExercise in customExercises) {
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
            cusExercise.images
                ?.map((e) => imagePerfix + e)
                .toList()
                .join(",") ??
            placeholderImageUrl,
        // 这几个原json没有的
        countingMode: cusExercise.countingMode ?? countingOptions.first.value,
        standardDuration:
            int.tryParse(cusExercise.standardDuration ?? "1") ?? 1,
        ttsNotes: cusExercise.ttsNotes,
        isCustom: false,
        contributor: "system",
        gmtCreate: getCurrentDateTime(),
      );

      try {
        // 将基础动作数据插入数据库
        await _dbHelper.insertExercise(exercise);
      } catch (e) {
        // 如果是唯一约束错误，则跳过
        if (kDebugMode) {
          print('导入基础动作数据时出错 (${cusExercise.id}): $e');
        }
      }
    }
  }
}

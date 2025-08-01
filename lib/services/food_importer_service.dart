import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import '../core/storage/db_dietary_helper.dart';
import '../core/utils/toast_utils.dart';
import '../core/utils/tools.dart';
import '../core/constants/constants.dart';
import '../models/food_composition.dart';
import '../models/dietary_state.dart';

/// 负责在应用初始化时导入内置的食物成分数据
class FoodImporterService {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
  final box = GetStorage();

  static const String _embeddedFoodsDir =
      'assets/datasets/china-food-composition';

  /// 检查并导入内置的食物成分数据
  Future<void> importEmbeddedFoods(String languageCode) async {
    dynamic closeToast;
    try {
      // 检查是否已经导入过
      bool alreadyImported = _checkIfAlreadyImported();
      if (alreadyImported) {
        if (kDebugMode) {
          print('食物成分数据已经导入过，跳过导入步骤');
        }
        return;
      }

      closeToast = ToastUtils.showLoading(
        languageCode == 'zh'
            ? '正在初始化“食物成分”数据...'
            : 'Initializing Food Composition Data...',
        Alignment.center,
      );

      // 获取指定目录下所有json文件的列表
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final foodJsonFiles = manifestMap.keys
          .where(
            (key) => key.startsWith(_embeddedFoodsDir) && key.endsWith('.json'),
          )
          .toList();

      if (foodJsonFiles.isEmpty) {
        if (kDebugMode) {
          print('没有找到食物成分数据文件');
        }
        return;
      }

      int importedCount = 0;

      // 处理每个json文件
      for (final filePath in foodJsonFiles) {
        try {
          final jsonData = await rootBundle.loadString(filePath);
          final List<dynamic> foodList = json.decode(jsonData);

          // 转换为FoodComposition对象列表
          final List<FoodComposition> foodCompositions = foodList
              .map((json) => FoodComposition.fromJson(json))
              .toList();

          // 保存到数据库
          final count = await _saveFoodsToDatabase(foodCompositions);
          importedCount += count;
        } catch (e) {
          ToastUtils.showError('处理文件 $filePath 时出错: $e');
        }
      }

      // 标记为已导入
      _markAsImported();

      ToastUtils.showSuccess(
        '成功导入 $importedCount 条食物成分数据',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      ToastUtils.showError('导入食物成分数据时出错: $e');
    } finally {
      if (closeToast != null) {
        closeToast();
      }
    }
  }

  /// 检查是否已经导入过数据
  bool _checkIfAlreadyImported() {
    // 使用GetStorage检查是否已导入
    return box.read(LocalStorageKey.foodDataImported) == true;
  }

  /// 标记数据已经导入
  void _markAsImported() {
    // 使用GetStorage标记已导入
    box.write(LocalStorageKey.foodDataImported, true);
  }

  /// 将FoodComposition列表转换为Food对象并保存到数据库
  Future<int> _saveFoodsToDatabase(
    List<FoodComposition> foodCompositions,
  ) async {
    int successCount = 0;

    // 处理每个食品记录
    for (var comp in foodCompositions) {
      // 将FoodComposition转换为Food和ServingInfo
      var food = Food(
        brand: comp.foodCode ?? '',
        product: comp.foodName ?? "",
        description: '数据来自《中国食物成分表标准版(第6版)》',
        contributor: "system",
        gmtCreate: getCurrentDateTime(),
        isDeleted: false,
      );

      // 创建营养素信息
      var serving = ServingInfo(
        foodId: 0, // 将在insertFoodWithServingInfoList中自动设置
        servingSize: 1,
        servingUnit: "100g",
        energy: double.tryParse(comp.energyKJ ?? "0") ?? 0,
        energyKCal: double.tryParse(comp.energyKCal ?? "0") ?? 0,
        protein: double.tryParse(comp.protein ?? "0") ?? 0,
        totalFat: double.tryParse(comp.fat ?? "0") ?? 0,
        totalCarbohydrate: double.tryParse(comp.cHO ?? "0") ?? 0,
        sodium: double.tryParse(comp.na ?? "0") ?? 0,
        potassium: double.tryParse(comp.k ?? "0") ?? 0,
        cholesterol: double.tryParse(comp.cholesterol ?? "0") ?? 0,
        dietaryFiber: double.tryParse(comp.dietaryFiber ?? "0") ?? 0,
        contributor: "system",
        gmtCreate: getCurrentDateTime(),
        isDeleted: false,
      );

      try {
        // 将食品数据插入数据库
        await _dietaryHelper.insertFoodWithServingInfoList(
          food: food,
          servingInfoList: [serving],
        );
        successCount++;
      } catch (e) {
        if (kDebugMode) {
          print('导入食物成分数据时出错 (${comp.foodCode}): $e');
        }
      }
    }

    return successCount;
  }
}

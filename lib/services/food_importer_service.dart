import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import '../core/storage/db_dietary_helper.dart';
import '../core/utils/import_progress.dart';
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
    bool isZh = languageCode == 'zh';

    try {
      // 检查是否已经导入过
      bool alreadyImported = _checkIfAlreadyImported();
      if (alreadyImported) {
        if (kDebugMode) {
          debugPrint('食物成分数据已经导入过，跳过导入步骤');
        }
        return;
      }

      String title = isZh
          ? '正在初始化“食物成分”数据'
          : 'Initializing Food Composition Data...';

      // 获取指定目录下所有json文件的列表
      // (新版 Flutter 不再生成文本版 AssetManifest.json，改用框架内置的
      //  AssetManifest API 读取二进制 AssetManifest.bin)
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final foodJsonFiles = manifest
          .listAssets()
          .where(
            (key) => key.startsWith(_embeddedFoodsDir) && key.endsWith('.json'),
          )
          .toList();

      if (foodJsonFiles.isEmpty) {
        if (kDebugMode) {
          debugPrint('没有找到食物成分数据文件');
        }
        return;
      }

      // 第一阶段：读取并解析全部分册文件(此阶段很快)，以得到总条数用于进度展示
      final List<List<FoodComposition>> batches = [];
      for (int f = 0; f < foodJsonFiles.length; f++) {
        final filePath = foodJsonFiles[f];
        try {
          final jsonData = await rootBundle.loadString(filePath);
          final List<dynamic> foodList = json.decode(jsonData);
          batches.add(
            foodList.map((json) => FoodComposition.fromJson(json)).toList(),
          );
        } catch (e) {
          ToastUtils.showError('处理文件 $filePath 时出错: $e');
        }

        ImportProgressCenter.update(
          ImportProgress(
            title: title,
            detail: isZh
                ? '读取数据文件 (${f + 1}/${foodJsonFiles.length})'
                : 'Reading files (${f + 1}/${foodJsonFiles.length})',
            current: f + 1,
            total: foodJsonFiles.length,
          ),
        );
      }

      final List<FoodComposition> allFoods = batches
          .expand((batch) => batch)
          .toList();
      int totalItems = allFoods.length;

      // 第二阶段：逐条写入数据库并上报进度(每10条刷新一次)
      int importedCount = 0;
      for (int i = 0; i < totalItems; i++) {
        bool success = await _saveSingleFood(allFoods[i]);
        if (success) importedCount++;

        if ((i + 1) % 10 == 0 || i + 1 == totalItems) {
          ImportProgressCenter.update(
            ImportProgress(
              title: title,
              detail: isZh
                  ? '已写入数据库 $importedCount 条'
                  : '$importedCount records saved',
              current: i + 1,
              total: totalItems,
            ),
          );
        }
      }

      // 标记为已导入
      _markAsImported();

      ToastUtils.showSuccess(
        isZh
            ? '成功导入 $importedCount 条食物成分数据'
            : 'Successfully imported $importedCount foods',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      ToastUtils.showError(
        isZh ? '导入食物成分数据时出错: $e' : 'Error importing food data: $e',
      );
      debugPrint('导入食物成分数据时出错: $e');
    } finally {
      ImportProgressCenter.update(null);
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

  /// 将单个FoodComposition转换为Food和ServingInfo并保存到数据库，返回是否成功
  Future<bool> _saveSingleFood(FoodComposition comp) async {
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
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('导入食物成分数据时出错 (${comp.foodCode}): $e');
      }
      return false;
    }
  }
}

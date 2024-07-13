// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:free_fitness/models/training_state.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../common/utils/db_diary_helper.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/diary_state.dart';
import '../../../models/dietary_state.dart';
import '../../../models/user_state.dart';

///
/// 2023-12-26 备份恢复还可以优化，就暂时不做
///
class BackupAndRestore extends StatefulWidget {
  const BackupAndRestore({super.key});

  @override
  State<BackupAndRestore> createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends State<BackupAndRestore> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
  final DBTrainingHelper _trainingHelper = DBTrainingHelper();
  final DBDiaryHelper _diaryHelper = DBDiaryHelper();
  final DBUserHelper _userHelper = DBUserHelper();

  bool isLoading = false;

  // 导出db中所有的数据
  _exportAllData() async {
    final status = await requestStoragePermission();

    // 用户没有授权，简单提示一下
    if (!mounted) return;
    if (!status) {
      showSnackMessage(context, CusAL.of(context).noStorageErrorText);
      return;
    }

    // 用户选择指定文件夹
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    // 如果有选中文件夹，执行导出数据库的json文件，并添加到压缩档。
    if (selectedDirectory != null) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      // 获取应用文档目录路径
      Directory appDocDir = await getApplicationDocumentsDirectory();
      // 临时存放zip文件的路径
      var tempZipDir =
          await Directory(p.join(appDocDir.path, "temp_zip")).create();
      // zip 文件的名称
      String zipName =
          "free-fitness-full-bak-${DateTime.now().millisecondsSinceEpoch}.zip";

      // 执行讲db数据导出到临时json路径和构建临时zip文件(？？？应该有错误检查)
      await backupDbData(zipName, tempZipDir.path);

      // 移动临时文件到用户选择的位置
      File sourceFile = File(p.join(tempZipDir.path, zipName));
      File destinationFile = File(p.join(selectedDirectory, zipName));

      // 如果目标文件已经存在，则先删除
      if (destinationFile.existsSync()) {
        destinationFile.deleteSync();
      }

      // 把文件从缓存的位置放到用户选择的位置
      sourceFile.copySync(p.join(selectedDirectory, zipName));
      print('文件已成功复制到：${p.join(selectedDirectory, zipName)}');

      // 删除临时zip文件
      if (sourceFile.existsSync()) {
        // 如果目标文件已经存在，则先删除
        sourceFile.deleteSync();
      }

      setState(() {
        isLoading = false;
      });

      if (!mounted) return;
      showSnackMessage(
        context,
        CusAL.of(context).bakSuccessNote(selectedDirectory),
        backgroundColor: Colors.green,
      );
    } else {
      print('保存操作已取消');
      return;
    }
  }

  // 备份db中数据到指定文件夹
  Future<void> backupDbData(
    // 会把所有json文件打包成1个压缩包，这是压缩包的名称
    String zipName,
    // 在构建zip文件时，会先放到临时文件夹，构建完成后才复制到用户指定的路径去
    String tempZipPath,
  ) async {
    // 等到所有文件导出，都默认放在同一个文件夹下，所以就不用返回路径了
    await _userHelper.exportDatabase();
    await _dietaryHelper.exportDatabase();
    await _trainingHelper.exportDatabase();
    await _diaryHelper.exportDatabase();

    // 创建或检索压缩包临时存放的文件夹
    var tempZipDir = await Directory(tempZipPath).create();

    // 获取临时文件夹目录(在导出函数中是固定了的，所以这里也直接取就好)
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String tempJsonsPath = p.join(appDocDir.path, "db_export");
    // 临时存放所有json文件的文件夹
    Directory tempDirectory = Directory(tempJsonsPath);

    // 创建压缩文件
    final encoder = ZipFileEncoder();
    encoder.create(p.join(tempZipDir.path, zipName));

    // 遍历临时文件夹中的所有文件和子文件夹，并将它们添加到压缩文件中
    await for (FileSystemEntity entity in tempDirectory.list(recursive: true)) {
      if (entity is File) {
        encoder.addFile(entity);
      } else if (entity is Directory) {
        encoder.addDirectory(entity);
      }
    }

    // 完成并关闭压缩文件
    encoder.close();

    // 压缩完成后，清空临时json文件夹中文件
    await deleteFilesInDirectory(tempJsonsPath);
  }

  // 解压zip文件
  Future<String> unzipFile(String zipFilePath) async {
    try {
      // 获取临时目录路径
      Directory tempDir = await getTemporaryDirectory();

      // 创建或检索压缩包临时存放的文件夹
      String tempPath =
          (await Directory(p.join(tempDir.path, "temp_de_zip")).create()).path;

      // 读取zip文件
      File file = File(zipFilePath);
      List<int> bytes = file.readAsBytesSync();

      // 解压缩
      Archive archive = ZipDecoder().decodeBytes(bytes);
      for (ArchiveFile file in archive) {
        String filename = '$tempPath/${file.name}';
        if (file.isFile) {
          File outFile = File(filename);
          outFile = await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content);

          print("解压时的outFile$outFile");
        } else {
          Directory dir = Directory(filename);
          await dir.create(recursive: true);
        }
      }
      print('解压完成');

      return tempPath;
    } catch (e) {
      print('解压失败: $e');
      throw Exception(e);
    }
  }

  // 2023-12-11 恢复的话，简单需要导出时同名的zip压缩包
  Future<void> restoreDataFromBackup() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      // 不允许多选，理论就是第一个文件，且不为空
      File file = File(result.files.first.path!);

      print("获取的上传zip文件路径${p.basename(file.path)}");
      print("获取的上传zip文件路径 result $result");

      // 这个判断虽然不准确，但先这样
      if (p
              .basename(file.path)
              .toLowerCase()
              .startsWith('free-fitness-full-bak-') &&
          p.basename(file.path).toLowerCase().endsWith('.zip')) {
        try {
          // 等待解压完成
          // 遍历解压后的文件，取得里面的文件(可能会有嵌套文件夹和其他格式的文件，不过这里没有)
          List<File> jsonFiles = Directory(await unzipFile(file.path))
              .listSync()
              .where(
                  (entity) => entity is File && entity.path.endsWith('.json'))
              .map((entity) => entity as File)
              .toList();

          print("jsonFiles---$jsonFiles");

          /// 删除前可以先备份一下到临时文件，避免出错后完成无法使用(最多确认恢复成功之后再删除就好了)

          // 获取应用文档目录路径
          Directory appDocDir = await getApplicationDocumentsDirectory();
          // 临时存放zip文件的路径
          var tempZipDir =
              await Directory(p.join(appDocDir.path, "temp_auto_zip")).create();
          // zip 文件的名称
          String zipName =
              "free-fitness-full-bak-${DateTime.now().millisecondsSinceEpoch}.zip";
          // 执行讲db数据导出到临时json路径和构建临时zip文件(？？？应该有错误检查)
          await backupDbData(zipName, tempZipDir.path);

          // 恢复旧数据之前，删除现有数据库
          await _dietaryHelper.deleteDB();
          await _userHelper.deleteDB();
          await _diaryHelper.deleteDB();
          await _trainingHelper.deleteDB();

          // 保存恢复的数据(应该检查的？？？)
          await _saveJsonFileDataToDb(jsonFiles);

          // 成功恢复后，删除临时备份的zip
          File sourceFile = File(p.join(tempZipDir.path, zipName));
          // 删除临时zip文件
          if (sourceFile.existsSync()) {
            // 如果目标文件已经存在，则先删除
            sourceFile.deleteSync();
          }

          setState(() {
            isLoading = false;
          });

          if (!mounted) return;
          showSnackMessage(
            context,
            CusAL.of(context).resSuccessNote,
            backgroundColor: Colors.green,
          );
        } catch (e) {
          // 弹出报错提示框
          if (!mounted) return;

          commonExceptionDialog(
            context,
            CusAL.of(context).importJsonError,
            CusAL.of(context).importJsonErrorText(file.path, e.toString()),
          );

          setState(() {
            isLoading = false;
          });
          // 中止操作
          return;
        }
      }
      // 这个判断不准确，但先这样

      setState(() {
        isLoading = false;
      });
    } else {
      // User canceled the picker
      return;
    }
  }

  // 将恢复的json数据存入db中
  _saveJsonFileDataToDb(List<File> jsonFiles) async {
    // 解压之后获取到所有的json文件，逐个添加到数据库，会先清空数据库的数据
    for (File file in jsonFiles) {
      print("_saveJsonFileDataToDb---${file.path}");

      String jsonData = await file.readAsString();
      // db导出时json文件是列表
      List jsonMapList = json.decode(jsonData);

      var filename = p.basename(file.path).toLowerCase();

      // 根据不同文件名，构建不同的数据
      if (filename == "ff_user.json") {
        var temp = jsonMapList.map((e) => User.fromMap(e)).toList();
        await _userHelper.insertUserList(temp);
      } else if (filename == "ff_intake_daily_goal.json") {
        var temp = jsonMapList.map((e) => IntakeDailyGoal.fromMap(e)).toList();
        await _userHelper.insertIntakeDailyGoalList(temp);
      } else if (filename == "ff_weight_trend.json") {
        var temp = jsonMapList.map((e) => WeightTrend.fromMap(e)).toList();
        await _userHelper.insertWeightTrendList(temp);
      } else if (filename == "ff_daily_food_item.json") {
        var temp = jsonMapList.map((e) => DailyFoodItem.fromMap(e)).toList();
        await _dietaryHelper.insertDailyFoodItemList(temp);
      } else if (filename == "ff_meal_photo.json") {
        var temp = jsonMapList.map((e) => MealPhoto.fromMap(e)).toList();
        await _dietaryHelper.insertMealPhotoList(temp);
      } else if (filename == "ff_trained_detail_log.json") {
        var temp = jsonMapList.map((e) => TrainedDetailLog.fromMap(e)).toList();
        await _trainingHelper.insertTrainingDetailLogList(temp);
      } else if (filename == "ff_diary.json") {
        var temp = jsonMapList.map((e) => Diary.fromMap(e)).toList();
        await _diaryHelper.insertDiaryList(temp);
      } else if (filename == "ff_exercise.json") {
        var temp = jsonMapList.map((e) => Exercise.fromMap(e)).toList();
        await _trainingHelper.insertExerciseList(temp);
      } else if (filename == "ff_action.json") {
        var temp = jsonMapList.map((e) => TrainingAction.fromMap(e)).toList();
        await _trainingHelper.insertTrainingActionList(temp);
      } else if (filename == "ff_group.json") {
        var temp = jsonMapList.map((e) => TrainingGroup.fromMap(e)).toList();
        await _trainingHelper.insertTrainingGroupList(temp);
      } else if (filename == "ff_plan.json") {
        var temp = jsonMapList.map((e) => TrainingPlan.fromMap(e)).toList();
        await _trainingHelper.insertTrainingPlanList(temp);
      } else if (filename == "ff_plan_has_group.json") {
        var temp = jsonMapList.map((e) => PlanHasGroup.fromMap(e)).toList();
        await _trainingHelper.insertPlanHasGroupList(temp);
      } else if (filename == "ff_food.json") {
        var temp = jsonMapList.map((e) => Food.fromMap(e)).toList();
        await _dietaryHelper.insertFoodList(temp);
      } else if (filename == "ff_serving_info.json") {
        var temp = jsonMapList.map((e) => ServingInfo.fromMap(e)).toList();
        await _dietaryHelper.insertServingInfoList(temp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(CusAL.of(context).bakLabels("0"))),
      body: isLoading ? buildLoader(isLoading) : buildBackupButton(),
    );
  }

  buildBackupButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(CusAL.of(context).bakLabels("1")),
                    content: Text(CusAL.of(context).bakOpNote),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.pop(context, false);
                        },
                        child: Text(CusAL.of(context).cancelLabel),
                      ),
                      TextButton(
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.pop(context, true);
                        },
                        child: Text(CusAL.of(context).confirmLabel),
                      ),
                    ],
                  );
                },
              ).then((value) {
                if (value != null && value) _exportAllData();
              });
            },
            icon: const Icon(Icons.backup),
            label: Text(
              CusAL.of(context).bakLabels("1"),
              style: TextStyle(fontSize: CusFontSizes.flagMedium),
            ),
          ),
          TextButton.icon(
            onPressed: restoreDataFromBackup,
            icon: const Icon(Icons.restore),
            label: Text(
              CusAL.of(context).bakLabels("2"),
              style: TextStyle(fontSize: CusFontSizes.flagMedium),
            ),
          ),
        ],
      ),
    );
  }
}

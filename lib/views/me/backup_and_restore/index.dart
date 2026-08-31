import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/backup_merge_service.dart';
import '../../../core/storage/db_ai_helper.dart';
import '../../../core/storage/db_diary_helper.dart';
import '../../../core/storage/db_dietary_helper.dart';
import '../../../core/storage/db_training_helper.dart';
import '../../../core/storage/db_user_helper.dart';
import '../../../core/utils/import_progress.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/tool_widgets.dart';
import '../../../core/utils/tools.dart';
import '../../../core/widgets/import_progress_overlay.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/paid_llm/llm_config.dart';
import '../../../services/llm_config_service.dart';

///
/// 2023-12-26 备份恢复还可以优化，就暂时不做
///
/// 2024-11-26 备份文件前缀
const bakPrefix = "FreeFitness-FullBackup_";

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
  // 2026-08-27 AI 模块数据(会话/消息/自定义角色)也纳入备份恢复
  final DBAiHelper _aiHelper = DBAiHelper();
  final LlmConfigService _configService = LlmConfigService();

  bool isLoading = false;

  // 导出db中所有的数据
  Future<void> _exportAllData() async {
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

    if (!mounted) return;
    if (selectedDirectory != null) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      // 获取应用文档目录路径
      Directory appDocDir = await getApplicationDocumentsDirectory();
      // 临时存放zip文件的路径
      var tempZipDir = await Directory(
        p.join(appDocDir.path, "temp_zip"),
      ).create();
      // zip 文件的名称
      String zipName = "$bakPrefix${DateTime.now().millisecondsSinceEpoch}.zip";

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
      if (kDebugMode) {
        print('文件已成功复制到：${p.join(selectedDirectory, zipName)}');
      }

      // 删除临时zip文件
      if (sourceFile.existsSync()) {
        // 如果目标文件已经存在，则先删除
        sourceFile.deleteSync();
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      showSnackMessage(
        context,
        CusAL.of(context).bakSuccessNote(selectedDirectory),
        backgroundColor: Colors.green,
      );
    } else {
      if (kDebugMode) {
        print('保存操作已取消');
      }
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

    // 2026-08-27 AI 模块数据一并导出：
    // 1) ai 库三表(会话/消息/自定义角色) → ff_ai_*.json
    await _aiHelper.exportDatabase();
    await _configService.load();

    // 创建或检索压缩包临时存放的文件夹
    var tempZipDir = await Directory(tempZipPath).create();

    // 获取临时文件夹目录(在导出函数中是固定了的，所以这里也直接取就好)
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String tempJsonsPath = p.join(appDocDir.path, "db_export");
    // 临时存放所有json文件的文件夹
    Directory tempDirectory = Directory(tempJsonsPath);

    // 2) llm 大模型配置(GetStorage 的配置列表，含 AK) → llm_config.json
    var llmConfigs = _configService.exportMaps();
    var llmConfigFile = File(p.join(tempDirectory.path, "llm_config.json"));
    await llmConfigFile.writeAsString(json.encode(llmConfigs));

    // 创建Archive对象
    final archive = Archive();

    // 遍历临时文件夹中的所有文件和子文件夹，并将它们添加到archive中
    await for (FileSystemEntity entity in tempDirectory.list(recursive: true)) {
      if (entity is File) {
        // 读取文件内容
        final bytes = await entity.readAsBytes();
        // 获取相对路径（相对于tempJsonsPath）
        final relativePath = p.relative(entity.path, from: tempJsonsPath);
        // 添加到archive
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }

    // 3) AI 对话图片目录(ai_images/{会话id}/{uuid}.jpg 保持相对结构入 zip)
    var externalDir = await getExternalStorageDirectory();
    var aiImagesDir = externalDir == null
        ? null
        : Directory(p.join(externalDir.path, "ai_images"));
    if (aiImagesDir != null && await aiImagesDir.exists()) {
      await for (FileSystemEntity entity in aiImagesDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          final relativePath = p.relative(entity.path, from: aiImagesDir.path);
          // 统一用 / 作为 zip 内分隔符
          archive.addFile(
            ArchiveFile(
              "ai_images/${relativePath.replaceAll('\\', '/')}",
              bytes.length,
              bytes,
            ),
          );
        }
      }
    }

    // 使用ZipEncoder编码archive为zip文件
    final encoder = ZipEncoder();
    final zipBytes = encoder.encode(archive);

    // 写入zip文件
    final zipFile = File(p.join(tempZipDir.path, zipName));
    await zipFile.writeAsBytes(zipBytes);

    // 压缩完成后，清空临时json文件夹中文件
    await deleteFilesInDirectory(tempJsonsPath);
  }

  // 删除指定文件夹下所有文件
  Future<void> _deleteFilesInDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await for (var file in directory.list()) {
        if (file is File) {
          await file.delete();
        }
      }
    }
  }

  // 2023-12-11 恢复的话，简单需要导出时同名的zip压缩包
  Future<void> restoreDataFromBackup() async {
    // l10n 实例在首个 await 前捕获，后续异步各阶段直接使用(避免跨异步间隙取 context)
    var l10n = CusAL.of(context);

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['zip', 'ZIP'],
    );
    if (result != null) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      // 不允许多选，理论就是第一个文件，且不为空
      File file = File(result.files.first.path!);

      if (kDebugMode) {
        print("获取的上传zip文件路径${p.basename(file.path)}");
        print("获取的上传zip文件路径 result $result");
      }

      // 这个判断虽然不准确，但先这样
      if (p.basename(file.path).startsWith(bakPrefix) &&
          p.basename(file.path).toLowerCase().endsWith('.zip')) {
        try {
          // 获取临时目录路径
          Directory tempDir = await getTemporaryDirectory();

          // 创建或检索压缩包临时存放的文件夹
          String unzipPath = (await Directory(
            p.join(tempDir.path, "temp_de_zip"),
          ).create()).path;

          // 先清空临时目录避免旧解压文件残留
          await _deleteFilesInDirectory(unzipPath);

          // 解压文件到指定位置
          await extractFileToDisk(file.path, unzipPath);

          // 等待解压完成
          // 遍历解压后的文件，取得里面的文件(可能会有嵌套文件夹和其他格式的文件，不过这里没有)
          List<File> jsonFiles = Directory(unzipPath)
              .listSync()
              .where(
                (entity) => entity is File && entity.path.endsWith('.json'),
              )
              .map((entity) => entity as File)
              .toList();

          if (kDebugMode) {
            print("jsonFiles---$jsonFiles");
          }

          // 2026-08-27 恢复语义从"删库重灌"改为"去重合并"：
          // 本机已有数据与备份数据按自然键合并(已存在跳过，新的补插，外键id重映射)，
          // 全程不删除任何本机数据，完整保留双方内容
          // (旧版本备份 zip 内没有 AI 表/llm 配置时，对应部分自然不参与合并=保留本机现状)
          // 2026-08-27 再次增强：解析出备份包含的模块后弹窗让用户勾选只恢复部分模块；
          // 且内置动作/食物(编码身份已存在)在合并服务内受保护不被重复引入
          var tableData = <String, List<Map<String, dynamic>>>{};
          List<Map<String, dynamic>>? llmConfigMaps;
          for (File file in jsonFiles) {
            var jsonData = await file.readAsString();
            List jsonMapList = json.decode(jsonData);
            var name = p
                .basename(file.path)
                .toLowerCase()
                .replaceAll('.json', '');

            if (name == 'llm_config') {
              llmConfigMaps = jsonMapList
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            } else {
              tableData[name] = jsonMapList
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            }
          }

          // 计算备份中实际存在的模块(AI 模块还包括 llm 配置与图片目录)
          var aiImagesInZip = Directory(
            p.join(unzipPath, "ai_images"),
          ).existsSync();
          Set<String> presentModules = RestoreModules.all.where((m) {
            if (m == RestoreModules.modAi) {
              return RestoreModules.tablesOf(
                    m,
                  ).any((t) => (tableData[t]?.isNotEmpty ?? false)) ||
                  llmConfigMaps != null ||
                  aiImagesInZip;
            }
            return RestoreModules.tablesOf(
              m,
            ).any((t) => (tableData[t]?.isNotEmpty ?? false));
          }).toSet();

          if (presentModules.isEmpty) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
            });
            ToastUtils.showInfo(CusAL.of(context).restoreNoData);
            return;
          }

          if (!mounted) return;
          // 用户取消或一个都没勾 → 放弃本次恢复(尚未做任何写库/自动备份)
          var selected = await _showModuleSelectDialog(presentModules);
          if (selected == null || selected.isEmpty) {
            setState(() {
              isLoading = false;
            });
            return;
          }

          // 获取应用文档目录路径
          Directory appDocDir = await getApplicationDocumentsDirectory();
          // 临时存放zip文件的路径
          var tempZipDir = await Directory(
            p.join(appDocDir.path, "temp_auto_zip"),
          ).create();
          // zip 文件的名称
          String zipName =
              "$bakPrefix${DateTime.now().millisecondsSinceEpoch}.zip";

          // 2026-08-27 恢复全程改为进度浮层(复用内置数据导入的浮层组件)：
          // 自动备份/表合并/llm配置/图片合并各阶段均上报文字与进度条(文案经 l10n 取 ARB)
          CancelFunc? closeProgress;
          try {
            closeProgress = showImportProgressOverlay();
            ImportProgressCenter.update(
              ImportProgress(
                title: l10n.restorePhaseBackup,
                detail: l10n.restorePhaseBackupNote,
                current: 0,
                total: 0,
              ),
            );
            // 恢复前先把当前数据自动全量备份一份(失败可回退，成功后删除)
            await backupDbData(zipName, tempZipDir.path);

            // 表合并阶段：mergeAll 内部按"表"粒度实时上报行数进度
            var mergeResult = await BackupMergeService().mergeAll(
              tableData,
              modules: selected,
              l10n: l10n,
            );

            // llm 大模型配置按 uuid id 去重合并(同 id 已存在跳过)
            // (仅当用户勾选了 AI 模块才参与恢复)
            var llmMerged = 0;
            if (selected.contains(RestoreModules.modAi) &&
                llmConfigMaps != null) {
              ImportProgressCenter.update(
                ImportProgress(
                  title: l10n.restorePhaseLlm,
                  current: 0,
                  total: 0,
                ),
              );
              await _configService.load();
              var existingIds = _configService.configs.map((c) => c.id).toSet();
              for (var m in llmConfigMaps) {
                var id = m['id'] as String?;
                if (id == null || existingIds.contains(id)) continue;
                await _configService.add(LlmConfig.fromMap(m));
                existingIds.add(id);
                llmMerged++;
              }
            }

            // AI 对话图片合并：按会话id映射拷贝缺失的文件(已有文件保留)
            if (selected.contains(RestoreModules.modAi)) {
              ImportProgressCenter.update(
                ImportProgress(
                  title: l10n.restorePhaseImages,
                  current: 0,
                  total: 0,
                ),
              );
              await _mergeAiImages(unzipPath, mergeResult.aiConversationIdMap);
            }

            // 成功恢复后，删除临时备份的zip
            File sourceFile = File(p.join(tempZipDir.path, zipName));
            // 删除临时zip文件
            if (sourceFile.existsSync()) {
              // 如果目标文件已经存在，则先删除
              sourceFile.deleteSync();
            }

            if (!mounted) return;
            setState(() {
              isLoading = false;
            });

            if (kDebugMode) {
              print(
                "恢复合并完成：新增${mergeResult.inserted}，跳过已存在${mergeResult.skipped}(内置${mergeResult.builtinSkipped})，llm配置新增$llmMerged",
              );
            }

            // 提示语：常规新增/保留统计；有内置命中时额外说明(不可覆盖语义)
            var msg = l10n.restoreResultNote(
              mergeResult.inserted,
              mergeResult.skipped,
            );
            if (mergeResult.builtinSkipped > 0) {
              msg += "\n${l10n.restoreBuiltinNote(mergeResult.builtinSkipped)}";
            }
            showSnackMessage(context, msg, backgroundColor: Colors.green);
          } catch (e) {
            rethrow;
          } finally {
            // 无论成败都收尾：清进度通知并关闭浮层
            RestoreProgressCenter.done();
            closeProgress?.call();
          }
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
      } else {
        ToastUtils.showInfo("Not a backup file exported from the app");
      }
      // 这个判断不准确，但先这样
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } else {
      // User canceled the picker
      return;
    }
  }

  // 2026-08-27 恢复模块选择弹窗：
  // 只列出该备份 zip 中实际包含的模块，默认全选；
  // 返回勾选的模块 key 集合；取消(或一个不选确认不可用)返回 null = 放弃恢复
  Future<Set<String>?> _showModuleSelectDialog(
    Set<String> presentModules,
  ) async {
    // 模块展示名与内容说明(zh/en 走 ARB)
    var l10n = CusAL.of(context);
    var meta = {
      RestoreModules.modUser: (l10n.restoreModUser, l10n.restoreModUserDesc),
      RestoreModules.modDietary: (
        l10n.restoreModDietary,
        l10n.restoreModDietaryDesc,
      ),
      RestoreModules.modDiary: (l10n.restoreModDiary, l10n.restoreModDiaryDesc),
      RestoreModules.modTraining: (
        l10n.restoreModTraining,
        l10n.restoreModTrainingDesc,
      ),
      RestoreModules.modAi: (l10n.restoreModAi, l10n.restoreModAiDesc),
    };

    var checked = {for (var m in presentModules) m: true};

    return showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.restoreSelectTitle),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var m in presentModules)
                      CheckboxListTile(
                        value: checked[m],
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (v) =>
                            setDialogState(() => checked[m] = v ?? false),
                        title: Text(meta[m]!.$1),
                        subtitle: Text(
                          meta[m]!.$2,
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                        ),
                      ),
                    SizedBox(height: 6.sp),
                    Text(
                      l10n.restoreMergeNote,
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(CusAL.of(context).cancelLabel),
                ),
                ElevatedButton(
                  onPressed: checked.values.any((v) => v)
                      ? () {
                          Navigator.pop(
                            context,
                            checked.entries
                                .where((e) => e.value)
                                .map((e) => e.key)
                                .toSet(),
                          );
                        }
                      : null,
                  child: Text(CusAL.of(context).confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 2026-08-27 合并 AI 对话图片(配合 BackupMergeService 的会话id映射)：
  // 解压目录 ai_images/{备份会话id}/xxx.jpg → 本机 ai_images/{映射后id}/xxx.jpg；
  // 只拷贝本机不存在的文件，已有文件一律保留(去重合并不覆盖)
  Future<void> _mergeAiImages(String unzipPath, Map<int, int> convIdMap) async {
    var srcDir = Directory(p.join(unzipPath, "ai_images"));
    if (!await srcDir.exists()) return;

    var externalDir = await getExternalStorageDirectory();
    if (externalDir == null) return;

    var targetRoot = Directory(p.join(externalDir.path, "ai_images"));
    if (!await targetRoot.exists()) {
      await targetRoot.create(recursive: true);
    }

    await for (FileSystemEntity entity in srcDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! Directory) continue;

      // 子目录名即备份中的会话id，映射到本机会话id
      var oldIdStr = p.basename(entity.path);
      var oldId = int.tryParse(oldIdStr);
      if (oldId == null) continue;
      var newId = convIdMap[oldId] ?? oldId;

      var targetDir = Directory(p.join(targetRoot.path, '$newId'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      await for (FileSystemEntity f in entity.list()) {
        if (f is! File) continue;
        var target = File(p.join(targetDir.path, p.basename(f.path)));
        // 已存在则不覆盖(图片文件名为uuid，天然不冲突；同备份重复恢复天然幂等)
        if (!await target.exists()) {
          await f.copy(target.path);
        }
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

  Center buildBackupButton() {
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

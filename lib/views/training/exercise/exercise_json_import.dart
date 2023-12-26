// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/custom_exercise.dart';
import '../../../models/training_state.dart';

class ExerciseJsonImport extends StatefulWidget {
  const ExerciseJsonImport({super.key});

  @override
  State<ExerciseJsonImport> createState() => _ExerciseJsonImportState();
}

class _ExerciseJsonImportState extends State<ExerciseJsonImport> {
  final DBTrainingHelper _trainingHelper = DBTrainingHelper();

  // 是否在解析json中或导入数据库中
  bool isLoading = false;
  // 上传的json文件列表
  List<File> jsons = [];
  // 解析后的动作列表(文件和动作都不支持移除)
  List<CustomExercise> cusExercises = [];
  // 如果用户没有在这里选择图片的文件夹，就使用预设要求用户放置的位置
  // String cusExerciseImagePerfix = cusExImgPre;
  // 2023-11-30 如果用户没选公共文件夹，则默认json文件图片路径是完整的
  String cusExerciseImagePerfix = "";

  // 构建json文件加载成功后的锻炼数据表格要用到
  // 待上传的动作数量已经每个动作的选中状态
  int exerciseItemsNum = 0;
  List<bool> exerciseSelectedList = [false];

  var importNote = """
json文件的images栏位只指定相对文件路径，
再指定一个公共文件夹存放所有的图片。

比如一个实际的图片位于设备的：
.../DCIM/exercise-images/3_4_Sit-Up/0.jpg;
.../DCIM/exercise-images/Ab_Roller/0.jpg;

那么对应json文件的 `images` 栏位可以如下填写:
3_4_Sit-Up.json:
 "images": ["3_4_Sit-Up/0.jpg","3_4_Sit-Up/1.jpg"],

Ab_Roller.json:
 "images": ["Ab_Roller/0.jpg","Ab_Roller/1.jpg"],

同时选择公共文件夹位置 -> 点击文件夹图标、选择公共文件夹:
.../DCIM/exercise-images/

这样保存的地址就是完整的 "公共文件夹/json文件images栏位"

比如 
/storage/emulated/0/DCIM/exercise-images/3_4_Sit-Up/0.jpg
/storage/emulated/0/DCIM/exercise-images/Ab_Roller/0.jpg

不指定公共文件夹，则默认json文件中存放的是完整的绝对路径。
找不到图片则需要在动作库模块对指定动作重新上传图片。

超过50条数据，就不用表格展示了，太耗费性能。
""";

  /// ？？？可以考虑在打开文件夹或者文件时，删除已选择的文件夹或文件(现在是追加，不会去重)
  // 上传指定文件夹，处理里面所有指定格式的json
  Future<void> _openFileExplorer() async {
    // 用户选择指定文件夹
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    // 如果有选中文件夹，遍历出里面所有json结尾的文件
    if (selectedDirectory != null) {
      setState(() {
        isLoading = true;
      });

      Directory directory = Directory(selectedDirectory);
      List<File> jsonFiles = directory
          .listSync()
          .where((entity) => entity.path.toLowerCase().endsWith('.json'))
          .map((entity) => File(entity.path))
          .toList();

      setState(() {
        jsons.addAll(jsonFiles);
      });

      for (File file in jsonFiles) {
        try {
          String jsonData = await file.readAsString();

          // 如果一个json文件只是一个动作，那就加上中括号；如果本身就是带了中括号的多个，就不再加
          List cusExerciseMapList =
              jsonData.trim().startsWith("[") && jsonData.trim().endsWith("]")
                  ? json.decode(jsonData)
                  : json.decode("[$jsonData]");

          var temp = cusExerciseMapList
              .map((e) => CustomExercise.fromJson(e))
              .toList();

          setState(() {
            cusExercises.addAll(temp);
            // 更新需要构建的表格的长度和每条数据的可选中状态
            exerciseItemsNum = cusExercises.length;
            exerciseSelectedList =
                List<bool>.generate(exerciseItemsNum, (int index) => false);
          });
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
      setState(() {
        isLoading = false;
      });
    } else {
      // User canceled the picker
      return;
    }
  }

  // 用户可以选择多个json文件
  Future<void> _openJsonFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      setState(() {
        isLoading = true;
      });

      for (File file in result.files.map((file) => File(file.path!))) {
        if (file.path.toLowerCase().endsWith('.json')) {
          try {
            String jsonData = await file.readAsString();

            // 如果一个json文件只是一个动作，那就加上中括号；如果本身就是带了中括号的多个，就不再加
            List cusExerciseMapList =
                jsonData.trim().startsWith("[") && jsonData.trim().endsWith("]")
                    ? json.decode(jsonData)
                    : json.decode("[$jsonData]");

            log("${cusExerciseMapList.length}");

            var temp = cusExerciseMapList.map((e) {
              return CustomExercise.fromJson(e);
            }).toList();

            setState(() {
              cusExercises.addAll(temp);
              // 更新需要构建的表格的长度和每条数据的可选中状态
              exerciseItemsNum = cusExercises.length;
              exerciseSelectedList =
                  List<bool>.generate(exerciseItemsNum, (int index) => false);
            });
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
      }
      setState(() {
        isLoading = false;
      });
    } else {
      // User canceled the picker
      return;
    }
  }

  // 获取上传的动作的图片文件夹
  Future<void> _openExerciseImagesExplorer() async {
    // 用户选择指定文件夹
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    log("selectedDirectory------------$selectedDirectory");

    // 如果有选中文件夹，遍历出里面所有json结尾的文件
    if (selectedDirectory != null) {
      setState(() {
        // 注意，这里的文件夹地址尾巴没有/，预设的是有的，所以带上
        cusExerciseImagePerfix = "$selectedDirectory/";
      });
    } else {
      // User canceled the picker
      return;
    }
  }

  // 讲json数据保存到数据库中
  _saveToDb() async {
    // 已经在保存中路，再点击保存直接返回即可
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 这里导入去重的工作要放在上面解析文件时，这里就全部保存了。
    // 而且id自增，食物或者编号和数据库重复，这里插入数据库中也不会报错。
    for (var e in cusExercises) {
      var tempExercise = Exercise(
        // exerciseId 数据库自增
        exerciseCode: e.code ?? e.id ?? '', // json文件的id就是代号
        exerciseName: e.name ?? "",
        category: e.category ?? "",
        countingMode: e.countingMode ?? countingOptions.first.value,
        force: e.force,
        level: e.level,
        mechanic: e.mechanic,
        equipment: e.equipment,
        standardDuration: int.tryParse(e.standardDuration ?? "1") ?? 1,
        // json描述是字符串数组，直接用换行符拼接
        instructions: e.instructions?.join("\n\n"),
        ttsNotes: e.ttsNotes,
        primaryMuscles: e.primaryMuscles?.join(","),
        secondaryMuscles: e.secondaryMuscles?.join(","),
        // images: e.images?.join(","),
        // 如果用户有指定文件夹的位置，就加上；没有的话就加上默认相册的位置
        images:
            e.images?.map((e) => cusExerciseImagePerfix + e).toList().join(","),
        // 导入json都为true则可以读取相册中对应位置的图片
        isCustom: true,
        contributor: CacheUser.userName,
        gmtCreate: getCurrentDateTime(),
      );

      try {
        await _trainingHelper.insertExerciseThrowError(tempExercise);
      } on Exception catch (e) {
        // 将错误信息展示给用户
        if (!mounted) return;
        // ？？？可以抽公共的错误处理和提示弹窗

        commonExceptionDialog(
          context,
          CusAL.of(context).exceptionWarningTitle,
          e.toString(),
        );
        setState(() {
          isLoading = false;
        });

        return;
      }
    }
    // 保存完了，情况数据，并弹窗提示。
    setState(() {
      jsons = [];
      cusExercises = [];
      // 更新需要构建的表格的长度和每条数据的可选中状态
      exerciseItemsNum = 0;
      exerciseSelectedList = [false];
      isLoading = false;
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(CusAL.of(context).tipLabel),
          content: Text(CusAL.of(context).importFinished),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(CusAL.of(context).confirmLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          CusAL.of(context).exerciseImport,
          style: TextStyle(fontSize: CusFontSizes.pageTitle),
        ),
        actions: [
          IconButton(
            onPressed: cusExercises.isNotEmpty ? _saveToDb : null,
            icon: Icon(
              Icons.save,
              color: cusExercises.isNotEmpty
                  ? null
                  : Theme.of(context).disabledColor,
            ),
          ),
          // TextButton.icon(
          //   onPressed: cusExercises.isNotEmpty ? _saveToDb : null,
          //   icon: Icon(
          //     Icons.save,
          //     color: cusExercises.isNotEmpty
          //         ? null
          //         : Theme.of(context).disabledColor,
          //   ),
          //   label: Text(
          //     CusAL.of(context).saveLabel,
          //     style: TextStyle(
          //       color: cusExercises.isNotEmpty
          //           ? null
          //           : Theme.of(context).disabledColor,
          //     ),
          //   ),
          // ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  /// 最上方的功能按钮区域
                  _buildButtonsArea(),

                  /// json文件列表不为空才显示对应区域
                  // if (jsons.isNotEmpty) ...buildJsonFileInfoArea(),

                  /// 动作列表不为空且待上传数量超过50显示简单文本(太大了用表格会巨卡)
                  if (cusExercises.isNotEmpty && cusExercises.length > 50)
                    ..._buildExerciseListArea(),

                  /// 动作列表且待上传数量不超过50显示表格形式(数量大了有性能问题)
                  if (cusExercises.isNotEmpty && cusExercises.length <= 50)
                    ..._buildExerciseDataTable(),
                ],
              ),
            ),
    );
  }

  /// 上方的功能按钮区域
  _buildButtonsArea() {
    return Card(
      elevation: 5,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: IconButton(
                  onPressed: _openFileExplorer,
                  icon: Icon(
                    Icons.drive_folder_upload,
                    size: CusIconSizes.iconMedium,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: _openJsonFiles,
                  icon: Icon(
                    Icons.file_upload,
                    size: CusIconSizes.iconMedium,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      jsons = [];
                      cusExercises = [];
                      cusExerciseImagePerfix = "";
                      exerciseItemsNum = 0;
                      exerciseSelectedList = [false];
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    size: CusIconSizes.iconMedium,
                    color: cusExercises.isNotEmpty
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ],
          ),
          // ？？？指定锻炼的图片公共文件夹地址(不复制到应用内部去，节约设备存储)
          // 2023-11-29 当然，还可以有一个同时上传图片到Android/data/app_name里面去，这样用户删了图片还能看到图片
          ListTile(
            title: Row(
              children: [
                Text(CusAL.of(context).exerciseImagePath),
                _buildHelpButton(),
              ],
            ),
            subtitle: Text(cusExerciseImagePerfix),
            trailing: IconButton(
              onPressed: _openExerciseImagesExplorer,
              icon: Icon(
                Icons.folder,
                size: CusIconSizes.iconMedium,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建图片公共文件夹提示按钮
  _buildHelpButton() {
    return IconButton(
      icon: const Icon(Icons.help_outline, color: Colors.lightGreen),
      onPressed: () {
        // 简单的自定义对话框(默认的弹窗有宽高限制)
        showGeneralDialog(
          context: context,
          // 背景色
          barrierColor: Colors.white.withOpacity(1),

          barrierDismissible: false,
          barrierLabel: 'Dialog',
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.sp),
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          '导入动作关联图片事宜',
                          style: TextStyle(fontSize: CusFontSizes.pageTitle),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: SingleChildScrollView(
                        child: Text(
                          importNote,
                          style: TextStyle(fontSize: CusFontSizes.itemContent),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        child: Text(CusAL.of(context).closeLabel),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  buildJsonFileInfoArea() {
    /// json文件列表不为空才显示对应区域
    /// 2023-11-30 数据用表格显示的话，就暂时不显示文件了，不好看
    return [
      Text(
        CusAL.of(context).jsonFiles,
        style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
        textAlign: TextAlign.start,
      ),
      SizedBox(
        height: 100.sp,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: jsons.length,
          itemBuilder: (context, index) {
            return Text(
              jsons[index].path,
              style: TextStyle(fontSize: CusFontSizes.itemContent),
              textAlign: TextAlign.start,
            );
          },
        ),
      ),
    ];
  }

  // 构建上传文件或文件夹时显示锻炼的数据概要和文件列表信息
  _buildExerciseListArea() {
    return [
      RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          children: [
            TextSpan(
              text: CusAL.of(context).itemCount(cusExercises.length),
              style: TextStyle(
                fontSize: CusFontSizes.itemSubTitle,
                color: Colors.blue,
              ),
            ),
            TextSpan(
              text: "  ${CusAL.of(context).exerciseLabelNote}",
              style: TextStyle(
                fontSize: CusFontSizes.itemContent,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 10.sp),
      Expanded(
        child: ListView.builder(
          itemCount: cusExercises.length,
          itemBuilder: (context, index) {
            return Row(
              verticalDirection: VerticalDirection.up,
              children: [
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${index + 1}  ',
                          style: TextStyle(
                            fontSize: CusFontSizes.itemContent,
                            color: Colors.green,
                          ),
                        ),
                        TextSpan(
                          text: "${cusExercises[index].id}  ",
                          style: TextStyle(
                            fontSize: CusFontSizes.itemContent,
                            color: Colors.grey,
                          ),
                        ),
                        TextSpan(
                          text: "${cusExercises[index].name}  ",
                          style: TextStyle(
                            fontSize: CusFontSizes.itemContent,
                            color: Colors.red,
                          ),
                        ),
                        TextSpan(
                          text: "${cusExercises[index].level}",
                          style: TextStyle(
                            fontSize: CusFontSizes.itemContent,
                            color: Colors.lightBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ];
  }

  _buildExerciseDataTable() {
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.sp),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              CusAL.of(context).uploadingItem(''),
              style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
              textAlign: TextAlign.start,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // 先找到被选中的索引
                  List<int> trueIndices = List.generate(
                          exerciseSelectedList.length, (index) => index)
                      .where((i) => exerciseSelectedList[i])
                      .toList();

                  // 从列表中移除
                  // 倒序遍历需要移除的索引列表，以避免索引变化导致的问题
                  for (int i = trueIndices.length - 1; i >= 0; i--) {
                    cusExercises.removeAt(trueIndices[i]);
                  }
                  // 更新需要构建的表格的长度和每条数据的可选中状态
                  exerciseItemsNum = cusExercises.length;
                  exerciseSelectedList = List<bool>.generate(
                    exerciseItemsNum,
                    (int index) => false,
                  );
                });
              },
              child: Text(
                CusAL.of(context).removeSelected,
                style: TextStyle(fontSize: CusFontSizes.buttonTiny),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          child: DataTable(
            dataRowMinHeight: 20.sp, // 设置行高范围
            // dataRowMaxHeight: 80.sp,
            headingRowHeight: 25, // 设置表头行高
            horizontalMargin: 10, // 设置水平边距
            columnSpacing: 5.sp, // 设置列间距
            columns: <DataColumn>[
              DataColumn(label: Text(CusAL.of(context).serialLabel)),
              DataColumn(label: Text(CusAL.of(context).exerciseQuerys('1'))),
              DataColumn(label: Text(CusAL.of(context).exerciseQuerys('2'))),
              DataColumn(
                label: Text(CusAL.of(context).exerciseQuerys('3')),
                numeric: true,
              ),
            ],
            rows: List<DataRow>.generate(
              exerciseItemsNum,
              (int index) => DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  // All rows will have the same selected color.
                  if (states.contains(MaterialState.selected)) {
                    return Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.08);
                  }
                  // Even rows will have a grey color.
                  if (index.isEven) {
                    return Colors.grey.withOpacity(0.3);
                  }
                  return null; // Use default value for other states and odd rows.
                }),
                cells: <DataCell>[
                  DataCell(
                    SizedBox(
                      width: 25.sp,
                      child: Text(
                        '${index + 1} ',
                        style: TextStyle(fontSize: CusFontSizes.itemContent),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 100.sp,
                      child: Text(
                        '${cusExercises[index].id}',
                        style: TextStyle(fontSize: CusFontSizes.itemContent),
                      ),
                    ),
                  ),
                  DataCell(
                    Wrap(
                      children: [
                        Text(
                          '${cusExercises[index].name}',
                          style: TextStyle(fontSize: CusFontSizes.itemContent),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 70.sp,
                      child: Text(
                        '${cusExercises[index].level}',
                        style: TextStyle(fontSize: CusFontSizes.itemContent),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
                selected: exerciseSelectedList[index],
                onSelectChanged: (bool? value) {
                  setState(() {
                    exerciseSelectedList[index] = value!;
                  });
                },
              ),
            ),
          ),
        ),
      )
    ];
  }
}

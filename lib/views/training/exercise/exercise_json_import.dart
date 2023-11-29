// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_training_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/custom_exercise.dart';
import '../../../models/training_state.dart';

class ExerciseJsonImport extends StatefulWidget {
  const ExerciseJsonImport({super.key});

  @override
  State<ExerciseJsonImport> createState() => _ExerciseJsonImportState();
}

class _ExerciseJsonImportState extends State<ExerciseJsonImport> {
  final DBTrainingHelper _trainingHelper = DBTrainingHelper();

  List<CustomExercise> cusExercises = [];
  List<File> jsons = [];
  // 如果用户没有在这里选择图片的文件夹，就使用预设要求用户放置的位置
  String cusExerciseImagePerfix = cusExImgPre;

  /// ？？？可以考虑在打开文件夹或者文件时，删除已选择的文件夹或文件(现在是追加，不会去重)
  // 上传指定文件夹，处理里面所有指定格式的json
  Future<void> _openFileExplorer() async {
    // 用户选择指定文件夹
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    // 如果有选中文件夹，遍历出里面所有json结尾的文件
    if (selectedDirectory != null) {
      Directory directory = Directory(selectedDirectory);
      List<File> jsonFiles = directory
          .listSync()
          .where((entity) => entity.path.toLowerCase().endsWith('.json'))
          .map((entity) => File(entity.path))
          .toList();

      print(jsonFiles);
      setState(() {
        jsons.addAll(jsonFiles);
      });

      for (File file in jsonFiles) {
        try {
          String jsonData = await file.readAsString();
          List foodEnergyMapList = json.decode(jsonData);
          var temp =
              foodEnergyMapList.map((e) => CustomExercise.fromJson(e)).toList();

          setState(() {
            cusExercises.addAll(temp);
          });
        } catch (e) {
          // 弹出报错提示框
          if (!mounted) return;

          commonExceptionDialog(
            context,
            "文件格式错误",
            '文件格式不合法:\n ${file.path}',
          );

          // 中止操作
          return;
        }
      }
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
      for (File file in result.files.map((file) => File(file.path!))) {
        if (file.path.endsWith('.json')) {
          try {
            String jsonData = await file.readAsString();

            // 如果一个json文件只是一个动作，那就加上中括号；如果本身就是带了中括号的多个，就不再加
            List cusExerciseMapList =
                jsonData.startsWith("[") && jsonData.endsWith("]")
                    ? json.decode(jsonData)
                    : json.decode("[$jsonData]");

            log("${cusExerciseMapList.first['instructions']}");

            var temp = cusExerciseMapList
                .map((e) => CustomExercise.fromJson(e))
                .toList();

            setState(() {
              cusExercises.addAll(temp);
            });
          } catch (e) {
            // 弹出报错提示框
            if (!mounted) return;

            commonExceptionDialog(
              context,
              "文件格式错误",
              '文件格式不合法:\n ${file.path}',
            );

            // 中止操作
            return;
          }
        }
      }
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
        standardDuration: e.standardDuration ?? "1",
        instructions: e.instructions?.join(","),
        ttsNotes: e.ttsNotes,
        primaryMuscles: e.primaryMuscles?.join(","),
        secondaryMuscles: e.secondaryMuscles?.join(","),
        // images: e.images?.join(","),
        // 如果用户有指定文件夹的位置，就加上；没有的话就加上默认相册的位置
        images:
            e.images?.map((e) => cusExerciseImagePerfix + e).toList().join(","),
        // 导入json都为true则可以读取相册中对应位置的图片
        isCustom: e.isCustom ?? "true",
        contributor: "用户导入",
        gmtCreate: DateFormat.yMMMd().format(DateTime.now()),
      );

      try {
        await _trainingHelper.insertExerciseThrowError(tempExercise);
      } on Exception catch (e) {
        // 将错误信息展示给用户
        if (!mounted) return;
        // ？？？可以抽公共的错误处理和提示弹窗

        commonExceptionDialog(context, "异常提醒", e.toString());

        return;
      }
    }
    // 保存完了，情况数据，并弹窗提示。
    setState(() {
      setState(() {
        jsons = [];
        cusExercises = [];
      });
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('完成'),
          content: const Text('数据已经插入数据库'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

不指定的话，Android平台 默认去此路径寻找对应图片:
/storage/emulated/0/DCIM/free-fitness/exercise-images/

""";

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入动作JSON数据'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: Colors.lightGreen,
            ),
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
                                style: TextStyle(fontSize: 20.sp),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 8,
                            child: SingleChildScrollView(
                              child: Text(
                                importNote,
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: TextButton(
                              child: const Text('关闭'),
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

              // showDialog(
              //   context: context,
              //   // 将该属性设置为false，禁止点击空白关闭弹窗
              //   barrierDismissible: false,
              //   builder: (BuildContext context) {
              //     return Dialog(
              //       child: Container(
              //         width: double.infinity,
              //         height: double.infinity,
              //         child: Text(
              //           importNote,
              //           style: TextStyle(fontSize: 14.sp),
              //         ),
              //       ),
              //     );

              // return AlertDialog(
              //   title: const Text('导入动作关联图片事宜'),
              //   content: SingleChildScrollView(
              //     child: Text(
              //       importNote,
              //       style: TextStyle(fontSize: 14.sp),
              //     ),
              //   ),
              //   actions: [
              //     TextButton(
              //       child: const Text('关闭'),
              //       onPressed: () {
              //         Navigator.of(context).pop();
              //       },
              //     ),
              //   ],
              // );
              //   },
              // );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Card(
              elevation: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: _openFileExplorer,
                      icon: Icon(
                        Icons.drive_folder_upload,
                        size: 30.sp,
                        color: Colors.blue,
                      ),
                    ),

                    // child: ElevatedButton(
                    //   onPressed: _openFileExplorer,
                    //   child: Text('文件夹', style: TextStyle(fontSize: 14.sp)),
                    // ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: _openJsonFiles,
                      icon: Icon(
                        Icons.file_upload,
                        size: 30.sp,
                        color: Colors.blue,
                      ),
                    ),
                    // child: ElevatedButton(
                    //   onPressed: _openJsonFiles,
                    //   child: Text('json文件', style: TextStyle(fontSize: 14.sp)),
                    // ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          jsons = [];
                          cusExercises = [];
                        });
                      },
                      icon: Icon(
                        Icons.clear,
                        size: 30.sp,
                        color: Colors.blue,
                      ),
                    ),
                    // child: ElevatedButton(
                    //   onPressed: () {
                    //     setState(() {
                    //       jsons = [];
                    //       foodComps = [];
                    //     });
                    //   },
                    //   child: Text('重置', style: TextStyle(fontSize: 14.sp)),
                    // ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: cusExercises.isNotEmpty ? _saveToDb : null,
                      disabledColor: Colors.grey,
                      icon: Icon(
                        Icons.save,
                        size: 30.sp,
                        color:
                            cusExercises.isNotEmpty ? Colors.blue : Colors.grey,
                      ),
                    ),
                    // child: ElevatedButton(
                    //   onPressed: _saveToDb,
                    //   child: Text('存到数据库', style: TextStyle(fontSize: 14.sp)),
                    // ),
                  ),
                ],
              ),
            ),
            // ？？？指定锻炼的图片地址(不复制到应用内部去，节约设备存储)
            // 2023-11-29 当然，还可以有一个同时上传图片到Android/data/app_name里面去，这样用户删了图片还能看到图片
            Card(
              elevation: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text("选择json中图片公共文件夹"),
                          subtitle: Text(cusExerciseImagePerfix),
                          trailing: IconButton(
                            onPressed: _openExerciseImagesExplorer,
                            icon: Icon(
                              Icons.folder,
                              size: 25.sp,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// json文件列表不为空才显示对应区域
            if (jsons.isNotEmpty)
              Text(
                "json文件列表:",
                style: TextStyle(fontSize: 14.sp),
                textAlign: TextAlign.start,
              ),
            if (jsons.isNotEmpty)
              SizedBox(
                height: 100.sp,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: jsons.length,
                  itemBuilder: (context, index) {
                    return Text(
                      'PATH: ${jsons[index].path}',
                      style: TextStyle(fontSize: 12.sp),
                      textAlign: TextAlign.start,
                    );
                  },
                ),
              ),

            /// 食物组成列表不为空才显示对应区域
            if (cusExercises.isNotEmpty)
              Text(
                "食物信息概述:",
                style: TextStyle(fontSize: 14.sp),
                textAlign: TextAlign.start,
              ),
            if (cusExercises.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: cusExercises.length,
                  itemBuilder: (context, index) {
                    return Row(
                      verticalDirection: VerticalDirection.up,
                      children: [
                        Expanded(
                          child: Text(
                            '编号: ${cusExercises[index].id} 名称: ${cusExercises[index].name}, 级别: ${cusExercises[index].level}',
                            style: TextStyle(fontSize: 12.sp),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

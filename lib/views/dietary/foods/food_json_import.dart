// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/dietary_state.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/food_composition.dart';

class FoodJsonImport extends StatefulWidget {
  const FoodJsonImport({super.key});

  @override
  State<FoodJsonImport> createState() => _FoodJsonImportState();
}

class _FoodJsonImportState extends State<FoodJsonImport> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  List<FoodComposition> foodComps = [];
  List<File> jsons = [];

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
          var temp = foodEnergyMapList
              .map((e) => FoodComposition.fromJson(e))
              .toList();

          setState(() {
            foodComps.addAll(temp);
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
            List foodEnergyMapList = json.decode(jsonData);
            print(foodEnergyMapList);
            var temp = foodEnergyMapList
                .map((e) => FoodComposition.fromJson(e))
                .toList();
            setState(() {
              foodComps.addAll(temp);
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

  // 讲json数据保存到数据库中
  _saveToDb() async {
    // 这里导入去重的工作要放在上面解析文件时，这里就全部保存了。
    // 而且id自增，食物或者编号和数据库重复，这里插入数据库中也不会报错。
    for (var e in foodComps) {
      var tempFood = Food(
        // 转型会把前面的0去掉(让id自增，否则下面serving的id也要指定)
        brand: e.foodCode ?? '',
        product: e.foodName ?? "",
        tags: "",
        category: "",
        contributor: "用户导入",
        gmtCreate: DateFormat.yMMMd().format(DateTime.now()),
      );

      /// 营养素值全是字符串，而且由于是orc识别，还可以包含无法转换的内容
      /// size都应该都是1；unit则是标准单份为100g或100ml，自定义则为1份
      ///   原书全是标准值，都是100g，但是有分可食用部分，这里排除
      /// 也是因为有可食用部分的栏位，这里就不计算单克的值来
      var tempServing = ServingInfo(
        // 因为同时新增食物和单份营养素，所以这个foodId会被上面的替换掉
        foodId: 0,
        servingSize: 1,
        servingUnit: "100g",
        energy: double.tryParse(e.energyKJ ?? "0") ?? 0,
        protein: double.tryParse(e.protein ?? "0") ?? 0,
        totalFat: double.tryParse(e.fat ?? "0") ?? 0,
        totalCarbohydrate: double.tryParse(e.cHO ?? "0") ?? 0,
        // ？？？钠在另外一份中，脚本把它们合并到一起？？？
        sodium: 0,
        // 其他可选值暂时不对应
        cholesterol: double.tryParse(e.cholesterol ?? "0") ?? 0,
        dietaryFiber: double.tryParse(e.dietaryFiber ?? "0") ?? 0,
      );

      try {
        await _dietaryHelper.insertFoodWithServingInfoList(
          food: tempFood,
          servingInfoList: [tempServing],
        );
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
        foodComps = [];
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入食物JSON数据'),
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
                          foodComps = [];
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
                      onPressed: foodComps.isNotEmpty ? _saveToDb : null,
                      disabledColor: Colors.grey,
                      icon: Icon(
                        Icons.save,
                        size: 30.sp,
                        color: foodComps.isNotEmpty ? Colors.blue : Colors.grey,
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
            if (foodComps.isNotEmpty)
              Text(
                "食物信息概述:",
                style: TextStyle(fontSize: 14.sp),
                textAlign: TextAlign.start,
              ),
            if (foodComps.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: foodComps.length,
                  itemBuilder: (context, index) {
                    return Row(
                      verticalDirection: VerticalDirection.up,
                      children: [
                        Expanded(
                          child: Text(
                            '编号: ${foodComps[index].foodCode} 名称: ${foodComps[index].foodName}, 大卡: ${foodComps[index].energyKCal}',
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

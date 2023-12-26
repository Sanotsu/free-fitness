// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/common/utils/tools.dart';
import 'package:free_fitness/models/dietary_state.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/food_composition.dart';

class FoodJsonImport extends StatefulWidget {
  const FoodJsonImport({super.key});

  @override
  State<FoodJsonImport> createState() => _FoodJsonImportState();
}

class _FoodJsonImportState extends State<FoodJsonImport> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  // 是否在解析json中或导入数据库中
  bool isLoading = false;
  // 解析后的食物营养素列表(文件和食物都不支持移除)
  List<FoodComposition> foodComps = [];
  // 上传的json文件列表
  List<File> jsons = [];

  // 构建json文件加载成功后的锻炼数据表格要用到
  // 待上传的动作数量已经每个动作的选中状态
  int exerciseItemsNum = 0;
  List<bool> exerciseSelectedList = [false];

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
          List foodEnergyMapList =
              jsonData.trim().startsWith("[") && jsonData.trim().endsWith("]")
                  ? json.decode(jsonData)
                  : json.decode("[$jsonData]");

          var temp = foodEnergyMapList
              .map((e) => FoodComposition.fromJson(e))
              .toList();

          setState(() {
            foodComps.addAll(temp);
            // 更新需要构建的表格的长度和每条数据的可选中状态
            exerciseItemsNum = foodComps.length;
            exerciseSelectedList =
                List<bool>.generate(exerciseItemsNum, (int index) => false);
          });
        } catch (e) {
          // 弹出报错提示框
          if (!mounted) return;

          commonExceptionDialog(
            context,
            CusAL.of(context).importJsonError,
            CusAL.of(context).importJsonErrorText(file.path, e.toString),
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
            List foodEnergyMapList =
                jsonData.trim().startsWith("[") && jsonData.trim().endsWith("]")
                    ? json.decode(jsonData)
                    : json.decode("[$jsonData]");

            var temp = foodEnergyMapList
                .map((e) => FoodComposition.fromJson(e))
                .toList();

            setState(() {
              foodComps.addAll(temp);
              // 更新需要构建的表格的长度和每条数据的可选中状态
              exerciseItemsNum = foodComps.length;
              exerciseSelectedList =
                  List<bool>.generate(exerciseItemsNum, (int index) => false);
            });
          } catch (e) {
            // 弹出报错提示框
            if (!mounted) return;

            commonExceptionDialog(
              context,
              CusAL.of(context).importJsonError,
              CusAL.of(context).importJsonErrorText(file.path, e.toString),
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

  // 讲json数据保存到数据库中
  _saveToDb() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });
    // 这里导入去重的工作要放在上面解析文件时，这里就全部保存了。
    // 而且id自增，食物或者编号和数据库重复，这里插入数据库中也不会报错。
    for (var e in foodComps) {
      var tempFood = Food(
        // 转型会把前面的0去掉(让id自增，否则下面serving的id也要指定)
        brand: e.foodCode ?? '',
        product: e.foodName ?? "",
        tags: e.tags?.join(","),
        category: e.category?.join(","),
        // ？？？2023-11-30 这里假设传入的图片是完整的，就不像动作那样再指定文件夹前缀了
        photos: e.photos?.join(","),
        contributor: CacheUser.userName,
        gmtCreate: getCurrentDateTime(),
        isDeleted: false,
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
        sodium: double.tryParse(e.na ?? "0") ?? 0,
        cholesterol: double.tryParse(e.cholesterol ?? "0") ?? 0,
        dietaryFiber: double.tryParse(e.dietaryFiber ?? "0") ?? 0,
        // 其他可选值暂时不对应
        contributor: CacheUser.userName,
        gmtCreate: getCurrentDateTime(),
        isDeleted: false,
      );

      try {
        await _dietaryHelper.insertFoodWithServingInfoList(
          food: tempFood,
          servingInfoList: [tempServing],
        );
      } on Exception catch (e) {
        // 将错误信息展示给用户
        if (!mounted) return;
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
      setState(() {
        jsons = [];
        foodComps = [];
        // 更新需要构建的表格的长度和每条数据的可选中状态
        exerciseItemsNum = 0;
        exerciseSelectedList = [false];

        isLoading = false;
      });
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
          CusAL.of(context).foodImport,
          style: TextStyle(fontSize: CusFontSizes.pageTitle),
        ),
        actions: [
          IconButton(
            onPressed: foodComps.isNotEmpty ? _saveToDb : null,
            icon: Icon(
              Icons.save,
              color:
                  foodComps.isNotEmpty ? null : Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                /// 最上方的功能按钮区域
                _buildButtonsArea(),

                /// json文件列表不为空才显示对应区域
                if (jsons.isNotEmpty) ..._buildJsonFileInfoArea(),

                /// 食物组成列表不为空且大于50条，简单的列表展示
                if (foodComps.isNotEmpty && foodComps.length > 50)
                  ..._buildFoodServingListArea(),

                /// 食物组成列表不为空且不大于50条，简单的表格展示
                if (foodComps.isNotEmpty && foodComps.length <= 50)
                  ..._buildFoodServingDataTable(),
              ],
            ),
    );
  }

  // 构建功能按钮区
  _buildButtonsArea() {
    return Card(
      elevation: 5,
      child: Row(
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
                  foodComps = [];
                  // 更新需要构建的表格的长度和每条数据的可选中状态
                  exerciseItemsNum = 0;
                  exerciseSelectedList = [false];
                });
              },
              icon: Icon(
                Icons.clear,
                size: CusIconSizes.iconMedium,
                color: foodComps.isNotEmpty
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建json文件列表区
  _buildJsonFileInfoArea() {
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

  // 当上传的食物营养素信息超过50条，就单纯的列表展示
  _buildFoodServingListArea() {
    return [
      RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          children: [
            TextSpan(
              text: CusAL.of(context).itemCount(foodComps.length),
              style: TextStyle(
                fontSize: CusFontSizes.itemSubTitle,
                color: Colors.blue,
              ),
            ),
            TextSpan(
              text: "  ${CusAL.of(context).foodLabelNote}",
              style: TextStyle(
                fontSize: CusFontSizes.itemSubTitle,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 10.sp),
      Expanded(
        child: ListView.builder(
          itemCount: foodComps.length,
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
                          text: '${index + 1} - ',
                          style: TextStyle(
                            fontSize: CusFontSizes.itemSubTitle,
                            color: Colors.green,
                          ),
                        ),
                        TextSpan(
                          text: "${foodComps[index].foodCode} - ",
                          style: TextStyle(
                            fontSize: CusFontSizes.itemSubTitle,
                            color: Colors.grey,
                          ),
                        ),
                        TextSpan(
                          text: "${foodComps[index].foodName} - ",
                          style: TextStyle(
                            fontSize: CusFontSizes.itemSubTitle,
                            color: Colors.red,
                          ),
                        ),
                        TextSpan(
                          text: "${foodComps[index].energyKCal}",
                          style: TextStyle(
                            fontSize: CusFontSizes.itemSubTitle,
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

  // 当上传的食物营养素信息不超过50条，可以表格管理
  _buildFoodServingDataTable() {
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
                    foodComps.removeAt(trueIndices[i]);
                  }
                  // 更新需要构建的表格的长度和每条数据的可选中状态
                  exerciseItemsNum = foodComps.length;
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
              DataColumn(label: Text(CusAL.of(context).foodLabels('6'))),
              DataColumn(label: Text(CusAL.of(context).foodLabels('2'))),
              DataColumn(
                label: Text(CusAL.of(context).foodTableMainLabels('1')),
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
                        '${foodComps[index].foodCode}',
                        style: TextStyle(fontSize: CusFontSizes.itemContent),
                      ),
                    ),
                  ),
                  DataCell(
                    Wrap(
                      children: [
                        Text(
                          '${foodComps[index].foodName}',
                          style: TextStyle(fontSize: CusFontSizes.itemContent),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 50.sp,
                      child: Text(
                        '${foodComps[index].energyKCal}',
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

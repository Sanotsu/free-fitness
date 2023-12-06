// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/global/constants.dart';
import '../../../../models/dietary_state.dart';
import '../../../common/components/dialog_widgets.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tools.dart';
import 'food_base_modify.dart';
import 'food_serving_info_base_modify.dart';

// ？？？看能不能和日志中的food detail 拆一些复用部件来
/// 2023-12-04 和饮食记录模块的食物详情不太一样:
/// 本页面要修改食物基本信息、新增删除修改单份营养素信息，不关联餐次；
/// 后者显示的内容更少些，主要是选择餐次、单份营养素种类和添加食物摄入数量而已
class FoodNutrientDetail extends StatefulWidget {
  // 这个是食物搜索页面点击食物进来详情页时传入的数据
  final FoodAndServingInfo foodItem;

  const FoodNutrientDetail({super.key, required this.foodItem});

  @override
  State<FoodNutrientDetail> createState() => _FoodNutrientDetailState();
}

class _FoodNutrientDetailState extends State<FoodNutrientDetail> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  // 传入的食物详细数据
  late FoodAndServingInfo fsInfo;

  // 页面添加了滚动条
  final ScrollController _scrollController = ScrollController();

  // 构建食物的单份营养素列表，可以多选，然后进行相关操作
  // 待上传的动作数量已经每个动作的选中状态
  int servingItemsNum = 0;
  List<bool> servingSelectedList = [false];

  // 新增单份营养素时，选择的营养素类型(标准或者自制)
  CusLabel dropdownValue = servingTypeList.first;

  @override
  void initState() {
    super.initState();

    setState(() {
      fsInfo = widget.foodItem;

      // 更新需要构建的表格的长度和每条数据的可选中状态
      servingItemsNum = fsInfo.servingInfoList.length;
      servingSelectedList =
          List<bool>.generate(servingItemsNum, (int index) => false);
    });
  }

  //

  // 在修改了食物基本信息或者单份营养素之和，重新查询该食物信息
  refreshFoodAndServing() async {
    var newItem = await _dietaryHelper.searchFoodWithServingInfoByFoodId(
      widget.foodItem.food.foodId!,
    );

    if (newItem != null) {
      setState(() {
        fsInfo = newItem;

        // 重新查询后也要更新单份营养素的列表复选框数量及其状态
        servingItemsNum = fsInfo.servingInfoList.length;
        servingSelectedList =
            List<bool>.generate(servingItemsNum, (int index) => false);
      });
    }
  }

  /// 新结构，上面是食物基本信息，下面是单份营养素详情表格；
  /// 右上角修改按钮，修改基本信息；
  /// 表格的单份营养素可选中索引进行删除，可新增；
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('食物详情'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FoodBaseModify(food: fsInfo.food)),
              ).then((value) {
                // 不管是否修改成功，这里都重新加载
                // 还是稍微判断一下吧
                if (value != null && value == true) {
                  refreshFoodAndServing();
                }
              });
            },
            icon: Icon(Icons.edit, size: 20.sp),
          ),
        ],
      ),
      body: ListView(
        children: [
          ///
          /// 展示食物基本信息表格
          ///
          ...buildTableData(fsInfo),

          ///
          /// 展示所有单份的数据，不用实时根据摄入数量修改值
          ///
          /// ？？？这个table可以用高级点的，
          ///

          Text(
            "食物单份营养素信息",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),

          // 当有单份营养素被选中后，显示删除或修改(仅单个被选中时)按钮

          SizedBox(
            height: 50.sp,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 2023-12-05 暂时不提供修改，以新增+删除代替修改
                // if (servingSelectedList.where((e) => e == true).length == 1)
                //   TextButton(
                //     onPressed: clickServingInfoModify,
                //     child: const Text("修改"),
                //   ),
                if (servingSelectedList.where((e) => e == true).isNotEmpty)
                  TextButton(
                    onPressed: clickServingInfoDelete,
                    child: const Text("删除"),
                  ),
                TextButton(
                  onPressed: clickServingInfoAdd,
                  child: const Text("新增"),
                ),
              ],
            ),
          ),

          _buildSimpleFoodTable(fsInfo),
        ],
      ),
    );
  }

  // todo 2023-12-05 因为单份营养素基础表没有是否标准的栏位，所以没法传servingType。
  // 所以以新增+删除代替修改
  clickServingInfoModify() {
    // 先找到被选中的索引，应该只有一个
    int trueIndices =
        List.generate(servingSelectedList.length, (index) => index)
            .firstWhere((i) => servingSelectedList[i]);

    var servingInfo = fsInfo.servingInfoList[trueIndices];

    print("servingInfo---$servingInfo");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodServingInfoBaseModify(
          servingType: servingTypeList.first, // 这个值真没地方取啊
          food: fsInfo.food,
          currentServingInfo: servingInfo,
        ),
      ),
    );
  }

  clickServingInfoDelete() {
    if (servingSelectedList.where((e) => e == true).length == servingItemsNum) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('警告'),
            content: const Text(
              '''至少保留一个单份营养素信息。
              \n若要删除所有数据，请考虑删除该条食物信息。
              \n若要更新全部单份营养素，请先新增完成后，再删除旧的数据。
              \n暂时不提供单份营养素的修改，请以【删除+新增】代替修改。''',
            ),
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
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text(
              '''确定删除选中的单份营养素信息？''',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  // 先找到被选中的索引
                  List<int> trueIndices = List.generate(
                          servingSelectedList.length, (index) => index)
                      .where((i) => servingSelectedList[i])
                      .toList();

                  // 找到选择的索引对应的营养素列表
                  List<int> selecteds = [];
                  for (var index in trueIndices) {
                    selecteds.add(fsInfo.servingInfoList[index].servingInfoId!);
                  }

                  print("selecteds----$selecteds");

                  await _dietaryHelper.deleteServingInfoList(selecteds);

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('确认'),
              ),
            ],
          );
        },
      ).then((value) => refreshFoodAndServing());
    }
  }

  clickServingInfoAdd() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择单份类型'),
          content: DropdownMenu<CusLabel>(
            initialSelection: servingTypeList.first,
            onSelected: (CusLabel? value) {
              setState(() {
                dropdownValue = value!;
              });
            },
            dropdownMenuEntries: servingTypeList
                .map<DropdownMenuEntry<CusLabel>>((CusLabel value) {
              return DropdownMenuEntry<CusLabel>(
                value: value,
                label: value.cnLabel,
              );
            }).toList(),
          ),

          // cusFormBuilerDropdown(
          //   "serving_info_type",
          //   servingTypeList,
          //   labelText: '*营养成分',
          //   initialValue: servingTypeList.first.cnLabel,
          //   validator: FormBuilderValidators.compose(
          //       [FormBuilderValidators.required(errorText: '营养成分')]),
          // ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.pop(context, true);
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null && value) {
        print("dropdownValue---$dropdownValue");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodServingInfoBaseModify(
              food: fsInfo.food,
              servingType: dropdownValue,
            ),
          ),
        ).then((value) {
          // 返回单份营养素新增成功的话重新查询当前食物详情数据
          if (value != null && value == true) {
            refreshFoodAndServing();
          }
        });
      }
    });
  }

  /// 表格显示食物基本信息
  buildTableData(FoodAndServingInfo info) {
    var food = info.food;
    var imageList = food.photos?.split(",") ?? [];

    return [
      Text(
        "食物基本信息",
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        textAlign: TextAlign.start,
      ),
      Padding(
        padding: EdgeInsets.all(10.sp),
        child: Table(
          border: TableBorder.all(), // 设置表格边框
          // 设置每列的宽度占比
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(4),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildTableRow("品牌", food.brand),
            _buildTableRow("名称", food.product),
            _buildTableRow("标签", food.tags ?? ""),
            _buildTableRow("分类", food.category ?? ""),
          ],
        ),
      ),
      buildImageCarouselSlider(imageList),
      SizedBox(height: 20.sp),
    ];
  }

  // 构建表格行数据
  _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            label,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            value,
            style: TextStyle(fontSize: 14.0.sp, color: Colors.grey[700]!),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  /// 表格展示单份营养素信息？？？
  ///
  _buildSimpleFoodTable(FoodAndServingInfo fsi) {
    // var food = fsi.food;
    // var foodName = "${food.product} (${food.brand})";
    var servingList = fsi.servingInfoList;

    return Card(
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // SizedBox(
          //   width: 1.sw,
          //   child: Container(
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(5.0), // 设置所有圆角的大小
          //       // 设置展开前的背景色
          //       color: const Color.fromARGB(255, 195, 198, 201),
          //     ),
          //     child: Padding(
          //       padding: EdgeInsets.all(10.sp),
          //       child: RichText(
          //         textAlign: TextAlign.start,
          //         maxLines: 2,
          //         overflow: TextOverflow.ellipsis,
          //         text: TextSpan(
          //           children: [
          //             TextSpan(
          //               text: '食物名称: ',
          //               style: TextStyle(fontSize: 14.sp, color: Colors.black),
          //             ),
          //             TextSpan(
          //               text: foodName,
          //               style: TextStyle(
          //                 fontSize: 16.sp,
          //                 color: Colors.black,
          //                 fontWeight: FontWeight.bold,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          Scrollbar(
            thickness: 5,
            // 设置交互模式后，滚动条和手势滚动方向才一致
            interactive: true,
            radius: Radius.circular(5.sp),
            // 不设置这个，滚动条默认不显示，在滚动时才显示
            thumbVisibility: true,
            // trackVisibility: true,
            // 滚动条默认在右边，要改在左边就配合Transform进行修改(此例没必要)
            // 刻意预留一点空间给滚动条
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: DataTable(
                  // dataRowHeight: 10.sp,
                  dataRowMinHeight: 60.sp, // 设置行高范围
                  dataRowMaxHeight: 100.sp,
                  headingRowHeight: 25, // 设置表头行高
                  horizontalMargin: 10, // 设置水平边距
                  columnSpacing: 20.sp, // 设置列间距
                  columns: [
                    _buildDataColumn("单份"),
                    _buildDataColumn("能量(大卡)"),
                    _buildDataColumn("蛋白质(克)"),
                    _buildDataColumn("脂肪(克)"),
                    _buildDataColumn("碳水(克)"),
                    _buildDataColumn("微量元素(毫克)"),
                  ],
                  rows: List<DataRow>.generate(servingList.length, (index) {
                    var serving = servingList[index];

                    return DataRow(
                      // 奇数行添加灰色背景色
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
                      // 是否被选中
                      selected: servingSelectedList[index],
                      // 选中变化的回调
                      onSelectChanged: (bool? value) {
                        setState(() {
                          servingSelectedList[index] = value!;
                        });
                      },
                      cells: [
                        _buildDataCell(serving.servingUnit),
                        _buildDataCell(formatDoubleToString(
                            serving.energy / oneCalToKjRatio)),
                        _buildDataCell(formatDoubleToString(serving.protein)),
                        _buildFatDataCell(
                          formatDoubleToString(serving.totalFat),
                          serving.transFat?.toStringAsFixed(2) ?? "",
                          serving.saturatedFat?.toStringAsFixed(2) ?? "",
                          serving.monounsaturatedFat?.toStringAsFixed(2) ?? "",
                          serving.polyunsaturatedFat?.toStringAsFixed(2) ?? "",
                        ),
                        _buildChoDataCell(
                          formatDoubleToString(serving.totalCarbohydrate),
                          serving.sugar?.toStringAsFixed(2) ?? "",
                          serving.dietaryFiber?.toStringAsFixed(2) ?? "",
                        ),
                        _buildMicroDataCell(
                          formatDoubleToString(serving.sodium),
                          serving.cholesterol?.toStringAsFixed(2) ?? "",
                          serving.potassium?.toStringAsFixed(2) ?? "",
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.sp),
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: DataTable(
          //     // dataRowHeight: 10.sp,
          //     dataRowMinHeight: 60.sp, // 设置行高范围
          //     dataRowMaxHeight: 100.sp,
          //     headingRowHeight: 25, // 设置表头行高
          //     horizontalMargin: 10, // 设置水平边距
          //     columnSpacing: 20.sp, // 设置列间距
          //     columns: [
          //       DataColumn(
          //         label: Text('单份', style: TextStyle(fontSize: 14.sp)),
          //       ),
          //       DataColumn(
          //         label: Text('能量(大卡)', style: TextStyle(fontSize: 14.sp)),
          //         numeric: true,
          //       ),
          //       DataColumn(
          //         label: Text('蛋白质(克)', style: TextStyle(fontSize: 14.sp)),
          //         numeric: true,
          //       ),
          //       DataColumn(
          //         label: Text('脂肪(克)', style: TextStyle(fontSize: 14.sp)),
          //         numeric: true,
          //       ),
          //       DataColumn(
          //         label: Text('碳水(克)', style: TextStyle(fontSize: 14.sp)),
          //         numeric: true,
          //       ),
          //       DataColumn(
          //         label: Text('微量元素(毫克)', style: TextStyle(fontSize: 14.sp)),
          //         numeric: true,
          //       ),
          //     ],
          //     rows: List<DataRow>.generate(servingList.length, (index) {
          //       var serving = servingList[index];

          //       return DataRow(
          //         cells: [
          //           _buildDataCell(serving.servingUnit),
          //           _buildDataCell(
          //               formatDoubleToString(serving.energy / oneCalToKjRatio)),
          //           _buildDataCell(formatDoubleToString(serving.protein)),
          //           _buildFatDataCell(
          //             formatDoubleToString(serving.totalFat),
          //             serving.transFat?.toStringAsFixed(2) ?? "",
          //             serving.saturatedFat?.toStringAsFixed(2) ?? "",
          //             serving.monounsaturatedFat?.toStringAsFixed(2) ?? "",
          //             serving.polyunsaturatedFat?.toStringAsFixed(2) ?? "",
          //           ),
          //           _buildChoDataCell(
          //             formatDoubleToString(serving.totalCarbohydrate),
          //             serving.sugar?.toStringAsFixed(2) ?? "",
          //             serving.dietaryFiber?.toStringAsFixed(2) ?? "",
          //           ),
          //           _buildMicroDataCell(
          //             formatDoubleToString(serving.sodium),
          //             serving.cholesterol?.toStringAsFixed(2) ?? "",
          //             serving.potassium?.toStringAsFixed(2) ?? "",
          //           ),
          //         ],
          //       );
          //     }),
          //   ),
          // ),
        ],
      ),
    );
  }

  /// 表格的标题和单元格样式
  _buildDataColumn(String text) {
    return DataColumn(
      label: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _buildDataCell(String text) {
    return DataCell(
      Text(
        text,
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }

  _buildFatDataCell(
    String totalFat,
    String transFat,
    String saturatedFat,
    String muFat,
    String puFat,
  ) {
    return DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("总脂肪 ", style: TextStyle(fontSize: 14.sp)),
              Text(totalFat, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          _buildDetailRowCellText("反式脂肪 ", transFat),
          _buildDetailRowCellText("饱和脂肪 ", transFat),
          _buildDetailRowCellText("单不饱和脂肪 ", transFat),
          _buildDetailRowCellText("多不饱和脂肪 ", transFat),
        ],
      ),
    );
  }

  _buildChoDataCell(String totalCho, String sugar, String dietaryFiber) {
    return DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("总碳水 ", style: TextStyle(fontSize: 14.sp)),
              Text(totalCho, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          _buildDetailRowCellText("糖 ", sugar),
          _buildDetailRowCellText("膳食纤维 ", dietaryFiber),
        ],
      ),
    );
  }

  _buildMicroDataCell(
    String sodium,
    String potassium,
    String cholesterol,
  ) {
    return DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("钠 ", style: TextStyle(fontSize: 14.sp)),
              Text(sodium, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("钾 ", style: TextStyle(fontSize: 14.sp)),
              Text(potassium, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("胆固醇 ", style: TextStyle(fontSize: 14.sp)),
              Text(cholesterol, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
        ],
      ),
    );
  }

  _buildDetailRowCellText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]!),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]!),
        ),
      ],
    );
  }
}

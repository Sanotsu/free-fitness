// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/global/constants.dart';
import '../../../../models/dietary_state.dart';
import '../../../common/components/dialog_widgets.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../models/cus_app_localizations.dart';
import 'detail_modify_food.dart';
import 'detail_modify_serving_info.dart';

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

  // 数据是否被修改
  // (这个标志要返回，如果有被修改，返回上一页列表时要重新查询；没有被修改则不用重新查询)
  bool isModified = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      fsInfo = widget.foodItem;

      // 更新需要构建的表格的长度和每条数据的可选中状态(初始状态是都未选中)
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // 返回上一页时，返回是否被修改标识，用于父组件判断是否需要重新查询
        Navigator.pop(context, isModified);
      },

      // WillPopScope(
      //   onWillPop: () async {
      //     // 在这里执行返回按钮被点击时的逻辑
      //     // 比如执行 Navigator.pop() 返回前一个页面并携带数据
      //     Navigator.pop(context, {"refreshData": true});
      //     return true; // 返回true表示允许退出当前页面
      //   },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(CusAL.of(context).foodDetail),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailModifyFood(food: fsInfo.food),
                  ),
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
            /// 展示食物基本信息表格
            ...buildFoodTable(fsInfo),

            /// 展示所有单份的数据，不用实时根据摄入数量修改值
            Text(
              CusAL.of(context).foodNutrientInfo,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.left,
            ),

            /// 当有单份营养素被选中后，显示删除或修改(仅单个被选中时)按钮；默认即可新增
            SizedBox(
              height: 50.sp,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 2023-12-05 暂时不提供修改，以新增+删除代替修改
                  if (servingSelectedList.where((e) => e == true).length == 1)
                    TextButton(
                      onPressed: clickServingInfoModify,
                      child: Text(CusAL.of(context).eidtLabel("")),
                    ),
                  if (servingSelectedList.where((e) => e == true).isNotEmpty)
                    TextButton(
                      onPressed: clickServingInfoDelete,
                      child: Text(CusAL.of(context).deleteLabel),
                    ),
                  TextButton(
                    onPressed: clickServingInfoAdd,
                    child: Text(CusAL.of(context).addLabel("")),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.sp),
            Card(
              elevation: 5,
              child: buildFoodServingDataTable(fsInfo),
            ),
            SizedBox(height: 20.sp),
          ],
        ),
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailModifyServingInfo(
          /// 这个值真没地方取啊
          /// 2023-12-06 简单判断是否是标准度量
          servingType: (servingInfo.servingUnit.toLowerCase() == "100ml" ||
                  servingInfo.servingUnit.toLowerCase() == "100g" ||
                  servingInfo.servingUnit.toLowerCase() == "1mg" ||
                  servingInfo.servingUnit.toLowerCase() == "1g")
              ? servingTypeList.first
              : servingTypeList.last,
          food: fsInfo.food,
          currentServingInfo: servingInfo,
        ),
      ),
    ).then((value) {
      // 返回单份营养素新增成功的话重新查询当前食物详情数据
      if (value != null && value == true) {
        refreshFoodAndServing();
        // 如果食物相关数据被修改，则变动标识设为true
        setState(() {
          isModified = true;
        });
      }
    });
  }

  clickServingInfoDelete() {
    if (servingSelectedList.where((e) => e == true).length == servingItemsNum) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(CusAL.of(context).alertTitle),
            content: const Text(
              '''至少保留一个单份营养素信息。
              \n若要删除所有数据，请考虑删除该条食物信息。
              \n若要更新全部单份营养素，请先新增完成后，再删除旧的数据。''',
            ),
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
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(CusAL.of(context).deleteConfirm),
            content: Text(CusAL.of(context).deleteNote("")),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(CusAL.of(context).cancelLabel),
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
                  // ？？？删除对应的单份营养素列表，应该要检测执行结果
                  await _dietaryHelper.deleteServingInfoList(selecteds);

                  if (!mounted) return;
                  Navigator.pop(context);
                  // 如果食物相关数据被修改，则变动标识设为true
                  setState(() {
                    isModified = true;
                  });
                },
                child: Text(CusAL.of(context).confirmLabel),
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
      builder: (ctx) {
        return AlertDialog(
          title: Text(CusAL.of(ctx).optionsLabel),
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
                label: showCusLableMapLabel(context, value),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
              },
              child: Text(CusAL.of(ctx).cancelLabel),
            ),
            TextButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.pop(ctx, true);
              },
              child: Text(CusAL.of(ctx).confirmLabel),
            ),
          ],
        );
      },
    ).then((value) {
      // 因为默认有选中新增单份营养素的类型，所以返回true确认新增时，一定有该type
      if (value != null && value) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailModifyServingInfo(
              food: fsInfo.food,
              servingType: dropdownValue,
            ),
          ),
        ).then((value) {
          // 返回单份营养素新增成功的话重新查询当前食物详情数据
          if (value != null && value == true) {
            refreshFoodAndServing();
            // 如果食物相关数据被修改，则变动标识设为true
            setState(() {
              isModified = true;
            });
          }
        });
      }
    });
  }

  /// 表格显示食物基本信息
  buildFoodTable(FoodAndServingInfo info) {
    var food = info.food;
    List<String> imageList = [];
    // 先要排除image是个空字符串在分割
    if (food.photos != null && food.photos!.trim().isNotEmpty) {
      imageList = food.photos!.split(",");
    }

    return [
      Text(
        CusAL.of(context).foodBasicInfo,
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
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(9),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildTableRow(
              CusAL.of(context).foodLabels("0"),
              food.product,
            ),
            _buildTableRow(
              CusAL.of(context).foodLabels("1"),
              food.brand,
            ),
            _buildTableRow(
              CusAL.of(context).foodLabels("2"),
              food.tags ?? "",
            ),
            _buildTableRow(
              CusAL.of(context).foodLabels("3"),
              food.category ?? "",
            ),
            _buildTableRow(
              CusAL.of(context).foodLabels("4"),
              food.description ?? "",
            ),
          ],
        ),
      ),
      buildImageCarouselSlider(imageList),
      SizedBox(height: 20.sp),
    ];
  }

  // 构建食物基本信息表格的行数据
  _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: Text(
            label,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
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

  /// 表格展示单份营养素信息
  buildFoodServingDataTable(FoodAndServingInfo fsi) {
    var servingList = fsi.servingInfoList;

    return buildDataTableWithHorizontalScrollbar(
      scrollController: _scrollController,
      columns: [
        _buildDataColumn(CusAL.of(context).foodTableMainLabels("0")),
        _buildDataColumn(CusAL.of(context).foodTableMainLabels("1")),
        _buildDataColumn(CusAL.of(context).foodTableMainLabels("2")),
        _buildDataColumn(CusAL.of(context).foodTableMainLabels("3")),
        _buildDataColumn(CusAL.of(context).foodTableMainLabels("4")),
        _buildDataColumn(CusAL.of(context).foodTableMainLabels("5")),
      ],
      rows: List<DataRow>.generate(servingList.length, (index) {
        var serving = servingList[index];

        return DataRow(
          // 偶数行(算上标题行)添加灰色背景色，和选中时的背景色
          color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            // 所有行被选中后都使用统一的背景
            if (states.contains(MaterialState.selected)) {
              return Theme.of(context).colorScheme.primary.withOpacity(0.08);
            }
            // 偶数行使用灰色背景
            if (index.isEven) {
              return Colors.grey.withOpacity(0.3);
            }
            // 对其他状态和奇数行使用默认值。
            return null;
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
            _buildDataCell(cusDoubleToString(serving.energy / oneCalToKjRatio)),
            _buildDataCell(cusDoubleToString(serving.protein)),
            _buildFatDataCell(
              cusDoubleToString(serving.totalFat),
              cusDoubleToString(serving.transFat),
              cusDoubleToString(serving.saturatedFat),
              cusDoubleToString(serving.monounsaturatedFat),
              cusDoubleToString(serving.polyunsaturatedFat),
            ),
            _buildChoDataCell(
              cusDoubleToString(serving.totalCarbohydrate),
              cusDoubleToString(serving.sugar),
              cusDoubleToString(serving.dietaryFiber),
            ),
            _buildMicroDataCell(
              cusDoubleToString(serving.sodium),
              cusDoubleToString(serving.cholesterol),
              cusDoubleToString(serving.potassium),
            ),
          ],
        );
      }),
    );
  }

  // 表格的标题和单元格样式
  _buildDataColumn(String text) {
    return DataColumn(
      label: Text(
        text,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 构建单个值的单元格
  _buildDataCell(String text) {
    return DataCell(
      Text(text, style: TextStyle(fontSize: 14.sp)),
    );
  }

  // 脂肪、碳水、蛋白质单元格有多个不同的值，要单独构建
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
              Text(
                '${CusAL.of(context).fatNutrients("0")}  ',
                style: TextStyle(fontSize: 14.sp),
              ),
              Text(totalFat, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          if (saturatedFat.isNotEmpty)
            _buildDetailRowCellText(
              '${CusAL.of(context).fatNutrients("1")}  ',
              saturatedFat,
            ),
          if (transFat.isNotEmpty)
            _buildDetailRowCellText(
              '${CusAL.of(context).fatNutrients("2")}  ',
              transFat,
            ),
          if (puFat.isNotEmpty)
            _buildDetailRowCellText(
              '${CusAL.of(context).fatNutrients("3")}  ',
              puFat,
            ),
          if (muFat.isNotEmpty)
            _buildDetailRowCellText(
              '${CusAL.of(context).fatNutrients("4")}  ',
              muFat,
            ),
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
              Text(
                '${CusAL.of(context).choNutrients("0")}  ',
                style: TextStyle(fontSize: 14.sp),
              ),
              Text(totalCho, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          if (sugar.isNotEmpty)
            _buildDetailRowCellText(
              '${CusAL.of(context).choNutrients("1")}  ',
              sugar,
            ),
          if (dietaryFiber.isNotEmpty)
            _buildDetailRowCellText(
              '${CusAL.of(context).choNutrients("2")}  ',
              dietaryFiber,
            ),
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
              Text(
                '${CusAL.of(context).microNutrients("0")}  ',
                style: TextStyle(fontSize: 14.sp),
              ),
              Text(sodium, style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          if (potassium.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${CusAL.of(context).microNutrients("1")}  ',
                  style: TextStyle(fontSize: 14.sp),
                ),
                Text(potassium, style: TextStyle(fontSize: 14.sp)),
              ],
            ),
          if (cholesterol.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${CusAL.of(context).microNutrients("2")}  ',
                  style: TextStyle(fontSize: 14.sp),
                ),
                Text(cholesterol, style: TextStyle(fontSize: 14.sp)),
              ],
            ),
        ],
      ),
    );
  }

  // 单元格中有多个值，每个值都还有label和value
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

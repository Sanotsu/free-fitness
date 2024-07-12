import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/dietary_state.dart';

import '../../../../common/global/constants.dart';
import '../../../../common/utils/db_dietary_helper.dart';
import '../../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import 'food_json_import.dart';
import 'add_food_with_serving.dart';
import 'food_nutrient_detail.dart';

/// 2023-11-21 食物单独一个大模块，可以逐步考虑和之前新增饮食记录的部件进行复用，或者整体复用
/// 这里是对食物的管理，所以不涉及饮食日志和餐次等逻辑
/// 主要就是食物的增删改查、详情、导入等内容
class DietaryFoods extends StatefulWidget {
  const DietaryFoods({super.key});

  @override
  State<DietaryFoods> createState() => _DietaryFoodsState();
}

class _DietaryFoodsState extends State<DietaryFoods> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  List<FoodAndServingInfo> foodItems = [];
  // 食物的总数(查询时则为符合条件的总数，默认一页只有10条，看不到总数量)
  int itemsCount = 0;
  int currentPage = 1; // 数据库查询的时候会从0开始offset
  int pageSize = 10;
  bool isLoading = false;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  String query = '';

  // 可以选择精简展示或者表格展示
  bool isSimpleMode = true;

  @override
  void initState() {
    super.initState();
    _loadFoodData();

    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    CusDataResult temp = await _dietaryHelper
        .searchFoodWithServingInfoWithPagination(query, currentPage, pageSize);

    var newData = temp.data as List<FoodAndServingInfo>;

    setState(() {
      foodItems.addAll(newData);
      itemsCount = temp.total;
      currentPage++;
      isLoading = false;
    });
  }

  void _scrollListener() {
    if (isLoading) return;

    final maxScrollExtent = scrollController.position.maxScrollExtent;
    final currentPosition = scrollController.position.pixels;
    final delta = 50.0.sp;

    if (maxScrollExtent - currentPosition <= delta) {
      _loadFoodData();
    }
  }

  void _handleSearch() {
    setState(() {
      foodItems.clear();
      currentPage = 1;
      query = searchController.text;
    });
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();

    _loadFoodData();
  }

  // 进入json文件导入前，先获取权限
  Future<void> clickFoodImport() async {
    final status = await requestStoragePermission();

    // 用户禁止授权，那就无法导入
    if (!status) {
      if (!mounted) return;
      showSnackMessage(context, CusAL.of(context).noStorageErrorText);
      return;
    }

    // 用户授权了访问内部存储权限，可以跳转到导入
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FoodJsonImport()),
    ).then((value) {
      // 从导入页面返回，总是刷新当前页面数据
      setState(() {
        foodItems.clear();
        currentPage = 1;
      });
      _loadFoodData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "${CusAL.of(context).food}\n",
                style: TextStyle(fontSize: CusFontSizes.pageTitle),
              ),
              TextSpan(
                text: CusAL.of(context).itemCount(itemsCount),
                style: TextStyle(fontSize: CusFontSizes.pageAppendix),
              ),
            ],
          ),
        ),
        actions: [
          isSimpleMode
              ? // 展示更多内容
              IconButton(
                  icon: const Icon(Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      isSimpleMode = !isSimpleMode;
                    });
                  },
                )
              // 展示更少内容
              : IconButton(
                  icon: const Icon(Icons.expand_less),
                  onPressed: () {
                    setState(() {
                      isSimpleMode = !isSimpleMode;
                    });
                  },
                ),

          // 导入
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: clickFoodImport,
          ),
          // 新增
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddfoodWithServing(),
                ),
              ).then((value) {
                // 不管是否新增成功，这里都重新加载；因为没有清空查询条件，所以新增的食物关键字不包含查询条件中，不会显示
                if (value != null) {
                  setState(() {
                    foodItems.clear();
                    currentPage = 1;
                  });
                  _loadFoodData();
                }
              });
            },
          ),
          // Row(
          //   children: [
          //     TextButton(
          //       onPressed: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //               builder: (context) => const AddfoodWithServing()),
          //         ).then((value) {
          //           // 不管是否新增成功，这里都重新加载；因为没有清空查询条件，所以新增的食物关键字不包含查询条件中，不会显示
          //           if (value != null) {
          //             setState(() {
          //               foodItems.clear();
          //               currentPage = 1;
          //             });
          //             _loadFoodData();
          //           }
          //         });
          //       },
          //       child: Text(
          //         CusAL.of(context).notFound,
          //         style: TextStyle(fontSize: 14.sp, color: Colors.white),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.sp),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: CusAL.of(context).queryKeywordHintText(
                        CusAL.of(context).food,
                      ),
                      // 设置透明底色
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _handleSearch,
                  child: Text(CusAL.of(context).searchLabel),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: foodItems.length + 1,
              itemBuilder: (context, index) {
                if (index == foodItems.length) {
                  return buildLoader(isLoading);
                } else {
                  return isSimpleMode
                      ? _buildSimpleFoodTile(foodItems[index], index)
                      : _buildSimpleFoodTable(foodItems[index]);
                }
              },
              controller: scrollController,
            ),
          ),
        ],
      ),
    );
  }

  _buildSimpleFoodTile(FoodAndServingInfo fsi, int index) {
    var food = fsi.food;
    var servingList = fsi.servingInfoList;
    var foodName = "${food.product} (${food.brand})";

    var firstServing = servingList.isNotEmpty ? servingList[0] : null;
    var foodUnit = firstServing?.servingUnit;
    var foodEnergy =
        (firstServing?.energy ?? 0 / oneCalToKjRatio).toStringAsFixed(0);

    // 能量文字
    var text1 = "$foodUnit - $foodEnergy ${CusAL.of(context).unitLabels('2')}";
    // 碳水文字
    var text2 =
        "${CusAL.of(context).mainNutrients('4')} ${formatDoubleToString(firstServing?.totalCarbohydrate ?? 0)} ${CusAL.of(context).unitLabels('0')}";
    // 脂肪文字
    var text3 =
        "${CusAL.of(context).mainNutrients('3')} ${formatDoubleToString(firstServing?.totalFat ?? 0)} ${CusAL.of(context).unitLabels('0')}";
    // 蛋白质文字
    var text4 =
        "${CusAL.of(context).mainNutrients('2')} ${formatDoubleToString(firstServing?.protein ?? 0)} ${CusAL.of(context).unitLabels('0')}";

    return Card(
      elevation: 5,
      child: ListTile(
        // 食物名称
        title: Text(
          "${index + 1} - $foodName",
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: CusFontSizes.itemTitle,
            color: Theme.of(context).primaryColor,
          ),
        ),
        // 单份食物营养素
        subtitle: Text(
          "$text1\n$text2 , $text3 , $text4",
          style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodNutrientDetail(
                foodItem: fsi,
              ),
            ),
          ).then((value) {
            // 从详情页返回后需要重新查询，因为不知道在内部是不是有变动单份营养素。
            // 有变动，退出不刷新，再次进入还是能看到旧的；但是返回就刷新对于只是浏览数据不友好。
            // 因此，详情页会有一个是否被异动的标志，返回true则重新查询；否则就不更新
            if (value != null && value) {
              setState(() {
                foodItems.clear();
                currentPage = 1;
              });
              _loadFoodData();
            }
          });
        },
        // 长按点击弹窗提示是否删除
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(CusAL.of(context).deleteConfirm),
                content: Text(
                  CusAL.of(context)
                      .deleteNote('\n${food.product}(${food.brand})'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text(CusAL.of(context).cancelLabel),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: Text(CusAL.of(context).confirmLabel),
                  ),
                ],
              );
            },
          ).then((value) async {
            if (value != null && value) {
              try {
                await _dietaryHelper.deleteFoodWithServingInfo(food.foodId!);

                // 删除后重新查询
                setState(() {
                  foodItems.clear();
                  currentPage = 1;
                });
                _loadFoodData();
              } catch (e) {
                if (!mounted) return;
                commonExceptionDialog(
                  context,
                  CusAL.of(context).exceptionWarningTitle,
                  e.toString(),
                );
              }
            }
          });
        },
      ),
    );
  }

  _buildSimpleFoodTable(FoodAndServingInfo fsi) {
    var food = fsi.food;
    var servingList = fsi.servingInfoList;
    var foodName = "${food.product} (${food.brand})";

    return Card(
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: 1.sw,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0), // 设置所有圆角的大小
                // 设置展开前的背景色
                // color: const Color.fromARGB(255, 195, 198, 201),
              ),
              child: Padding(
                padding: EdgeInsets.all(10.sp),
                child: RichText(
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: foodName,
                        style: TextStyle(
                          fontSize: CusFontSizes.itemTitle,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMinHeight: 20.sp, // 设置行高范围
              dataRowMaxHeight: 30.sp,
              headingRowHeight: 25.sp, // 设置表头行高
              horizontalMargin: 10.sp, // 设置水平边距
              columnSpacing: 10.sp, // 设置列间距
              columns: [
                DataColumn(
                  label: Text(
                    CusAL.of(context).foodTableMainLabels("0"),
                    style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                  ),
                ),
                DataColumn(
                  label: Text(
                    CusAL.of(context).foodTableMainLabels("1"),
                    style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    CusAL.of(context).foodTableMainLabels("2"),
                    style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    CusAL.of(context).foodTableMainLabels("3"),
                    style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    CusAL.of(context).foodTableMainLabels("4"),
                    style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                  ),
                  numeric: true,
                ),
              ],
              rows: List<DataRow>.generate(servingList.length, (index) {
                var serving = servingList[index];

                return DataRow(
                  cells: [
                    _buildDataCell(serving.servingUnit),
                    _buildDataCell(
                        formatDoubleToString(serving.energy / oneCalToKjRatio)),
                    _buildDataCell(formatDoubleToString(serving.protein)),
                    _buildDataCell(formatDoubleToString(serving.totalFat)),
                    _buildDataCell(
                        formatDoubleToString(serving.totalCarbohydrate)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  _buildDataCell(String text) {
    return DataCell(
      Text(
        text,
        style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
      ),
    );
  }
}

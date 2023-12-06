// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/dietary_state.dart';

import '../../../../common/global/constants.dart';
import '../../../../common/utils/db_dietary_helper.dart';
import '../../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import 'food_json_import.dart';
import 'add_food_with_serving.dart';
import 'food_nutrient_detail.dart';

/// 2023-11-21 食物单独一个大模块，可以逐步考虑和之前新增饮食记录的部件进行复用，或者整体复用
/// 这里是对食物的管理，所以不涉及饮食日志和餐次等逻辑
/// 主要就是食物的增删改查、详情、导入等内容
class DietaryFoods extends StatefulWidget {
  const DietaryFoods({Key? key}) : super(key: key);

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

    CusDataResult temp = await _queryFood(
      page: currentPage,
      size: pageSize,
      query: query,
    );

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

  Future<CusDataResult> _queryFood({
    required int page,
    required int size,
    String query = '',
  }) async {
    print("进入了_queryFood");

    var data = await _dietaryHelper.searchFoodWithServingInfoWithPagination(
      query,
      page,
      size,
    );
    print("进入了_queryFood,查询结果$data");

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '食物\n', style: TextStyle(fontSize: 20.sp)),
              TextSpan(
                text: "共 $itemsCount 条",
                style: TextStyle(fontSize: 12.sp),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FoodJsonImport()),
              ).then((value) {
                // 从导入页面返回，总是刷新当前页面数据
                // ？？？直接返回就不用？还是根据返回值来刷新？
                setState(() {
                  foodItems.clear();
                  currentPage = 1;
                });
                _loadFoodData();
              });
            },
          ),
          // 新增
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddfoodWithServing()),
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
                child: Text(
                  "找不到?",
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: '请输入产品或品牌关键字',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _handleSearch,
                  child: const Text('搜索'),
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

    return Card(
      elevation: 5,
      child: ListTile(
        // 食物名称
        title: Text(
          "${index + 1} - $foodName",
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
        // 单份食物营养素
        subtitle: Text(
          "$foodUnit - $foodEnergy 大卡 \n碳水 ${formatDoubleToString(firstServing?.totalCarbohydrate ?? 0)} g , 脂肪 ${formatDoubleToString(firstServing?.totalFat ?? 0)} g , 蛋白质 ${formatDoubleToString(firstServing?.protein ?? 0)} g",
          style: TextStyle(fontSize: 14.sp),
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),

        onTap: () {
          print("food lsit 点击了food item ，跳转到food detail ---> ");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodNutrientDetail(
                foodItem: fsi,
              ),
            ),
          );
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
                color: const Color.fromARGB(255, 195, 198, 201),
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
                        text: '食物名称: ',
                        style: TextStyle(fontSize: 14.sp, color: Colors.black),
                      ),
                      TextSpan(
                        text: foodName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.black,
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
              // dataRowHeight: 10.sp,
              dataRowMinHeight: 20.sp, // 设置行高范围
              dataRowMaxHeight: 30.sp,
              headingRowHeight: 25, // 设置表头行高为 40 像素
              horizontalMargin: 10, // 设置水平边距为 10 像素
              columnSpacing: 10.sp, // 设置列间距为 10 像素
              columns: [
                DataColumn(
                  label: Text('单份', style: TextStyle(fontSize: 14.sp)),
                ),
                DataColumn(
                  label: Text('能量(大卡)', style: TextStyle(fontSize: 14.sp)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('蛋白质(克)', style: TextStyle(fontSize: 14.sp)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('脂肪(克)', style: TextStyle(fontSize: 14.sp)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('碳水(克)', style: TextStyle(fontSize: 14.sp)),
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
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }
}

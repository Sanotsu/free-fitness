// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/dietary_state.dart';

import '../../../../common/global/constants.dart' as constants;
import '../../../../common/utils/sqlite_db_helper.dart';
import 'food_modify.dart';
import 'food_detail.dart';

class FoodList extends StatefulWidget {
  const FoodList({Key? key}) : super(key: key);

  @override
  State<FoodList> createState() => _FoodListState();
}

class _FoodListState extends State<FoodList> {
  List<FoodAndServingInfo> foodItems = [];
  int currentPage = 1; // 数据库查询的时候会从0开始offset
  int pageSize = 10;
  bool isLoading = false;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  String query = '';

  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  @override
  void initState() {
    super.initState();
    _loadData();

    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print("进入了_loadData");

    // _dietaryHelper.deleteDb();

    // return;

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    List<FoodAndServingInfo> newData =
        await _queryFood(page: currentPage, size: pageSize, query: query);

    setState(() {
      foodItems.addAll(newData);
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
      _loadData();
    }
  }

  void _handleSearch() {
    print("点击了_handleSearch");
    setState(() {
      foodItems.clear();
      currentPage = 1;
      query = searchController.text;
    });
    _loadData();
  }

  Future<List<FoodAndServingInfo>> _queryFood(
      {required int page, required int size, String query = ''}) async {
    print("进入了_queryFood");

    var data = await _dietaryHelper.searchFoodWithServingInfoWithPagination(
        query, page, size);
    print("进入了_queryFood,查询结果$data");

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food List'),
        actions: [
          Row(
            children: [
              const Text("找不到?"),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // _addFoodDemo();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FoodModify()),
                  );
                },
              )
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
                      hintText: 'Enter query',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _handleSearch,
                  child: const Text('Search11'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: foodItems.length + 1,
              itemBuilder: (context, index) {
                if (index == foodItems.length) {
                  return _buildLoader();
                } else {
                  var food = foodItems[index].food;
                  var foodName = "${food.product} (${food.brand})";

                  var fistServingInfo = foodItems[index].servingInfoList[0];
                  var foodUnit = fistServingInfo.metricServingSize != null
                      ? "${fistServingInfo.metricServingSize} 克"
                      : fistServingInfo.servingSize;
                  var foodEnergy = (foodItems[index].servingInfoList[0].energy /
                          constants.oneCalToKjRatio)
                      .toStringAsFixed(2);

                  return ListTile(
                    // 食物名称
                    title: Text(foodName),
                    // 单份食物营养素
                    subtitle: Text("$foodUnit - $foodEnergy 大卡"),
                    trailing: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add_box_outlined),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodDetail(
                            foodItem: foodItems[index],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
              controller: scrollController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Container();
    }
  }
}

class FoodDetailsPage extends StatelessWidget {
  final String foodItem;

  const FoodDetailsPage(this.foodItem, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Details - $foodItem'),
      ),
      body: Center(
        child: Text('Details of $foodItem'),
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/dietary_state.dart';

import '../../../../common/global/constants.dart' as constants;
import '../../../../common/global/constants.dart';
import '../../../../common/utils/sqlite_db_helper.dart';
import 'food_modify.dart';
import 'food_detail.dart';

class FoodList extends StatefulWidget {
  // 2023-10-26
  // 目前能进入食物列表的入口的，只有在饮食主界面点击顶部搜索按钮、知道餐次添加食物信息的时候。
  // 如果是顶部搜索，默认为早餐；其他指定餐次点击添加时也会自动带上对应餐次。
  final Mealtimes mealtime;

  // 当前的日记数据(注意，这个类不是数据库表直接映射表，是VO)
  // 进入列表的时候，可能是全新新加，也可能是已存在的餐次添加新的meal food item。
  //  如果是后者，需要 log id 和meal id
  //    这个值应该只是取值，不会变化
  //  如果是前者，则父组件没有日记数据传入
  final FoodDailyLogRecord? fdlr;

  // 当前日期，由主界面传入。
  // 理论上主界面可以选择任意日期进入此列表进行食物摄入添加，比如过去的日期补上，未来的日期预估。
  // 如果有传入上方的日记数据，其里面的date和这个date应该是一样的值。
  // 有传日记新增食物摄入时可以用日记里的或者这个值；没有日记完全新增时，只有用这个数据。
  final String logDate;

  const FoodList({
    Key? key,
    required this.mealtime,
    required this.fdlr,
    required this.logDate,
  }) : super(key: key);

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

  // 当前食物食用量管理的餐次 (传入的值，可以在这个列表页面进行修改，后续到详情页面进行添加时就是添加到对应的餐次)
  late Mealtimes currentMealtime;
  // 被选中的餐次（和传入的类型不一样）
  CusDropdownOption dropdownValue = mealtimeList.first;
  // 传入的饮食日记数据，这个应该不会变，只是查询数据
  FoodDailyLogRecord? currentFdlr;
  // 这次食物摄入的查询或者预计新增的meal item，属于哪一天的(也是用来查daily log的条件，应该不会变)
  late String currentDate;

  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  @override
  void initState() {
    super.initState();
    _loadData();

    setState(() {
      currentMealtime = widget.mealtime;
      currentFdlr = widget.fdlr;
      currentDate = widget.logDate;
      // 顶部显示的餐次，默认是取列表的第一个，这个改为父组件传入的值
      // ？？？可以父组件改为传入的就是list里面的对象而不是字符串，这样这里少个参数也不用转换
      dropdownValue =
          mealtimeList.firstWhere((e) => e.value == currentMealtime);
    });
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

    print(widget.mealtime);
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
        title: ListTile(
          // 这里使用DropdownButton可以控制显示的大小，用DropdownMenu暂时没搞定，会挤掉子标题文字
          title: SizedBox(
            height: 20.sp,
            child: DropdownButton<CusDropdownOption>(
              value: dropdownValue,
              onChanged: (CusDropdownOption? newValue) {
                setState(() {
                  // 修改下拉按钮的显示值
                  dropdownValue = newValue!;
                  // 修改要修改食物摄入数据的餐次
                  currentMealtime = newValue.value;
                });
              },
              items: mealtimeList.map<DropdownMenuItem<CusDropdownOption>>(
                  (CusDropdownOption value) {
                return DropdownMenuItem<CusDropdownOption>(
                  value: value,
                  child: Text(value.label),
                );
              }).toList(),
              underline: Container(), // 将下划线设置为空的Container
              icon: null, // 将图标设置为null
            ),
          ),
          subtitle: Text(currentDate),
        ),
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
                  var foodUnit = fistServingInfo.servingUnit;
                  var foodEnergy = (foodItems[index].servingInfoList[0].energy /
                          constants.oneCalToKjRatio)
                      .toStringAsFixed(2);

                  return ListTile(
                    // 食物名称
                    title: Text(foodName),
                    // 单份食物营养素
                    subtitle:
                        Text("$foodUnit - $foodEnergy $currentMealtime 大卡"),
                    trailing: IconButton(
                      onPressed: () async {
                        print("==========在这里直接添加份量值到日记对应餐次======");
                        print("==========当前食物：${foodItems[index]}");
                        print("==========当前餐次：$currentMealtime");
                        print("==========当日当餐已有食物摄入记录时，对应日、餐次添加meal food item");
                        print("==========此时需要日记id、meal id才行（从父组件传入）======");
                        log("==========此时传入的日记数据 $currentFdlr）======");
                        print("==========如果该日、该餐没有的数据，则是全新曾======");

                        // ？？？这里暂时先只新增1条数据，传入log、meal、mealItem和餐次标识字符串，具体判断逻辑全部放到db helper中区

                        // 如果没有当前日，则完全新增
                        var foodDailyLog = FoodDailyLog(
                          date: currentDate,
                          contributor: "david",
                          gmtCreate: DateTime.now().toString(),
                        );

                        var meal = Meal(
                          mealName: "$currentDate 的$currentMealtime",
                          description: "$currentMealtime吃好",
                          gmtCreate: DateTime.now().toString(),
                        );

                        var mealFoodItem = MealFoodItem(
                          // 当日没有日记的话，这个餐次编号就不会存在；
                          // 当日有日记、有餐次的话，这个餐次编号也是使用在新增时使用日记数据的值；
                          // 当日有日记、无餐次的话，餐次编号也是全新新增的，也不会用这个值；
                          // 所以这里要填值只是因为它必填，可以为任何int，毕竟逻辑中不会用到。
                          mealId: 11111,
                          // 这三个都是用户选择真实值。此处是直接预览的单份食物营养素，其实没有修改的位置。
                          // 真正用户自行输入的，是进入food详情之后才有。
                          foodId: foodItems[index].food.foodId!,
                          foodIntakeSize:
                              fistServingInfo.servingSize.toDouble(),
                          servingInfoId: fistServingInfo.servingInfoId!,
                        );

                        var tempStr = mealtimeList
                            .firstWhere((e) => e.value == currentMealtime);

                        var insertRst = await _dietaryHelper.insertFoodDailyLog(
                          foodDailyLog,
                          tempStr.label,
                          meal,
                          mealFoodItem,
                        );

                        print("food list 里面的新增 insertRst：$insertRst");
                      },
                      icon: const Icon(Icons.add_box_outlined),
                    ),
                    onTap: () {
                      print("food lsit 点击了food item ，跳转到food detail ---> ");

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodDetail(
                            foodItem: foodItems[index],
                            mealtime: currentMealtime,
                            logDate: currentDate,
                            jumpSource: 'FOOD_LIST',
                            fdlr: currentFdlr,
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

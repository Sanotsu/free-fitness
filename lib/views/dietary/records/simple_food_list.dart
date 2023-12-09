// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/common/utils/tools.dart';
import 'package:free_fitness/models/dietary_state.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../common/global/constants.dart' as constants;
import '../../../../common/global/constants.dart';
import '../../../../common/utils/db_dietary_helper.dart';
import '../../../../common/utils/tool_widgets.dart';

import '../foods/add_food_with_serving.dart';
import 'simple_food_detail.dart';

/// 2023-12-04 这个是饮食条目选择食物的时候展示的食物列表；
/// 和单独的“食物成分”模块不一样，显示的内容更少些，但关联的内容多些，比如日期、餐次等等
class SimpleFoodList extends StatefulWidget {
  // 2023-10-26
  // 目前能进入简单食物列表的入口的，只有在饮食主界面点击顶部搜索按钮、知道餐次添加食物信息的时候。
  // 如果是顶部搜索，默认为早餐；其他指定餐次点击添加时也会自动带上对应餐次。
  final CusMeals mealtime;

  // 当前日期，由主界面传入。
  // 理论上主界面可以选择任意日期进入此列表进行食物摄入添加，比如过去的日期补上，未来的日期预估。
  // 如果有传入上方的日记数据，其里面的date和这个date应该是一样的值。
  // 有传日记新增食物摄入时可以用日记里的或者这个值；没有日记完全新增时，只有用这个数据。
  final String logDate;

  const SimpleFoodList({
    Key? key,
    required this.mealtime,
    required this.logDate,
  }) : super(key: key);

  @override
  State<SimpleFoodList> createState() => _SimpleFoodListState();
}

class _SimpleFoodListState extends State<SimpleFoodList> {
  // 获取缓存中的用户编号(理论上进入app主页之后，就一定有一个默认的用户编号了)
  final box = GetStorage();
  int get currentUserId => box.read(LocalStorageKey.userId) ?? 1;

  List<FoodAndServingInfo> foodItems = [];
  int currentPage = 1; // 数据库查询的时候会从0开始offset
  int pageSize = 10;
  bool isLoading = false;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  String query = '';

  // 当前食物食用量管理的餐次 (传入的值，可以在这个列表页面进行修改，后续到详情页面进行添加时就是添加到对应的餐次)
  late CusMeals currentMealtime;
  // 被选中的餐次（和传入的类型不一样）
  CusLabel dropdownValue = mealtimeList.first;

  // 这次食物摄入的查询或者预计新增的meal item，属于哪一天的(也是用来查daily log的条件，应该不会变)
  late String currentDate;

  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  @override
  void initState() {
    super.initState();
    _loadData();

    setState(() {
      currentMealtime = widget.mealtime;
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

  // 加载食物数据，每次10条
  Future<void> _loadData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    CusDataResult temp =
        await _dietaryHelper.searchFoodWithServingInfoWithPagination(
      query,
      currentPage,
      pageSize,
    );

    List<FoodAndServingInfo> newData = temp.data as List<FoodAndServingInfo>;

    setState(() {
      foodItems.addAll(newData);
      currentPage++;
      isLoading = false;
    });
  }

  // 滚动到底部加载更多数据
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
    // 取消键盘输入框聚焦
    FocusScope.of(context).unfocus();
    setState(() {
      foodItems.clear();
      currentPage = 1;
      query = searchController.text;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          // 这里使用DropdownButton可以控制显示的大小，用DropdownMenu暂时没搞定，会挤掉子标题文字
          title: SizedBox(
            height: 20.sp,
            child: DropdownButton<CusLabel>(
              value: dropdownValue,
              onChanged: (CusLabel? newValue) {
                setState(() {
                  // 修改下拉按钮的显示值
                  dropdownValue = newValue!;
                  // 修改要修改食物摄入数据的餐次
                  currentMealtime = newValue.value;
                });
              },
              items: mealtimeList.map<DropdownMenuItem<CusLabel>>(
                (CusLabel value) {
                  return DropdownMenuItem<CusLabel>(
                    value: value,
                    child: Text(
                      value.cnLabel,
                      style: TextStyle(fontSize: 15.sp),
                    ),
                  );
                },
              ).toList(),
              underline: Container(), // 将下划线设置为空的Container
              icon: null, // 将图标设置为null
            ),
          ),
          subtitle: Text(currentDate, style: TextStyle(fontSize: 14.sp)),
        ),
        actions: [
          Row(
            children: [
              const Text("找不到?"),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddfoodWithServing()),
                  ).then((value) {
                    // 不管是否新增成功，这里都重新加载；因为没有清空查询条件，所以新增的食物关键字不包含查询条件中，不会显示
                    if (value != null) {
                      setState(() {
                        foodItems.clear();
                        currentPage = 1;
                      });
                      _loadData();
                    }
                  });
                },
              )
            ],
          ),
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
                  var food = foodItems[index].food;
                  var foodName = "${food.product}\n(${food.brand})";

                  var fistServingInfo = foodItems[index].servingInfoList[0];
                  var foodUnit = fistServingInfo.servingUnit;
                  var foodEnergy = (foodItems[index].servingInfoList[0].energy /
                          constants.oneCalToKjRatio)
                      .toStringAsFixed(2);

                  return Card(
                    elevation: 2,
                    child: ListTile(
                      // 食物名称
                      title: Text(
                        foodName,
                        // style: TextStyle(fontSize: 14.sp),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 单份食物营养素
                      subtitle: Text("$foodUnit - $foodEnergy 大卡"),
                      // 点击这个添加就是默认添加单份营养素的食物，那就直接返回日志页面。
                      trailing: IconButton(
                        onPressed: () async {
                          var tempStr = mealtimeList
                              .firstWhere((e) => e.value == currentMealtime);
                          // 如果没有当前日，则完全新增
                          var dailyFoodItem = DailyFoodItem(
                            date: currentDate,
                            mealCategory: tempStr.enLabel,
                            foodId: foodItems[index].food.foodId!,
                            servingInfoId: fistServingInfo.servingInfoId!,
                            foodIntakeSize:
                                fistServingInfo.servingSize.toDouble(),
                            userId: currentUserId,
                            gmtCreate: getCurrentDateTime(),
                          );

                          // ？？？这里应该有插入是否成功的判断
                          var rst = await _dietaryHelper
                              .insertDailyFoodItemList([dailyFoodItem]);

                          print("tempStr.enLabel----${tempStr.enLabel}");
                          if (!mounted) return;
                          if (rst.isNotEmpty) {
                            // 返回餐次，让主页面展开新增的那个折叠栏
                            Navigator.of(context).pop(tempStr.enLabel);
                          } else {
                            Navigator.of(context).pop(tempStr.enLabel);
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.blue),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SimpleFoodDetail(
                              foodItem: foodItems[index],
                              mealtime: currentMealtime,
                              logDate: currentDate,
                            ),
                          ),
                        );
                      },
                    ),
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
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/global/constants.dart' as constants;
import '../../../../common/global/constants.dart';
import '../../../../common/utils/db_dietary_helper.dart';
import '../../../../common/utils/tool_widgets.dart';

import '../../../../common/utils/tools.dart';

import '../../../../models/dietary_state.dart';
import '../../foods/add_food_with_serving.dart';
import 'simple_food_detail.dart';

///
/// 2023-12-13
/// 给指定餐次添加条目时，可以选择某个食物再输入一个摄入量，也可以直接添加最近有吃过的记录。
/// 原本点击+直接是简单的食物列表，现在是先到这个tabview，默认是最近摄入，滚动切换到简单食物列表
/// 传入的参数依旧是 餐次+日期
///
class AddIntakeItem extends StatefulWidget {
  final CusMeals mealtime;
  final String logDate;

  const AddIntakeItem({
    Key? key,
    required this.mealtime,
    required this.logDate,
  }) : super(key: key);

  @override
  State<AddIntakeItem> createState() => _AddIntakeItemState();
}

class _AddIntakeItemState extends State<AddIntakeItem>
    with SingleTickerProviderStateMixin {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  // 当前食物食用量管理的餐次 (传入的值，可以在这个列表页面进行修改，后续到详情页面进行添加时就是添加到对应的餐次)
  late CusMeals currentMealtime;
  // 被选中的餐次（和传入的类型不一样）
  CusLabel dropdownValue = mealtimeList.first;

  // 这次食物摄入的查询或者预计新增的meal item，属于哪一天的(也是用来查daily log的条件，应该不会变)
  late String currentDate;

// 定义TabController
  late TabController _tabController;

  /// ------------- 查询简单食物列表时一次性只查询10条，上滑加载更多
  List<FoodAndServingInfo> foodItems = [];
  int currentPage = 1; // 数据库查询的时候会从0开始offset
  int pageSize = 10;
  bool isFoodLoading = false;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  String query = '';

  // 是否显示新增食物的按钮，因为默认是在最近摄入记录tab，所以默认不显示
  bool isShowAddButton = false;

  ///-------------- 最近摄入列表构建相关

  // 最近的摄入加载中
  bool isRecentLoading = false;
  // 根据条件查询的最近的条目数据
  List<DailyFoodItemWithFoodServing> dfiwfsList = [];
  // 记录每个列表项是否被选中
  List<bool> checkedItems = [false];
  // 记录被选中的索引
  List<int> selectedIndexes = [];

  @override
  void initState() {
    super.initState();

    currentMealtime = widget.mealtime;
    currentDate = widget.logDate;
    // 顶部显示的餐次，默认是取列表的第一个，这个改为父组件传入的值
    // ？？？可以父组件改为传入的就是list里面的对象而不是字符串，这样这里少个参数也不用转换
    dropdownValue = mealtimeList.firstWhere((e) => e.value == currentMealtime);

    // 监听上滑滚动
    scrollController.addListener(_scrollListener);

    // 初始化TabController
    _tabController = TabController(vsync: this, length: 2, initialIndex: 0);
    // 监听Tab切换
    _tabController.addListener(_handleTabSelection);

    // 加载初始化数据，也可以根据当前tab的索引分别初始化
    _loadFoodListData();
    _queryRecentDailyFoodItemList(mealEnLabel: dropdownValue.enLabel);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 滚动到底部加载更多数据
  _scrollListener() {
    if (isFoodLoading) return;

    final maxScrollExtent = scrollController.position.maxScrollExtent;
    final currentPosition = scrollController.position.pixels;
    final delta = 50.0.sp;

    if (maxScrollExtent - currentPosition <= delta) {
      _loadFoodListData();
    }
  }

  /// 处理点击了搜索按钮
  _handleSearch() {
    // 取消键盘输入框聚焦
    FocusScope.of(context).unfocus();
    setState(() {
      foodItems.clear();
      currentPage = 1;
      query = searchController.text;
    });
    _loadFoodListData();
  }

  /// 加载食物数据，每次10条
  _loadFoodListData() async {
    if (isFoodLoading) return;

    setState(() {
      isFoodLoading = true;
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
      isFoodLoading = false;
    });
  }

  /// ------------------ 最近记录相关
  ///
  /// 处理Tab切换
  ///
  _handleTabSelection() {
    // 暂时当tab切换到食物列表时，选中的最近摄入条目清空
    // 因为tab的切换最近摄入的饮食条目的数据不会变化，所以不用重新查询
    if (_tabController.index == 1) {
      setState(() {
        selectedIndexes.clear();
        isShowAddButton = true;
      });
    } else {
      setState(() {
        isShowAddButton = false;
      });
    }
  }

  /// 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryRecentDailyFoodItemList({String? mealEnLabel}) async {
    if (isRecentLoading) return;

    setState(() {
      isRecentLoading = true;
    });

    // 最近摄入的食物列表，默认查询最近一个月的
    var [startDate, endDate] = getStartEndDateString(30);

    List<DailyFoodItemWithFoodServing> temp =
        (await _dietaryHelper.queryDailyFoodItemListWithDetail(
      userId: CacheUser.userId,
      startDate: startDate,
      endDate: endDate,
      mealCategory: mealEnLabel,
      withDetail: true,
    ) as List<DailyFoodItemWithFoodServing>);

    // 要过滤重复的，即产品、摄入单份营养素、摄入量是一样的
    Map<String, DailyFoodItemWithFoodServing> uniqueObjects = {};
    for (DailyFoodItemWithFoodServing obj in temp) {
      // 用 食物编号、单份营养素编号、摄入量作为唯一键
      String key =
          '${obj.food.foodId}_${obj.servingInfo.servingInfoId}_${obj.dailyFoodItem.foodIntakeSize}';

      if (!uniqueObjects.containsKey(key)) {
        uniqueObjects[key] = obj; // 只保留第一个出现的对象
      }
    }
    List<DailyFoodItemWithFoodServing> result = uniqueObjects.values.toList();

    setState(() {
      dfiwfsList = result;
      // 要根据实际list的数量设置录每个列表项是否被选中
      checkedItems = List<bool>.generate(dfiwfsList.length, (index) => false);

      isRecentLoading = false;
    });
  }

  /// 将选择的最近摄入数据保存到数据库
  _saveSelectedRecentListToDb() async {
    if (isRecentLoading) return;

    setState(() {
      isRecentLoading = true;
    });

    // 能点击添加一定是有选中数据，保存时只需要把这些最近的摄入再次添加即可

    List<DailyFoodItem> tempList = [];

    for (var index in selectedIndexes) {
      // 这里复用旧的或者创建新的都可以
      DailyFoodItem temp = dfiwfsList[index].dailyFoodItem;
      // 主id是自增的,旧的要清空
      temp.dailyFoodItemId = null;
      // 最主要的摄入量、食物编号、单份营养素编号不用改
      temp.userId = CacheUser.userId;
      temp.date = getCurrentDate();
      temp.mealCategory = dropdownValue.enLabel;
      temp.gmtCreate = getCurrentDateTime();

      tempList.add(temp);
    }

    try {
      var rst = await _dietaryHelper.insertDailyFoodItemList(tempList);

      if (rst.isNotEmpty) {
        if (!mounted) return;

        Navigator.of(context).pop(dropdownValue.enLabel);
      }
      setState(() {
        isRecentLoading = false;
      });
    } catch (e) {
      // 将错误信息展示给用户
      if (!mounted) return;
      commonExceptionDialog(context, "异常提醒", e.toString());

      setState(() {
        isRecentLoading = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 选项卡的数量
      child: Scaffold(
        appBar: AppBar(
          title: buildAppBarTitle(),
          actions: buildAppBarActions(),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "最近记录"),
              Tab(text: "食物列表"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            isRecentLoading
                ? buildLoader(isRecentLoading)
                : buildRecentFoodListTabView(),
            buildSimpleFoodListTabView(),
          ],
        ),
      ),
    );
  }

  ///
  /// appbar 标题
  ///
  buildAppBarTitle() {
    return ListTile(
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

              // 切换餐次后，要重新查询对应餐次的最近摄入数据
              _queryRecentDailyFoodItemList(mealEnLabel: dropdownValue.enLabel);
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
    );
  }

  ///
  /// appbar 动作按钮
  ///
  buildAppBarActions() {
    return [
      /// 当tab是最近饮食记录且有选中摄入条目，才显示添加按钮
      if (_tabController.index == 0 && selectedIndexes.isNotEmpty)
        TextButton(
          onPressed: _saveSelectedRecentListToDb,
          child: const Text(
            '添加',
            style: TextStyle(color: Colors.white),
          ),
        ),

      /// 当tab是食物列表时，才显示增加食物的按钮
      if (isShowAddButton)
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
                  // 不管是否新增成功，这里都重新加载；
                  // 因为没有清空查询条件，所以新增的食物关键字不包含查询条件中，不会显示
                  if (value != null) {
                    setState(() {
                      foodItems.clear();
                      currentPage = 1;
                    });
                    _loadFoodListData();
                  }
                });
              },
            )
          ],
        ),
    ];
  }

  ///
  /// 构建最近30天对应餐次摄入的条目数据
  ///
  buildRecentFoodListTabView() {
    return ListView.builder(
      itemCount: dfiwfsList.length,
      itemBuilder: (BuildContext context, int index) {
        DailyFoodItemWithFoodServing e = dfiwfsList[index];
        var foodIntakeSize = e.dailyFoodItem.foodIntakeSize;

        // 当条摄入记录的数量和单份单位
        var tempIntake = cusDoubleTryToIntString(foodIntakeSize);
        // 当日已经摄入的卡路里数量
        var tempCalories = cusDoubleTryToIntString(
            foodIntakeSize * e.servingInfo.energy / oneCalToKjRatio);

        return SizedBox(
          height: 60.sp,
          child: CheckboxListTile(
            title: Text('${e.food.product} (${e.food.brand})'),
            subtitle: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$tempIntake * ${e.servingInfo.servingUnit}",
                    style: TextStyle(fontSize: 15.sp, color: Colors.black),
                  ),
                  TextSpan(
                    text: " - $tempCalories 大卡",
                    style: TextStyle(fontSize: 15.sp, color: Colors.green),
                  ),
                ],
              ),
            ),
            value: checkedItems[index],
            onChanged: (bool? value) {
              if (value != null) {
                setState(() {
                  checkedItems[index] = value;
                  if (value) {
                    // 如果当前项被选中，则添加到选择的索引列表中
                    selectedIndexes.add(index);
                  } else {
                    // 如果当前项被取消选中，则从选择的索引列表中删除
                    selectedIndexes.remove(index);
                  }
                });
              }
            },
          ),
        );
      },
    );
  }

  ///
  /// 构建简单食物列表条目数据
  ///
  buildSimpleFoodListTabView() {
    return Padding(
      padding: EdgeInsets.all(8.sp),
      child: Column(
        children: [
          /// 搜索区域
          _buildSearchRowArea(),
          SizedBox(height: 5.sp),

          /// 食物列表区域
          Expanded(
            child: ListView.builder(
              itemCount: foodItems.length + 1,
              itemBuilder: (context, index) {
                if (index == foodItems.length) {
                  return buildLoader(isFoodLoading);
                } else {
                  return _buildFoodItemCard(foodItems[index]);
                }
              },
              controller: scrollController,
            ),
          ),
        ],
      ),
    );
  }

  /// 查询条件输入行
  _buildSearchRowArea() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.sp),
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
    );
  }

  /// 食物列表区域
  _buildFoodItemCard(FoodAndServingInfo item) {
    var food = item.food;
    var foodName = "${food.product} (${food.brand})";

    var fistServingInfo = item.servingInfoList[0];
    var foodUnit = fistServingInfo.servingUnit;
    var foodEnergy = (fistServingInfo.energy / constants.oneCalToKjRatio);

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
        subtitle: Text("$foodUnit - ${cusDoubleToString(foodEnergy)} 大卡"),
        // 点击这个添加就是默认添加单份营养素的食物，那就直接返回日志页面。
        trailing: IconButton(
          onPressed: () async {
            var tempStr =
                mealtimeList.firstWhere((e) => e.value == currentMealtime);

            // ？？？这里应该有插入是否成功的判断
            var rst = await _dietaryHelper.insertDailyFoodItemList(
              [
                DailyFoodItem(
                  date: currentDate,
                  mealCategory: tempStr.enLabel,
                  foodId: food.foodId!,
                  servingInfoId: fistServingInfo.servingInfoId!,
                  foodIntakeSize: fistServingInfo.servingSize.toDouble(),
                  userId: CacheUser.userId,
                  gmtCreate: getCurrentDateTime(),
                )
              ],
            );

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
                foodItem: item,
                mealtime: currentMealtime,
                logDate: currentDate,
              ),
            ),
          );
        },
      ),
    );
  }
}
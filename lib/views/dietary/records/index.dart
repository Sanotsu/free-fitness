// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/common/global/constants.dart';
import 'package:free_fitness/models/dietary_state.dart';
import 'package:intl/intl.dart';

import '../../../common/utils/sqlite_db_helper.dart';
import 'foods/food_detail.dart';
import 'foods/food_list.dart';

class DietaryRecords extends StatefulWidget {
  const DietaryRecords({super.key});

  @override
  State<DietaryRecords> createState() => _DietaryRecordsState();
}

class _DietaryRecordsState extends State<DietaryRecords> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  /// 根据条件查询的日记条目数据
  List<DailyFoodItemWithFoodServing> dfiwfsList = [];

// 数据是否加载中
  bool isLoading = false;

  /// 用户可能切换日期，但显示的内容是一样的
  /// (这个是日期组件的值，默认是当天。日期范围，可能只在导出时才用到，一般都是单日)

  // 日期选择器中选择的日期，用于构建初始值，有选择后保留选择的
  DateTime selectedDate = DateTime.now();
  // 用户选择日期格式化后的字符串，传入子组件或者查询日志条目的参数
  String selectedDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  // 在标题处显示当前展示的日期信息（日期选择器之后有一点自定义处理）
  String showedDateStr = "今天";

  // 每日饮食记录数据显示模式(目前就摘要(summary默认)和详情detailed两种即可)
  String dataDisplayMode = dietaryLogDisplayModeList[1].value;

  // RDA 的值应该在用户配置表里面带出来，在init的时候赋值。现在没有实现所以列个示例在这里
  int valueRDA = 0;

// 用于存储预设4个餐次的ExpansionTile的展开状态
  Map<String, bool> isExpandedList = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
    'other': false,
  };

  @override
  void initState() {
    super.initState();

    setState(() {
      valueRDA = 1800;
    });

    _queryDailyFoodItemList();
  }

  // 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryDailyFoodItemList({String? userSelectedDate}) async {
    print("开始运行查询当日饮食日记条目---------");

    // _dietaryHelper.deleteDb();

    // await demoInsertDailyLogData();
    // return;

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 理论上是默认查询当日的，有选择其他日期则查询指定日期
    var temp = await _dietaryHelper.queryDailyFoodItemListWithDetail(
      startDate: selectedDateStr,
      endDate: selectedDateStr,
    );

    // log("---------测试查询的当前日记item $temp");

    setState(() {
      dfiwfsList = temp;
      isLoading = false;
    });
  }

  // 滑动删除指定饮食日记条目
  _removeDailyFoodItem(dailyFoodItemId) async {
    await _dietaryHelper.deleteDailyFoodItem(dailyFoodItemId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 饮食记录首页的日期选择器是单日的，可以不用第三方库，简单showDatePicker就好
        // 导出之类的可以花式选择日期的再用
        title: GestureDetector(
          child: Text(showedDateStr),
          onTap: () {
            _selectDate(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodList(
                    mealtime: Mealtimes.breakfast,
                    // 注意，这里应该是一个日期选择器插件选中的值，格式化为固定字符串，子组件就不再处理
                    logDate: selectedDateStr,
                  ),
                ),
              ).then((value) {
                // 确认新增成功后重新加载当前日期的条目数据
                final arguments =
                    ModalRoute.of(context)!.settings.arguments as Map;
                final bool result = arguments['isItemAdded'];
                if (result) {
                  _queryDailyFoodItemList(userSelectedDate: selectedDateStr);
                }

                (ModalRoute.of(context)!.settings.arguments as Map).clear();
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildLoader()
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildDailyOverviewCard(),
                  const SizedBox(height: 10),
                  ListView.builder(
                    // 解决 NEEDS-PAINT ……的问题
                    shrinkWrap: true,
                    // 只有外部的 SingleChildScrollView 滚动，这个内部的listview不滚动
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mealtimeList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final mealtime = mealtimeList[index];
                      return Column(
                        children: [
                          _buildMealCard(mealtime),
                          SizedBox(height: 20.sp)
                        ],
                      );
                    },
                  ),
                  const Card(
                    child: ListTile(
                      title: Text('Last Card'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderTableCell(
    String label, {
    double fontSize = 16,
    textAlign = TextAlign.right,
  }) {
    return TableCell(
      child: Text(
        label,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize),
        // 中英文的leading好像不一样，统一一下避免显示不在一条水平线
        strutStyle: StrutStyle(
          forceStrutHeight: true,
          leading: 1.sp,
        ),
      ),
    );
  }

  /// 最上面的每日概述卡片
  Widget _buildDailyOverviewCard() {
    // 两种形态：只显示卡路里的基本，显示主要营养素的详细

    var tempEnergy = 0.0;
    var tempProtein = 0.0;
    var tempFat = 0.0;
    var tempCHO = 0.0;

    for (var e in dfiwfsList) {
      var foodIntakeSize = e.dailyFoodItem.foodIntakeSize;
      var servingInfo = e.servingInfo;
      tempEnergy += foodIntakeSize * servingInfo.energy;
      tempProtein += foodIntakeSize * servingInfo.protein;
      tempFat += foodIntakeSize * servingInfo.totalFat;
      tempCHO += foodIntakeSize * servingInfo.totalCarbohydrate;
    }

    var tempCalories = tempEnergy / oneCalToKjRatio;

    print("当日的累加值……");
    print("tempEnergy $tempEnergy");
    print("tempProtein $tempProtein");
    print("tempFat $tempFat");
    print("tempCHO $tempCHO");
    print("tempCalories $tempCalories");

/*
    //  这个虽然和下面的table显示宽度一致了，但是数据无法完整显示，暂时不这么用
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Table(
              children: [
                TableRow(
                  children: [
                    _buildHeaderTableCell("碳水物"),
                    _buildHeaderTableCell("蛋白质"),
                    _buildHeaderTableCell("脂肪"),
                    _buildHeaderTableCell("RDA"),
                  ],
                ),
                _buildMainMutrientsValueTableRow(
                  tempCHO,
                  tempProtein,
                  tempFat,
                  tempCalories,
                  fontSize: 16.sp,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            // dense: true,
            trailing: SizedBox(
              width: 0.15.sw,
              child: GestureDetector(
                onTap: () {
                  // 处理点击事件
                },
                child: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: (valueRDA - tempCalories).toStringAsFixed(0),
                        style: TextStyle(color: Colors.red, fontSize: 18.sp),
                      ),
                      TextSpan(
                        text: '\n${tempCalories.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.blue, fontSize: 18.sp),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right, // 设置文字靠右排列
                ),
              ),
            ),
          )
        ],
      ),
    );
*/

    return Card(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(left: 10.sp),
              child: dataDisplayMode == "summary"
                  ? Row(
                      children: [
                        const Expanded(
                          flex: 4,
                          child: Text("百分比占位"),
                        ),
                        Expanded(
                          flex: 6,
                          child: ListTile(
                            title: _buildListTileText("剩余的卡路里"),
                            subtitle: _buildListTileText("消耗的卡路里"),
                          ),
                        ),
                      ],
                    )
                  : Table(
                      children: [
                        TableRow(
                          children: [
                            _buildHeaderTableCell("碳水物"),
                            _buildHeaderTableCell("蛋白质"),
                            _buildHeaderTableCell("脂肪"),
                            _buildHeaderTableCell("RDA"),
                          ],
                        ),
                        _buildMainMutrientsValueTableRow(
                          tempCHO,
                          tempProtein,
                          tempFat,
                          tempCalories,
                          fontSize: 15.sp,
                        ),
                      ],
                    ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListTile(
              title: dataDisplayMode == "summary"
                  ? _buildListTileText(
                      (valueRDA - tempCalories).toStringAsFixed(0),
                      textAlign: TextAlign.right,
                    )
                  : _buildListTileText(
                      "$valueRDA",
                      textAlign: TextAlign.right,
                    ),
              subtitle: _buildListTileText(
                tempCalories.toStringAsFixed(0),
                textAlign: TextAlign.right,
              ),
              onTap: () {
                setState(() {
                  dataDisplayMode =
                      dataDisplayMode == "summary" ? "detailed" : "summary";
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // 早中晚夜各个餐次的卡片
  Card _buildMealCard(CusDropdownOption mealtime) {
    // 从查询的日记条目中过滤当前餐次的数据
    // DailyFoodItemWithFoodServingMealItems 太长了，缩写 dfiwfsMealItems
    var dfiwfsMealItems = dfiwfsList
        .where(
          (e) => e.dailyFoodItem.mealCategory == mealtime.label,
        )
        .toList();

    // 该餐次的主要营养素累加值
    var tempEnergy = 0.0;
    var tempProtein = 0.0;
    var tempFat = 0.0;
    var tempCHO = 0.0;

    for (var e in dfiwfsMealItems) {
      var foodIntakeSize = e.dailyFoodItem.foodIntakeSize;
      var servingInfo = e.servingInfo;
      tempEnergy += foodIntakeSize * servingInfo.energy;
      tempProtein += foodIntakeSize * servingInfo.protein;
      tempFat += foodIntakeSize * servingInfo.totalFat;
      tempCHO += foodIntakeSize * servingInfo.totalCarbohydrate;
    }

    var tempCalories = tempEnergy / oneCalToKjRatio;

    // 当前餐次有条目，展开行可用
    bool showExpansionTile = dfiwfsMealItems.isNotEmpty;

    return Card(
      elevation: 20, // 设置阴影的程度
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // 设置圆角的大小
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ListTile(
                  leading: const Icon(Icons.food_bank_sharp),
                  title: _buildListTileText("${mealtime.name}"),
                  subtitle: _buildListTileText('${dfiwfsMealItems.length} 项'),
                  dense: true,
                ),
              ),
              Expanded(
                flex: 2,
                child: ListTile(
                  title: _buildListTileText(
                    "总卡路里",
                    textAlign: TextAlign.right,
                  ),
                  subtitle: _buildListTileText(
                    tempCalories.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: () {
                    print("日记主页面点击了餐次的add -------- ${mealtime.value}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // 主页面点击餐次的添加是新增，没有旧数据，需要餐次和日期信息
                        builder: (context) => FoodList(
                          mealtime: mealtime.value,
                          // 注意，这里应该是一个日期选择器插件选中的值，格式化为固定字符串，子组件就不再处理
                          logDate: selectedDateStr,
                        ),
                      ),
                    ).then((value) {
                      // 确认新增成功后重新加载当前日期的条目数据
                      final arguments =
                          ModalRoute.of(context)!.settings.arguments as Map;
                      final bool result = arguments['isItemAdded'];

                      if (result) {
                        _queryDailyFoodItemList(
                          userSelectedDate: selectedDateStr,
                        );
                      }
                      // 使用参数后应清除Map
                      (ModalRoute.of(context)!.settings.arguments as Map)
                          .clear();
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.blue),
                ),
              ),
            ],
          ),
          // 折叠tile展开灰色，展开后白色
          if (showExpansionTile)
            Container(
              decoration: const BoxDecoration(
                // borderRadius: BorderRadius.circular(10.0), // 设置所有圆角的大小
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0.0), // 保持上左角为直角
                  topRight: Radius.circular(0.0), // 保持上右角为直角
                  bottomLeft: Radius.circular(10.0), // 设置下左角为圆角
                  bottomRight: Radius.circular(10.0), // 设置下右角为圆角
                ),
                // 设置展开前的背景色
                color: Color.fromARGB(255, 195, 198, 201),
              ),
              child: ExpansionTile(
                // 如果是概要，展开的标题只显示餐次的食物数量；是详情，则展示该餐次各项食物的主要营养素之和
                title: dataDisplayMode == "summary"
                    ? Text('${dfiwfsMealItems.length} 项')
                    : Table(
                        children: [
                          _buildMainMutrientsValueTableRow(
                            tempCHO,
                            tempProtein,
                            tempFat,
                            tempCalories,
                          ),
                        ],
                      ),
                backgroundColor: const Color.fromARGB(255, 235, 227, 227),
                trailing: SizedBox(
                  width: 0.15.sw, // 将屏幕宽度的四分之一作为trailing的宽度
                  child: Icon(
                    isExpandedList[mealtime.label]!
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                  ),
                ),
                onExpansionChanged: (isExpanded) {
                  setState(() {
                    isExpandedList[mealtime.label] = isExpanded; // 更新展开状态列表
                  });
                },
                // 展开显示食物详情
                children: _buildListTile(mealtime, dfiwfsMealItems),
              ),
            ),
        ],
      ),
    );
  }

  // 餐次展开的文本样式基本都一样的
  _buildListTileText(
    String text, {
    double fontSize = 16,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize),
      textAlign: textAlign,
    );
  }

  // 各餐次卡片点击展开的食物条目
  List<Widget> _buildListTile(
    CusDropdownOption curMeal,
    List<DailyFoodItemWithFoodServing> list,
  ) {
    List<Widget> temp = [
      const Divider(),
    ];

    if (list.isEmpty) return temp;

    return list.map((logItem) {
      // 该餐次的主要营养素累加值
      var foodIntakeSize = logItem.dailyFoodItem.foodIntakeSize;
      var servingInfo = logItem.servingInfo;

      var tempEnergy = foodIntakeSize * servingInfo.energy;
      var tempProtein = foodIntakeSize * servingInfo.protein;
      var tempFat = foodIntakeSize * servingInfo.totalFat;
      var tempCHO = foodIntakeSize * servingInfo.totalCarbohydrate;
      var tempCalories = tempEnergy / oneCalToKjRatio;

      var tempUnit = servingInfo.servingUnit;

      return GestureDetector(
        onTap: () async {
          print("cutMeal-----${curMeal.label}");

          print(
            "daily log index 的 指定餐次 点击了meal food item ，跳转到food detail ---> ",
          );

          // 先获取到当前item的食物信息，再传递到food detail
          var data = await _dietaryHelper.searchFoodWithServingInfoByFoodId(
            logItem.dailyFoodItem.foodId,
          );

          if (data == null) {
            // 抛出异常之后已经return了
            throw Exception("有meal food id找不到 food？");
          }

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              // 主页面点击item详情是修改或删除，只需要传入食物信息和item详情就好
              builder: (context) => FoodDetail(foodItem: data, dfiwfs: logItem),
            ),
          ).then((value) {
            // 确认修改或删除成功后重新加载当前日期的条目数据
            final bool result = value['isItemModified'];
            if (result) {
              _queryDailyFoodItemList(userSelectedDate: selectedDateStr);
            }
          });
        },
        // 滑动可删除，
        child: Dismissible(
          key: Key(logItem.hashCode.toString()),
          onDismissed: (direction) async {
            print("logItem-------------------$logItem");
            // 确认滑动移除之后，要重新查询当日数据构建卡片（全部重绘感觉有点浪费）
            await _removeDailyFoodItem(logItem.dailyFoodItem.dailyFoodItemId);
            _queryDailyFoodItemList();
          },
          // 滑动时条目的背景色
          background: Container(
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 餐次的每个 listTile 间隔一点空隙
              SizedBox(
                height: 5.sp,
                child: Container(
                  color: const Color.fromARGB(255, 216, 202, 201),
                ),
              ),
              // 具体的食物和数量
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: ListTile(
                      // ？？？这个0.05宽度好像没效果
                      leading: SizedBox(width: 0.05.sw),
                      title: _buildListTileText(
                        "${logItem.food.brand}-${logItem.food.product}",
                      ),
                      subtitle: _buildListTileText(
                        '${logItem.dailyFoodItem.foodIntakeSize} * $tempUnit',
                      ),
                      dense: true,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ListTile(
                      title: _buildListTileText(
                        '卡路里',
                        textAlign: TextAlign.right,
                      ),
                      subtitle: _buildListTileText(
                        tempCalories.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                      ),
                      dense: true,
                    ),
                  ),
                  const Expanded(
                    flex: 1,
                    child: Icon(Icons.keyboard_arrow_right),
                  ),
                ],
              ),
              // 如果是详情展示，还需要显示每个食物的主要营养素含量
              dataDisplayMode == "summary"
                  ? Container()
                  : ListTile(
                      title: Table(
                        children: [
                          _buildMainMutrientsValueTableRow(
                            tempCHO,
                            tempProtein,
                            tempFat,
                            tempCalories,
                          ),
                        ],
                      ),
                      // 这个只是为了让表格行数据和上面 expansionTile 排版一致，所以设置透明图标
                      trailing: SizedBox(
                        width: 0.15.sw,
                        child: const Icon(
                          Icons.circle,
                          color: Colors.transparent,
                        ),
                      ),
                      dense: true,
                    ),
            ],
          ),
        ),
      );
    }).toList();
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

  // 详情展示时表格显示依次碳水物、蛋白质、脂肪、RDA比例的数据，以及文本大小
  TableRow _buildMainMutrientsValueTableRow(
    double choValue,
    double proteinValue,
    double fatValue,
    double caloriesValue, {
    double fontSize = 14,
    TextAlign textAlign = TextAlign.end,
  }) {
    return TableRow(
      children: [
        TableCell(
          child: Text(
            choValue.toStringAsFixed(2),
            style: TextStyle(fontSize: fontSize),
            textAlign: textAlign,
          ),
        ),
        TableCell(
          child: Text(
            proteinValue.toStringAsFixed(2),
            style: TextStyle(fontSize: fontSize),
            textAlign: textAlign,
          ),
        ),
        TableCell(
          child: Text(
            fatValue.toStringAsFixed(2),
            style: TextStyle(fontSize: fontSize),
            textAlign: textAlign,
          ),
        ),
        TableCell(
          child: Text(
            "${(caloriesValue / valueRDA * 100).toStringAsFixed(2)}%",
            style: TextStyle(fontSize: fontSize),
            textAlign: textAlign,
          ),
        ),
      ],
    );
  }

  // 导航栏处点击显示日期选择器
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1994, 7),
        lastDate: DateTime(2077));

    if (!mounted) return;
    if (picked != null) {
      // 包含了月日星期，其他格式修改 MMMEd 为其他即可
      var formatDate = DateFormat('MMMEd', "zh_CN").format(picked);

      print("选择的日期、星期信息----$picked $formatDate");

      print(picked.day == DateTime.now().day);

      // 昨天今天明天三天的显示可以特殊一点，比较的话就比较对应年月日转换的字符串即可
      var today = DateTime.now();
      var todayStr = "${today.year}${today.month}${today.day}";
      var yesterdayStr = "${today.year}${today.month}${today.day - 1}";
      var tomorrowStr = "${today.year}${today.month}${today.day + 1}";
      var pickedDateStr = "${picked.year}${picked.month}${picked.day}";

      if (pickedDateStr == yesterdayStr) {
        formatDate = "昨天";
      } else if (pickedDateStr == todayStr) {
        formatDate = "今天";
      } else if (pickedDateStr == tomorrowStr) {
        formatDate = "明天";
      }

      print("格式化之后----$pickedDateStr $todayStr $yesterdayStr $tomorrowStr");

      setState(() {
        selectedDate = picked;
        selectedDateStr = DateFormat('yyyy-MM-dd').format(picked);
        showedDateStr = formatDate;
        _queryDailyFoodItemList(userSelectedDate: selectedDateStr);
      });
    }
  }
}

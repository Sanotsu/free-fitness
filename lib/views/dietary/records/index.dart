// ignore_for_file: avoid_print

import 'dart:developer';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/common/global/constants.dart';
import 'package:free_fitness/models/dietary_state.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import 'report_calendar_summary.dart';
import 'save_meal_photo.dart';
import 'simple_food_detail.dart';
import 'simple_food_list.dart';

class DietaryRecords extends StatefulWidget {
  const DietaryRecords({super.key});

  @override
  State<DietaryRecords> createState() => _DietaryRecordsState();
}

class _DietaryRecordsState extends State<DietaryRecords> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
  final DBUserHelper _userHelper = DBUserHelper();

  // 获取缓存中的用户编号(理论上进入app主页之后，就一定有一个默认的用户编号了)
  final box = GetStorage();
  int get currentUserId => box.read(LocalStorageKey.userId) ?? 1;

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

  // 当日总数据还需要记录，除了顶部的概述处，其他地方也可能用到(餐次内的和指定食物的暂不需要)
  List<CusNutrientInfo> mainNutrientsChartData = [];

// 用于存储预设4个餐次的ExpansionTile的展开状态
  Map<String, bool> isExpandedList = {
    mealNameMap[CusMeals.breakfast]!.enLabel: false,
    mealNameMap[CusMeals.lunch]!.enLabel: false,
    mealNameMap[CusMeals.dinner]!.enLabel: false,
    mealNameMap[CusMeals.other]!.enLabel: false,
  };

  // 一日四餐对应拥有的餐次照片路径
  // key是餐次英文，value是MealPhoto实例
  Map<String, MealPhoto?> mealPhotoNums = {
    mealNameMap[CusMeals.breakfast]!.enLabel: null,
    mealNameMap[CusMeals.lunch]!.enLabel: null,
    mealNameMap[CusMeals.dinner]!.enLabel: null,
    mealNameMap[CusMeals.other]!.enLabel: null,
  };

  @override
  void initState() {
    super.initState();

    _queryDailyFoodItemList();

    print("currentUserId-----$currentUserId");
  }

  // 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryDailyFoodItemList({String? mealEnLabel}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 查询用户目标值
    // TODO 这里还应该根据今天是星期几显示对应的RDA值
    var tempUser = await _userHelper.queryUser(userId: currentUserId);

    print("开始运行查询当日饮食日记条目---------");
    if (tempUser != null) {
      setState(() {
        valueRDA = tempUser.rdaGoal != null
            ? tempUser.rdaGoal!
            : tempUser.gender == "男"
                ? 2250
                : 1766;
      });
    }

    // 理论上是默认查询当日的，有选择其他日期则查询指定日期
    List<DailyFoodItemWithFoodServing> temp =
        (await _dietaryHelper.queryDailyFoodItemListWithDetail(
      userId: currentUserId,
      startDate: selectedDateStr,
      endDate: selectedDateStr,
      withDetail: true,
    ) as List<DailyFoodItemWithFoodServing>);

    print("---------测试查询的当前日记item ${temp.length}");

    // 查询餐次照片数量
    _queryMealPhotoNums();

    setState(() {
      dfiwfsList = temp;

      print('mealEnLabelmealEnLabelmealEnLabel--$mealEnLabel');
      // ？？？没有效果，这个得重新设计
      if (mealEnLabel != null) {
        isExpandedList[mealEnLabel] = true;

        print('isExpandedList[meal.enLabel]-${isExpandedList[mealEnLabel]}');
      }

      isLoading = false;
    });
  }

  // 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryMealPhotoNums({String? mealEnLabel}) async {
    // 理论上是默认查询当日的，有选择其他日期则查询指定日期

    List<MealPhoto> temp = await _dietaryHelper.queryMealPhotoList(
      1, // ？？？userId是必传的
      startDate: selectedDateStr,
      endDate: selectedDateStr,
      mealCategory: mealEnLabel,
    );

    log("---------_queryMealPhotoNums测试查询的当前日记item $temp");

    setState(() {
      // 正常来讲，每天每个餐次最多只有一条数据，只要有数据，照片就是修改或删除了
      var bfMp = temp.where(
          (e) => e.mealCategory == mealNameMap[CusMeals.breakfast]!.enLabel);
      if (bfMp.isNotEmpty) {
        mealPhotoNums[mealNameMap[CusMeals.breakfast]!.enLabel] = bfMp.first;
      }

      var lunchMp = temp
          .where((e) => e.mealCategory == mealNameMap[CusMeals.lunch]!.enLabel);
      if (lunchMp.isNotEmpty) {
        mealPhotoNums[mealNameMap[CusMeals.lunch]!.enLabel] = lunchMp.first;
      }

      var dinnerMp = temp.where(
          (e) => e.mealCategory == mealNameMap[CusMeals.dinner]!.enLabel);
      if (dinnerMp.isNotEmpty) {
        mealPhotoNums[mealNameMap[CusMeals.dinner]!.enLabel] = dinnerMp.first;
      }

      var otherMp = temp
          .where((e) => e.mealCategory == mealNameMap[CusMeals.other]!.enLabel);
      if (otherMp.isNotEmpty) {
        mealPhotoNums[mealNameMap[CusMeals.other]!.enLabel] = otherMp.first;
      }
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
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportCalendarSummary(),
                ),
              ).then((value) {
                // 2023-12-04 之前是在食物详情中有设置一个新增成功的返回参数，确认新增成功后重新加载当前日期的条目数据。
                // 现在就只要是返回这个页面，都重新加载，也避免了跨级子组件数据返回的设计

                print("TableCalendarComplex---$value");
                // // ？？？为什么不回触发？？？
                // if (value != null) {
                //   print(2222222222222222);

                //   _queryDailyFoodItemList(mealEnLabel: value as String);
                // }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SimpleFoodList(
                    mealtime: CusMeals.breakfast,
                    // 注意，这里应该是一个日期选择器插件选中的值，格式化为固定字符串，子组件就不再处理
                    logDate: selectedDateStr,
                  ),
                ),
              ).then((value) {
                // 2023-12-04 之前是在食物详情中有设置一个新增成功的返回参数，确认新增成功后重新加载当前日期的条目数据。
                // 现在就只要是返回这个页面，都重新加载，也避免了跨级子组件数据返回的设计

                print("1111111111111111111---$value");
                // ？？？为什么不回触发？？？
                if (value != null) {
                  print(2222222222222222);

                  _queryDailyFoodItemList(mealEnLabel: value as String);
                }
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text("几个功能按钮(底部)"),
                      ElevatedButton(
                        onPressed: () {
                          // 跳过去就是新的模块，返回时就不用再返回这里而是直接回到主页面
                          Navigator.pushReplacementNamed(
                            context,
                            "/dietaryReports",
                          );
                        },
                        child: const Text("今天"),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text("相册"),
                      ),
                    ],
                  ),
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
                          SizedBox(height: 10.sp)
                        ],
                      );
                    },
                  ),

                  /// 当日主要营养素占比
                  Card(
                    elevation: 10,
                    child: SizedBox(
                      height: 450.sp,
                      child: Column(
                        children: [
                          Text(
                            '当日三大营养素占比',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18.sp,
                            ),
                          ),
                          Divider(height: 5.sp, thickness: 2.sp),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 左边图例
                                Expanded(
                                  flex: 2,
                                  child: _buildMainNutrientsPieLegend(),
                                ),
                                // 右边饼图
                                Expanded(
                                  flex: 1,
                                  child: _buildMainNutrientsPieChart(),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '主要营养素摄入量',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18.sp,
                            ),
                          ),
                          Divider(height: 5.sp, thickness: 2.sp),

                          // 更多的信息列表
                          _buildMainNutrientsList(),
                        ],
                      ),
                    ),
                  ),

                  const Card(
                    child: ListTile(
                      title: Text('其他选项功能区(暂留)'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // 当日主要营养素图例
  _buildMainNutrientsList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mainNutrientsChartData.map((data) {
        String tempStr = "${data.value.toStringAsFixed(2)} ${data.unit}";

        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.sp),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: data.color),
              SizedBox(width: 8.sp),
              // 将百分比数据添加到标题后面
              Expanded(
                child: Text(
                  '${data.name}: $tempStr',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 当日主要营养素图例
  _buildMainNutrientsPieLegend() {
    // 绘图只是三大营养素
    var tempList = mainNutrientsChartData
        .where(
            (e) => e.label == "cho" || e.label == "protein" || e.label == "fat")
        .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tempList.map((data) {
        double total =
            tempList.fold(0, (previous, current) => previous + current.value);
        String percentage = ((data.value / total) * 100).toStringAsFixed(1);

        String tempStr = "${data.value.toStringAsFixed(2)} 克";

        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.sp),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: data.color),
              SizedBox(width: 8.sp),
              // 将百分比数据添加到标题后面
              Expanded(
                  child: Text(
                '${data.name}: $tempStr - $percentage%',
                style: TextStyle(fontSize: 14.sp),
              )),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 当日主要营养素饼图
  _buildMainNutrientsPieChart() {
    var temp = mainNutrientsChartData
        .where(
            (e) => e.label == "cho" || e.label == "protein" || e.label == "fat")
        .toList();

    return PieChart(
      PieChartData(
        sections: _createPieChartSections(temp),
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections(
    List<CusNutrientInfo> data,
  ) {
    // double total =
    //     data.fold(0, (previous, current) => previous + current['value']);
    return data.map((e) {
      // double percentage = (e.value / total) * 100;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: e.color,
        // title: '${percentage.toStringAsFixed(1)}%', // 将百分比显示在标题中
        // 没给指定title就默认是其value，所以有图例了就不显示标题
        showTitle: false,
      );
    }).toList();
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
    // 这几个在底部总计可能用到
    var tempSodium = 0.0;
    var tempCholesterol = 0.0;
    var tempDietaryFiber = 0.0;
    var tempPotassium = 0.0;
    var tempSugar = 0.0;

    for (var e in dfiwfsList) {
      var foodIntakeSize = e.dailyFoodItem.foodIntakeSize;
      var servingInfo = e.servingInfo;
      tempEnergy += foodIntakeSize * servingInfo.energy;
      tempProtein += foodIntakeSize * servingInfo.protein;
      tempFat += foodIntakeSize * servingInfo.totalFat;
      tempCHO += foodIntakeSize * servingInfo.totalCarbohydrate;
      tempSodium += foodIntakeSize * servingInfo.sodium;
      tempCholesterol += foodIntakeSize * (servingInfo.cholesterol ?? 0);
      tempDietaryFiber += foodIntakeSize * (servingInfo.dietaryFiber ?? 0);
      tempPotassium += foodIntakeSize * (servingInfo.potassium ?? 0);
      tempSugar += foodIntakeSize * (servingInfo.sugar ?? 0);
    }

    var tempCalories = tempEnergy / oneCalToKjRatio;

    // print("当日的累加值……");
    // print("tempEnergy $tempEnergy");
    // print("tempProtein $tempProtein");
    // print("tempFat $tempFat");
    // print("tempCHO $tempCHO");
    // print("tempCalories $tempCalories");

    setState(() {
      // 当日主要营养素表格数据
      mainNutrientsChartData = [
        CusNutrientInfo(
          label: "calorie",
          value: tempCalories,
          color: cusNutrientColors[CusNutType.calorie]!,
          name: '卡路里',
          unit: '大卡',
        ),
        CusNutrientInfo(
          label: "energy",
          value: tempEnergy,
          color: cusNutrientColors[CusNutType.energy]!,
          name: '能量',
          unit: '千焦',
        ),
        CusNutrientInfo(
          label: "protein",
          value: tempProtein,
          color: cusNutrientColors[CusNutType.protein]!,
          name: '蛋白质',
          unit: '克',
        ),
        CusNutrientInfo(
          label: "fat",
          value: tempFat,
          color: cusNutrientColors[CusNutType.totalFat]!,
          name: '脂肪',
          unit: '克',
        ),
        CusNutrientInfo(
          label: "cho",
          value: tempCHO,
          color: cusNutrientColors[CusNutType.totalCHO]!,
          name: '碳水',
          unit: '克',
        ),
        CusNutrientInfo(
          label: "dietaryFiber",
          value: tempDietaryFiber,
          color: cusNutrientColors[CusNutType.dietaryFiber]!,
          name: '膳食纤维',
          unit: '克',
        ),
        CusNutrientInfo(
          label: "sugar",
          value: tempSugar,
          color: cusNutrientColors[CusNutType.sugar]!,
          name: '糖',
          unit: '克',
        ),
        CusNutrientInfo(
          label: "sodium",
          value: tempSodium,
          color: cusNutrientColors[CusNutType.sodium]!,
          name: '钠',
          unit: '毫克',
        ),
        CusNutrientInfo(
          label: "cholesterol",
          value: tempCholesterol,
          color: cusNutrientColors[CusNutType.cholesterol]!,
          name: '胆固醇',
          unit: '毫克',
        ),
        CusNutrientInfo(
          label: "potassium",
          value: tempPotassium,
          color: cusNutrientColors[CusNutType.potassium]!,
          name: '钾',
          unit: '毫克',
        ),
      ];
    });

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
  Card _buildMealCard(CusLabel mealtime) {
    // 从查询的日记条目中过滤当前餐次的数据
    // DailyFoodItemWithFoodServingMealItems 太长了，缩写 dfiwfsMealItems
    var dfiwfsMealItems = dfiwfsList
        .where(
          (e) => e.dailyFoodItem.mealCategory == mealtime.enLabel,
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
                  title: _buildListTileText(mealtime.cnLabel),
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
                        builder: (context) => SimpleFoodList(
                          mealtime: mealtime.value,
                          // 注意，这里应该是一个日期选择器插件选中的值，格式化为固定字符串，子组件就不再处理
                          logDate: selectedDateStr,
                        ),
                      ),
                    ).then((value) {
                      // 2023-12-04 之前是在食物详情中有设置一个新增成功的返回参数，确认新增成功后重新加载当前日期的条目数据。
                      // 现在就只要是返回这个页面，都重新加载，也避免了跨级子组件数据返回的设计
                      _queryDailyFoodItemList();
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
                  initiallyExpanded: isExpandedList[mealtime.enLabel]!,
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
                      isExpandedList[mealtime.enLabel]!
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                    ),
                  ),
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      isExpandedList[mealtime.enLabel] = isExpanded; // 更新展开状态列表
                    });
                  },
                  // 展开显示食物详情
                  children: [
                    ..._buildListTile(mealtime, dfiwfsMealItems),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SaveMealPhotos(
                              mealtime: mealtime,
                              mealItems: dfiwfsMealItems,
                              mealPhoto: mealPhotoNums[mealtime.enLabel],
                            ),
                          ),
                        ).then((value) {
                          // 进入过添加照片页面的返回都要重新查询
                          setState(() {
                            _queryMealPhotoNums();
                          });
                        });
                      },
                      icon: const Icon(Icons.photo),
                      label: Text('照片 ${_getPhotoCount(mealtime)}'),
                    ),
                  ]),
            ),
        ],
      ),
    );
  }

  // 获取指定餐次的照片数量
  _getPhotoCount(CusLabel mealtime) {
    return ((mealPhotoNums[mealtime.enLabel]?.photos != null &&
                mealPhotoNums[mealtime.enLabel]!.photos.trim().isNotEmpty)
            ? mealPhotoNums[mealtime.enLabel]!.photos.trim().split(",")
            : [])
        .length;
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
    CusLabel curMeal,
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
          print("cutMeal-----${curMeal.enLabel}");

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
              builder: (context) =>
                  SimpleFoodDetail(foodItem: data, dfiwfs: logItem),
            ),
          ).then((value) {
            // 2023-12-04 之前是在食物详情中有设置一个修改或删除成功的返回参数，确认修改或删除成功后重新加载当前日期的条目数据。
            // 现在就只要是返回这个页面，都重新加载，也避免了跨级子组件数据返回的设计
            _queryDailyFoodItemList();
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
            formatDoubleToString(choValue),
            style: TextStyle(fontSize: fontSize),
            textAlign: textAlign,
          ),
        ),
        TableCell(
          child: Text(
            formatDoubleToString(proteinValue),
            style: TextStyle(fontSize: fontSize),
            textAlign: textAlign,
          ),
        ),
        TableCell(
          child: Text(
            formatDoubleToString(fatValue),
            style: TextStyle(fontSize: fontSize),
            textAlign: textAlign,
          ),
        ),
        TableCell(
          child: Text(
            "${formatDoubleToString((caloriesValue / valueRDA * 100))}%",
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
        _queryDailyFoodItemList();
      });
    }
  }
}

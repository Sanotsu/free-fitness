// ignore_for_file: avoid_print

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/common/global/constants.dart';
import 'package:free_fitness/models/dietary_state.dart';

import 'package:intl/intl.dart';

import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../reports/index.dart';
import 'add_intake_item/index.dart';
import 'ai_suggestion/ai_suggestion_page.dart';
import 'format_tools.dart';
import 'report_calendar_summary.dart';
import 'save_meal_photo.dart';
import 'add_intake_item/simple_food_detail.dart';

class DietaryRecords extends StatefulWidget {
  const DietaryRecords({super.key});

  @override
  State<DietaryRecords> createState() => _DietaryRecordsState();
}

class _DietaryRecordsState extends State<DietaryRecords> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
  final DBUserHelper _userHelper = DBUserHelper();

  /// 根据条件查询的日记条目数据
  List<DailyFoodItemWithFoodServing> dfiwfsList = [];
  // 数据是否加载中
  bool isLoading = false;

  /// 用户可能切换日期，但显示的内容是一样的
  /// (这个是日期组件的值，默认是当天。日期范围，可能只在导出时才用到，一般都是单日)

  // 日期选择器中选择的日期，用于构建初始值，有选择后保留选择的
  DateTime selectedDate = DateTime.now();
  // 用户选择日期格式化后的字符串，传入子组件或者查询日志条目的参数
  String selectedDateStr = DateFormat(constDateFormat).format(DateTime.now());
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
    MealLabels.enBreakfast: false,
    MealLabels.enLunch: false,
    MealLabels.enDinner: false,
    MealLabels.enOther: false,
  };

  // 一日四餐对应拥有的餐次照片路径
  // key是餐次英文，value是MealPhoto实例
  Map<String, MealPhoto?> mealPhotoNums = {
    MealLabels.enBreakfast: null,
    MealLabels.enLunch: null,
    MealLabels.enDinner: null,
    MealLabels.enOther: null,
  };

  @override
  void initState() {
    super.initState();

    _queryDailyFoodItemList();
  }

  // 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryDailyFoodItemList({String? mealEnLabel}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 查询用户目标值，根据今天是星期几显示对应的RDA值
    var tempUser = await _userHelper.queryUserWithIntakeDailyGoal(
      userId: CacheUser.userId,
    );

    // 查询指定用户摄入目标信息，并筛选是否有当天(星期几)特定的摄入目标值
    var dailyGoal = tempUser.intakeGoals
        .where((e) => e.dayOfWeek == DateTime.now().weekday.toString())
        .toList();

    setState(() {
      // 如果有对应的星期几的摄入目标，则使用该值
      if (dailyGoal.isNotEmpty) {
        valueRDA = dailyGoal.first.rdaDailyGoal;
      } else if (tempUser.user.rdaGoal != null) {
        // 如果没有当天特定的，则使用整体的
        valueRDA = tempUser.user.rdaGoal!;
      } else {
        // 如果既没有单独每天的也没有整体的，则默认男女推荐值(不是男的都当做女的)
        valueRDA = tempUser.user.gender == "male" ? 2250 : 1800;
      }
    });

    // 理论上是默认查询当日的，有选择其他日期则查询指定日期
    List<DailyFoodItemWithFoodServing> temp =
        (await _dietaryHelper.queryDailyFoodItemListWithDetail(
      userId: CacheUser.userId,
      startDate: selectedDateStr,
      endDate: selectedDateStr,
      withDetail: true,
    ) as List<DailyFoodItemWithFoodServing>);

    // 查询餐次照片数量
    _queryMealPhotoNums();

    setState(() {
      dfiwfsList = temp;

      // 如果是指定餐次添加了条目，返回本页面后该餐次展开
      if (mealEnLabel != null) {
        isExpandedList[mealEnLabel] = true;
      }

      isLoading = false;
    });
  }

  // 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryMealPhotoNums({String? mealEnLabel}) async {
    // 理论上是默认查询当日的，有选择其他日期则查询指定日期

    List<MealPhoto> temp = await _dietaryHelper.queryMealPhotoList(
      CacheUser.userId, // userId是必传的
      startDate: selectedDateStr,
      endDate: selectedDateStr,
      mealCategory: mealEnLabel,
    );

    setState(() {
      // 2023-12-31 需要先清空之前的，否则即便没有也会展示旧的数据
      // mealPhotoNums = {
      //   MealLabels.enBreakfast: null,
      //   MealLabels.enLunch: null,
      //   MealLabels.enDinner: null,
      //   MealLabels.enOther: null,
      // };

      mealPhotoNums.clear();

      // 正常来讲，每天每个餐次最多只有一条数据，只要有数据，照片就是修改或删除了
      for (var e in temp) {
        if (e.mealCategory == MealLabels.enBreakfast) {
          mealPhotoNums[MealLabels.enBreakfast] = e;
        } else if (e.mealCategory == MealLabels.enLunch) {
          mealPhotoNums[MealLabels.enLunch] = e;
        } else if (e.mealCategory == MealLabels.enDinner) {
          mealPhotoNums[MealLabels.enDinner] = e;
        } else if (e.mealCategory == MealLabels.enOther) {
          mealPhotoNums[MealLabels.enOther] = e;
        }
      }
    });
  }

  // 导航栏处点击显示日期选择器
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1994, 7),
        lastDate: DateTime(2077));

    if (!context.mounted) return;
    if (picked != null) {
      // 包含了月日星期，其他格式修改 MMMEd 为其他即可
      var formatDate = DateFormat.MMMEd().format(picked);

      // 昨天今天明天三天的显示可以特殊一点，比较的话就比较对应年月日转换的字符串即可
      var today = DateTime.now();
      var todayStr = "${today.year}${today.month}${today.day}";
      var yesterdayStr = "${today.year}${today.month}${today.day - 1}";
      var tomorrowStr = "${today.year}${today.month}${today.day + 1}";
      var pickedDateStr = "${picked.year}${picked.month}${picked.day}";

      if (pickedDateStr == yesterdayStr) {
        formatDate = CusAL.of(context).rangeLabels('0');
      } else if (pickedDateStr == todayStr) {
        formatDate = CusAL.of(context).rangeLabels('1');
      } else if (pickedDateStr == tomorrowStr) {
        formatDate = CusAL.of(context).rangeLabels('2');
      }

      setState(() {
        selectedDate = picked;
        selectedDateStr = DateFormat(constDateFormat).format(picked);
        showedDateStr = formatDate;
        _queryDailyFoodItemList();
      });
    }
  }

  /// 2024-07-08 可以使用大模型询问今日摄入的情况，并做出分析
  /// 但需要比较好的规划提问的内容。
  String buildSuggestionString() {
    var str = box.read('language') == "en"
        ? """Please analyze my food intake today, provide effective healthy dietary recommendations, and arrange improved quantitative recipes.
        \n\nThis is my main food intake for today:\n\n"""
        : "请根据我今天的食物摄入做出分析，给出有效的健康饮食建议，安排改善后的量化食谱。\n\n这是我今天的主要食物摄入量:\n\n";

    // 2024-07-08 想要分餐次，营养素也得分，然后食物的营养素成分表也得说明。目前这AI也不好用，就笼统一整天的好了
    // Map<String, List<DailyFoodItemWithFoodServing>> itemsByMeal =
    //     dfiwfsList.groupListsBy((l) => l.dailyFoodItem.mealCategory);

    // // 分餐次的食物摄入
    // itemsByMeal.forEach((meal, items) {
    //   str += "- $meal:\n\n";
    //   for (var e in items) {
    //     str +=
    //         "  - ${e.food.product} ${e.dailyFoodItem.foodIntakeSize} x ${e.servingInfo.servingUnit}; \n\n";
    //   }
    // });

    for (var e in dfiwfsList) {
      var temp = mealtimeList
          .firstWhere((m) => m.enLabel == e.dailyFoodItem.mealCategory);

      str += """  - [${showCusLable(temp)}] ${e.food.product} 
          ${e.dailyFoodItem.foodIntakeSize} x ${e.servingInfo.servingUnit}\n\n""";
    }

    str += box.read('language') == "en"
        ? "\n\nThis is my main nutrient intake for today:\n\n"
        : "\n\n这是我今天的主要营养素摄入量:\n\n";

    // 全部营养素
    for (var e in mainNutrientsChartData) {
      str += "  - ${e.name} ${e.value.toStringAsFixed(2)} ${e.unit}\n\n";
    }

    return str;
  }

  @override
  Widget build(BuildContext context) {
    // 不能在init处理这个
    if (showedDateStr == "今天") {
      setState(() {
        showedDateStr = CusAL.of(context).rangeLabels('1');
      });
    }

    return Scaffold(
      appBar: AppBar(
        // 饮食记录首页的日期选择器是单日的，可以不用第三方库，简单showDatePicker就好
        // 导出之类的可以花式选择日期的再用
        title: GestureDetector(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 设置一条白色的下划线，表示可以点击切换
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 1.sp),
                    ),
                  ),
                  child: Text(
                    showedDateStr,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: CusFontSizes.pageTitle),
                  ),
                ),
              ),
            ],
          ),
          onTap: () {
            _selectDate(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.report),
            onPressed: () {
              /// 还是要返回当前页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DietaryReports(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportCalendarSummary(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddIntakeItem(
                    mealtime: CusMeals.breakfast,
                    // 注意，这里应该是一个日期选择器插件选中的值，格式化为固定字符串，子组件就不再处理
                    logDate: selectedDateStr,
                  ),
                ),
              ).then((value) {
                // 2023-12-04 之前是在食物详情中有设置一个新增成功的返回参数，确认新增成功后重新加载当前日期的条目数据。
                // 现在就只要是返回这个页面，都重新加载，也避免了跨级子组件数据返回的设计
                // 2023-12-13
                if (value != null) {
                  _queryDailyFoodItemList(mealEnLabel: value as String);
                }
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Column(
              children: [
                /// 顶部的每日概述卡片，点击切换表格或概述模式
                buildDailyOverviewCard(),

                /// 饮食日记条目列表
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                buildMealCard(mealtime),
                                SizedBox(height: 5.sp)
                              ],
                            );
                          },
                        ),

                        /// 当日主要营养素占比(当日有饮食摄入条目才显示，否则不显示)
                        SizedBox(height: 5.sp),
                        if (dfiwfsList.isNotEmpty)
                          buildNutrientProportionCard(),
                        // const Card(
                        //   child: ListTile(
                        //     title: Text('其他选项功能区(暂留)'),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (dfiwfsList.isEmpty) {
            commonExceptionDialog(
              context,
              "提示",
              "本日暂无食物摄入信息，无须AI助手给出分析建议。",
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    OneChatScreen(intakeInfo: buildSuggestionString()),
              ),
            );
          }
        },
        tooltip: box.read('language') == "en" ? "AI Assistant" : 'AI分析对话助手',
        child: const Icon(Icons.chat),
        // child: Text(
        //   box.read('language') == "en" ? "AIA" : "AI\n助手",
        //   style: TextStyle(fontSize: 12.sp),
        //   textAlign: TextAlign.center,
        // ),
      ),
    );
  }

  /// 最上面的每日概述卡片
  Widget buildDailyOverviewCard() {
    return Card(
      elevation: 4,
      color: Theme.of(context).secondaryHeaderColor,
      child: GestureDetector(
        onTap: () {
          setState(() {
            dataDisplayMode =
                dataDisplayMode == "detailed" ? "summary" : "detailed";
          });
        },
        child: SizedBox(
          height: 70.sp,
          child: _buildDailyOverviewListTile(),
        ),
      ),
    );
  }

  /// 最上面的每日概述卡片的文本
  Widget _buildDailyOverviewListTile() {
    // 两种形态：只显示卡路里的基本，显示主要营养素的详细
    var tempList = formatIntakeItemListForMarker(context, dfiwfsList);

    var totalCalorie = tempList.firstWhere((e) => e.label == "calorie").value;
    var totalProtein = tempList.firstWhere((e) => e.label == "protein").value;
    var totalFat = tempList.firstWhere((e) => e.label == "fat").value;
    var totalCho = tempList.firstWhere((e) => e.label == "cho").value;

    setState(() {
      // 当日主要营养素表格数据
      mainNutrientsChartData = tempList;
    });

    // 最上方的是当日摄入的主要营养素总量，根据详细和概要展示不同内容.1是表格模式，2是简单的已食用和剩余卡路里
    return ListTile(
      title: Table(
        children: (dataDisplayMode == "detailed")
            ? [
                TableRow(
                  children: [
                    _buildHeaderTableCell(CusAL.of(context).mainNutrients('4')),
                    _buildHeaderTableCell(CusAL.of(context).mainNutrients('2')),
                    _buildHeaderTableCell(CusAL.of(context).mainNutrients('3')),
                    _buildHeaderTableCell(CusAL.of(context).mainNutrients('5')),
                  ],
                ),
                _buildMainMutrientsValueTableRow(
                    totalCho, totalProtein, totalFat, totalCalorie),
              ]
            : [
                TableRow(
                  children: [
                    _buildHeaderTableCell(CusAL.of(context).calorieLabels('0')),
                  ],
                ),
                TableRow(
                  children: [
                    // 不能使用上面那个header cell，格式细微不同
                    TableCell(
                      child: Text(
                        CusAL.of(context).calorieLabels('1'),
                        style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
      ),
      // 尾部留七分之一显示RDA值
      trailing: SizedBox(
        width: 0.142.sw,
        child: Table(
          children: [
            TableRow(
              children: [
                _buildHeaderTableCell(
                  (dataDisplayMode == "detailed")
                      ? valueRDA.toString()
                      : (valueRDA - totalCalorie).toStringAsFixed(0),
                  // color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            TableRow(
              children: [
                // 不能使用上面那个header cell，格式细微不同
                TableCell(
                  child: Text(
                    totalCalorie.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: CusFontSizes.itemSubTitle,
                      // color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      dense: true,
    );
  }

  Widget _buildHeaderTableCell(
    String label, {
    double? fontSize,
    textAlign = TextAlign.right,
    Color? color,
  }) {
    fontSize ??= CusFontSizes.itemSubTitle;
    return TableCell(
      child: Text(
        label,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize, color: color),
        // 中英文的leading好像不一样，统一一下避免显示不在一条水平线
        strutStyle: StrutStyle(
          forceStrutHeight: true,
          leading: 1.sp,
        ),
        // 只显示1行,不然表格变形
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }

  /// 早中晚夜各个餐次的卡片
  Card buildMealCard(CusLabel mealtime) {
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
      elevation: 5, // 设置阴影的程度
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp), // 设置圆角的大小
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// 餐次和该餐次摄入总的能量
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ListTile(
                  // 设置leading的最小宽度
                  minLeadingWidth: 24.sp,
                  leading: const Icon(Icons.food_bank_sharp),
                  title: _buildListTileText(
                    showCusLableMapLabel(context, mealtime),
                    fontSize: CusFontSizes.pageSubTitle,
                  ),
                  subtitle: _buildListTileText(
                    CusAL.of(context).itemLabel(dfiwfsMealItems.length),
                    fontSize: CusFontSizes.itemContent,
                  ),
                  dense: true,
                ),
              ),
              Expanded(
                flex: 3,
                child: ListTile(
                  title: _buildListTileText(
                    tempCalories.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                    fontSize: CusFontSizes.pageSubTitle,
                  ),
                  subtitle: _buildListTileText(
                    CusAL.of(context).calorieLabels("2"),
                    textAlign: TextAlign.right,
                    fontSize: CusFontSizes.itemContent,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddIntakeItem(
                          mealtime: mealtime.value,
                          // 注意，这里应该是一个日期选择器插件选中的值，格式化为固定字符串，子组件就不再处理
                          logDate: selectedDateStr,
                        ),
                      ),
                    ).then((value) {
                      // 2023-12-04 之前是在食物详情中有设置一个新增成功的返回参数，确认新增成功后重新加载当前日期的条目数据。
                      // 现在就只要是返回这个页面，都重新加载，也避免了跨级子组件数据返回的设计

                      if (value != null) {
                        _queryDailyFoodItemList(mealEnLabel: value as String);
                      }
                    });
                  },
                  icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),

          /// 折叠tile展开灰色，展开后白色
          if (showExpansionTile)
            Container(
              decoration: BoxDecoration(
                // borderRadius: BorderRadius.circular(10.0), // 设置所有圆角的大小
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0.sp), // 保持上左角为直角
                  topRight: Radius.circular(0.sp), // 保持上右角为直角
                  bottomLeft: Radius.circular(10.sp), // 设置下左角为圆角
                  bottomRight: Radius.circular(10.sp), // 设置下右角为圆角
                ),
                // 折叠栏设置展开前的背景色
                color: Theme.of(context).focusColor,
              ),
              child: ExpansionTile(
                  initiallyExpanded: isExpandedList[mealtime.enLabel]!,
                  // 如果是概要，展开的标题只显示餐次的食物数量；是详情，则展示该餐次各项食物的主要营养素之和
                  title: dataDisplayMode == "summary"
                      ? Text(
                          CusAL.of(context).itemLabel(dfiwfsMealItems.length),
                        )
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
                  // 折叠栏展开后的背景色
                  // backgroundColor: Theme.of(context).focusColor,
                  trailing: SizedBox(
                    // 设置的这个宽度让餐次中的表格数据和顶部保持差不多样子(7分之1)
                    width: 0.142.sw,
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
                    // 具体的每个食物的名称喝摄入量
                    ...buildListTile(mealtime, dfiwfsMealItems),
                    // 下方是添加图片的按钮，带个分割线
                    Divider(thickness: 2, height: 2.sp),

                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SaveMealPhotos(
                              mealtime: mealtime,
                              mealItems: dfiwfsMealItems,
                              mealPhoto: mealPhotoNums[mealtime.enLabel],
                              date: selectedDateStr,
                            ),
                          ),
                        ).then((value) {
                          // 进入过添加照片页面的返回都要重新查询
                          setState(() {
                            _queryMealPhotoNums();
                          });
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        CusAL.of(context).photoLabel(_getPhotoCount(mealtime)),
                      ),
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
    double fontSize = 14,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 各餐次卡片点击展开的食物条目
  List<Widget> buildListTile(
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
        // 点击饮食摄入条目，进入详情页面，可以修改摄入量、单份营养素单位、餐次信息等
        onTap: () async {
          // 先获取到当前item的食物信息，再传递到food detail
          var data = await _dietaryHelper.searchFoodWithServingInfoByFoodId(
            logItem.dailyFoodItem.foodId,
            onlyNotDeleted: false,
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

            // 2023-12-13 点击条目直接进入条目食物详情页面，修改、删除后有返回true才重新查询；否则就是没变动。
            if (value != null && value) {
              _queryDailyFoodItemList();
            }
          });
        },
        // 滑动删除指定饮食日记条目
        child: Dismissible(
          key: Key(logItem.hashCode.toString()),
          onDismissed: (direction) async {
            // 确认滑动移除之后，要重新查询当日数据构建卡片（？？？全部重绘感觉有点浪费）
            await _dietaryHelper.deleteDailyFoodItem(
              logItem.dailyFoodItem.dailyFoodItemId!,
            );

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
                height: 2.sp,
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
                      // 2023-12-12 前面不留空，否则食物名称太长就显示得不好看
                      // leading: SizedBox(width: 0.05.sw),
                      title: _buildListTileText(
                        "${logItem.food.product} (${logItem.food.brand})",
                      ),
                      subtitle: _buildListTileText(
                        '${cusDoubleTryToIntString(logItem.dailyFoodItem.foodIntakeSize)} * $tempUnit',
                      ),
                      dense: true,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ListTile(
                      title: _buildListTileText(
                        tempCalories.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        fontSize: CusFontSizes.pageSubTitle,
                      ),
                      subtitle: _buildListTileText(
                        CusAL.of(context).calorieLabels("2"),
                        textAlign: TextAlign.right,
                        fontSize: CusFontSizes.itemContent,
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
                      // 这个只是为了让表格行数据和上面 expansionTile 排版一致(七分之一)，所以设置透明图标
                      trailing: SizedBox(
                        width: 0.142.sw,
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
    double? fontSize,
    TextAlign textAlign = TextAlign.end,
    bool isHeader = false, // 如果是标题，则还要显示第五个单元格
  }) {
    fontSize ??= CusFontSizes.itemSubTitle;
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
        if (isHeader)
          TableCell(
            child: Text(
              caloriesValue.toStringAsFixed(0),
              style: TextStyle(fontSize: fontSize),
              textAlign: textAlign,
            ),
          ),
      ],
    );
  }

  /// 绘制营养素占比卡片区域
  buildNutrientProportionCard() {
    return Card(
      elevation: 10,
      child: Padding(
        padding: EdgeInsets.all(10.sp),
        child: SizedBox(
          height: 450.sp,
          child: Column(
            children: [
              Text(
                CusAL.of(context).illustratedDesc("0"),
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: CusFontSizes.itemTitle,
                ),
              ),
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
              Divider(height: 10.sp, thickness: 2.sp),
              Text(
                CusAL.of(context).illustratedDesc("1"),
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: CusFontSizes.itemTitle,
                ),
              ),

              // 更多的信息列表
              _buildMainNutrientsList(),
            ],
          ),
        ),
      ),
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

        String tempStr =
            "${cusDoubleTryToIntString(data.value)}${CusAL.of(context).unitLabels('0')}";

        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.sp),
          child: Row(
            children: [
              Container(width: 14, height: 14, color: data.color),
              SizedBox(width: 8.sp),
              // 将百分比数据添加到标题后面
              Expanded(
                  child: Text(
                '${data.name}: $tempStr - $percentage%',
                style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
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
        sections: temp.map((e) {
          return PieChartSectionData(
            value: e.value.toDouble(),
            color: e.color,
            // 没给指定title就默认是其value，所以有图例了就不显示标题
            showTitle: false,
          );
        }).toList(),
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
              Container(width: 14, height: 14, color: data.color),
              SizedBox(width: 8.sp),
              // 将百分比数据添加到标题后面
              Expanded(
                child: Text(
                  '${data.name}: $tempStr',
                  style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

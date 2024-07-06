// ignore_for_file: avoid_print

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/dietary_state.dart';

class WeekIntakeBar extends StatefulWidget {
  // 需要展示的一周七天的数据(宏量素摄入目标和实际摄入都可以通用，但数据结构需要一致)
  final Map<String, FoodNutrientTotals> fntMap;

  // 类型，绘制一周每天的四餐摄入，还是一周每天的主要营养素
  final CusChartType type;

  const WeekIntakeBar({super.key, required this.fntMap, required this.type});

  @override
  State<StatefulWidget> createState() => WeekIntakeBarState();
}

class WeekIntakeBarState extends State<WeekIntakeBar> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.67,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: BarChart(mainBarData()),
      ),
    );
  }

  // 条状图的数据
  // (这里默认启用触摸事件，触摸知道柱子显示该条状图y轴数据)
  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        // 提示框的样式和内容
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.blueGrey,
          // 太宽了的话最两边还是超出了屏幕
          tooltipHorizontalAlignment: FLHorizontalAlignment.center,
          tooltipPadding: EdgeInsets.symmetric(
            horizontal: 5.sp,
            vertical: 8.sp,
          ),
          // 提示框的最大宽度(默认120)
          maxContentWidth: 0.4.sw,
          // 提示框举例条状图顶部的距离(正数就是往上空，负数就是向下移动)
          // 如果柱状图高低差别太大，还是有一些被遮住看不到
          tooltipMargin: 0,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            // 点击时展示主要营养素的含量，但需要先取到值
            List<double> fromYList =
                rod.rodStackItems.map((item) => item.fromY).toList();
            List<double> toYList =
                rod.rodStackItems.map((item) => item.toY).toList();

            var unit = widget.type == CusChartType.calory
                ? CusAL.of(context).unitLabels('2')
                : CusAL.of(context).unitLabels('0');

            String getNutrientString(String name, int index) {
              double nutrientAmount = toYList[index] - fromYList[index];
              double percentage = (nutrientAmount / toYList[2]) * 100;
              return '$name ${nutrientAmount.toStringAsFixed(2)} $unit (${percentage.toStringAsFixed(2)}%)';
            }

            if (widget.type == CusChartType.macro) {
              String weekDay =
                  showCusLableMapLabel(context, weekdayStringMap[group.x + 1]);
              String choStr =
                  getNutrientString(CusAL.of(context).mainNutrients('4'), 0);
              String fatStr =
                  getNutrientString(CusAL.of(context).mainNutrients('3'), 1);
              String proteinStr =
                  getNutrientString(CusAL.of(context).mainNutrients('2'), 2);

              // 构建气泡框显示的内容
              return BarTooltipItem(
                '$weekDay\n',
                TextStyle(fontSize: CusFontSizes.flagTiny),
                textAlign: TextAlign.left,
                children: <TextSpan>[
                  TextSpan(text: "$choStr\n"),
                  TextSpan(text: "$fatStr\n"),
                  TextSpan(text: proteinStr),
                ],
              );
            } else {
              String weekDay =
                  showCusLableMapLabel(context, weekdayStringMap[group.x + 1]);
              String bfStr =
                  getNutrientString(CusAL.of(context).mealLabels('0'), 0);
              String lunchStr =
                  getNutrientString(CusAL.of(context).mealLabels('1'), 1);
              String dinnerStr =
                  getNutrientString(CusAL.of(context).mealLabels('2'), 2);
              String otherStr =
                  getNutrientString(CusAL.of(context).mealLabels('3'), 3);

              // 构建气泡框显示的内容
              return BarTooltipItem(
                '$weekDay\n',
                TextStyle(fontSize: CusFontSizes.flagTiny),
                textAlign: TextAlign.left,
                children: <TextSpan>[
                  TextSpan(text: "$bfStr\n"),
                  TextSpan(text: "$lunchStr\n"),
                  TextSpan(text: "$dinnerStr\n"),
                  TextSpan(text: otherStr),
                ],
              );
            }
          },
        ),
      ),
      // 图表4面的标题
      titlesData: FlTitlesData(
        show: true,
        // 有设置底部x轴标签和坐标y轴刻度标签
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: _bottomTitles,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60, // 左侧刻度标签的宽度
            getTitlesWidget: _leftTitles,
          ),
        ),
        // 不显示内容也要设定，否则就是默认的样式
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      // 图表的边框
      borderData: FlBorderData(show: false),

      /// 图表背景网格
      // 不展示网格需要说明
      // gridData: const FlGridData(show: false),
      // 也可以自定义
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: true,
        checkToShowHorizontalLine: (value) => value % 1 == 0,
        checkToShowVerticalLine: (value) => value % 1 == 0,
        getDrawingHorizontalLine: (value) {
          if (value == 0) {
            return FlLine(color: Colors.orange, strokeWidth: 2.sp);
          } else {
            return FlLine(color: Colors.black26, strokeWidth: 0.5.sp);
          }
        },
        getDrawingVerticalLine: (value) {
          if (value == 0) {
            return FlLine(color: Colors.redAccent, strokeWidth: 10.sp);
          } else {
            return FlLine(color: Colors.black26, strokeWidth: 0.5.sp);
          }
        },
      ),
      // 条状图组的数据
      barGroups: _showingGroups(),
    );
  }

  // 底部的标签(周一到周日)
  Widget _bottomTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      fitInside: SideTitleFitInsideData.disable(),
      child: Text(
        showCusLableMapLabel(context, weekdayStringMap[value.toInt() + 1]),
        style: TextStyle(fontSize: CusFontSizes.flagTiny),
      ),
    );
  }

  // 左侧的标签
  Widget _leftTitles(double value, TitleMeta meta) {
    if (value == meta.max) {
      return Container();
    }
    var unit = widget.type == CusChartType.calory
        ? CusAL.of(context).unitLabels('2')
        : CusAL.of(context).unitLabels('0');

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        "${meta.formattedValue}$unit",
        style: TextStyle(fontSize: CusFontSizes.flagTiny),
      ),
    );
  }

  // 整体条状图数据
  List<BarChartGroupData> _showingGroups() => List.generate(7, (i) {
        // 查询map中存在的日期key是一周的周几，如果该weekday有数据，则构建条状图，否则就空的。
        for (String key in widget.fntMap.keys) {
          int weekdayNumber = DateFormat(constDateFormat).parse(key).weekday;

          // 星期的数字从1-7,而索引是从0-6,所以比较时后者要加一
          if (weekdayNumber == i + 1) {
            return makeGroupData(i, widget.fntMap[key]!);
          }
        }

        return BarChartGroupData(x: i);
      });

  // 单组条状图数据
  BarChartGroupData makeGroupData(
    // 沿着x轴的顺序，其中将显示标题，并且仅显示标题
    int x,
    // 用于构建y轴条状图的数据
    FoodNutrientTotals fnt, {
    double width = 14, // 条状图宽度
    List<int> showTooltips = const [], // 气泡框显示
  }) {
    List<BarChartRodStackItem> rodStackItems = [];
    double sum = 0;

    List<double> nums = [];
    List<Color> colors = [];

    if (widget.type == CusChartType.calory) {
      // 依次为早中晚夜的柱子数值
      nums = [
        fnt.bfCalorie,
        fnt.lunchCalorie,
        fnt.dinnerCalorie,
        fnt.otherCalorie,
      ];
      // 依次为早中晚夜的柱子颜色
      colors = [
        cusNutrientColors[CusNutType.bfCalorie]!,
        cusNutrientColors[CusNutType.lunchCalorie]!,
        cusNutrientColors[CusNutType.dinnerCalorie]!,
        cusNutrientColors[CusNutType.otherCalorie]!
      ];
    } else {
      // 依次为碳水、脂肪、蛋白质的数值
      nums = [fnt.totalCHO, fnt.totalFat, fnt.protein];
      // 依次为碳水、脂肪、蛋白质的颜色
      colors = [
        cusNutrientColors[CusNutType.totalCHO]!,
        cusNutrientColors[CusNutType.totalFat]!,
        cusNutrientColors[CusNutType.protein]!,
      ];
    }

    // 指定这个条状图每组数据的长度范围和指定颜色，依次为碳水、脂肪、蛋白质
    for (int i = 0; i < nums.length; i++) {
      rodStackItems.add(BarChartRodStackItem(sum, sum + nums[i], colors[i]));
      sum += nums[i];
    }

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          // y轴是总和的高度
          // toY: nums.reduce((value, element) => value + element),
          // 上面for循环已经把和累加了
          toY: sum,
          rodStackItems: rodStackItems,
          // 每个条状图的宽度
          width: width,
          borderRadius: BorderRadius.zero,
        ),
      ],
      // 点击条状图柱子会显示提示框
      showingTooltipIndicators: showTooltips,
    );
  }
}

// ignore_for_file: avoid_print

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';

class WeekIntakeBarChart extends StatefulWidget {
  // 需要展示的一周七天的数据(宏量素摄入目标和实际摄入都可以通用，但数据结构需要一致)
  final Map<int, CusMacro> intakeData;

  const WeekIntakeBarChart({super.key, required this.intakeData});

  @override
  State<StatefulWidget> createState() => WeekIntakeBarChartState();
}

class WeekIntakeBarChartState extends State<WeekIntakeBarChart> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        // 这个边框是为了手指放到柱状图时，最两侧显示的tooltip能不被遮挡
        padding: EdgeInsets.only(left: 8.sp, right: 28.sp),
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
          tooltipHorizontalAlignment: FLHorizontalAlignment.center,
          tooltipPadding: EdgeInsets.symmetric(horizontal: 5.sp, vertical: 8),
          // 提示框的最大宽度(默认120)
          maxContentWidth: 0.5.sw,
          // 提示框举例条状图顶部的距离(正数就是往上空，负数就是向下移动)
          // tooltipMargin: -100,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            // 点击时展示主要营养素的含量，但需要先取到值
            List<double> fromYList =
                rod.rodStackItems.map((item) => item.fromY).toList();
            List<double> toYList =
                rod.rodStackItems.map((item) => item.toY).toList();

            String getNutrientString(String name, int index) {
              double nutrientAmount = toYList[index] - fromYList[index];
              double percentage = (nutrientAmount / toYList[2]) * 100;
              return '$name ${nutrientAmount.toStringAsFixed(2)} ${CusAL.of(context).unitLabels('0')} (${percentage.toStringAsFixed(2)}%)';
            }

            String weekDay = showCusLableMapLabel(
              context,
              weekdayStringMap[group.x + 1],
            );

            String choStr = getNutrientString(
              CusAL.of(context).mainNutrients('4'),
              0,
            );
            String fatStr = getNutrientString(
              CusAL.of(context).mainNutrients('3'),
              1,
            );
            String proteinStr = getNutrientString(
              CusAL.of(context).mainNutrients('2'),
              2,
            );

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
            reservedSize: 50, // 左侧刻度标签的宽度
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
      // 条状图组的数据
      barGroups: _showingGroups(),
    );
  }

  // 底部的标签
  Widget _bottomTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
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

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        "${meta.formattedValue} ${CusAL.of(context).unitLabels('0')}",
        style: TextStyle(fontSize: CusFontSizes.flagTiny),
      ),
    );
  }

  // 整体条状图数据
  List<BarChartGroupData> _showingGroups() => List.generate(7, (i) {
        // 传入的一周摄入数据key是从1到7,但这里和绘制时需要0到6,所以取值时i+1即可。
        if (widget.intakeData[i + 1] != null) {
          return makeGroupData(i, widget.intakeData[i + 1]!);
        } else {
          return throw Error();
        }
      });

  // 单组条状图数据
  BarChartGroupData makeGroupData(
    // 沿着x轴的顺序，其中将显示标题，并且仅显示标题
    int x,
    // 用于构建y轴条状图的数据
    CusMacro cusMacro, {
    double width = 22, // 条状图宽度
    List<int> showTooltips = const [], // 气泡框显示
  }) {
    List<BarChartRodStackItem> rodStackItems = [];
    double sum = 0;
    // 依次为碳水、脂肪、蛋白质的数值
    List<double> nums = [cusMacro.carbs, cusMacro.fat, cusMacro.protein];
    // 依次为碳水、脂肪、蛋白质的柱子颜色
    List<Color> colors = [
      cusNutrientColors[CusNutType.totalCHO]!,
      cusNutrientColors[CusNutType.totalFat]!,
      cusNutrientColors[CusNutType.protein]!,
    ];

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

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/user_state.dart';

class WeightChangeLineChart extends StatefulWidget {
  final User user;

  const WeightChangeLineChart({super.key, required this.user});

  @override
  State<WeightChangeLineChart> createState() => _WeightChangeLineChartState();
}

class _WeightChangeLineChartState extends State<WeightChangeLineChart> {
  final DBUserHelper _userHelper = DBUserHelper();

  // 需要显示的提示的点(下面数据的横坐标索引?)
  // 默认是最大体重和最小体重的数据点才显示 工具提示框
  List<int> showingTooltipOnSpots = [0, 0];

  // 记录查到的体重数据，显示的时候需要根据索引显示日期
  List<WeightTrend> weightTrends = [];

  // 折线上的数据点列表
  List<FlSpot> allSpots = [];

  // 最大最小值，纵坐标标题的间隔有用到
  double minWeight = 0;
  double maxWeight = 0;

  // 折线中每个数据点的宽度，如果用户想要缩放图片的时候可以修改这个值
  double spotWidth = 60.sp;

  bool isLoading = false;

  // 保存折线图图表为图片时需要
  final GlobalKey _chartKey = GlobalKey();

// 是否显示保存的按钮(Android9及其以下是无法保存的，组件已经不支持了)
  bool isShowSaveButton = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      getWeightData();
      getDeviceInfo();
    });
  }

  getWeightData({String? startDate, String? endDate}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    var tempList = await _userHelper.queryWeightTrendByUser(
      userId: widget.user.userId,
      startDate: startDate,
      endDate: endDate,
    );

    setState(() {
      weightTrends = tempList;
      allSpots.clear();

      if (weightTrends.isEmpty) {
        isLoading = false;
        return;
      }

      /// 反正构建spot的时候都要遍历，就在遍历是获取最大最小值了
      // 获取到查询的体重列表中的最大值和最小值
      // var minW = tempList.reduce((a, b) => a.weight < b.weight ? a : b);
      // var minWindex = tempList.indexOf(minW);
      // var maxW = tempList.reduce((a, b) => a.weight > b.weight ? a : b);
      // var maxWindex = tempList.indexOf(maxW);

      // 获取查询结果中体重最大值和最小值及其所在的索引数据
      minWeight = tempList[0].weight;
      maxWeight = tempList[0].weight;
      int minWeightIndex = 0;
      int maxWeightIndex = 0;

      for (var i = 0; i < tempList.length; i++) {
        var e = tempList[i];

        // 在遍历中查询体重最大最小值及其索引
        if (e.weight < minWeight) {
          minWeight = e.weight;
          minWeightIndex = i;
        }
        if (e.weight > maxWeight) {
          maxWeight = e.weight;
          maxWeightIndex = i;
        }

        // 所有的数据都构建折线的数据点
        // flspot坐标x，y需要是double，这里的日期转为索引，显示的时候再索引转为日期。
        // 所以查询的结果要安装日期升序排序
        allSpots.add(FlSpot(i.toDouble(), e.weight));
      }

      // 最大最小的值默认显示工具提示框
      showingTooltipOnSpots = [minWeightIndex, maxWeightIndex];

      isLoading = false;
    });
  }

  // 左侧的标签(体重)
  Widget _leftTitles(double value, TitleMeta meta) {
    if (value == meta.max) {
      return Container();
    }
    var unit = "kg";
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        "${meta.formattedValue}$unit",
        style: TextStyle(fontSize: CusFontSizes.flagTiny),
      ),
    );
  }

  // 底部的标签(日期)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    // 显示的时候只显示当前月份的创建时间的日期数据
    var temp = weightTrends[value.toInt()].gmtCreate;
    // 单纯的日
    // String text = temp.split(" ")[0].split("-")[2];
    // 完整日期
    // String text = temp.split(" ")[0];
    // 取月-日
    var tempDate = temp.split(" ")[0].split("-");
    String text = tempDate.sublist(tempDate.length - 2).join("-");

    // 如果图表单个数据点宽度过小，x轴标题只显示日
    if (spotWidth >= 60) {
      text =
          '${tempDate.sublist(tempDate.length - 2).join("-")}\n${temp.split(" ")[1]}';
    } else if (spotWidth >= 30) {
      text = tempDate.sublist(tempDate.length - 2).join("-");
    } else {
      text = temp.split(" ")[0].split("-")[2];
    }

    return SideTitleWidget(
      axisSide: AxisSide.top,
      fitInside: SideTitleFitInsideData.disable(),
      child: Text(
        text,
        // "$text\n${temp.split(" ")[1]}",
        style: TextStyle(fontSize: CusFontSizes.flagTiny),
      ),
    );
  }

  // 找了很多问题，是Android9及之下，无法保存。
  // 权限什么的都已经给了的，还是存不了，有时间找个Android10及其之上的设备试一下
  saveChartImage() async {
    RenderRepaintBoundary boundary =
        _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 2.sp);

    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final result = await ImageGallerySaver.saveImage(
        byteData.buffer.asUint8List(),
        name: "${getCurrentDateTime()}图表",
      );
      print(result);
    }
  }

  // 获取设备信息，判断是否显示保存按钮
  getDeviceInfo() async {
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      // Android9对应sdk是28,<=28就不显示保存按钮
      if (sdkInt <= 28) {
        isShowSaveButton = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 添加这个可以横线滚动
    return weightTrends.isEmpty
        ? SizedBox(
            height: 300.sp,
            child: Center(child: Text(CusAL.of(context).noRecordNote)),
          )
        : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {
                      var temp = getStartEndDateString(3);
                      getWeightData(startDate: temp[0], endDate: temp[1]);
                    },
                    child: Text(CusAL.of(context).lastDayLabels("7")),
                  ),
                  TextButton(
                    onPressed: () {
                      var temp = getStartEndDateString(30);
                      getWeightData(startDate: temp[0], endDate: temp[1]);
                    },
                    child: Text(CusAL.of(context).lastDayLabels("30")),
                  ),
                  TextButton(
                    onPressed: () {
                      var temp = getStartEndDateString(90);
                      getWeightData(startDate: temp[0], endDate: temp[1]);
                    },
                    child: Text(CusAL.of(context).lastDayLabels("90")),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 2023-12-30 还没有优化，暂时不支持下载
                  // if (isShowSaveButton)
                  //   IconButton(
                  //     onPressed: saveChartImage,
                  //     icon: Icon(
                  //       Icons.download,
                  //       color: Theme.of(context).primaryColor,
                  //     ),
                  //   ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        // 每个点最小宽度20；在50以上，每次缩小10；在25-40每次缩小5；
                        if (spotWidth >= 50.sp) {
                          spotWidth -= 10.sp;
                        } else if (spotWidth >= 25.sp) {
                          spotWidth -= 5.sp;
                        }
                      });
                    },
                    icon: Icon(
                      Icons.zoom_out,
                      color: spotWidth <= 20.sp
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // 每个点最大宽度120
                      setState(() {
                        if (spotWidth <= 110.sp) {
                          spotWidth += 10.sp;
                        }
                      });
                    },
                    icon: Icon(
                      Icons.zoom_in,
                      color: spotWidth >= 120.sp
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              isLoading
                  ? Center(
                      child: SizedBox(
                      height: 300.sp,
                      child: const CircularProgressIndicator(),
                    ))
                  : _buildLineChart(),
            ],
          );
  }

  _buildLineChart() {
    // 折线的数据和配置
    final lineBarsData = [
      LineChartBarData(
        // 要展示的工具提示框的数据点列表
        showingIndicators: showingTooltipOnSpots,
        // 折线上的数据点列表
        spots: allSpots,
        // 是否曲线平滑
        // isCurved: true,
        // 线宽
        barWidth: 2,
        // 设置线加上阴影
        // shadow: Shadow(blurRadius: 3.sp),

        // 设置折线下方的区域的配置
        // belowBarData: BarAreaData(
        //   show: true, // 不显示的话就只是看到一条折线(默认就是不显示)
        //   gradient: LinearGradient(
        //     colors: [
        //       Colors.blue.withOpacity(0.4),
        //       Colors.pink.withOpacity(0.4),
        //       Colors.red.withOpacity(0.4),
        //     ],
        //   ),
        // ),

        // 折线上每个数据点的配置(是否显示、圆形圆点等等)
        // dotData: const FlDotData(show: false),

        /// 折线的渐变色
        // 如果提供，此[LineChartBarData]将使用此[gradient]绘制。否则，使用[color]来绘制背景。
        // 如果同时提供[color]和[gradient]，则会引发异常
        gradient: const LinearGradient(
          colors: [
            Colors.blue,
            Colors.pink,
            Colors.red,
          ],
          stops: [0.1, 0.4, 0.9],
        ),
      ),
    ];

    final tooltipsOnBar = lineBarsData[0];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        // 四周留点边框方便标题显示完整(上面右边多留点为了数据点提示工具框显示完整)
        padding: EdgeInsets.fromLTRB(10.sp, 50.sp, 30.sp, 10.sp),
        // 表格的宽度可以根据数量来(这每个sport的宽度可以根据x轴坐标的标题长度来定)
        // width: allSpots.length * 60.sp,

        // 要考虑上面padding左右边框和适当的图表最小宽度
        width: (allSpots.length * spotWidth) + 80.sp,
        height: 300.sp,
        child: RepaintBoundary(
          key: _chartKey,
          child: LineChart(
            // 折线图的数据
            LineChartData(
              // 显示工具提示框的设置
              showingTooltipIndicators: showingTooltipOnSpots.map((index) {
                return ShowingTooltipIndicators([
                  LineBarSpot(
                    tooltipsOnBar,
                    lineBarsData.indexOf(tooltipsOnBar),
                    tooltipsOnBar.spots[index],
                  ),
                ]);
              }).toList(),
              // 折线图触摸的时候的数据
              lineTouchData: LineTouchData(
                // 启用触摸反馈
                enabled: true,
                // 内置触摸处理
                handleBuiltInTouches: false,
                // 这个触摸反馈是：点击某个点，显示该点的值；再点击就取消显示
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? response) {
                  if (response == null || response.lineBarSpots == null) {
                    return;
                  }
                  if (event is FlTapUpEvent) {
                    final spotIndex = response.lineBarSpots!.first.spotIndex;
                    // 点击某个数据点，如果已经展示了工具提示框就从工具提示框点列表移除；没有，则加入
                    setState(() {
                      if (showingTooltipOnSpots.contains(spotIndex)) {
                        showingTooltipOnSpots.remove(spotIndex);
                      } else {
                        showingTooltipOnSpots.add(spotIndex);
                      }
                    });
                  }
                },
                // 鼠标解析器(注释了在安卓上好像没影响)
                // mouseCursorResolver:
                //     (FlTouchEvent event, LineTouchResponse? response) {
                //   if (response == null || response.lineBarSpots == null) {
                //     return SystemMouseCursors.basic;
                //   }
                //   return SystemMouseCursors.click;
                // },

                ///  获取触摸点的工具提示框(就是上面触摸反馈时，展示的内容工具提示框的样式)
                getTouchedSpotIndicator:
                    (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      const FlLine(color: Colors.pink),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          // 被选中展示了工具提示框的数据点的半径
                          radius: 5,
                          color: lerpGradient(
                            barData.gradient!.colors,
                            barData.gradient!.stops!,
                            percent / 100,
                          ),
                          // 折线上数据点的颜色，如果不那么较真跟着折线的渐变色显示，都统一纯色就好，简单。
                          // color: Colors.black,
                          strokeWidth: 2,
                          strokeColor: Colors.grey,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.pink,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                    return lineBarsSpot.map((lineBarSpot) {
                      return LineTooltipItem(
                        // 工具提示框中的数据可能太长，只取两位小数
                        lineBarSpot.y.toStringAsFixed(2),
                        TextStyle(
                          fontSize: CusFontSizes.itemSubContent,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              // 折线图的条数据
              lineBarsData: lineBarsData,
              // y轴最小值
              // minY: 0, // ？？？如果是体重的话，传入的数据的最小值减个三五千克，然后间隔单位小一点
              minY: (weightTrends
                          .reduce((currentWT, nextWT) =>
                              currentWT.weight < nextWT.weight
                                  ? currentWT
                                  : nextWT)
                          .weight)
                      .floor() -
                  3, // 最后的-3是避免最小的值就显示在最下面了，还是留点空隙
              // 标题数据
              titlesData: FlTitlesData(
                // 左侧标题
                leftTitles: AxisTitles(
                  // axisNameWidget: Text('体重(kg)'),
                  // axisNameSize: 24,
                  // sideTitles: SideTitles(showTitles: false, reservedSize: 0),
                  sideTitles: SideTitles(
                    showTitles: true,
                    // interval: 2, // ？？？间隔可以根据数量多少来,不设置就自动来
                    // interval: (maxWeight - minWeight) / 5,
                    getTitlesWidget: _leftTitles,
                    // 标题所需的最大空间（所有标题都将使用此值进行扩展）
                    reservedSize: 50,
                  ),
                ),
                // 底部标题(日期)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1, // ？？？间隔可以根据数量多少来
                    getTitlesWidget: bottomTitleWidgets,
                    reservedSize: 40,
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
              // 是否显示辅助线(默认是true)
              gridData: const FlGridData(show: true),
              // 图表的边框
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lerps between a [LinearGradient] colors, based on [t]
Color lerpGradient(List<Color> colors, List<double> stops, double t) {
  if (colors.isEmpty) {
    throw ArgumentError('"colors" is empty.');
  } else if (colors.length == 1) {
    return colors[0];
  }

  if (stops.length != colors.length) {
    stops = [];

    /// provided gradientColorStops is invalid and we calculate it here
    colors.asMap().forEach((index, color) {
      final percent = 1.0 / (colors.length - 1);
      stops.add(percent * index);
    });
  }

  for (var s = 0; s < stops.length - 1; s++) {
    final leftStop = stops[s];
    final rightStop = stops[s + 1];
    final leftColor = colors[s];
    final rightColor = colors[s + 1];
    if (t <= leftStop) {
      return leftColor;
    } else if (t < rightStop) {
      final sectionT = (t - leftStop) / (rightStop - leftStop);
      return Color.lerp(leftColor, rightColor, sectionT)!;
    }
  }
  return colors.last;
}

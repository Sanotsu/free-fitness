import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/user_state.dart';
import 'weight_change_line_chart.dart';
import 'weight_record_manage.dart';

// 取这个名字主要和标的基本类 weightTrend 全然区别开
class WeightChangeRecord extends StatefulWidget {
  final User userInfo;

  const WeightChangeRecord({super.key, required this.userInfo});

  @override
  State<WeightChangeRecord> createState() => _WeightChangeRecordState();
}

class _WeightChangeRecordState extends State<WeightChangeRecord> {
  final DBUserHelper _userHelper = DBUserHelper();

  double _currentWeight = 0;
  double _currentHeight = 0;

  late User user;

  // 查询数据的时候不显示图表
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      user = widget.userInfo;
      _currentWeight = user.currentWeight ?? 70;
      _currentHeight = user.height ?? 170;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CusAL.of(context).settingLabels('1')),
      ),
      body: ListView(
        children: [
          /// 体重趋势折线图区域
          /// 修改成功之后应该要重新刷新数据？？？

          Card(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CusAL.of(context).weightLabel(''),
                      style: TextStyle(
                        fontSize: CusFontSizes.flagMedium,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // 这里只显示修改体重
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WeightRecordManage(user: user),
                              ),
                            ).then(
                              (value) async {
                                // 强制重新加载体重变化图表
                                setState(() {
                                  isLoading = true;
                                });
                                var tempUser = (await _userHelper.queryUser(
                                  userId: CacheUser.userId,
                                ))!;

                                setState(() {
                                  user = tempUser;
                                  _currentWeight = user.currentWeight ?? 70;
                                  _currentHeight = user.height ?? 170;
                                  isLoading = false;
                                });
                              },
                            );
                          },
                          child: Text(CusAL.of(context).manageLabel),
                        ),
                        SizedBox(width: 10.sp),
                        ElevatedButton(
                          onPressed: () {
                            // 这里只显示修改体重
                            _buildModifyWeightOrBmiDialog(onlyWeight: true)
                                .then(
                              (value) async {
                                // 强制重新加载体重变化图表
                                setState(() {
                                  isLoading = true;
                                });
                                var tempUser = (await _userHelper.queryUser(
                                  userId: CacheUser.userId,
                                ))!;

                                setState(() {
                                  user = tempUser;
                                  _currentWeight = user.currentWeight ?? 70;
                                  _currentHeight = user.height ?? 170;
                                  isLoading = false;
                                });
                              },
                            );
                          },
                          child: Text(CusAL.of(context).recordLabel),
                        ),
                      ],
                    )
                  ],
                ),
                if (!isLoading) WeightChangeLineChart(user: user),
              ],
            ),
          ),

          /// BMI区域
          Center(
            child: Card(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "BMI",
                              style: TextStyle(
                                fontSize: CusFontSizes.flagMedium,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const TextSpan(
                              text: " (15 ~ 40)",
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // 这里要显示修改身高和体重
                          _buildModifyWeightOrBmiDialog(onlyWeight: false).then(
                            (value) async {
                              // 强制重新加载体重变化图表
                              setState(() {
                                isLoading = true;
                              });
                              var tempUser = (await _userHelper.queryUser(
                                userId: CacheUser.userId,
                              ))!;

                              setState(() {
                                user = tempUser;
                                _currentWeight = user.currentWeight ?? 70;
                                _currentHeight = user.height ?? 170;
                                isLoading = false;
                              });
                            },
                          );
                        },
                        child: Text(CusAL.of(context).recordLabel),
                      ),
                    ],
                  ),
                  _buildBmiArea(context),
                ],
              ),
            ),
          ),

          /// 占位的
          // SizedBox(
          //   height: 30,
          //   child: Row(
          //     children: [
          //       Expanded(child: Container(color: Colors.grey)),
          //       Expanded(child: Container(color: Colors.green)),
          //       Expanded(child: Container(color: Colors.blue)),
          //       Expanded(child: Container(color: Colors.yellow)),
          //       Expanded(child: Container(color: Colors.red)),
          //     ],
          //   ),
          // ),
          SizedBox(height: 20.sp),
        ],
      ),
    );
  }

  _buildBmiArea(BuildContext context) {
    // 存的是kg
    var tempWeight = user.currentWeight ?? 0;
    // 存的是cm，所以要/100
    var tempHeight = (user.height ?? 0) / 100;
    var bmi = (tempWeight / (tempHeight * tempHeight));

    /// 注意，这里的所有内容都是基于
    ///   BMI 范围: 偏瘦<=18.4;正常18.5~23.9;过重24.0~27.9;肥胖>=28.0
    ///   显示的长度15-40
    ///   对应矩形长度：0-300.sp
    ///   然后每个范围显示不同的颜色，指针也是使用padding进行偏移描点。
    /// 改一个，全都乱，尤其是flex
    /// 2023-12-18 几个区间用计算式
    var uwtFlex = ((18.4 - 15) / (40 - 15) * 300).toInt();
    var nwtFlex = ((23.9 - 18.4) / (40 - 15) * 300).toInt();
    var owtFlex = ((28 - 23.9) / (40 - 15) * 300).toInt();
    var fatFlex = ((35 - 28) / (40 - 15) * 300).toInt();
    var obesityFlex = ((40 - 35) / (40 - 15) * 300).toInt();

    return SizedBox(
      width: 320.sp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bmi.toStringAsFixed(2),
                style: TextStyle(fontSize: CusFontSizes.flagMedium),
              ),
              buildWeightBmiText(bmi, context),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: bmi < 15
                  ? 0
                  : bmi > 40
                      ? 300
                      : ((bmi - 15) / (40 - 15) * 300.sp),
            ),
            child: Icon(Icons.arrow_downward, size: CusIconSizes.iconNormal),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.sp),
            child: SizedBox(
              height: 30.sp,
              width: 300.sp,
              child: Row(
                children: [
                  Expanded(
                    flex: uwtFlex,
                    child: Container(
                      color: Colors.grey,
                      child: const Text("<18.4", textAlign: TextAlign.end),
                    ),
                  ),
                  Expanded(
                    flex: nwtFlex,
                    child: Container(
                      color: Colors.green,
                      child: const Text("<23.9", textAlign: TextAlign.end),
                    ),
                  ),
                  Expanded(
                    flex: owtFlex,
                    child: Container(
                      color: Colors.blue,
                      child: const Text("<28", textAlign: TextAlign.end),
                    ),
                  ),
                  Expanded(
                    flex: fatFlex,
                    child: Container(
                      color: Colors.yellow,
                      child: const Text("<35", textAlign: TextAlign.end),
                    ),
                  ),
                  Expanded(
                    flex: obesityFlex,
                    child: Container(
                      color: Colors.red,
                      child: const Text("<40", textAlign: TextAlign.end),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.sp),
            child: SizedBox(
              height: 30.sp,
              width: 300.sp,
              child: Row(
                children: [
                  Expanded(
                    flex: uwtFlex,
                    child: Text(CusAL.of(context).bmiLabels('0')),
                  ),
                  Expanded(
                    flex: nwtFlex,
                    child: Text(CusAL.of(context).bmiLabels('1')),
                  ),
                  Expanded(
                    flex: owtFlex,
                    child: Text(CusAL.of(context).bmiLabels('2')),
                  ),
                  Expanded(
                    flex: fatFlex,
                    child: Text(CusAL.of(context).bmiLabels('3')),
                  ),
                  Expanded(
                    flex: obesityFlex,
                    child: Text(CusAL.of(context).bmiLabels('4')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _buildModifyWeightOrBmiDialog({bool onlyWeight = true}) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: (onlyWeight ? 220.sp : 380.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Card(
                    child: Column(
                      children: [
                        Text(
                          CusAL.of(context).weightLabel('(kg)'),
                          style: TextStyle(fontSize: CusFontSizes.flagMedium),
                        ),
                        DecimalNumberPicker(
                          value: _currentWeight,
                          minValue: 10,
                          maxValue: 300,
                          decimalPlaces: 1,
                          itemHeight: 40,
                          onChanged: (value) =>
                              setState(() => _currentWeight = value),
                        ),
                      ],
                    ),
                  ),
                  if (!onlyWeight)
                    Card(
                      child: Column(
                        children: [
                          Text(
                            CusAL.of(context).weightLabel('(cm)'),
                            style: TextStyle(fontSize: CusFontSizes.flagMedium),
                          ),
                          DecimalNumberPicker(
                            value: _currentHeight,
                            minValue: 50,
                            maxValue: 240,
                            decimalPlaces: 1,
                            itemHeight: 40,
                            onChanged: (value) =>
                                setState(() => _currentHeight = value),
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        user.height = _currentHeight;
                        user.currentWeight = _currentWeight;
                      });

                      // ？？？这里应该判断是否修改成功
                      // 修改用户基本信息
                      await _userHelper.updateUser(user);

                      var bmi = _currentWeight /
                          (_currentHeight / 100 * _currentHeight / 100);

                      // 新增体重趋势信息
                      var temp = WeightTrend(
                        userId: CacheUser.userId,
                        weight: _currentWeight,
                        weightUnit: 'kg',
                        height: _currentHeight,
                        heightUnit: 'cm',
                        bmi: bmi,
                        // 日期随机，带上一个插入时的time
                        gmtCreate: getCurrentDateTime(),
                      );

                      try {
                        await _userHelper.insertWeightTrendList([temp]);
                        if (!context.mounted) return;
                        Navigator.of(context).pop(true);
                      } catch (e) {
                        if (!context.mounted) return;
                        commonExceptionDialog(
                          context,
                          CusAL.of(context).exceptionWarningTitle,
                          e.toString(),
                        );
                      }
                    },
                    child: Text(CusAL.of(context).saveLabel),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

buildWeightBmiText(double bmi, BuildContext context) {
  if (bmi < 18.4) {
    return Text(
      CusAL.of(context).bmiLabels("0"),
      style: TextStyle(color: Colors.grey, fontSize: CusFontSizes.itemTitle),
    );
  } else if (bmi < 23.9) {
    return Text(
      CusAL.of(context).bmiLabels("1"),
      style: TextStyle(color: Colors.green, fontSize: CusFontSizes.itemTitle),
    );
  } else if (bmi < 28) {
    return Text(
      CusAL.of(context).bmiLabels("2"),
      style: TextStyle(color: Colors.blue, fontSize: CusFontSizes.itemTitle),
    );
  } else if (bmi < 35) {
    return Text(
      CusAL.of(context).bmiLabels("3"),
      style: TextStyle(color: Colors.yellow, fontSize: CusFontSizes.itemTitle),
    );
  } else {
    return Text(
      CusAL.of(context).bmiLabels("4"),
      style: TextStyle(color: Colors.red, fontSize: CusFontSizes.itemTitle),
    );
  }
}

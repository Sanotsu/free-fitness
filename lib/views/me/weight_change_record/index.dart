// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/user_state.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tools.dart';
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
        title: const Text('WeightChangeRecord'),
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
                      "体重",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // 这里只显示修改体重
                            print("点击管理可以删除一些体重数据");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WeightRecordManage(user: user),
                              ),
                            ).then(
                              (value) async {
                                // 强制重新加载体重变化图表
                                setState(() {
                                  isLoading = true;
                                });
                                var tempUser =
                                    (await _userHelper.queryUser(userId: 1))!;

                                setState(() {
                                  user = tempUser;
                                  _currentWeight = user.currentWeight ?? 70;
                                  _currentHeight = user.height ?? 170;
                                  isLoading = false;
                                });
                              },
                            );
                          },
                          child: const Text("管理"),
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
                                var tempUser =
                                    (await _userHelper.queryUser(userId: 1))!;

                                setState(() {
                                  user = tempUser;
                                  _currentWeight = user.currentWeight ?? 70;
                                  _currentHeight = user.height ?? 170;
                                  isLoading = false;
                                });
                              },
                            );
                          },
                          child: const Text("记录"),
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
                      Text(
                        "BMI",
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
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
                              var tempUser =
                                  (await _userHelper.queryUser(userId: 1))!;

                              setState(() {
                                user = tempUser;
                                _currentWeight = user.currentWeight ?? 70;
                                _currentHeight = user.height ?? 170;
                                isLoading = false;
                              });
                            },
                          );
                        },
                        child: const Text("记录"),
                      ),
                    ],
                  ),
                  _buildBmiArea(),
                ],
              ),
            ),
          ),

          /// 占位的
          Container(
            width: 50,
            height: 30,
            color: Colors.grey, // 默认灰色

            child: Row(
              children: [
                Expanded(flex: 5, child: Container(color: Colors.grey)),
                Expanded(flex: 5, child: Container(color: Colors.green)),
                Expanded(flex: 5, child: Container(color: Colors.blue)),
                Expanded(flex: 5, child: Container(color: Colors.yellow)),
                Expanded(flex: 5, child: Container(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildBmiArea() {
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
                style: TextStyle(fontSize: 20.sp),
              ),
              buildWeightBmiText(bmi),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                left: bmi < 15
                    ? 0
                    : bmi > 40
                        ? 300
                        : (bmi - 15) / 40 * 300.sp),
            child: Icon(Icons.arrow_downward, size: 20.sp),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.sp),
            child: SizedBox(
              height: 30.sp,
              width: 300.sp,
              child: Row(
                children: [
                  Expanded(
                    flex: 41,
                    child: Container(
                      color: Colors.grey,
                      child: const Text("<18.4"),
                    ),
                  ),
                  Expanded(
                    flex: 60,
                    child: Container(
                      color: Colors.green,
                      child: const Text("<23.9"),
                    ),
                  ),
                  Expanded(
                    flex: 48,
                    child: Container(
                      color: Colors.blue,
                      child: const Text("<28"),
                    ),
                  ),
                  Expanded(
                    flex: 85,
                    child: Container(
                      color: Colors.yellow,
                      child: const Text("<35"),
                    ),
                  ),
                  Expanded(
                    flex: 60,
                    child: Container(
                      color: Colors.red,
                      child: const Text("<40"),
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
              child: const Row(
                children: [
                  Expanded(flex: 41, child: Text("偏瘦")),
                  Expanded(flex: 60, child: Text("正常")),
                  Expanded(flex: 48, child: Text("超重")),
                  Expanded(flex: 85, child: Text("肥胖")),
                  Expanded(flex: 60, child: Text("过胖")),
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
                        Text("体重(kg)", style: TextStyle(fontSize: 20.sp)),
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
                          Text("身高(cm)", style: TextStyle(fontSize: 20.sp)),
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
                        userId: 1,
                        weight: _currentWeight,
                        weightUnit: 'kg',
                        height: _currentHeight,
                        heightUnit: 'cm',
                        bmi: bmi,
                        // 日期随机，带上一个插入时的time
                        gmtCreate: getCurrentDateTime(),
                      );

                      // ？？？这里应该判断是否新增成功
                      await _userHelper.insertWeightTrendList([temp]);

                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: const Text('保存'),
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

buildWeightBmiText(double bmi) {
  if (bmi < 18.4) {
    return Text(
      "偏瘦",
      style: TextStyle(color: Colors.grey, fontSize: 20.sp),
    );
  } else if (bmi < 23.9) {
    return Text(
      "正常",
      style: TextStyle(color: Colors.green, fontSize: 20.sp),
    );
  } else if (bmi < 28) {
    return Text(
      "超重",
      style: TextStyle(color: Colors.blue, fontSize: 20.sp),
    );
  } else if (bmi < 35) {
    return Text(
      "肥胖",
      style: TextStyle(color: Colors.yellow, fontSize: 20.sp),
    );
  } else {
    return Text(
      "过胖",
      style: TextStyle(color: Colors.red, fontSize: 20.sp),
    );
  }
}

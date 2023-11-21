// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../models/training_state.dart';
import '../../../common/components/counter_widget.dart';

/// 弹出动作配置弹窗，并在关闭后直接回传修改后的action
void showConfigDialog(
  BuildContext context,
  ActionDetail ad,
  int index, // 修改了列表中的哪一条，在回传之后的回调函数中用于修改状态，在这个函数里没什么用
  // 回调函数传回被修改的action及修改后的配置内容
  Function(
    int index,
    ActionDetail adItem,
  ) onConfigurationDialogClosed,
) {
  // 默认动作配置最少20秒或者10次
  int timeInSeconds = ad.action.duration ?? 20;
  int count = ad.action.frequency ?? 10;
  double equipmentWeight = ad.action.equipmentWeight ?? 0;

  // 其他需要输入的例如器械重量、action名称、描述之类的
  final formKey = GlobalKey<FormBuilderState>();

  // 底部的保存按钮区域(固定在底部靠上10)
  Widget genBottomArea() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10.sp,
      child: Center(
        child: SizedBox(
          width: 0.8.sw,
          child: FloatingActionButton.extended(
            onPressed: () {
              // 点击保存按钮的逻辑
              print("点击了底部的保存按钮……");

              if (formKey.currentState!.saveAndValidate()) {
                var tempWeight = double.tryParse(
                  formKey.currentState?.fields['equipment_weight']?.value,
                );

                // 是个对象，直接修改(直接复制的浅拷贝没意义)
                ad.action.duration = timeInSeconds;
                ad.action.frequency = count;
                ad.action.equipmentWeight = tempWeight;

                print("表单的ad数据：修改后--- ${ad.action} ");

                Navigator.pop(context);

                // 调用回调函数并传递数据
                onConfigurationDialogClosed(index, ad);
              }
            },
            label: Text('保存', style: TextStyle(fontSize: 20.sp)),
          ),
        ),
      ),
    );
  }

  // 顶部的关闭按钮和重置按钮
  List<Widget> genTopArea() {
    // 关闭按钮
    return [
      Positioned(
        left: 20,
        top: 10,
        child: Text("动作配置弹窗", style: TextStyle(fontSize: 20.sp)),
      ),
      Positioned(
        right: 0,
        top: 0,
        // 不要重置按钮了，就关闭再打开就好
        child: IconButton(
          icon: Icon(Icons.close, size: 36.sp, color: Colors.blue),
          onPressed: () {
            // 在此处添加关闭按钮的点击处理逻辑
            print('关闭按钮被点击了');
            Navigator.of(context).pop();
          },
        ),
      ),
    ];
  }

  // 下面body中的构建计时器和计数器区域行
  Widget buildCountinfModeAre() {
    return Row(
      children: [
        if (ad.exercise.countingMode == countingOptions.first.value)
          Expanded(
            flex: 1,
            child: CounterWidget(
              isTimeMode: true,
              initialCount: timeInSeconds ~/ 10,
              onCountChanged: (newCount) {
                timeInSeconds = newCount * 10;
              },
            ),
          ),
        if (ad.exercise.countingMode == countingOptions.last.value)
          Expanded(
            flex: 1,
            child: CounterWidget(
              initialCount: count,
              onCountChanged: (newCount) {
                count = newCount;
              },
            ),
          ),
        Expanded(
          flex: 1,
          child: FormBuilder(
            key: formKey,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 30.sp),
                  child: FormBuilderTextField(
                    name: 'equipment_weight',
                    initialValue: equipmentWeight.toStringAsFixed(2),
                    decoration: InputDecoration(
                      labelText: '器械重量(kg)',
                      hintText: "无需器械则不填",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 1.0.sp,
                        ),
                      ),
                    ),
                    // 限制只能输入数字和1位小数
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}$'),
                      ),
                      FilteringTextInputFormatter.deny(
                        RegExp(r'^[0]{2,}'),
                      ),
                    ],
                    // 打开数字键盘
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

// 中间的配置区域和锻炼的概要介绍
  Widget genConfigBody() {
    return Positioned(
      left: 0,
      right: 0,
      top: 50,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 其他内容
            Container(
              padding: EdgeInsets.all(1.0.sp),
              height: MediaQuery.of(context).size.height * 0.8,
              child: ListView(
                children: [
                  Stack(
                    children: [
                      // 图片部分
                      Container(
                        height: 200.0,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(placeholderImageUrl),
                            // ？？？这个不好弄，暂时与屏幕宽度对其就好，不知道会不会变形或者超出
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 其他内容
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.sp),
                        child: buildCountinfModeAre(),
                      ),
                      // 下半部分标题、子标题和正文
                      Container(
                        height: 300.sp,
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.all(10.sp),
                          child: Container(
                            padding: EdgeInsets.only(bottom: 20.sp),
                            child: ListTile(
                              title: Text(
                                ad.exercise.exerciseName,
                                // 限制只显示一行，多的用省略号
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(fontSize: 20.sp),
                              ),
                              subtitle: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Text(
                                  ad.exercise.instructions ?? "",
                                  overflow: TextOverflow.clip, // 设置文字溢出时的处理方式
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 预留空白避免被下方的保存按钮挡住说明文字，显示不全
                      SizedBox(height: 60.sp)
                    ],
                  ),
                ],
              ),
            ), // 此处添加一个高度以便滑动
          ],
        ),
      ),
    );
  }

  print("ad.exercise.countingMode ${ad.action}");

  // 绘制弹窗
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      // 弹窗的整体高度占屏幕的8成
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 1.sp),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Stack(
          alignment: Alignment.topRight,
          children: <Widget>[
            /// 关闭按钮和重置按钮固定在弹窗顶部左上角和右上角
            ...genTopArea(),
            // 中间是配置的主体：图片、计数计时器、标题和描述
            genConfigBody(),
            // 底部的保存按钮
            genBottomArea(),

            /// 保存按钮固定在屏幕底部
          ],
        ),
      );
    },
  );
}

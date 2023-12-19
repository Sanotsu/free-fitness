// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../models/cus_app_localizations.dart';
import 'common_utils_for_food_modify.dart';

class FoodServingInfoModify extends StatefulWidget {
  // 一定会传单份食物营养素的分类(度量的metric 或者自定义的custom)
  final CusLabel servingType;

  // 新增食物添加了营养素确认之后返回到食物新增表单，但可以想要修改，又再点击来到营养素表单，会带上之前传上去的对象
  final Map<String, dynamic>? currentServingInfo;

  const FoodServingInfoModify({
    required this.servingType,
    this.currentServingInfo,
    super.key,
  });

  @override
  State<FoodServingInfoModify> createState() => _FoodServingInfoModifyState();
}

class _FoodServingInfoModifyState extends State<FoodServingInfoModify> {
  final _servingInfoformKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果有传表单的初始对象值，就显示该值
      if (widget.currentServingInfo != null) {
        setState(() {
          _servingInfoformKey.currentState
              ?.patchValue(widget.currentServingInfo!);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          CusAL.of(context).eidtLabel(CusAL.of(context).foodNutrientInfo),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(10.sp),
            child: SingleChildScrollView(
              child: FormBuilder(
                key: _servingInfoformKey,
                initialValue: widget.currentServingInfo != null
                    ? widget.currentServingInfo!
                    : {},
                child: buildServingModifyFormColumn(
                  context,
                  widget.servingType,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20.sp, right: 20.sp, top: 20.sp),
            child: ElevatedButton(
              onPressed: () {
                if (_servingInfoformKey.currentState!.saveAndValidate()) {
                  var temp = _servingInfoformKey.currentState?.value;
                  // 直接返回表单的值就好
                  Navigator.pop(context, temp);
                }
              },
              child: Text(CusAL.of(context).saveLabel),
            ),
          ),
        ],
      ),
    );
  }
}

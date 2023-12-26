// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/dietary_state.dart';
import 'common_utils_for_food_modify.dart';

/// 这个是在食物详情中，修改了某个食物单份营养素信息而已，简单传入单份营养素信息，然后修改即可
class DetailModifyServingInfo extends StatefulWidget {
  // 新增时一定会传单份食物营养素的分类(度量的metric 或者自定义的custom)
  // ？？？因为修改时 db表没有这个栏位，所以暂时不提供修改，以新增+删除代替修改
  final CusLabel servingType;
  // 方便看食物名称
  final Food food;

  // 修改时可能会带上已有的单份营养素信息，新增时则没有
  final ServingInfo? currentServingInfo;

  const DetailModifyServingInfo({
    required this.servingType,
    this.currentServingInfo,
    super.key,
    required this.food,
  });

  @override
  State<DetailModifyServingInfo> createState() =>
      _DetailModifyServingInfoState();
}

class _DetailModifyServingInfoState extends State<DetailModifyServingInfo> {
  final _servingInfoformKey = GlobalKey<FormBuilderState>();
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  ServingInfo? serving;

  // 新增前要转圈圈
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    /// todo 2023-12-05 暂时不提供修改，以新增+删除代替修改；所以先不管这个初始化值的设定了
    if (widget.currentServingInfo != null) {
      serving = widget.currentServingInfo;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果有传表单的初始对象值，就显示该值
      if (widget.currentServingInfo != null) {
        // 有其他类型可能无法给表单初始化赋值，全部转为string map就可以了
        var map = widget.currentServingInfo!.toStringMap();

        setState(() {
          _servingInfoformKey.currentState?.patchValue(map);
          // 如果修改时传入的是标准度量，则修改单位为ml或者g
          // 此时的值是100ml或者100g，删除前面的100即可(1g/1ml会被当做客制化的)
          if (widget.servingType.value == "metric") {
            _servingInfoformKey.currentState?.fields['serving_unit']
                ?.didChange((map["serving_unit"] as String).substring(3));
          }
        });
      }
    });
  }

  _modifyServingInfo() async {
    if (_servingInfoformKey.currentState!.saveAndValidate()) {
      // 营养素表单保存验证通过后，要先格式化成指定类型数据，再才能保持到db
      var servingList = parseServingInfo(
        _servingInfoformKey.currentState!.value,
        // 2023-12-19 修改都当做是非标准
        widget.servingType.value,
        foodId: widget.food.foodId,
        servingInfoId: (widget.currentServingInfo != null)
            ? widget.currentServingInfo!.servingInfoId!
            : null,
      );

      try {
        if (isLoading) return;

        setState(() {
          isLoading = true;
        });

        // 有传单份详情是修改，没有则是新增
        if (widget.currentServingInfo != null) {
          // 处理用户的输入表单的列表，如果是修改单份营养素信息，其列表第一个就是修改后的。
          var temp = servingList[0];
          temp.servingInfoId = widget.currentServingInfo!.servingInfoId!;
          _dietaryHelper.updateSingleServingInfo(temp);
        } else {
          await _dietaryHelper.insertFoodWithServingInfoList(
            servingInfoList: servingList,
          );
        }
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        Navigator.pop(context, true);
      } on Exception catch (e) {
        // 将错误信息展示给用户
        if (!mounted) return;
        commonExceptionDialog(
          context,
          CusAL.of(context).exceptionWarningTitle,
          e.toString(),
        );

        setState(() {
          isLoading = false;
        });
        return;
      }
    }
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
                child: buildServingModifyFormColumn(
                  context,
                  widget.servingType,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text(CusAL.of(context).cancelLabel),
                  ),
                ),
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: _modifyServingInfo,
                    child: Text(CusAL.of(context).saveLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

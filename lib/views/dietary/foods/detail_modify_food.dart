// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:free_fitness/common/utils/tools.dart';
import 'package:sqflite/sqflite.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/dietary_state.dart';
import 'common_utils_for_food_modify.dart';

// 新增的时候用旧的food_modify和food_serving_info_modify_form。
// 而在食物成分的详情页面进行修改时，是食物基本信息和指定单份营养素分开修改，所以有_base关键字
class DetailModifyFood extends StatefulWidget {
  // 专门在食物详情中修改食物基本信息
  final Food food;

  const DetailModifyFood({super.key, required this.food});

  @override
  State<DetailModifyFood> createState() => _DetailModifyFoodState();
}

class _DetailModifyFoodState extends State<DetailModifyFood> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

//  食物添加的表单key
  final _foodFormKey = GlobalKey<FormBuilderState>();

  // 默认显示的图片列表
  List<PlatformFile>? initImages;

  @override
  void initState() {
    super.initState();

    // 如果有食物有图片，则显示图片(不能放在下面那个callback中，会在表单初始化完成之后再赋值，那就没有意义了)
    setState(() {
      if (widget.food.photos != null && widget.food.photos != "") {
        initImages = convertStringToPlatformFiles(widget.food.photos!);
      }
    });

    // 这是在表单初始化之后再赋值给栏位
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果有传表单的初始对象值，就显示该值
      setState(() {
        _foodFormKey.currentState?.patchValue(widget.food.toMap());
      });
    });
  }

  _updateFoodInfo() async {
    if (_foodFormKey.currentState!.saveAndValidate()) {
      var temp = _foodFormKey.currentState?.value;
      var food = Food(
        foodId: widget.food.foodId,
        brand: temp?["brand"],
        product: temp?["product"],
        description: temp?["description"],
        tags: temp?["tags"],
        category: temp?["category"],
        photos: temp?["images"] != null
            ? (temp?["images"] as List<PlatformFile>)
                .map((e) => e.path)
                .toList()
                .join(",")
            : null,
        contributor: CacheUser.userName,
        gmtCreate: getCurrentDateTime(),
        isDeleted: false,
      );

      try {
        int ret = await _dietaryHelper.updateFood(food);
        // 修改成功
        if (ret > 0) {
          if (!mounted) return;
          // 父组件要直接修改当前的食物基本信息，所以返回是否新增成功的bool
          Navigator.pop(context, true);
        }
      } catch (e) {
        // 或者显示一个SnackBar
        var errorMessage = "数据插入数据库失败,可能该产品已存在";

        if (!mounted) return;
        if (e is DatabaseException) {
          /// 它默认有判断是否是哪种错误，常见的唯一值重复还可以指定检查哪个栏位重复。
          if (e.isUniqueConstraintError()) {
            // errorMessage = '该【食物品牌】+【产品名称】已存在！';
            errorMessage = CusAL.of(context).uniqueErrorText(
              "${CusAL.of(context).foodLabels('0')}(${CusAL.of(context).foodLabels('1')})",
            );
          }
        }

        // 在底部显示错误信息
        if (!mounted) return;
        showErrorMessage(context, errorMessage);
      }
    } else {
      if (!mounted) return;
      showErrorMessage(context, CusAL.of(context).invalidFormErrorText);
    }
  }

  void showErrorMessage(BuildContext context, String errorMessage) {
    var snackBar = SnackBar(
      content: Text(errorMessage),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          CusAL.of(context).eidtLabel(CusAL.of(context).foodBasicInfo),
        ),
      ),
      body: _buildFoodForm(),
    );
  }

  _buildFoodForm() {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(10.sp),
          child: SingleChildScrollView(
            child: FormBuilder(
              key: _foodFormKey,
              child: Column(
                children: [
                  ...buildFoodModifyFormColumns(
                    context,
                    initImages: initImages,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 20.sp, right: 20.sp, top: 20.sp),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              // 两个按钮之间的占位空白
              const Expanded(flex: 1, child: SizedBox()),
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  onPressed: _updateFoodInfo,
                  child: Text(CusAL.of(context).saveLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

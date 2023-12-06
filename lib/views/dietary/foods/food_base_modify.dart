// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:free_fitness/common/utils/tools.dart';
import 'package:sqflite/sqflite.dart';

import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/dietary_state.dart';

// 新增的时候用旧的food_modify和food_serving_info_modify_form。
// 而在食物成分的详情页面进行修改时，是食物基本信息和指定单份营养素分开修改，所以有_base关键字
class FoodBaseModify extends StatefulWidget {
  // 专门在食物详情中修改食物基本信息
  final Food food;

  const FoodBaseModify({super.key, required this.food});

  @override
  State<FoodBaseModify> createState() => _FoodBaseModifyState();
}

class _FoodBaseModifyState extends State<FoodBaseModify> {
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

  _addFoodAndServingList() async {
    if (_foodFormKey.currentState!.saveAndValidate()) {
      var temp = _foodFormKey.currentState?.value;
      var food = Food(
        foodId: widget.food.foodId,
        brand: temp?["brand"],
        product: temp?["product"],
        tags: temp?["tags"],
        category: temp?["category"],
        photos: temp?["images"] != null
            ? (temp?["images"] as List<PlatformFile>)
                .map((e) => e.path)
                .toList()
                .join(",")
            : "",
        contributor: '1', // 全局存放的用不编号？？？后续要改为int类型
        gmtCreate: getCurrentDateTime(),
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

        if (e is DatabaseException) {
          /// 它默认有判断是否是哪种错误，常见的唯一值重复还可以指定检查哪个栏位重复。
          if (e.isUniqueConstraintError()) {
            errorMessage = '该【食物品牌】+【产品名称】已存在！';
          }
        }

        // 在底部显示错误信息
        if (!mounted) return;
        showErrorMessage(context, errorMessage);
      }
    } else {
      if (!mounted) return;
      showErrorMessage(context, "表单验证未通过！");
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
        title: const Text('食物基本信息修改'),
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
                    // 食物的品牌和产品名称(没有对应数据库，没法更人性化的筛选，都是用户输入)
                    cusFormBuilerTextField(
                      "brand",
                      labelText: '*食物品牌',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '品牌不可为空'),
                      ]),
                    ),
                    cusFormBuilerTextField(
                      "product",
                      labelText: '*产品名称',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '名称不可为空'),
                      ]),
                    ),
                    cusFormBuilerTextField("tags", labelText: '标签'),
                    cusFormBuilerTextField("category", labelText: '分类'),

                    const SizedBox(height: 10),
                    // 上传活动示例图片（静态图或者gif）
                    FormBuilderFilePicker(
                      name: 'images',
                      decoration: const InputDecoration(labelText: '演示图片'),
                      initialValue: initImages,
                      maxFiles: null,
                      allowMultiple: true,
                      previewImages: true,
                      onChanged: (val) => debugPrint(val.toString()),
                      typeSelectors: const [
                        TypeSelector(
                          type: FileType.image,
                          selector: Row(
                            children: <Widget>[
                              Icon(Icons.file_upload),
                              Text('图片上传'),
                            ],
                          ),
                        )
                      ],
                      customTypeViewerBuilder: (children) => Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: children,
                      ),
                      onFileLoading: (val) {
                        debugPrint(val.toString());
                      },
                    ),
                  ],
                )),
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
                  child: const Text("取消"),
                ),
              ),
              // 两个按钮之间的占位空白
              const Expanded(flex: 1, child: SizedBox()),
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  onPressed: _addFoodAndServingList,
                  child: const Text("确定"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

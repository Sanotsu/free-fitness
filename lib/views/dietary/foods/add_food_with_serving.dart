import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:free_fitness/common/utils/tools.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/dietary_state.dart';
import 'add_food_serving_info.dart';
import 'common_utils_for_food_modify.dart';

// 目前这个是食物新增时使用，新增时会同时至少新增一条单份食物营养素信息(add_food_serving_info)。
// 而食物某一单份营养素信息的修改可以在食物详情找到修改(新增+删除)入口
class AddfoodWithServing extends StatefulWidget {
  const AddfoodWithServing({super.key});

  @override
  State<AddfoodWithServing> createState() => _AddfoodWithServingState();
}

class _AddfoodWithServingState extends State<AddfoodWithServing> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

//  食物添加的表单key
  final _foodFormKey = GlobalKey<FormBuilderState>();
  // 要添加的食物信息和单份营养素信息
  late Food inputFood;
  List<ServingInfo> inputServingInfos = [];

  // 当前选中的单份食物营养素类型
  late CusLabel servingType;

  // 如果是有进入了营养素表单并且填了值返回，则保存该表单的值
  Map<String, dynamic>? tempServingFormData;
  // 上一个map的属性是数据库的栏位，还包含只为null的属性，这个是用于格式化展示的变量，更加可读
  var formattedTempServingFormData = "";

  // 新增前要转圈圈
  bool isLoading = false;

  /// 食物和单份营养素存入数据库
  _addFoodAndServingList() async {
    var flag = _foodFormKey.currentState!.saveAndValidate();

    if (flag && inputServingInfos.isNotEmpty) {
      // 构建食物基本信息
      var temp = _foodFormKey.currentState?.value;
      var food = Food(
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
        if (isLoading) return;

        setState(() {
          isLoading = true;
        });

        await _dietaryHelper.insertFoodWithServingInfoList(
          food: food,
          servingInfoList: inputServingInfos,
        );

        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        // 父组件应该重新加载(传参到父组件中重新加载)
        Navigator.pop(context, true);
      } catch (e) {
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
    } else if (inputServingInfos.isEmpty) {
      if (!mounted) return;
      showErrorMessage(context, "无单份营养素信息");
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

  _formatTempServingFormDate() {
    // 在完成添加/修改单份营养素详情的表单之后，点击保存会把填入的营养素信息传回食物修改页面。
    // 为了更加可视化这些用户填入的营养素，需要对其进行一些格式化之后显示文本

    if (tempServingFormData != null) {
      var filteredData = Map.fromEntries(tempServingFormData!.entries
          .where((entry) => entry.value != null)
          .map((entry) => entry));

      var tempList = [];

      filteredData.forEach((key, value) {
        // 找到该属性对应的中文
        var temp = nutrientList.where((e) => e.value == key).toList();

        if (temp.isNotEmpty) {
          tempList.add('${showCusLableMapLabel(context, temp[0])}:$value');
        }
      });

      setState(() {
        formattedTempServingFormData = tempList.join(", ");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CusAL.of(context).addLabel(CusAL.of(context).food)),
      ),
      body: _buildFoodForm(),
    );
  }

  _buildFoodForm() {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(5.sp),
          child: SingleChildScrollView(
            child: FormBuilder(
                key: _foodFormKey,
                child: Column(
                  children: [
                    // 食物的品牌和产品名称(没有对应数据库，没法更人性化的筛选，都是用户输入)
                    ...buildFoodModifyFormColumns(context),
                    // 单份营养素类型
                    _buildServingTypeRadio(),
                    // 单份营养素数据简单显示
                    Text(
                      formattedTempServingFormData,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
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
                  child: Text(CusAL.of(context).backLabel),
                ),
              ),
              // 两个按钮之间的占位空白
              const Expanded(flex: 1, child: SizedBox()),
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  onPressed: _addFoodAndServingList,
                  child: Text(CusAL.of(context).addLabel("")),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建单份营养素的类型单选框
  _buildServingTypeRadio() {
    return FormBuilderRadioGroup(
      decoration: InputDecoration(
        labelText: CusAL.of(context).nutrientLabel,
        // 设置透明底色
        filled: true,
        fillColor: Colors.transparent,
      ),
      name: 'serving_info_type',
      validator: FormBuilderValidators.required(),
      options: servingTypeList
          .map(
            (servingType) => FormBuilderFieldOption(
              value: showCusLableMapLabel(context, servingType),

              // 当点击被选中的单选框的文本时，弹出的营养素表单才带有之前返回的数据
              // 单选框值变化后的弹窗，则是全新的表单
              child: GestureDetector(
                onTap: () {
                  final currentValue = _foodFormKey
                      .currentState?.fields['serving_info_type']?.value;

                  if (currentValue ==
                      showCusLableMapLabel(context, servingType)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodServingInfoModify(
                          servingType: servingType,
                          currentServingInfo: tempServingFormData,
                        ),
                      ),
                    ).then(_handleServingFormCallback);
                  }
                },
                child: Text(showCusLableMapLabel(context, servingType)),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        setState(() {
          // 有切换单份类型之后，先要把存的之前的单份营养素信息清空
          tempServingFormData = null;
          inputServingInfos = [];
          servingType = servingTypeList.firstWhere(
            (e) => showCusLableMapLabel(context, e) == value,
          );
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodServingInfoModify(
              servingType: servingType,
            ),
          ),
        ).then(_handleServingFormCallback);
      },
    );
  }

  // 单份营养素详情页面返回后的处理逻辑
  _handleServingFormCallback(value) {
    // 从编辑单份营养素详情回来不要聚焦输入框
    unfocusHandle();

    if (value != null) {
      // 此页面是新增食物带营养素，所以没有食物信息
      var servingList = parseServingInfo(
        value,
        servingType.value,
      );

      setState(() {
        // 把单份营养素表单页面返回的数据全局保存，方便格式化显示
        tempServingFormData = value;
        // 把格式化后的单份营养素列表也保存到全局，方便存入db时使用
        inputServingInfos = servingList;
      });
      _formatTempServingFormDate();
    } else {
      // 如果是空返回，则还是要清空旧的格式化数据
      setState(() {
        formattedTempServingFormData = "";
      });
    }
  }
}

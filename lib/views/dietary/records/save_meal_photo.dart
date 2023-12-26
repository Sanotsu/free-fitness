// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/global/constants.dart';
import '../../../common/utils/db_dietary_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/dietary_state.dart';

class SaveMealPhotos extends StatefulWidget {
// 需要传入餐次和对应餐次的饮食条目，方便展示
  final CusLabel mealtime;
  final List<DailyFoodItemWithFoodServing> mealItems;
  // 如果是修改，则会带上之前实例的照片；没有则是新增没有旧照片(也是用这个判断是新增还是修改)
  final MealPhoto? mealPhoto;

  const SaveMealPhotos({
    super.key,
    required this.mealtime,
    required this.mealItems,
    this.mealPhoto,
  });

  @override
  State<SaveMealPhotos> createState() => _SaveMealPhotosState();
}

class _SaveMealPhotosState extends State<SaveMealPhotos> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

  final _formKey = GlobalKey<FormBuilderState>();

  late List<DailyFoodItemWithFoodServing> items;

  // 默认显示的图片列表
  List<PlatformFile>? initImages;

  List<String> imagesUrls = [];

  bool isLoading = false;

  // 默认是预览照片，没有照片是就为空
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      items = widget.mealItems;

      // 如果有照片，则先显示照片
      if (widget.mealPhoto != null) {
        String paths = widget.mealPhoto!.photos;

        initImages = convertStringToPlatformFiles(paths);
        // 先排除照片路径是空字符串，再分割
        if (paths.trim().isNotEmpty) {
          imagesUrls = paths.trim().split(",");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 最上面图片走马灯，下面餐次item信息，action是保存和取消/返回按钮
    return Scaffold(
      appBar: AppBar(
        title: Text(CusAL.of(context).mealPhotos),
        actions: [
          if (!isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  isEditing = !isEditing;
                });
              },
              icon: const Icon(Icons.edit),
            ),
          if (isEditing)
            IconButton(
              onPressed: () async {
                if (isLoading) return;
                setState(() {
                  isLoading = true;
                });

                // 如果有传照片过来，那一定是修改已存在的；没有传照片的才是新增。
                if (_formKey.currentState!.saveAndValidate()) {
                  var temp = _formKey.currentState?.fields['images']?.value;

                  var photos =
                      (temp != null && temp != "" && temp.toString() != "[]")
                          ? (temp as List<PlatformFile>)
                              .map((e) => e.path)
                              .toList()
                              .join(",")
                          : '';

                  var tempMp = MealPhoto(
                    date: getCurrentDate(),
                    mealCategory: widget.mealtime.enLabel,
                    photos: photos,
                    gmtCreate: getCurrentDateTime(),
                    userId: CacheUser.userId,
                  );

                  try {
                    // 如果有照片，则是修改
                    if (widget.mealPhoto != null) {
                      tempMp.mealPhotoId = widget.mealPhoto!.mealPhotoId!;

                      // 如果有传照片，但现在没有照片了，就是删除该条记录；否则就是修改
                      if (photos.trim().isEmpty || photos.split(",").isEmpty) {
                        await _dietaryHelper.deleteMealPhotoById(
                          tempMp.mealPhotoId!,
                        );
                      } else {
                        await _dietaryHelper.updateMealPhoto(tempMp);
                      }
                    } else {
                      // 没有传数据，则是新增，没有选择任何图片也算新增，反正下一次还为空就一定删除了
                      await _dietaryHelper.insertMealPhoto(tempMp);
                    }

                    if (!mounted) return;
                    setState(() {
                      isLoading = false;
                      isEditing = !isEditing;
                      imagesUrls =
                          photos.trim().isEmpty ? [] : photos.split(",");
                    });
                    // 父组件应该重新加载(传参到父组件中重新加载)
                    // 强行返回前一页为了加载新数据，不返回的话这里轮播图是删除修改之前的
                    // Navigator.pop(context, true);
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
                      isEditing = !isEditing;
                      imagesUrls =
                          photos.trim().isEmpty ? [] : photos.split(",");
                    });
                    return;
                  }
                }
              },
              icon: const Icon(Icons.save),
            )
        ],
      ),
      body: Column(
        children: [
          if (imagesUrls.isNotEmpty && !isEditing)
            buildImageCarouselSlider(imagesUrls),
          const SizedBox(height: 10),
          // 上传活动示例图片（静态图或者gif）
          if (isEditing)
            FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.sp),
                    child: FormBuilderFilePicker(
                      name: 'images',
                      initialValue: initImages,
                      maxFiles: null,
                      allowMultiple: true,
                      previewImages: true,
                      // onChanged: (val) =>
                      //     debugPrint("onChanged ${val.toString()}"),
                      // onSaved: (val) => debugPrint("onsave ${val.toString()}"),
                      typeSelectors: [
                        TypeSelector(
                          type: FileType.image,
                          selector: Row(
                            children: <Widget>[
                              const Icon(Icons.file_upload),
                              Text(CusAL.of(context).imageUploadLabel),
                            ],
                          ),
                        )
                      ],
                      customTypeViewerBuilder: (children) => Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: children,
                      ),
                      // onFileLoading: (val) {
                      //   debugPrint("onFileLoading ${val.toString()}");
                      // },
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 10.sp),

          Text(
            showCusLableMapLabel(context, widget.mealtime),
            style: TextStyle(fontSize: CusFontSizes.flagMedium),
          ),

          // 预览已有的图片
          ListView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                var food = items[index].food;
                var log = items[index].dailyFoodItem;
                var serving = items[index].servingInfo;
                // 摄入量
                var intake =
                    "${log.foodIntakeSize.toStringAsFixed(2)} x ${serving.servingUnit} ";

                // 能量用卡路里
                var calories =
                    (log.foodIntakeSize * serving.energy / oneCalToKjRatio)
                        .toStringAsFixed(2);

                return ListTile(
                  title: Text("${food.product} (${food.brand})"),
                  subtitle: Text(
                    "$intake - $calories ${CusAL.of(context).calorieLabels('2')}",
                  ),
                );
              }),
        ],
      ),
    );
  }
}

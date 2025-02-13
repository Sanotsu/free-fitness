import 'dart:io';

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
import 'ai_suggestion/ai_suggestion_page.dart';

class SaveMealPhotos extends StatefulWidget {
  // 2023-12-31 还需要传是为哪一天的餐次添加照片
  final String date;
  // 需要传入餐次和对应餐次的饮食条目，方便展示
  final CusLabel mealtime;
  final List<DailyFoodItemWithFoodServing> mealItems;

  // 如果是修改，则会带上之前实例的照片；没有则是新增没有旧照片(也是用这个判断是新增还是修改)
  final MealPhoto? mealPhoto;

  const SaveMealPhotos({
    super.key,
    required this.date,
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

  // 传入的餐次条目不会改变，这个变量只是为了减少 widget.mealItems 的使用
  late List<DailyFoodItemWithFoodServing> items;

  // 2024-12-02 因为传入餐次的饮食记录和图片，在这里虽然不能改变餐次条目，但可以改变图片
  // 如果改过图片，再次修改，没有使用更新后的餐次记录，还是传入时的记录，数据就会出错
  late MealPhoto? inputPhotos;

  // 默认显示的图片列表(输入框展示的)
  List<PlatformFile>? initImages;

  // 用于显示的图片 地址(和上面两者类型不一样)
  List<String> imagesUrls = [];

  bool isLoading = false;

  // 默认是预览照片，没有照片是就为空
  bool isEditing = false;

  @override
  void initState() {
    super.initState();

    items = widget.mealItems;
    inputPhotos = widget.mealPhoto;

    getImageByPhotos();
  }

  getImageByPhotos() {
    // 如果有照片，则先显示照片
    if (inputPhotos != null) {
      String paths = inputPhotos!.photos;

      initImages = convertStringToPlatformFiles(paths);
      // 先排除照片路径是空字符串，再分割
      if (paths.trim().isNotEmpty) {
        imagesUrls = paths.trim().split(",");
      }
    } else {
      initImages = [];
      imagesUrls = [];
    }
  }

  // 2024-12-02 因为存在删除餐次图片的情况，所以删除之后再新增，图片编号就变了。
  // 删除之后、新增了，再修改，就要用新的编号了
  rebuildMealPhoto() async {
    List<MealPhoto> temp = await _dietaryHelper.queryMealPhotoList(
      CacheUser.userId, // userId是必传的
      startDate: widget.date,
      endDate: widget.date,
      mealCategory: widget.mealtime.enLabel,
    );

    if (!mounted) return;
    setState(() {
      inputPhotos = null;
      for (var e in temp) {
        if (e.mealCategory == widget.mealtime.enLabel) {
          inputPhotos = e;
        }
      }
    });

    getImageByPhotos();
  }

  @override
  Widget build(BuildContext context) {
    // 最上面图片走马灯，下面餐次item信息，action是保存和取消/返回按钮
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            children: [
              TextSpan(
                text: CusAL.of(context).mealPhotos,
                style: TextStyle(
                  fontSize: CusFontSizes.pageTitle,
                ),
              ),
              TextSpan(
                text: "\n${widget.date}",
                style: TextStyle(
                  fontSize: CusFontSizes.pageAppendix,
                ),
              ),
            ],
          ),
        ),
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

                  // 用于存入数据库的图片地址
                  List<String> photoStrs = [];
                  // 用于去重的文件名列表
                  List<String> fileNames = [];
                  if (temp != null && temp != "" && temp.toString() != "[]") {
                    // 餐次图片上传，放到设备外部存储固定位置
                    if (!await MEAL_PHOTO_DIR.exists()) {
                      await MEAL_PHOTO_DIR.create(recursive: true);
                    }

                    // 把上传的文件都异动到指定的位置去
                    // 2024-07-12 注意，暂时不考虑餐次图片被删除的情况
                    for (var e in (temp as List<PlatformFile>)) {
                      final file = File(e.path!);

                      var filename = file.path.split('/').last;

                      // 2024-07-12？？？注意，这里同名的图片，简单去重
                      if (!fileNames.contains(filename)) {
                        fileNames.add(filename);
                      } else {
                        continue;
                      }
                      // 将上传的文件放到设备外部存储，避免冲突，文件重命名加上时间戳
                      final targetPath =
                          '${MEAL_PHOTO_DIR.path}/${DateTime.now().millisecondsSinceEpoch}-$filename';

                      await file.copy(targetPath);
                      photoStrs.add(targetPath);
                    }
                  }

                  // 餐食相册地址数组字符串
                  var photos = photoStrs.join(",");

                  var tempMp = MealPhoto(
                    date: widget.date,
                    mealCategory: widget.mealtime.enLabel,
                    photos: photos,
                    gmtCreate: getCurrentDateTime(),
                    userId: CacheUser.userId,
                  );

                  try {
                    // 如果有照片，则是修改
                    if (inputPhotos != null) {
                      tempMp.mealPhotoId = inputPhotos!.mealPhotoId!;

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

                    // 父组件应该重新加载(传参到父组件中重新加载)
                    // 强行返回前一页为了加载新数据，不返回的话这里轮播图是删除修改之前的
                    // Navigator.pop(context, true);
                  } catch (e) {
                    // 将错误信息展示给用户
                    if (!context.mounted) return;
                    commonExceptionDialog(
                      context,
                      CusAL.of(context).exceptionWarningTitle,
                      e.toString(),
                    );
                  } finally {
                    setState(() {
                      isLoading = false;
                      isEditing = !isEditing;

                      // 2024-12-02 新增或删除了餐次图片后，更新当前的餐次相关图片信息
                      rebuildMealPhoto();
                    });
                  }
                }
              },
              icon: const Icon(Icons.save),
            )
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10.sp),
          if (imagesUrls.isNotEmpty && !isEditing)
            buildImageCarouselSlider(imagesUrls),
          SizedBox(height: 10.sp),
          // 上传活动示例图片（静态图或者gif）
          if (isEditing)
            FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(5.sp),
                    child: FormBuilderFilePicker(
                      name: 'images',
                      initialValue: initImages,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (imagesUrls.isNotEmpty && !isEditing) {
            handleImageAnalysis(context, imagesUrls);
          } else {
            commonExceptionDialog(
              context,
              box.read('language') == "en" ? "Tips" : "温馨提示",
              box.read('language') == "en"
                  ? """There is no food intake information available for this day and no need for the AI assistant to give analytical advice."""
                  : "本日暂无食物摄入信息，无须AI助手给出分析建议。",
            );
          }
        },
        tooltip: box.read('language') == "en" ? "AI Assistant" : 'AI分析对话助手',
        child: const Icon(Icons.chat),
      ),
    );
  }
}

/// 2024-07-12 这两个函数在 meal_photo_gallery 也会用到
// 提示即将用于AI分析的图片信息
void handleImageAnalysis(BuildContext context, List<String> imagesUrls) {
  if (imagesUrls.length > 1) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(box.read('language') == "en" ? "Tips" : "温馨提示"),
          content: Text(
            box.read('language') == "en"
                ? """Currently, only a single image with a size no larger than 1024*1024 is supported for analysis.
                \nIf there are more than one meal image, only the first image will be used for analysis.
                """
                : "目前仅支持单张、且尺寸不大于1024*1024的图片进行分析。如果餐次图片大于1张，仅会使用第一张图片进行分析",
            style: TextStyle(fontSize: 15.sp),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(box.read('language') == "en" ? "confirm" : "确定"),
            ),
          ],
        );
      },
    ).then((value) {
      if (!context.mounted) return;
      navigateToOneChatScreen(context, imagesUrls.first);
    });
  } else {
    navigateToOneChatScreen(context, imagesUrls.first);
  }
}

// 跳转到AI问答页面
void navigateToOneChatScreen(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => OneChatScreen(
        intakeInfo: box.read('language') == "en"
            ? """Please analyze the given pictures and answer each of the following questions.
         \n\n - Please list the foods in the pictures and estimate the number of servings (in grams) of each food. If the food items are not present, answer truthfully; 
         \n\n - Analyze the nutritional composition of the meal in the picture, whether it is reasonably balanced and healthy;.
         \n\n - Optimize the proportions of the food provided in the picture to achieve nutritional balance."""
            : """请分析给出的图片，分别回答以下问题:
         \n\n - 请列出图片中的食物，并预估每种食物的份量(单位：克)。如果不存在食物，请如实回答;
         \n\n - 分析图中这顿饭的营养搭配，是否合理均衡，是否健康;
         \n\n - 优化图片提供食物的比例，达到营养均衡。""",
        imageUrl: imageUrl,
      ),
    ),
  );
}

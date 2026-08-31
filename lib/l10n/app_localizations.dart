import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Fitness'**
  String get appTitle;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get report;

  /// 主要营养素标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Energy} 1{Calorie} 2{Protein} 3{Fat} 4{CHO} 5{RDI} other{Other} }'**
  String mainNutrients(String num);

  /// 脂肪相关营养素标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{TotalFat} 1{SaturatedFat} 2{TransFat} 3{puFat} 4{muFat} other{Other} }'**
  String fatNutrients(String num);

  /// 碳水相关营养素标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{TotalCHO} 1{Sugar} 2{DietaryFiber} other{Other} }'**
  String choNutrients(String num);

  /// 微量元素相关营养素标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Sodium} 1{Potassium} 2{Cholesterol} other{Other} }'**
  String microNutrients(String num);

  /// 各种单位
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{g} 1{mg} 2{kcal} 3{kj} 4{cm} 5{kg} 6{s} 7{time(s)} 8{minutes} other{Other} }'**
  String unitLabels(String num);

  /// 是否真假各种标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Yes} 1{No} 2{True} 3{False} other{Other} }'**
  String boolLabels(String num);

  /// No description provided for @averageGoal.
  ///
  /// In en, this message translates to:
  /// **'Nutrient Goals'**
  String get averageGoal;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get dailyGoal;

  /// No description provided for @dailyGoalBars.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals Chart'**
  String get dailyGoalBars;

  /// 各个模块主页appbar的标题文字
  ///
  /// In en, this message translates to:
  /// **'{ titles, select, 0{Training} 1{Dietary} 2{Daily Calendar} 3{User & Settings} other{Other} }'**
  String moduleTitles(String titles);

  /// 用户设置页面切换头像需要的几个标签
  ///
  /// In en, this message translates to:
  /// **'{ num, select, 0{Change Avatar} 1{Options} 2{Camera} 3{Gallery} other{Other} }'**
  String changeAvatarLabels(String num);

  /// 用户与设置页面的备份与恢复的标签
  ///
  /// In en, this message translates to:
  /// **'{ num, select, 0{Backup & Restore} 1{Full Backup} 2{Merge Restore}  other{Other} }'**
  String bakLabels(String num);

  /// No description provided for @bakOpNote.
  ///
  /// In en, this message translates to:
  /// **'Confirm exporting all data?'**
  String get bakOpNote;

  /// No description provided for @bakSuccessNote.
  ///
  /// In en, this message translates to:
  /// **'Has been saved to {dir}.'**
  String bakSuccessNote(Object dir);

  /// No description provided for @resSuccessNote.
  ///
  /// In en, this message translates to:
  /// **'Backup data has been merged into the device.'**
  String get resSuccessNote;

  /// No description provided for @restIntervals.
  ///
  /// In en, this message translates to:
  /// **'Rest time between follow-up exercises (s)'**
  String get restIntervals;

  /// No description provided for @chooseSeconds.
  ///
  /// In en, this message translates to:
  /// **'Choose a duration(s)'**
  String get chooseSeconds;

  /// bmi的几个标签
  ///
  /// In en, this message translates to:
  /// **'{ num, select, 0{UWT} 1{NWT} 2{OWT} 3{Fat} 4{Obesity} other{Other} }'**
  String bmiLabels(String num);

  /// No description provided for @weightRecord.
  ///
  /// In en, this message translates to:
  /// **'Weight Record'**
  String get weightRecord;

  /// 用户设置目标的栏位
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{UserName} 1{UserCode} 2{Gender} 3{DateOfBirth} 4{Height} 5{Weight} 6{Description} other{Other} }'**
  String userInfoLabels(String num);

  /// No description provided for @userGoalLabels.
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{RDA} 1{RestIntervals} other{Other} }'**
  String userGoalLabels(String num);

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @trainingReports.
  ///
  /// In en, this message translates to:
  /// **'Training Reports'**
  String get trainingReports;

  /// No description provided for @trainingReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reports management'**
  String get trainingReportsSubtitle;

  /// 训练记录报告的标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Total Workouts} 1{Trained Time} 2{Rest Time} 3{Paused Time} 4{Total (minutes)} 5{LastTrained} 6{Date} 7{Name} 8{Duration} other{其他} }'**
  String trainedReportLabels(String num);

  /// 训练记录报告日历展示的标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Start Time} 1{End Time} 2{Trained Duration} 3{Paused Duration} 4{Rest Duration} 5{Start & End Time} other{其他} }'**
  String trainedCalendarLabels(String num);

  /// No description provided for @trainedReportExport.
  ///
  /// In en, this message translates to:
  /// **'Export trained records'**
  String get trainedReportExport;

  /// No description provided for @trainedDoneNote.
  ///
  /// In en, this message translates to:
  /// **'Completed. Duration {totolTime} s:'**
  String trainedDoneNote(Object totolTime);

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercise;

  /// No description provided for @exerciseLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseLabel;

  /// No description provided for @exerciseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise management'**
  String get exerciseSubtitle;

  /// No description provided for @exerciseDeleteAlert.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you need to delete this exercise: {exerciseName}? Deletion is not recoverable!'**
  String exerciseDeleteAlert(Object exerciseName);

  /// No description provided for @exerciseInUse.
  ///
  /// In en, this message translates to:
  /// **'Exercise {exerciseName} in use, deletion is not supported'**
  String exerciseInUse(Object exerciseName);

  /// 常用exercise查询用的标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Muscles} 1{Code} 2{Name} 3{Level} 4{Mechanic} 5{Category} 6{Equipment} 7{Counting} other{other} }'**
  String exerciseQuerys(String num);

  /// 除了上面查询的，其他的exercise的栏位标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Force} 1{Std. Duration} 2{Primary Muscles} 3{Secondary Muscles} 4{Instructions} 5{TTS Notes} 6{Exercise Images} 7{isCustom} other{其他} }'**
  String exerciseLabels(String num);

  /// No description provided for @exerciseImport.
  ///
  /// In en, this message translates to:
  /// **'Import Exercise Json'**
  String get exerciseImport;

  /// No description provided for @exerciseLabelNote.
  ///
  /// In en, this message translates to:
  /// **'LTR: index - code - name - level'**
  String get exerciseLabelNote;

  /// No description provided for @exerciseImagePath.
  ///
  /// In en, this message translates to:
  /// **'Select image public folder'**
  String get exerciseImagePath;

  /// No description provided for @exerciseDetail.
  ///
  /// In en, this message translates to:
  /// **'Exercise Detail'**
  String get exerciseDetail;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @workoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Workout management'**
  String get workoutSubtitle;

  /// No description provided for @workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// 常用workout查询用的标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Name} 1{Category} 2{Level} 3{级别} 4{类型} 5{分类} 6{器械} 7{计量} other{其他} }'**
  String workoutQuerys(String num);

  /// No description provided for @groupDeleteAlert.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you need to delete the workout: {workoutName}? Deletion is not recoverable!'**
  String groupDeleteAlert(Object workoutName);

  /// No description provided for @groupInUse.
  ///
  /// In en, this message translates to:
  /// **'Workout {workoutName} in use, deletion is not supported'**
  String groupInUse(Object workoutName);

  /// 修改或新建训练动作组的标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Workout Add} 1{Workout Modify} 2{主要肌肉} 3{次要肌肉} 4{技术要点} 5{语音提示要点} 6{动作图片} 7{用户上传} other{其他} }'**
  String modifyGroupLabels(String num);

  /// 常用action相关的标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Action} 1{Actions} other{Other} }'**
  String actionLabel(String num);

  /// 在action详情弹窗中显示的栏位
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Dur.(s)} 1{Rpt. (times)} 2{Eqpt. (kg)} other{Other} }'**
  String actionDetailLabel(String num);

  /// action list页面中，在action详情弹窗中显示的栏位和新增action时exercise 列表页面显示的栏位
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Action Configuration Dialog} 1{Eqpt.Wgt.(kg)} 2{Click to select exercise} other{Other} }'**
  String actionConfigLabel(String num);

  /// 训练跟练页面相关栏位
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Follow Workout} 1{Ready} 2{REST} 3{Next} 4{Congratulations} other{Other} }'**
  String workoutFollowLabel(String num);

  /// No description provided for @noTtsEngine.
  ///
  /// In en, this message translates to:
  /// **'No available TTS engine'**
  String get noTtsEngine;

  /// 无TTS引擎时的说明(仅提示，不中断跟练)
  ///
  /// In en, this message translates to:
  /// **'Follow practice still works, just without voice prompts'**
  String get noTtsEngineDesc;

  /// 显示当前使用的TTS引擎信息
  ///
  /// In en, this message translates to:
  /// **'Using TTS engine: {engineName}'**
  String ttsEngineInfo(String engineName);

  /// No description provided for @selectTtsEngine.
  ///
  /// In en, this message translates to:
  /// **'Select TTS Engine'**
  String get selectTtsEngine;

  /// No description provided for @multipleTtsEnginesFound.
  ///
  /// In en, this message translates to:
  /// **'Multiple TTS engines detected, please select one:'**
  String get multipleTtsEnginesFound;

  /// No description provided for @ttsEngineCheckFail.
  ///
  /// In en, this message translates to:
  /// **'TTS engine check failed; voice prompts may be unavailable'**
  String get ttsEngineCheckFail;

  /// 训练跟练页面tts相关文字
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Ready, the next action is } 1{It\'s half the time.} 2{Start} 3{Congratulations,the workout is over.} 4{Take a break, the next action} other{其他} }'**
  String followTtsLabel(String num);

  /// 退出跟练页面是的弹窗标题和正文
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Workout Pause } 1{Are you sure want to quit this workout?} other{Other} }'**
  String quitFollowNotes(String num);

  /// No description provided for @previewReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get previewReport;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @planSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan management'**
  String get planSubtitle;

  /// 常用 plan 查询用的标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Name} 1{Category} 2{Level} other{Other} }'**
  String planQuerys(String num);

  /// No description provided for @planDeleteAlert.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you need to delete the plan: {planName}? Deletion is not recoverable!'**
  String planDeleteAlert(Object planName);

  /// No description provided for @planInUse.
  ///
  /// In en, this message translates to:
  /// **'Plan {planName} in use, deletion is not supported'**
  String planInUse(Object planName);

  /// 修改或新建 plan 的标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Plan Add} 1{Plan Modify} 2{Name} 3{Code} 4{Category} 5{Level} 6{Plan Period} 7{Description} other{Other} }'**
  String modifyPlanLabels(String num);

  /// No description provided for @dayNumber.
  ///
  /// In en, this message translates to:
  /// **'Day {number}'**
  String dayNumber(Object number);

  /// No description provided for @dayCount.
  ///
  /// In en, this message translates to:
  /// **'total {number} day(s)'**
  String dayCount(Object number);

  /// No description provided for @incompleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Never Completed'**
  String get incompleteLabel;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in total'**
  String itemCount(Object count);

  /// No description provided for @dietary.
  ///
  /// In en, this message translates to:
  /// **'Dietary'**
  String get dietary;

  /// No description provided for @dietaryReports.
  ///
  /// In en, this message translates to:
  /// **'Dietary Reports'**
  String get dietaryReports;

  /// No description provided for @dietaryReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reports management'**
  String get dietaryReportsSubtitle;

  /// No description provided for @foodCompo.
  ///
  /// In en, this message translates to:
  /// **'Food Composition'**
  String get foodCompo;

  /// No description provided for @foodCompoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nutritional composition'**
  String get foodCompoSubtitle;

  /// No description provided for @dietaryRecords.
  ///
  /// In en, this message translates to:
  /// **'Dietary Records'**
  String get dietaryRecords;

  /// No description provided for @dietaryRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily dietary records'**
  String get dietaryRecordsSubtitle;

  /// No description provided for @mealGallery.
  ///
  /// In en, this message translates to:
  /// **'Meal Gallery'**
  String get mealGallery;

  /// No description provided for @mealGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View daily meal photos'**
  String get mealGallerySubtitle;

  /// No description provided for @mealPhotos.
  ///
  /// In en, this message translates to:
  /// **'Meal Photos'**
  String get mealPhotos;

  /// 餐次信息
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Breakfast} 1{Lunch} 2{Dinner} 3{Other} other{其他} }'**
  String mealLabels(String num);

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get food;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'NotFound?'**
  String get notFound;

  /// No description provided for @foodName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get foodName;

  /// No description provided for @foodDetail.
  ///
  /// In en, this message translates to:
  /// **'Food Detail'**
  String get foodDetail;

  /// No description provided for @foodBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Food Basic Info'**
  String get foodBasicInfo;

  /// No description provided for @foodNutrientInfo.
  ///
  /// In en, this message translates to:
  /// **'Food Nutrient Info'**
  String get foodNutrientInfo;

  /// No description provided for @servingUnit.
  ///
  /// In en, this message translates to:
  /// **'Serving Unit'**
  String get servingUnit;

  /// No description provided for @servingEquivalence.
  ///
  /// In en, this message translates to:
  /// **'Equivalence Unit'**
  String get servingEquivalence;

  /// No description provided for @nutrientLabel.
  ///
  /// In en, this message translates to:
  /// **'Nutrients'**
  String get nutrientLabel;

  /// No description provided for @mainNutrientLabel.
  ///
  /// In en, this message translates to:
  /// **'Main Nutrients'**
  String get mainNutrientLabel;

  /// No description provided for @allNutrientLabel.
  ///
  /// In en, this message translates to:
  /// **'Nutritional Information'**
  String get allNutrientLabel;

  /// No description provided for @eatableSize.
  ///
  /// In en, this message translates to:
  /// **'Eatable'**
  String get eatableSize;

  /// No description provided for @dietaryReportExport.
  ///
  /// In en, this message translates to:
  /// **'Export dietary records'**
  String get dietaryReportExport;

  /// 表格展示营养素的主要栏位
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Unit} 1{Energy(kcal)} 2{Protein(g)} 3{Fat(g)} 4{CHO(g)} 5{Micronutrient(mg)} other{Other} }'**
  String foodTableMainLabels(String num);

  /// 表格展示营养素的主要栏位
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Product} 1{Brand}  2{Tags} 3{Category} 4{Description} 5{Images} 6{Code} other{Other} }'**
  String foodLabels(String num);

  /// 总计平均等标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Total} 1{AVG} other{Other} }'**
  String countLabels(String num);

  /// No description provided for @foodImport.
  ///
  /// In en, this message translates to:
  /// **'Import Food Json'**
  String get foodImport;

  /// No description provided for @importFinished.
  ///
  /// In en, this message translates to:
  /// **'Data has been inserted into the database'**
  String get importFinished;

  /// No description provided for @uploadingItem.
  ///
  /// In en, this message translates to:
  /// **'An overview of the {obj} items:'**
  String uploadingItem(Object obj);

  /// No description provided for @jsonFiles.
  ///
  /// In en, this message translates to:
  /// **'Json Files:'**
  String get jsonFiles;

  /// No description provided for @foodLabelNote.
  ///
  /// In en, this message translates to:
  /// **'LTR: index - code - name - energy(kcal)'**
  String get foodLabelNote;

  /// 几个常见的时间范围
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Yesterday} 1{Today} 2{Tomorrow} 3{LastWeek} 4{ThisWeek} other{Other} }'**
  String rangeLabels(String num);

  /// 饮食日记条目的头部说明
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Calories Remaining} 1{Calories Consumed} 2{Calories} other{Other} }'**
  String calorieLabels(String num);

  /// 饮食日记条目的底部的图示说明
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{The Proportion} 1{Main Nutrient Intake} 2{Calories} other{Other} }'**
  String illustratedDesc(String num);

  /// No description provided for @photoLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo ({count})'**
  String photoLabel(Object count);

  /// No description provided for @photoUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'photo(s)'**
  String get photoUnitLabel;

  /// 饮食日记条目新增时的tab页面标题
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Recently Eaten} 1{Food List} 2{Size} 3{Unit} 4{New Unit?} 5{Meal}  other{Other} }'**
  String dietaryAddTabs(String num);

  /// 饮食报告页面的tab页面标题和表单栏位
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Calories} 1{Macros} 2{Nutrients} other{Other} }'**
  String dietaryReportTabs(String num);

  /// 饮食报告页面食物摄入相关栏位
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Foods Eaten} 1{Macros Eaten} 2{Times Eaten} 3{Cals(kcal)} other{Other} }'**
  String intakeLabels(String num);

  /// No description provided for @goalAchieved.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of goal'**
  String goalAchieved(Object pct);

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal: {number}'**
  String goalLabel(Object number);

  /// No description provided for @dietaryCalendar.
  ///
  /// In en, this message translates to:
  /// **'Dietary Calendar'**
  String get dietaryCalendar;

  /// 饮食日历表格统计的栏位标签
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Month Intake} 1{Today Intake} 2{Detailed Intake} other{Other} }'**
  String dietaryCalendarLabels(String num);

  /// No description provided for @diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @appExitInfo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to exit Free Fitness?'**
  String get appExitInfo;

  /// No description provided for @userInfo.
  ///
  /// In en, this message translates to:
  /// **'User Info'**
  String get userInfo;

  /// 手记显示模式
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Diary Calendar} 1{Timeline} 2{Title} 3{Content} other{Other} }'**
  String diaryLables(String num);

  /// 日历表格切换显示模式
  ///
  /// In en, this message translates to:
  /// **'{num, select, 0{Month} 1{2 weeks} 2{Week} other{Other} }'**
  String calenderLables(String num);

  /// No description provided for @diaryTitleNote.
  ///
  /// In en, this message translates to:
  /// **' All is well ^~^'**
  String get diaryTitleNote;

  /// No description provided for @diaryTagsNote.
  ///
  /// In en, this message translates to:
  /// **' tags (split by entering comma or semi)'**
  String get diaryTagsNote;

  /// No description provided for @richTextToolNote.
  ///
  /// In en, this message translates to:
  /// **' Expand Quill Toolbar'**
  String get richTextToolNote;

  /// No description provided for @lastModified.
  ///
  /// In en, this message translates to:
  /// **'Last Modified'**
  String get lastModified;

  /// No description provided for @gmtCreate.
  ///
  /// In en, this message translates to:
  /// **'Created Time'**
  String get gmtCreate;

  /// No description provided for @confirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @resetLabel.
  ///
  /// In en, this message translates to:
  /// **'reset'**
  String get resetLabel;

  /// No description provided for @queryLabel.
  ///
  /// In en, this message translates to:
  /// **'query'**
  String get queryLabel;

  /// No description provided for @moreLabel.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get moreLabel;

  /// No description provided for @moreDetail.
  ///
  /// In en, this message translates to:
  /// **'More Detail'**
  String get moreDetail;

  /// No description provided for @lessLabel.
  ///
  /// In en, this message translates to:
  /// **'less'**
  String get lessLabel;

  /// No description provided for @enterLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enterLabel;

  /// No description provided for @skipLabel.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get skipLabel;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @eidtLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String eidtLabel(Object name);

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String addLabel(Object name);

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @recordLabel.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordLabel;

  /// No description provided for @manageLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageLabel;

  /// No description provided for @removeSelected.
  ///
  /// In en, this message translates to:
  /// **'Remove Selected'**
  String get removeSelected;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @optionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsLabel;

  /// No description provided for @imageUploadLabel.
  ///
  /// In en, this message translates to:
  /// **'Image Upload'**
  String get imageUploadLabel;

  /// No description provided for @detailLabel.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detailLabel;

  /// No description provided for @modifiedSuccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Successfully Modified'**
  String get modifiedSuccessLabel;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @pauseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseLabel;

  /// No description provided for @resumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeLabel;

  /// No description provided for @restartLabel.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartLabel;

  /// No description provided for @prevLabel.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get prevLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @switchUser.
  ///
  /// In en, this message translates to:
  /// **'Switch User'**
  String get switchUser;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'note'**
  String get noteLabel;

  /// No description provided for @tipLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get tipLabel;

  /// No description provided for @itemLabel.
  ///
  /// In en, this message translates to:
  /// **'{num} item(s)'**
  String itemLabel(Object num);

  /// No description provided for @userGuide.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get userGuide;

  /// No description provided for @questionAndAnswer.
  ///
  /// In en, this message translates to:
  /// **'Q&A'**
  String get questionAndAnswer;

  /// No description provided for @alertTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alertTitle;

  /// No description provided for @noRecordNote.
  ///
  /// In en, this message translates to:
  /// **'No data yet.'**
  String get noRecordNote;

  /// No description provided for @noOtherUser.
  ///
  /// In en, this message translates to:
  /// **' No other users'**
  String get noOtherUser;

  /// 最近几天的选项标签
  ///
  /// In en, this message translates to:
  /// **'last {count} days'**
  String lastDayLabels(Object count);

  /// No description provided for @allRecords.
  ///
  /// In en, this message translates to:
  /// **'All data in selected range:'**
  String get allRecords;

  /// No description provided for @serialLabel.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get serialLabel;

  /// No description provided for @measuredTime.
  ///
  /// In en, this message translates to:
  /// **'Measured Time'**
  String get measuredTime;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Change Range'**
  String get selectDateRange;

  /// No description provided for @queryKeywordHintText.
  ///
  /// In en, this message translates to:
  /// **'Please enter {key} keywords'**
  String queryKeywordHintText(Object key);

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height{unit}'**
  String heightLabel(Object unit);

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight{unit}'**
  String weightLabel(Object unit);

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'please input your name'**
  String get nameLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'please select your gender'**
  String get genderLabel;

  /// No description provided for @exceptionWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Exception Warning'**
  String get exceptionWarningTitle;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Confirm'**
  String get deleteConfirm;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to delete the selected data?{data}'**
  String deleteNote(Object data);

  /// No description provided for @deletedInfo.
  ///
  /// In en, this message translates to:
  /// **'The item has been deleted.'**
  String get deletedInfo;

  /// No description provided for @initInfo.
  ///
  /// In en, this message translates to:
  /// **'Could you please provide some basic info? \nOr just click \'Next\' button to use default info.'**
  String get initInfo;

  /// No description provided for @moreSettings.
  ///
  /// In en, this message translates to:
  /// **'More Settings'**
  String get moreSettings;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get followSystem;

  /// No description provided for @themeSetting.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeSetting;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @settingLabels.
  ///
  /// In en, this message translates to:
  /// **'{ setting, select, 0{Basic Info} 1{Weight Trend} 2{Intake Goal} 3{Training Setting} 4{Backup & Restore} 5{More Settings} other{Unknown Setting} }'**
  String settingLabels(String setting);

  /// No description provided for @exportRangeNote.
  ///
  /// In en, this message translates to:
  /// **'Select export range'**
  String get exportRangeNote;

  /// No description provided for @importJsonButtons.
  ///
  /// In en, this message translates to:
  /// **'{ num, select, 0{Select Json} 1{Clear Data} other{Unknown Setting} }'**
  String importJsonButtons(String num);

  /// No description provided for @importJsonError.
  ///
  /// In en, this message translates to:
  /// **'Import json file error'**
  String get importJsonError;

  /// No description provided for @importJsonErrorText.
  ///
  /// In en, this message translates to:
  /// **'Filename:\n{path}\n\nError:\n{msg}'**
  String importJsonErrorText(Object msg, Object path);

  /// No description provided for @invalidFormErrorText.
  ///
  /// In en, this message translates to:
  /// **'Form validation failed'**
  String get invalidFormErrorText;

  /// No description provided for @uniqueErrorText.
  ///
  /// In en, this message translates to:
  /// **'{text} already exists'**
  String uniqueErrorText(Object text);

  /// No description provided for @noStorageErrorText.
  ///
  /// In en, this message translates to:
  /// **'The user has disabled access to internal storage and cannot import JSON files'**
  String get noStorageErrorText;

  /// No description provided for @requiredErrorText.
  ///
  /// In en, this message translates to:
  /// **'{text} required'**
  String requiredErrorText(Object text);

  /// No description provided for @numericErrorText.
  ///
  /// In en, this message translates to:
  /// **'{text} must be numeric'**
  String numericErrorText(Object text);

  /// No description provided for @aiSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Dietary Health Analysis'**
  String get aiSuggestionTitle;

  /// No description provided for @aiSuggestionHint.
  ///
  /// In en, this message translates to:
  /// **'You can ask me questions for advice on healthy eating'**
  String get aiSuggestionHint;

  /// No description provided for @regeneration.
  ///
  /// In en, this message translates to:
  /// **'regen'**
  String get regeneration;

  /// No description provided for @copiedHint.
  ///
  /// In en, this message translates to:
  /// **'cpoied'**
  String get copiedHint;

  /// No description provided for @apiErrorHint.
  ///
  /// In en, this message translates to:
  /// **'The HTTP API reports an error, please check the network or try again later!'**
  String get apiErrorHint;

  /// No description provided for @noStorageHint.
  ///
  /// In en, this message translates to:
  /// **'File management permissions have not been granted, and some features may be affected.'**
  String get noStorageHint;

  /// No description provided for @permissionRequest.
  ///
  /// In en, this message translates to:
  /// **'Permission Request'**
  String get permissionRequest;

  /// No description provided for @featuresRestrictionNote.
  ///
  /// In en, this message translates to:
  /// **'The features of display images, import exercise, import food composition, and data backup in the application require file management permissions. Please allow them.'**
  String get featuresRestrictionNote;

  /// No description provided for @appNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get appNote;

  /// No description provided for @initFinished.
  ///
  /// In en, this message translates to:
  /// **'InitFinished'**
  String get initFinished;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing, please wait for 3 minutes'**
  String get initializing;

  /// No description provided for @initializingFood.
  ///
  /// In en, this message translates to:
  /// **'Initializing Food Composition Data...'**
  String get initializingFood;

  /// No description provided for @initializingExercise.
  ///
  /// In en, this message translates to:
  /// **'Initializing Exercise Data...'**
  String get initializingExercise;

  /// No description provided for @loadEmbeddedExercise.
  ///
  /// In en, this message translates to:
  /// **'Load embedded exercise'**
  String get loadEmbeddedExercise;

  /// No description provided for @confirmLoadEmbeddedExercise.
  ///
  /// In en, this message translates to:
  /// **'Load embedded exercise? This will overwrite duplicates.'**
  String get confirmLoadEmbeddedExercise;

  /// No description provided for @loadEmbeddedFood.
  ///
  /// In en, this message translates to:
  /// **'Load embedded Food'**
  String get loadEmbeddedFood;

  /// No description provided for @confirmLoadEmbeddedFood.
  ///
  /// In en, this message translates to:
  /// **'Load embedded food? This will overwrite duplicates.'**
  String get confirmLoadEmbeddedFood;

  /// No description provided for @tipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tipsTitle;

  /// No description provided for @guideStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {num}/4 · {name}'**
  String guideStepLabel(int num, Object name);

  /// No description provided for @guideStepIntro.
  ///
  /// In en, this message translates to:
  /// **'Intro'**
  String get guideStepIntro;

  /// No description provided for @guideStepStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get guideStepStorage;

  /// No description provided for @guideStepData.
  ///
  /// In en, this message translates to:
  /// **'Built-in Data'**
  String get guideStepData;

  /// No description provided for @guideStepProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get guideStepProfile;

  /// No description provided for @guideIntroTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get guideIntroTrainingTitle;

  /// No description provided for @guideIntroTrainingDesc.
  ///
  /// In en, this message translates to:
  /// **'Exercise library & period plans with guided workouts'**
  String get guideIntroTrainingDesc;

  /// No description provided for @guideIntroDietaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Dietary'**
  String get guideIntroDietaryTitle;

  /// No description provided for @guideIntroDietaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Food composition, servings, meal photos & daily intake'**
  String get guideIntroDietaryDesc;

  /// No description provided for @guideIntroDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get guideIntroDiaryTitle;

  /// No description provided for @guideIntroDiaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Rich-text notes and long-term weight trends'**
  String get guideIntroDiaryDesc;

  /// No description provided for @guideIntroAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get guideIntroAiTitle;

  /// No description provided for @guideIntroAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Bring your own LLM API key for diet/training analysis'**
  String get guideIntroAiDesc;

  /// No description provided for @guideStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Why storage permission?'**
  String get guideStorageTitle;

  /// No description provided for @guideStorageReason1.
  ///
  /// In en, this message translates to:
  /// **'Databases live in the app-specific directory, removed on uninstall'**
  String get guideStorageReason1;

  /// No description provided for @guideStorageReason2.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore: full zip backups for device migration and safety'**
  String get guideStorageReason2;

  /// No description provided for @guideStorageReason3.
  ///
  /// In en, this message translates to:
  /// **'Images: diary photos and analyzed meal photos are copied for history'**
  String get guideStorageReason3;

  /// No description provided for @guideStorageGranted.
  ///
  /// In en, this message translates to:
  /// **'✓ Granted'**
  String get guideStorageGranted;

  /// No description provided for @guideStorageSkippable.
  ///
  /// In en, this message translates to:
  /// **'You may skip; features will ask again later'**
  String get guideStorageSkippable;

  /// No description provided for @guideDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Load built-in data?'**
  String get guideDataTitle;

  /// No description provided for @guideDataHint.
  ///
  /// In en, this message translates to:
  /// **'(Recommended on first launch)'**
  String get guideDataHint;

  /// No description provided for @guideDataExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Built-in exercise library'**
  String get guideDataExerciseTitle;

  /// No description provided for @guideDataExerciseDesc.
  ///
  /// In en, this message translates to:
  /// **'Common strength/cardio exercises with categories'**
  String get guideDataExerciseDesc;

  /// No description provided for @guideDataFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Food composition table'**
  String get guideDataFoodTitle;

  /// No description provided for @guideDataFoodDesc.
  ///
  /// In en, this message translates to:
  /// **'China Food Composition datasets with energy & macros'**
  String get guideDataFoodDesc;

  /// No description provided for @guideDataManualNote.
  ///
  /// In en, this message translates to:
  /// **'Skip freely: use the flash icon on the exercise/food pages to import anytime.'**
  String get guideDataManualNote;

  /// No description provided for @guideBtnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guideBtnNext;

  /// No description provided for @guideBtnSkipStep.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get guideBtnSkipStep;

  /// No description provided for @guideBtnGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant & continue'**
  String get guideBtnGrant;

  /// No description provided for @guideBtnGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted, continue'**
  String get guideBtnGranted;

  /// No description provided for @guideBtnStartLoad.
  ///
  /// In en, this message translates to:
  /// **'Start loading'**
  String get guideBtnStartLoad;

  /// No description provided for @guideBtnNoLoad.
  ///
  /// In en, this message translates to:
  /// **'Skip loading'**
  String get guideBtnNoLoad;

  /// No description provided for @restoreSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select data to restore'**
  String get restoreSelectTitle;

  /// No description provided for @restoreModUser.
  ///
  /// In en, this message translates to:
  /// **'User & goals'**
  String get restoreModUser;

  /// No description provided for @restoreModUserDesc.
  ///
  /// In en, this message translates to:
  /// **'Profiles / intake goals / weight trends'**
  String get restoreModUserDesc;

  /// No description provided for @restoreModDietary.
  ///
  /// In en, this message translates to:
  /// **'Dietary'**
  String get restoreModDietary;

  /// No description provided for @restoreModDietaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Foods / servings / daily intake / meal photos'**
  String get restoreModDietaryDesc;

  /// No description provided for @restoreModDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get restoreModDiary;

  /// No description provided for @restoreModDiaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Rich-text notes'**
  String get restoreModDiaryDesc;

  /// No description provided for @restoreModTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get restoreModTraining;

  /// No description provided for @restoreModTrainingDesc.
  ///
  /// In en, this message translates to:
  /// **'Exercises / groups / plans / training logs\nBuilt-in items already on this device are kept as-is'**
  String get restoreModTrainingDesc;

  /// No description provided for @restoreModAi.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get restoreModAi;

  /// No description provided for @restoreModAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Conversations / custom roles / LLM configs (incl. keys) / images'**
  String get restoreModAiDesc;

  /// No description provided for @restoreMergeNote.
  ///
  /// In en, this message translates to:
  /// **'Restore merges into existing data (deduplicated); an automatic full backup is made first.'**
  String get restoreMergeNote;

  /// No description provided for @restoreNoData.
  ///
  /// In en, this message translates to:
  /// **'No restorable data in this backup'**
  String get restoreNoData;

  /// No description provided for @restorePhaseBackup.
  ///
  /// In en, this message translates to:
  /// **'Backing up current data first'**
  String get restorePhaseBackup;

  /// No description provided for @restorePhaseBackupNote.
  ///
  /// In en, this message translates to:
  /// **'For rollback safety'**
  String get restorePhaseBackupNote;

  /// No description provided for @restorePhaseLlm.
  ///
  /// In en, this message translates to:
  /// **'Merging LLM configs'**
  String get restorePhaseLlm;

  /// No description provided for @restorePhaseImages.
  ///
  /// In en, this message translates to:
  /// **'Merging AI images'**
  String get restorePhaseImages;

  /// No description provided for @restoreProgressDetail.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} rows merged'**
  String restoreProgressDetail(int current, int total);

  /// No description provided for @restoreResultNote.
  ///
  /// In en, this message translates to:
  /// **'Restore merged: {inserted} new, {skipped} existing kept'**
  String restoreResultNote(int inserted, int skipped);

  /// No description provided for @restoreBuiltinNote.
  ///
  /// In en, this message translates to:
  /// **'({count} built-in entries kept)'**
  String restoreBuiltinNote(int count);

  /// No description provided for @restoreTblUser.
  ///
  /// In en, this message translates to:
  /// **'user profiles'**
  String get restoreTblUser;

  /// No description provided for @restoreTblIntakeGoal.
  ///
  /// In en, this message translates to:
  /// **'intake goals'**
  String get restoreTblIntakeGoal;

  /// No description provided for @restoreTblWeightTrend.
  ///
  /// In en, this message translates to:
  /// **'weight trends'**
  String get restoreTblWeightTrend;

  /// No description provided for @restoreTblFood.
  ///
  /// In en, this message translates to:
  /// **'foods'**
  String get restoreTblFood;

  /// No description provided for @restoreTblServing.
  ///
  /// In en, this message translates to:
  /// **'servings'**
  String get restoreTblServing;

  /// No description provided for @restoreTblDailyIntake.
  ///
  /// In en, this message translates to:
  /// **'daily intake'**
  String get restoreTblDailyIntake;

  /// No description provided for @restoreTblMealPhoto.
  ///
  /// In en, this message translates to:
  /// **'meal photos'**
  String get restoreTblMealPhoto;

  /// No description provided for @restoreTblDiary.
  ///
  /// In en, this message translates to:
  /// **'diary notes'**
  String get restoreTblDiary;

  /// No description provided for @restoreTblExercise.
  ///
  /// In en, this message translates to:
  /// **'exercises'**
  String get restoreTblExercise;

  /// No description provided for @restoreTblGroup.
  ///
  /// In en, this message translates to:
  /// **'workout groups'**
  String get restoreTblGroup;

  /// No description provided for @restoreTblAction.
  ///
  /// In en, this message translates to:
  /// **'plan actions'**
  String get restoreTblAction;

  /// No description provided for @restoreTblPlan.
  ///
  /// In en, this message translates to:
  /// **'plans'**
  String get restoreTblPlan;

  /// No description provided for @restoreTblPlanDay.
  ///
  /// In en, this message translates to:
  /// **'plan schedules'**
  String get restoreTblPlanDay;

  /// No description provided for @restoreTblTrainLog.
  ///
  /// In en, this message translates to:
  /// **'training logs'**
  String get restoreTblTrainLog;

  /// No description provided for @restoreTblAiConv.
  ///
  /// In en, this message translates to:
  /// **'AI conversations'**
  String get restoreTblAiConv;

  /// No description provided for @restoreTblAiMsg.
  ///
  /// In en, this message translates to:
  /// **'AI messages'**
  String get restoreTblAiMsg;

  /// No description provided for @restoreTblAiRole.
  ///
  /// In en, this message translates to:
  /// **'custom roles'**
  String get restoreTblAiRole;

  /// No description provided for @llmConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'LLM Config'**
  String get llmConfigTitle;

  /// No description provided for @llmConfigStatusNone.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get llmConfigStatusNone;

  /// No description provided for @llmConfigStatusCount.
  ///
  /// In en, this message translates to:
  /// **'{count} config(s)'**
  String llmConfigStatusCount(int count);

  /// No description provided for @llmConfigEmpty.
  ///
  /// In en, this message translates to:
  /// **'No configs yet.\nTap + to add an OpenAI-compatible LLM config.'**
  String get llmConfigEmpty;

  /// No description provided for @llmConfigAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add config'**
  String get llmConfigAddTooltip;

  /// No description provided for @llmConfigDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete config \"{name}\"? Existing conversations keep their history (snapshot display).'**
  String llmConfigDeleteNote(Object name);

  /// No description provided for @llmConfigPageAdd.
  ///
  /// In en, this message translates to:
  /// **'Add LLM Config'**
  String get llmConfigPageAdd;

  /// No description provided for @llmConfigPageEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit LLM Config'**
  String get llmConfigPageEdit;

  /// No description provided for @llmConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get llmConfigSaved;

  /// No description provided for @llmConfigFixForm.
  ///
  /// In en, this message translates to:
  /// **'Please fix form errors first'**
  String get llmConfigFixForm;

  /// No description provided for @llmConfigFieldName.
  ///
  /// In en, this message translates to:
  /// **'Config name'**
  String get llmConfigFieldName;

  /// No description provided for @llmConfigFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. SiliconFlow-Qwen'**
  String get llmConfigFieldNameHint;

  /// No description provided for @llmConfigFieldUrl.
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get llmConfigFieldUrl;

  /// No description provided for @llmConfigFieldKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get llmConfigFieldKey;

  /// No description provided for @llmConfigFieldModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get llmConfigFieldModel;

  /// No description provided for @llmConfigFieldModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Qwen/Qwen2.5-VL-32B-Instruct'**
  String get llmConfigFieldModelHint;

  /// No description provided for @llmConfigFieldVision.
  ///
  /// In en, this message translates to:
  /// **'Supports vision'**
  String get llmConfigFieldVision;

  /// No description provided for @llmConfigFieldVisionNote.
  ///
  /// In en, this message translates to:
  /// **'Most modern models are multimodal. Turn off for text-only models (e.g. deepseek-chat).'**
  String get llmConfigFieldVisionNote;

  /// No description provided for @llmConfigFieldExtra.
  ///
  /// In en, this message translates to:
  /// **'Advanced params (JSON, optional)'**
  String get llmConfigFieldExtra;

  /// No description provided for @llmConfigFieldExtraNote.
  ///
  /// In en, this message translates to:
  /// **'Merged into request body. Keys model/messages/stream are ignored.'**
  String get llmConfigFieldExtraNote;

  /// No description provided for @llmConfigRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get llmConfigRequired;

  /// No description provided for @llmConfigInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get llmConfigInvalidUrl;

  /// No description provided for @llmConfigInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'Must be a valid JSON object'**
  String get llmConfigInvalidJson;

  /// No description provided for @llmConfigQuickFill.
  ///
  /// In en, this message translates to:
  /// **'Quick fill:'**
  String get llmConfigQuickFill;

  /// No description provided for @llmConfigTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get llmConfigTestConnection;

  /// No description provided for @llmConfigTestVision.
  ///
  /// In en, this message translates to:
  /// **'Test vision'**
  String get llmConfigTestVision;

  /// No description provided for @llmConfigTestResult.
  ///
  /// In en, this message translates to:
  /// **'Test result'**
  String get llmConfigTestResult;

  /// No description provided for @llmConfigEmptyReply.
  ///
  /// In en, this message translates to:
  /// **'(empty reply)'**
  String get llmConfigEmptyReply;

  /// No description provided for @llmConfigVisionTest.
  ///
  /// In en, this message translates to:
  /// **'Vision test'**
  String get llmConfigVisionTest;

  /// No description provided for @llmConfigVisionOk.
  ///
  /// In en, this message translates to:
  /// **'The model seems to support image input.\n\nReply: {reply}'**
  String llmConfigVisionOk(Object reply);

  /// No description provided for @llmConfigVisionFail.
  ///
  /// In en, this message translates to:
  /// **'The model may NOT support image input.\n\n{detail}'**
  String llmConfigVisionFail(Object detail);

  /// No description provided for @llmConfigPingText.
  ///
  /// In en, this message translates to:
  /// **'Hi, reply with \"ok\" only.'**
  String get llmConfigPingText;

  /// No description provided for @llmConfigVisionPingText.
  ///
  /// In en, this message translates to:
  /// **'What color is this image?'**
  String get llmConfigVisionPingText;

  /// No description provided for @llmGateNoKey.
  ///
  /// In en, this message translates to:
  /// **'No LLM API key configured.\nPlease configure it in Me → More Settings → LLM Config first.'**
  String get llmGateNoKey;

  /// No description provided for @llmGateGoConfig.
  ///
  /// In en, this message translates to:
  /// **'Go config'**
  String get llmGateGoConfig;

  /// No description provided for @llmGateNoVision.
  ///
  /// In en, this message translates to:
  /// **'No vision-capable model config.\nPlease enable \"supports vision\" on a config first.'**
  String get llmGateNoVision;

  /// No description provided for @aiChatNoConfig.
  ///
  /// In en, this message translates to:
  /// **'No LLM config, please configure first'**
  String get aiChatNoConfig;

  /// No description provided for @aiChatSwitchModel.
  ///
  /// In en, this message translates to:
  /// **'Switch model'**
  String get aiChatSwitchModel;

  /// No description provided for @aiChatVisionTag.
  ///
  /// In en, this message translates to:
  /// **'vision'**
  String get aiChatVisionTag;

  /// No description provided for @aiChatModelNoVision.
  ///
  /// In en, this message translates to:
  /// **'Current model doesn\'t support images; pending images removed'**
  String get aiChatModelNoVision;

  /// No description provided for @aiChatImageLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to 4 images'**
  String get aiChatImageLimit;

  /// No description provided for @aiChatRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get aiChatRename;

  /// No description provided for @aiChatClearNote.
  ///
  /// In en, this message translates to:
  /// **'Clear all messages in this conversation?'**
  String get aiChatClearNote;

  /// No description provided for @aiChatDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation? Messages and images will be removed too.'**
  String get aiChatDeleteNote;

  /// No description provided for @aiChatDeleteShort.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation?'**
  String get aiChatDeleteShort;

  /// No description provided for @aiChatClearMessages.
  ///
  /// In en, this message translates to:
  /// **'Clear messages'**
  String get aiChatClearMessages;

  /// No description provided for @aiChatDeleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get aiChatDeleteConversation;

  /// No description provided for @aiChatNoConfigName.
  ///
  /// In en, this message translates to:
  /// **'No config'**
  String get aiChatNoConfigName;

  /// No description provided for @aiChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything...'**
  String get aiChatInputHint;

  /// No description provided for @aiChatAskWith.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name}:'**
  String aiChatAskWith(Object name);

  /// No description provided for @aiChatRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get aiChatRegenerate;

  /// No description provided for @aiChatCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aiChatCopied;

  /// No description provided for @aiChatTokenUsage.
  ///
  /// In en, this message translates to:
  /// **'tokens in:{inputTokens} out:{outputTokens} total:{totalTokens}'**
  String aiChatTokenUsage(int inputTokens, int outputTokens, int totalTokens);

  /// No description provided for @aiChatAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add images (up to 4)'**
  String get aiChatAddImage;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiChatTitle;

  /// No description provided for @aiChatNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get aiChatNewChat;

  /// No description provided for @aiChatManageRoles.
  ///
  /// In en, this message translates to:
  /// **'Manage roles'**
  String get aiChatManageRoles;

  /// No description provided for @aiChatHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get aiChatHistory;

  /// No description provided for @aiChatNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get aiChatNoHistory;

  /// No description provided for @aiChatDataUpdated.
  ///
  /// In en, this message translates to:
  /// **'(The data has been updated. Please analyze based on the following latest data.)'**
  String get aiChatDataUpdated;

  /// No description provided for @aiChatException.
  ///
  /// In en, this message translates to:
  /// **'Exception'**
  String get aiChatException;

  /// No description provided for @rolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Roles'**
  String get rolesTitle;

  /// No description provided for @rolesBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in roles'**
  String get rolesBuiltIn;

  /// No description provided for @rolesCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom roles'**
  String get rolesCustom;

  /// No description provided for @rolesEmptyCustom.
  ///
  /// In en, this message translates to:
  /// **'No custom roles yet, tap + to add one'**
  String get rolesEmptyCustom;

  /// No description provided for @rolesAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add role'**
  String get rolesAddTooltip;

  /// No description provided for @rolesDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete role \"{name}\"? Existing conversations keep their history.'**
  String rolesDeleteNote(Object name);

  /// No description provided for @rolePageAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Role'**
  String get rolePageAdd;

  /// No description provided for @rolePageEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get rolePageEdit;

  /// No description provided for @rolePageDetail.
  ///
  /// In en, this message translates to:
  /// **'Role Details'**
  String get rolePageDetail;

  /// No description provided for @roleReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Built-in roles are read-only and cannot be modified or deleted'**
  String get roleReadOnlyNote;

  /// No description provided for @roleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get roleNameLabel;

  /// No description provided for @roleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Running Coach'**
  String get roleNameHint;

  /// No description provided for @rolePromptLabel.
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get rolePromptLabel;

  /// No description provided for @rolePromptHint.
  ///
  /// In en, this message translates to:
  /// **'Describe this role\'s expertise, tone and how it should answer...'**
  String get rolePromptHint;

  /// No description provided for @rolePromptNote.
  ///
  /// In en, this message translates to:
  /// **'This prompt will be used as the system message when chatting with this role.'**
  String get rolePromptNote;

  /// No description provided for @roleInvalid.
  ///
  /// In en, this message translates to:
  /// **'Name and prompt cannot be empty'**
  String get roleInvalid;

  /// 训练组/计划的预估耗时(按动作标准耗时+间隔休息估算)
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String estMinutes(int minutes);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

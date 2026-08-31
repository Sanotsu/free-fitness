// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Free Fitness';

  @override
  String get report => 'Reports';

  @override
  String mainNutrients(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Energy',
      '1': 'Calorie',
      '2': 'Protein',
      '3': 'Fat',
      '4': 'CHO',
      '5': 'RDI',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String fatNutrients(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'TotalFat',
      '1': 'SaturatedFat',
      '2': 'TransFat',
      '3': 'puFat',
      '4': 'muFat',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String choNutrients(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'TotalCHO',
      '1': 'Sugar',
      '2': 'DietaryFiber',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String microNutrients(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Sodium',
      '1': 'Potassium',
      '2': 'Cholesterol',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String unitLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'g',
      '1': 'mg',
      '2': 'kcal',
      '3': 'kj',
      '4': 'cm',
      '5': 'kg',
      '6': 's',
      '7': 'time(s)',
      '8': 'minutes',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String boolLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Yes',
      '1': 'No',
      '2': 'True',
      '3': 'False',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get averageGoal => 'Nutrient Goals';

  @override
  String get dailyGoal => 'Daily Goals';

  @override
  String get dailyGoalBars => 'Daily Goals Chart';

  @override
  String moduleTitles(String titles) {
    String _temp0 = intl.Intl.selectLogic(titles, {
      '0': 'Training',
      '1': 'Dietary',
      '2': 'Daily Calendar',
      '3': 'User & Settings',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String changeAvatarLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Change Avatar',
      '1': 'Options',
      '2': 'Camera',
      '3': 'Gallery',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String bakLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Backup & Restore',
      '1': 'Full Backup',
      '2': 'Merge Restore',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get bakOpNote => 'Confirm exporting all data?';

  @override
  String bakSuccessNote(Object dir) {
    return 'Has been saved to $dir.';
  }

  @override
  String get resSuccessNote => 'Backup data has been merged into the device.';

  @override
  String get restIntervals => 'Rest time between follow-up exercises (s)';

  @override
  String get chooseSeconds => 'Choose a duration(s)';

  @override
  String bmiLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'UWT',
      '1': 'NWT',
      '2': 'OWT',
      '3': 'Fat',
      '4': 'Obesity',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get weightRecord => 'Weight Record';

  @override
  String userInfoLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'UserName',
      '1': 'UserCode',
      '2': 'Gender',
      '3': 'DateOfBirth',
      '4': 'Height',
      '5': 'Weight',
      '6': 'Description',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String userGoalLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'RDA',
      '1': 'RestIntervals',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get training => 'Training';

  @override
  String get trainingReports => 'Training Reports';

  @override
  String get trainingReportsSubtitle => 'Reports management';

  @override
  String trainedReportLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Total Workouts',
      '1': 'Trained Time',
      '2': 'Rest Time',
      '3': 'Paused Time',
      '4': 'Total (minutes)',
      '5': 'LastTrained',
      '6': 'Date',
      '7': 'Name',
      '8': 'Duration',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String trainedCalendarLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Start Time',
      '1': 'End Time',
      '2': 'Trained Duration',
      '3': 'Paused Duration',
      '4': 'Rest Duration',
      '5': 'Start & End Time',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get trainedReportExport => 'Export trained records';

  @override
  String trainedDoneNote(Object totolTime) {
    return 'Completed. Duration $totolTime s:';
  }

  @override
  String get exercise => 'Exercises';

  @override
  String get exerciseLabel => 'Exercise';

  @override
  String get exerciseSubtitle => 'Exercise management';

  @override
  String exerciseDeleteAlert(Object exerciseName) {
    return 'Are you sure you need to delete this exercise: $exerciseName? Deletion is not recoverable!';
  }

  @override
  String exerciseInUse(Object exerciseName) {
    return 'Exercise $exerciseName in use, deletion is not supported';
  }

  @override
  String exerciseQuerys(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Muscles',
      '1': 'Code',
      '2': 'Name',
      '3': 'Level',
      '4': 'Mechanic',
      '5': 'Category',
      '6': 'Equipment',
      '7': 'Counting',
      'other': 'other',
    });
    return '$_temp0';
  }

  @override
  String exerciseLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Force',
      '1': 'Std. Duration',
      '2': 'Primary Muscles',
      '3': 'Secondary Muscles',
      '4': 'Instructions',
      '5': 'TTS Notes',
      '6': 'Exercise Images',
      '7': 'isCustom',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get exerciseImport => 'Import Exercise Json';

  @override
  String get exerciseLabelNote => 'LTR: index - code - name - level';

  @override
  String get exerciseImagePath => 'Select image public folder';

  @override
  String get exerciseDetail => 'Exercise Detail';

  @override
  String get workout => 'Workout';

  @override
  String get workoutSubtitle => 'Workout management';

  @override
  String get workouts => 'Workouts';

  @override
  String workoutQuerys(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Name',
      '1': 'Category',
      '2': 'Level',
      '3': '级别',
      '4': '类型',
      '5': '分类',
      '6': '器械',
      '7': '计量',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String groupDeleteAlert(Object workoutName) {
    return 'Are you sure you need to delete the workout: $workoutName? Deletion is not recoverable!';
  }

  @override
  String groupInUse(Object workoutName) {
    return 'Workout $workoutName in use, deletion is not supported';
  }

  @override
  String modifyGroupLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Workout Add',
      '1': 'Workout Modify',
      '2': '主要肌肉',
      '3': '次要肌肉',
      '4': '技术要点',
      '5': '语音提示要点',
      '6': '动作图片',
      '7': '用户上传',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String actionLabel(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Action',
      '1': 'Actions',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String actionDetailLabel(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Dur.(s)',
      '1': 'Rpt. (times)',
      '2': 'Eqpt. (kg)',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String actionConfigLabel(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Action Configuration Dialog',
      '1': 'Eqpt.Wgt.(kg)',
      '2': 'Click to select exercise',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String workoutFollowLabel(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Follow Workout',
      '1': 'Ready',
      '2': 'REST',
      '3': 'Next',
      '4': 'Congratulations',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get noTtsEngine => 'No available TTS engine';

  @override
  String get noTtsEngineDesc =>
      'Follow practice still works, just without voice prompts';

  @override
  String ttsEngineInfo(String engineName) {
    return 'Using TTS engine: $engineName';
  }

  @override
  String get selectTtsEngine => 'Select TTS Engine';

  @override
  String get multipleTtsEnginesFound =>
      'Multiple TTS engines detected, please select one:';

  @override
  String get ttsEngineCheckFail =>
      'TTS engine check failed; voice prompts may be unavailable';

  @override
  String followTtsLabel(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Ready, the next action is ',
      '1': 'It\'s half the time.',
      '2': 'Start',
      '3': 'Congratulations,the workout is over.',
      '4': 'Take a break, the next action',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String quitFollowNotes(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Workout Pause ',
      '1': 'Are you sure want to quit this workout?',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get previewReport => 'Report';

  @override
  String get plans => 'Plans';

  @override
  String get plan => 'Plan';

  @override
  String get planSubtitle => 'Plan management';

  @override
  String planQuerys(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Name',
      '1': 'Category',
      '2': 'Level',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String planDeleteAlert(Object planName) {
    return 'Are you sure you need to delete the plan: $planName? Deletion is not recoverable!';
  }

  @override
  String planInUse(Object planName) {
    return 'Plan $planName in use, deletion is not supported';
  }

  @override
  String modifyPlanLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Plan Add',
      '1': 'Plan Modify',
      '2': 'Name',
      '3': 'Code',
      '4': 'Category',
      '5': 'Level',
      '6': 'Plan Period',
      '7': 'Description',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String dayNumber(Object number) {
    return 'Day $number';
  }

  @override
  String dayCount(Object number) {
    return 'total $number day(s)';
  }

  @override
  String get incompleteLabel => 'Never Completed';

  @override
  String itemCount(Object count) {
    return '$count in total';
  }

  @override
  String get dietary => 'Dietary';

  @override
  String get dietaryReports => 'Dietary Reports';

  @override
  String get dietaryReportsSubtitle => 'Reports management';

  @override
  String get foodCompo => 'Food Composition';

  @override
  String get foodCompoSubtitle => 'Nutritional composition';

  @override
  String get dietaryRecords => 'Dietary Records';

  @override
  String get dietaryRecordsSubtitle => 'Daily dietary records';

  @override
  String get mealGallery => 'Meal Gallery';

  @override
  String get mealGallerySubtitle => 'View daily meal photos';

  @override
  String get mealPhotos => 'Meal Photos';

  @override
  String mealLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Breakfast',
      '1': 'Lunch',
      '2': 'Dinner',
      '3': 'Other',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get food => 'Foods';

  @override
  String get notFound => 'NotFound?';

  @override
  String get foodName => 'Name';

  @override
  String get foodDetail => 'Food Detail';

  @override
  String get foodBasicInfo => 'Food Basic Info';

  @override
  String get foodNutrientInfo => 'Food Nutrient Info';

  @override
  String get servingUnit => 'Serving Unit';

  @override
  String get servingEquivalence => 'Equivalence Unit';

  @override
  String get nutrientLabel => 'Nutrients';

  @override
  String get mainNutrientLabel => 'Main Nutrients';

  @override
  String get allNutrientLabel => 'Nutritional Information';

  @override
  String get eatableSize => 'Eatable';

  @override
  String get dietaryReportExport => 'Export dietary records';

  @override
  String foodTableMainLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Unit',
      '1': 'Energy(kcal)',
      '2': 'Protein(g)',
      '3': 'Fat(g)',
      '4': 'CHO(g)',
      '5': 'Micronutrient(mg)',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String foodLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Product',
      '1': 'Brand',
      '2': 'Tags',
      '3': 'Category',
      '4': 'Description',
      '5': 'Images',
      '6': 'Code',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String countLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Total',
      '1': 'AVG',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get foodImport => 'Import Food Json';

  @override
  String get importFinished => 'Data has been inserted into the database';

  @override
  String uploadingItem(Object obj) {
    return 'An overview of the $obj items:';
  }

  @override
  String get jsonFiles => 'Json Files:';

  @override
  String get foodLabelNote => 'LTR: index - code - name - energy(kcal)';

  @override
  String rangeLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Yesterday',
      '1': 'Today',
      '2': 'Tomorrow',
      '3': 'LastWeek',
      '4': 'ThisWeek',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String calorieLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Calories Remaining',
      '1': 'Calories Consumed',
      '2': 'Calories',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String illustratedDesc(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'The Proportion',
      '1': 'Main Nutrient Intake',
      '2': 'Calories',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String photoLabel(Object count) {
    return 'Photo ($count)';
  }

  @override
  String get photoUnitLabel => 'photo(s)';

  @override
  String dietaryAddTabs(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Recently Eaten',
      '1': 'Food List',
      '2': 'Size',
      '3': 'Unit',
      '4': 'New Unit?',
      '5': 'Meal',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String dietaryReportTabs(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Calories',
      '1': 'Macros',
      '2': 'Nutrients',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String intakeLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Foods Eaten',
      '1': 'Macros Eaten',
      '2': 'Times Eaten',
      '3': 'Cals(kcal)',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String goalAchieved(Object pct) {
    return '$pct% of goal';
  }

  @override
  String goalLabel(Object number) {
    return 'Goal: $number';
  }

  @override
  String get dietaryCalendar => 'Dietary Calendar';

  @override
  String dietaryCalendarLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Month Intake',
      '1': 'Today Intake',
      '2': 'Detailed Intake',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get diary => 'Diary';

  @override
  String get me => 'Me';

  @override
  String get closeLabel => 'Close';

  @override
  String get appExitInfo => 'Are you sure to exit Free Fitness?';

  @override
  String get userInfo => 'User Info';

  @override
  String diaryLables(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Diary Calendar',
      '1': 'Timeline',
      '2': 'Title',
      '3': 'Content',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String calenderLables(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Month',
      '1': '2 weeks',
      '2': 'Week',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get diaryTitleNote => ' All is well ^~^';

  @override
  String get diaryTagsNote => ' tags (split by entering comma or semi)';

  @override
  String get richTextToolNote => ' Expand Quill Toolbar';

  @override
  String get lastModified => 'Last Modified';

  @override
  String get gmtCreate => 'Created Time';

  @override
  String get confirmLabel => 'Confirm';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get resetLabel => 'reset';

  @override
  String get queryLabel => 'query';

  @override
  String get moreLabel => 'more';

  @override
  String get moreDetail => 'More Detail';

  @override
  String get lessLabel => 'less';

  @override
  String get enterLabel => 'Enter';

  @override
  String get skipLabel => 'Not Now';

  @override
  String get backLabel => 'Back';

  @override
  String get saveLabel => 'Save';

  @override
  String eidtLabel(Object name) {
    return 'Edit $name';
  }

  @override
  String get updateLabel => 'Update';

  @override
  String addLabel(Object name) {
    return 'Add $name';
  }

  @override
  String get deleteLabel => 'Delete';

  @override
  String get recordLabel => 'Record';

  @override
  String get manageLabel => 'Manage';

  @override
  String get removeSelected => 'Remove Selected';

  @override
  String get searchLabel => 'Search';

  @override
  String get optionsLabel => 'Options';

  @override
  String get imageUploadLabel => 'Image Upload';

  @override
  String get detailLabel => 'Detail';

  @override
  String get modifiedSuccessLabel => 'Successfully Modified';

  @override
  String get startLabel => 'Start';

  @override
  String get pauseLabel => 'Pause';

  @override
  String get resumeLabel => 'Resume';

  @override
  String get restartLabel => 'Restart';

  @override
  String get prevLabel => 'Prev';

  @override
  String get nextLabel => 'Next';

  @override
  String get doneLabel => 'Done';

  @override
  String get switchUser => 'Switch User';

  @override
  String get noteLabel => 'note';

  @override
  String get tipLabel => 'Notification';

  @override
  String itemLabel(Object num) {
    return '$num item(s)';
  }

  @override
  String get userGuide => 'User Guide';

  @override
  String get questionAndAnswer => 'Q&A';

  @override
  String get alertTitle => 'Alert';

  @override
  String get noRecordNote => 'No data yet.';

  @override
  String get noOtherUser => ' No other users';

  @override
  String lastDayLabels(Object count) {
    return 'last $count days';
  }

  @override
  String get allRecords => 'All data in selected range:';

  @override
  String get serialLabel => 'No.';

  @override
  String get measuredTime => 'Measured Time';

  @override
  String get selectDateRange => 'Change Range';

  @override
  String queryKeywordHintText(Object key) {
    return 'Please enter $key keywords';
  }

  @override
  String heightLabel(Object unit) {
    return 'Height$unit';
  }

  @override
  String weightLabel(Object unit) {
    return 'Weight$unit';
  }

  @override
  String get nameLabel => 'please input your name';

  @override
  String get genderLabel => 'please select your gender';

  @override
  String get exceptionWarningTitle => 'Exception Warning';

  @override
  String get deleteConfirm => 'Delete Confirm';

  @override
  String deleteNote(Object data) {
    return 'Are you sure to delete the selected data?$data';
  }

  @override
  String get deletedInfo => 'The item has been deleted.';

  @override
  String get initInfo =>
      'Could you please provide some basic info? \nOr just click \'Next\' button to use default info.';

  @override
  String get moreSettings => 'More Settings';

  @override
  String get languageSetting => 'Language';

  @override
  String get followSystem => 'System';

  @override
  String get themeSetting => 'Theme Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String settingLabels(String setting) {
    String _temp0 = intl.Intl.selectLogic(setting, {
      '0': 'Basic Info',
      '1': 'Weight Trend',
      '2': 'Intake Goal',
      '3': 'Training Setting',
      '4': 'Backup & Restore',
      '5': 'More Settings',
      'other': 'Unknown Setting',
    });
    return '$_temp0';
  }

  @override
  String get exportRangeNote => 'Select export range';

  @override
  String importJsonButtons(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'Select Json',
      '1': 'Clear Data',
      'other': 'Unknown Setting',
    });
    return '$_temp0';
  }

  @override
  String get importJsonError => 'Import json file error';

  @override
  String importJsonErrorText(Object msg, Object path) {
    return 'Filename:\n$path\n\nError:\n$msg';
  }

  @override
  String get invalidFormErrorText => 'Form validation failed';

  @override
  String uniqueErrorText(Object text) {
    return '$text already exists';
  }

  @override
  String get noStorageErrorText =>
      'The user has disabled access to internal storage and cannot import JSON files';

  @override
  String requiredErrorText(Object text) {
    return '$text required';
  }

  @override
  String numericErrorText(Object text) {
    return '$text must be numeric';
  }

  @override
  String get aiSuggestionTitle => 'AI Dietary Health Analysis';

  @override
  String get aiSuggestionHint =>
      'You can ask me questions for advice on healthy eating';

  @override
  String get regeneration => 'regen';

  @override
  String get copiedHint => 'cpoied';

  @override
  String get apiErrorHint =>
      'The HTTP API reports an error, please check the network or try again later!';

  @override
  String get noStorageHint =>
      'File management permissions have not been granted, and some features may be affected.';

  @override
  String get permissionRequest => 'Permission Request';

  @override
  String get featuresRestrictionNote =>
      'The features of display images, import exercise, import food composition, and data backup in the application require file management permissions. Please allow them.';

  @override
  String get appNote => 'Note';

  @override
  String get initFinished => 'InitFinished';

  @override
  String get initializing => 'Initializing, please wait for 3 minutes';

  @override
  String get initializingFood => 'Initializing Food Composition Data...';

  @override
  String get initializingExercise => 'Initializing Exercise Data...';

  @override
  String get loadEmbeddedExercise => 'Load embedded exercise';

  @override
  String get confirmLoadEmbeddedExercise =>
      'Load embedded exercise? This will overwrite duplicates.';

  @override
  String get loadEmbeddedFood => 'Load embedded Food';

  @override
  String get confirmLoadEmbeddedFood =>
      'Load embedded food? This will overwrite duplicates.';

  @override
  String get tipsTitle => 'Tips';

  @override
  String guideStepLabel(int num, Object name) {
    return 'Step $num/4 · $name';
  }

  @override
  String get guideStepIntro => 'Intro';

  @override
  String get guideStepStorage => 'Storage';

  @override
  String get guideStepData => 'Built-in Data';

  @override
  String get guideStepProfile => 'Profile';

  @override
  String get guideIntroTrainingTitle => 'Training';

  @override
  String get guideIntroTrainingDesc =>
      'Exercise library & period plans with guided workouts';

  @override
  String get guideIntroDietaryTitle => 'Dietary';

  @override
  String get guideIntroDietaryDesc =>
      'Food composition, servings, meal photos & daily intake';

  @override
  String get guideIntroDiaryTitle => 'Diary';

  @override
  String get guideIntroDiaryDesc =>
      'Rich-text notes and long-term weight trends';

  @override
  String get guideIntroAiTitle => 'AI Assistant';

  @override
  String get guideIntroAiDesc =>
      'Bring your own LLM API key for diet/training analysis';

  @override
  String get guideStorageTitle => 'Why storage permission?';

  @override
  String get guideStorageReason1 =>
      'Databases live in the app-specific directory, removed on uninstall';

  @override
  String get guideStorageReason2 =>
      'Backup & restore: full zip backups for device migration and safety';

  @override
  String get guideStorageReason3 =>
      'Images: diary photos and analyzed meal photos are copied for history';

  @override
  String get guideStorageGranted => '✓ Granted';

  @override
  String get guideStorageSkippable =>
      'You may skip; features will ask again later';

  @override
  String get guideDataTitle => 'Load built-in data?';

  @override
  String get guideDataHint => '(Recommended on first launch)';

  @override
  String get guideDataExerciseTitle => 'Built-in exercise library';

  @override
  String get guideDataExerciseDesc =>
      'Common strength/cardio exercises with categories';

  @override
  String get guideDataFoodTitle => 'Food composition table';

  @override
  String get guideDataFoodDesc =>
      'China Food Composition datasets with energy & macros';

  @override
  String get guideDataManualNote =>
      'Skip freely: use the flash icon on the exercise/food pages to import anytime.';

  @override
  String get guideBtnNext => 'Next';

  @override
  String get guideBtnSkipStep => 'Skip';

  @override
  String get guideBtnGrant => 'Grant & continue';

  @override
  String get guideBtnGranted => 'Granted, continue';

  @override
  String get guideBtnStartLoad => 'Start loading';

  @override
  String get guideBtnNoLoad => 'Skip loading';

  @override
  String get restoreSelectTitle => 'Select data to restore';

  @override
  String get restoreModUser => 'User & goals';

  @override
  String get restoreModUserDesc => 'Profiles / intake goals / weight trends';

  @override
  String get restoreModDietary => 'Dietary';

  @override
  String get restoreModDietaryDesc =>
      'Foods / servings / daily intake / meal photos';

  @override
  String get restoreModDiary => 'Diary';

  @override
  String get restoreModDiaryDesc => 'Rich-text notes';

  @override
  String get restoreModTraining => 'Training';

  @override
  String get restoreModTrainingDesc =>
      'Exercises / groups / plans / training logs\nBuilt-in items already on this device are kept as-is';

  @override
  String get restoreModAi => 'AI Assistant';

  @override
  String get restoreModAiDesc =>
      'Conversations / custom roles / LLM configs (incl. keys) / images';

  @override
  String get restoreMergeNote =>
      'Restore merges into existing data (deduplicated); an automatic full backup is made first.';

  @override
  String get restoreNoData => 'No restorable data in this backup';

  @override
  String get restorePhaseBackup => 'Backing up current data first';

  @override
  String get restorePhaseBackupNote => 'For rollback safety';

  @override
  String get restorePhaseLlm => 'Merging LLM configs';

  @override
  String get restorePhaseImages => 'Merging AI images';

  @override
  String restoreProgressDetail(int current, int total) {
    return '$current / $total rows merged';
  }

  @override
  String restoreResultNote(int inserted, int skipped) {
    return 'Restore merged: $inserted new, $skipped existing kept';
  }

  @override
  String restoreBuiltinNote(int count) {
    return '($count built-in entries kept)';
  }

  @override
  String get restoreTblUser => 'user profiles';

  @override
  String get restoreTblIntakeGoal => 'intake goals';

  @override
  String get restoreTblWeightTrend => 'weight trends';

  @override
  String get restoreTblFood => 'foods';

  @override
  String get restoreTblServing => 'servings';

  @override
  String get restoreTblDailyIntake => 'daily intake';

  @override
  String get restoreTblMealPhoto => 'meal photos';

  @override
  String get restoreTblDiary => 'diary notes';

  @override
  String get restoreTblExercise => 'exercises';

  @override
  String get restoreTblGroup => 'workout groups';

  @override
  String get restoreTblAction => 'plan actions';

  @override
  String get restoreTblPlan => 'plans';

  @override
  String get restoreTblPlanDay => 'plan schedules';

  @override
  String get restoreTblTrainLog => 'training logs';

  @override
  String get restoreTblAiConv => 'AI conversations';

  @override
  String get restoreTblAiMsg => 'AI messages';

  @override
  String get restoreTblAiRole => 'custom roles';

  @override
  String get llmConfigTitle => 'LLM Config';

  @override
  String get llmConfigStatusNone => 'Not configured';

  @override
  String llmConfigStatusCount(int count) {
    return '$count config(s)';
  }

  @override
  String get llmConfigEmpty =>
      'No configs yet.\nTap + to add an OpenAI-compatible LLM config.';

  @override
  String get llmConfigAddTooltip => 'Add config';

  @override
  String llmConfigDeleteNote(Object name) {
    return 'Delete config \"$name\"? Existing conversations keep their history (snapshot display).';
  }

  @override
  String get llmConfigPageAdd => 'Add LLM Config';

  @override
  String get llmConfigPageEdit => 'Edit LLM Config';

  @override
  String get llmConfigSaved => 'Saved';

  @override
  String get llmConfigFixForm => 'Please fix form errors first';

  @override
  String get llmConfigFieldName => 'Config name';

  @override
  String get llmConfigFieldNameHint => 'e.g. SiliconFlow-Qwen';

  @override
  String get llmConfigFieldUrl => 'API URL';

  @override
  String get llmConfigFieldKey => 'API Key';

  @override
  String get llmConfigFieldModel => 'Model';

  @override
  String get llmConfigFieldModelHint => 'e.g. Qwen/Qwen2.5-VL-32B-Instruct';

  @override
  String get llmConfigFieldVision => 'Supports vision';

  @override
  String get llmConfigFieldVisionNote =>
      'Most modern models are multimodal. Turn off for text-only models (e.g. deepseek-chat).';

  @override
  String get llmConfigFieldExtra => 'Advanced params (JSON, optional)';

  @override
  String get llmConfigFieldExtraNote =>
      'Merged into request body. Keys model/messages/stream are ignored.';

  @override
  String get llmConfigRequired => 'Required';

  @override
  String get llmConfigInvalidUrl => 'Invalid URL';

  @override
  String get llmConfigInvalidJson => 'Must be a valid JSON object';

  @override
  String get llmConfigQuickFill => 'Quick fill:';

  @override
  String get llmConfigTestConnection => 'Test connection';

  @override
  String get llmConfigTestVision => 'Test vision';

  @override
  String get llmConfigTestResult => 'Test result';

  @override
  String get llmConfigEmptyReply => '(empty reply)';

  @override
  String get llmConfigVisionTest => 'Vision test';

  @override
  String llmConfigVisionOk(Object reply) {
    return 'The model seems to support image input.\n\nReply: $reply';
  }

  @override
  String llmConfigVisionFail(Object detail) {
    return 'The model may NOT support image input.\n\n$detail';
  }

  @override
  String get llmConfigPingText => 'Hi, reply with \"ok\" only.';

  @override
  String get llmConfigVisionPingText => 'What color is this image?';

  @override
  String get llmGateNoKey =>
      'No LLM API key configured.\nPlease configure it in Me → More Settings → LLM Config first.';

  @override
  String get llmGateGoConfig => 'Go config';

  @override
  String get llmGateNoVision =>
      'No vision-capable model config.\nPlease enable \"supports vision\" on a config first.';

  @override
  String get aiChatNoConfig => 'No LLM config, please configure first';

  @override
  String get aiChatSwitchModel => 'Switch model';

  @override
  String get aiChatVisionTag => 'vision';

  @override
  String get aiChatModelNoVision =>
      'Current model doesn\'t support images; pending images removed';

  @override
  String get aiChatImageLimit => 'Up to 4 images';

  @override
  String get aiChatRename => 'Rename';

  @override
  String get aiChatClearNote => 'Clear all messages in this conversation?';

  @override
  String get aiChatDeleteNote =>
      'Delete this conversation? Messages and images will be removed too.';

  @override
  String get aiChatDeleteShort => 'Delete this conversation?';

  @override
  String get aiChatClearMessages => 'Clear messages';

  @override
  String get aiChatDeleteConversation => 'Delete conversation';

  @override
  String get aiChatNoConfigName => 'No config';

  @override
  String get aiChatInputHint => 'Ask anything...';

  @override
  String aiChatAskWith(Object name) {
    return 'Chat with $name:';
  }

  @override
  String get aiChatRegenerate => 'Regenerate';

  @override
  String get aiChatCopied => 'Copied';

  @override
  String aiChatTokenUsage(int inputTokens, int outputTokens, int totalTokens) {
    return 'tokens in:$inputTokens out:$outputTokens total:$totalTokens';
  }

  @override
  String get aiChatAddImage => 'Add images (up to 4)';

  @override
  String get aiChatTitle => 'AI Assistant';

  @override
  String get aiChatNewChat => 'New chat';

  @override
  String get aiChatManageRoles => 'Manage roles';

  @override
  String get aiChatHistory => 'History';

  @override
  String get aiChatNoHistory => 'No conversations yet';

  @override
  String get aiChatDataUpdated =>
      '(The data has been updated. Please analyze based on the following latest data.)';

  @override
  String get aiChatException => 'Exception';

  @override
  String get rolesTitle => 'Manage Roles';

  @override
  String get rolesBuiltIn => 'Built-in roles';

  @override
  String get rolesCustom => 'Custom roles';

  @override
  String get rolesEmptyCustom => 'No custom roles yet, tap + to add one';

  @override
  String get rolesAddTooltip => 'Add role';

  @override
  String rolesDeleteNote(Object name) {
    return 'Delete role \"$name\"? Existing conversations keep their history.';
  }

  @override
  String get rolePageAdd => 'Add Role';

  @override
  String get rolePageEdit => 'Edit Role';

  @override
  String get rolePageDetail => 'Role Details';

  @override
  String get roleReadOnlyNote =>
      'Built-in roles are read-only and cannot be modified or deleted';

  @override
  String get roleNameLabel => 'Role name';

  @override
  String get roleNameHint => 'e.g. Running Coach';

  @override
  String get rolePromptLabel => 'System prompt';

  @override
  String get rolePromptHint =>
      'Describe this role\'s expertise, tone and how it should answer...';

  @override
  String get rolePromptNote =>
      'This prompt will be used as the system message when chatting with this role.';

  @override
  String get roleInvalid => 'Name and prompt cannot be empty';

  @override
  String estMinutes(int minutes) {
    return '~$minutes min';
  }
}

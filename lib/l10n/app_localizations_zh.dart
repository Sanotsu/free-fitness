// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '悦动健康';

  @override
  String get report => '报告';

  @override
  String mainNutrients(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '能量',
      '1': '卡路里',
      '2': '蛋白质',
      '3': '脂肪',
      '4': '碳水',
      '5': 'RDI',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String fatNutrients(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '总脂肪',
      '1': '饱和脂肪',
      '2': '反式脂肪',
      '3': '多不饱和脂肪',
      '4': '单不饱和脂肪',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String choNutrients(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '总碳水化合物',
      '1': '糖',
      '2': '膳食纤维',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String microNutrients(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '钠',
      '1': '钾',
      '2': '胆固醇',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String unitLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '克',
      '1': '毫克',
      '2': '大卡',
      '3': '千焦',
      '4': '公分',
      '5': '公斤',
      '6': '秒',
      '7': '次',
      '8': '分钟',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String boolLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '是',
      '1': '否',
      '2': '真',
      '3': '假',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get averageGoal => '整体宏量素目标';

  @override
  String get dailyGoal => '每日宏量素目标';

  @override
  String get dailyGoalBars => '每日宏量素目标图示';

  @override
  String moduleTitles(String titles) {
    String _temp0 = intl.Intl.selectLogic(titles, {
      '0': '运动',
      '1': '饮食',
      '2': '手记日历',
      '3': '用户与设置',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String changeAvatarLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '切换头像',
      '1': '指定选项',
      '2': '拍照',
      '3': '相册',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String bakLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '备份恢复',
      '1': '全量备份',
      '2': '覆写恢复',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get bakOpNote => '确认导出所有数据?';

  @override
  String bakSuccessNote(Object dir) {
    return '已经保存到 $dir';
  }

  @override
  String get resSuccessNote => '原有数据已删除，备份数据已恢复。';

  @override
  String get restIntervals => '跟练动作间隔休息时间(秒)';

  @override
  String get chooseSeconds => '选择休息间隔(秒)';

  @override
  String bmiLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '偏瘦',
      '1': '正常',
      '2': '超重',
      '3': '肥胖',
      '4': '过胖',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get weightRecord => '体重记录';

  @override
  String userInfoLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '用户名称',
      '1': '用户代号',
      '2': '性别',
      '3': '出生年月',
      '4': '身高',
      '5': '体重',
      '6': '简述',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String userGoalLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': 'RDA',
      '1': '锻炼休息时间',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get training => '运动';

  @override
  String get trainingReports => '运动报告';

  @override
  String get trainingReportsSubtitle => '运动跟练的各项统计数据';

  @override
  String trainedReportLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '总锻炼次数',
      '1': '总锻炼时间',
      '2': '总休息时间',
      '3': '总暂停时间',
      '4': '总时间(分钟)',
      '5': '上次运动',
      '6': '日期',
      '7': '名称',
      '8': '用时',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String trainedCalendarLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '开始时间',
      '1': '结束时间',
      '2': '锻炼时长',
      '3': '暂停时长',
      '4': '休息时长',
      '5': '锻炼时间',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get trainedReportExport => '导出训练记录';

  @override
  String trainedDoneNote(Object totolTime) {
    return '你已完成所有锻炼\n总耗时 $totolTime 秒，其中：';
  }

  @override
  String get exercise => '动作';

  @override
  String get exerciseLabel => '基础动作';

  @override
  String get exerciseSubtitle => '管理运动的各个基础动作';

  @override
  String exerciseDeleteAlert(Object exerciseName) {
    return '确认要删除该动作: $exerciseName ? 删除后不可恢复!';
  }

  @override
  String exerciseInUse(Object exerciseName) {
    return '该动作 $exerciseName 有被训练或计划使用，暂不支持删除.';
  }

  @override
  String exerciseQuerys(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '训练部位',
      '1': '代号',
      '2': '名称',
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
  String exerciseLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '发力',
      '1': '标准动作耗时',
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
  String get exerciseImport => '导入动作JSON数据';

  @override
  String get exerciseLabelNote => '从左到右依次为: 索引-编号-名称-级别';

  @override
  String get exerciseImagePath => '选择json中图片公共文件夹';

  @override
  String get exerciseDetail => '动作详情';

  @override
  String get workout => '训练做组';

  @override
  String get workoutSubtitle => '制定专项的训练动作做组';

  @override
  String get workouts => '训练组';

  @override
  String workoutQuerys(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '名称',
      '1': '分类',
      '2': '难度',
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
    return '确认要删除该训练动作组: $workoutName ? 删除后不可恢复!';
  }

  @override
  String groupInUse(Object workoutName) {
    return '该训练 $workoutName 有被计划使用，暂不支持删除';
  }

  @override
  String modifyGroupLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '新建训练',
      '1': '修改训练',
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
      '0': '动作',
      '1': '动作',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String actionDetailLabel(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '时长(秒)',
      '1': '重复(次)',
      '2': '器械(公斤)',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String actionConfigLabel(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '动作配置弹窗',
      '1': '器械重量(公斤)',
      '2': '点击选择指定动作',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String workoutFollowLabel(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '开始锻炼',
      '1': '预备开始',
      '2': '休息',
      '3': '下一个',
      '4': '祝贺',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get noTtsEngine => '无可用TTS引擎';

  @override
  String followTtsLabel(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '预备开始，下一个动作：',
      '1': '一半时间了',
      '2': '开始',
      '3': '祝贺，锻炼已结束',
      '4': '休息一下，下一个动作：',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String quitFollowNotes(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '跟练中止',
      '1': '你确定要退出跟练吗？',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get previewReport => '查看报告';

  @override
  String get plans => '计划';

  @override
  String get plan => '周期计划';

  @override
  String get planSubtitle => '完成既定的每日训练计划';

  @override
  String planQuerys(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '名称',
      '1': '分类',
      '2': '难度',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String planDeleteAlert(Object planName) {
    return '确认要删除该训练计划: $planName ? 删除后不可恢复!';
  }

  @override
  String planInUse(Object planName) {
    return '该训练计划 $planName 存在跟练记录，暂不支持删除';
  }

  @override
  String modifyPlanLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '新建计划',
      '1': '修改计划',
      '2': '名称',
      '3': '代号',
      '4': '分类',
      '5': '级别',
      '6': '训练周期',
      '7': '概述',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String dayNumber(Object number) {
    return '第 $number 天';
  }

  @override
  String dayCount(Object number) {
    return '共 $number 天';
  }

  @override
  String get incompleteLabel => '从未跟练';

  @override
  String itemCount(Object count) {
    return '共 $count 条';
  }

  @override
  String get dietary => '饮食';

  @override
  String get dietaryReports => '饮食报告';

  @override
  String get dietaryReportsSubtitle => '饮食记录的各项统计报告';

  @override
  String get foodCompo => '食物成分';

  @override
  String get foodCompoSubtitle => '常见食物的营养成分标准';

  @override
  String get dietaryRecords => '饮食日记';

  @override
  String get dietaryRecordsSubtitle => '每日饮食的记录数据管理';

  @override
  String get mealGallery => '餐食相册';

  @override
  String get mealGallerySubtitle => '浏览已有的餐点食物照片';

  @override
  String get mealPhotos => '餐次相册';

  @override
  String mealLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '早餐',
      '1': '午餐',
      '2': '晚餐',
      '3': '小食',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get food => '食物';

  @override
  String get notFound => '找不到?';

  @override
  String get foodName => '食物名';

  @override
  String get foodDetail => '食物详情';

  @override
  String get foodBasicInfo => '食物基本信息';

  @override
  String get foodNutrientInfo => '食物单份营养素信息';

  @override
  String get servingUnit => '单份单位';

  @override
  String get servingEquivalence => '等价度量值及单位';

  @override
  String get nutrientLabel => '营养成分';

  @override
  String get mainNutrientLabel => '主要营养信息';

  @override
  String get allNutrientLabel => '全部营养信息';

  @override
  String get eatableSize => '食用量';

  @override
  String get dietaryReportExport => '导出饮食记录';

  @override
  String foodTableMainLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '单份',
      '1': '能量(大卡)',
      '2': '蛋白质(克)',
      '3': '脂肪(克)',
      '4': '碳水(克)',
      '5': '微量元素(毫克)',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String foodLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '名称',
      '1': '品牌',
      '2': '标签',
      '3': '分类',
      '4': '概述',
      '5': '图片',
      '6': '代号',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String countLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '总计',
      '1': '平均',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get foodImport => '导入食物JSON数据';

  @override
  String get importFinished => '数据已经插入数据库';

  @override
  String uploadingItem(Object obj) {
    return '待上传的$obj信息概述如下';
  }

  @override
  String get jsonFiles => 'json文件列表:';

  @override
  String get foodLabelNote => '从左到右为: 索引-代号-名称-能量(大卡)';

  @override
  String rangeLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '昨天',
      '1': '今天',
      '2': '明天',
      '3': '上周',
      '4': '本周',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String calorieLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '剩余的卡路里',
      '1': '消耗的卡路里',
      '2': '卡路里',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String illustratedDesc(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '当日三大营养素占比',
      '1': '主要营养素摄入量',
      '2': '卡路里',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String photoLabel(Object count) {
    return '照片 ($count)';
  }

  @override
  String get photoUnitLabel => '张照片';

  @override
  String dietaryAddTabs(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '最近记录',
      '1': '食物列表',
      '2': '数量',
      '3': '单位',
      '4': '添加新单位?',
      '5': '餐次',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String dietaryReportTabs(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '卡路里',
      '1': '宏量素',
      '2': '营养素',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String intakeLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '食物摄入',
      '1': '宏量素摄入',
      '2': '摄入次数',
      '3': '摄入大卡',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String goalAchieved(Object pct) {
    return '目标已达成$pct%';
  }

  @override
  String goalLabel(Object number) {
    return '目标: $number';
  }

  @override
  String get dietaryCalendar => '饮食日历表格统计';

  @override
  String dietaryCalendarLabels(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '当月摄入统计',
      '1': '当日摄入总量',
      '2': '详细摄入数据',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get diary => '手记';

  @override
  String get me => '我的';

  @override
  String get closeLabel => '关闭';

  @override
  String get appExitInfo => '确定要退出 Free Fitness 吗?';

  @override
  String get userInfo => '用户信息';

  @override
  String diaryLables(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '手记日历',
      '1': '手记时间线',
      '2': '手记标题',
      '3': '手记正文',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String calenderLables(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '展示整月',
      '1': '展示两周',
      '2': '展示一周',
      'other': '其他',
    });
    return '$_temp0';
  }

  @override
  String get diaryTitleNote => ' 一句话也好，哪怕想写的不多^~^';

  @override
  String get diaryTagsNote => ' 输入标签(输入逗号或分号自动分割)';

  @override
  String get richTextToolNote => '展开富文本编辑工具栏';

  @override
  String get lastModified => '上次修改';

  @override
  String get gmtCreate => '初始创建';

  @override
  String get confirmLabel => '确定';

  @override
  String get cancelLabel => '取消';

  @override
  String get resetLabel => '重置';

  @override
  String get queryLabel => '查询';

  @override
  String get moreLabel => '更多';

  @override
  String get moreDetail => '更多详情';

  @override
  String get lessLabel => '收起';

  @override
  String get enterLabel => '完成输入';

  @override
  String get skipLabel => '暂时忽略';

  @override
  String get backLabel => '返回';

  @override
  String get saveLabel => '保存';

  @override
  String eidtLabel(Object name) {
    return '修改$name';
  }

  @override
  String get updateLabel => '更新';

  @override
  String addLabel(Object name) {
    return '新增$name';
  }

  @override
  String get deleteLabel => '删除';

  @override
  String get recordLabel => '记录';

  @override
  String get manageLabel => '管理';

  @override
  String get removeSelected => '移除选中项次';

  @override
  String get searchLabel => '搜索';

  @override
  String get optionsLabel => '选项';

  @override
  String get imageUploadLabel => '图片上传';

  @override
  String get detailLabel => '详情';

  @override
  String get modifiedSuccessLabel => '变更成功';

  @override
  String get startLabel => '开始';

  @override
  String get pauseLabel => '暂停';

  @override
  String get resumeLabel => '继续';

  @override
  String get restartLabel => '重新开始';

  @override
  String get prevLabel => '上一个';

  @override
  String get nextLabel => '下一个';

  @override
  String get doneLabel => '完成';

  @override
  String get switchUser => '切换用户';

  @override
  String get noteLabel => '提示';

  @override
  String get tipLabel => '提示';

  @override
  String itemLabel(Object num) {
    return '$num 项';
  }

  @override
  String get userGuide => '用户手册';

  @override
  String get questionAndAnswer => '常见问题';

  @override
  String get alertTitle => '提示';

  @override
  String get noRecordNote => '暂无数据.';

  @override
  String get noOtherUser => ' 没有任何用户信息';

  @override
  String lastDayLabels(Object count) {
    return '最近$count天';
  }

  @override
  String get allRecords => '选中的日期范围内的所有数据:';

  @override
  String get serialLabel => '序号';

  @override
  String get measuredTime => '测量时间';

  @override
  String get selectDateRange => '选择范围';

  @override
  String queryKeywordHintText(Object key) {
    return '请输入$key关键字';
  }

  @override
  String heightLabel(Object unit) {
    return '身高$unit';
  }

  @override
  String weightLabel(Object unit) {
    return '体重$unit';
  }

  @override
  String get nameLabel => '怎么称呼您?';

  @override
  String get genderLabel => '请选择性别';

  @override
  String get exceptionWarningTitle => '异常提醒';

  @override
  String get deleteConfirm => '删除确认';

  @override
  String deleteNote(Object data) {
    return '确认删除选择的数据?$data';
  }

  @override
  String get deletedInfo => '该项次已被删除';

  @override
  String get initInfo => '初次使用，可以提供一些信息方便称呼\n可以跳过，使用可随时修改的预设数据';

  @override
  String get moreSettings => '更多设置';

  @override
  String get languageSetting => '切换语言';

  @override
  String get followSystem => '跟随系统';

  @override
  String get themeSetting => '切换主题';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String settingLabels(String setting) {
    String _temp0 = intl.Intl.selectLogic(setting, {
      '0': '基本信息',
      '1': '体重趋势',
      '2': '摄入目标',
      '3': '运动设置',
      '4': '备份恢复',
      '5': '更多设置',
      'other': '未知设置',
    });
    return '$_temp0';
  }

  @override
  String get exportRangeNote => '选择导出范围';

  @override
  String importJsonButtons(String num) {
    String _temp0 = intl.Intl.selectLogic(num, {
      '0': '选择文件',
      '1': '清空数据',
      'other': '未知设置',
    });
    return '$_temp0';
  }

  @override
  String get importJsonError => '导入json文件出错';

  @override
  String importJsonErrorText(Object msg, Object path) {
    return '文件名称:\n$path\n\n错误信息:\n$msg';
  }

  @override
  String get invalidFormErrorText => '表单验证未通过';

  @override
  String uniqueErrorText(Object text) {
    return '$text已存在';
  }

  @override
  String get noStorageErrorText => '用户已禁止访问内部存储,无法进行json文件导入。';

  @override
  String requiredErrorText(Object text) {
    return '$text不可为空';
  }

  @override
  String numericErrorText(Object text) {
    return '$text只能是数字';
  }

  @override
  String get aiSuggestionTitle => 'AI饮食健康分析';

  @override
  String get aiSuggestionHint => '可以向我提问，获取健康饮食相关建议';

  @override
  String get regeneration => '重新生成';

  @override
  String get copiedHint => '已复制到剪贴板';

  @override
  String get apiErrorHint => '接口报错，请检查网络或稍后重试';

  @override
  String get noStorageHint => '未授予文件管理权限，部分功能可能将会受到影响。';

  @override
  String get permissionRequest => '权限申请';

  @override
  String get featuresRestrictionNote =>
      '应用中显示图片、基础动作导入、营养成分导入、数据备份等功能需要文件管理权限，请允许。';

  @override
  String get appNote => '注意事项';

  @override
  String get initFinished => '初始化完成';

  @override
  String get initializing => '正在初始化应用，请耐心等待几分钟...';

  @override
  String get initializingFood => '正在初始化“食物成分”数据...';

  @override
  String get initializingExercise => '正在初始化“基础动作”数据...';

  @override
  String get loadEmbeddedExercise => '加载内置基础动作数据';

  @override
  String get confirmLoadEmbeddedExercise => '是否加载内置基础动作？同名动作会被覆盖';

  @override
  String get loadEmbeddedFood => '加载内置食物成分数据';

  @override
  String get confirmLoadEmbeddedFood =>
      '是否加载内置食物成分？同名《中国食物成分标准》“食物代号”或者“品牌+产品”的食品会被覆盖';
}

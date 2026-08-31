import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:numberpicker/numberpicker.dart';

import '../core/constants/constants.dart';
import '../core/storage/db_user_helper.dart';
import '../core/utils/tools.dart';
import '../core/widgets/import_progress_overlay.dart';
import '../l10n/app_localizations.dart';
import '../models/cus_app_localizations.dart';
import '../models/user_state.dart';
import '../services/exercise_importer_service.dart';
import '../services/food_importer_service.dart';
import 'home.dart';

///
/// 2026-08-27 首次使用的引导页面(四步向导重构)
///
/// 旧版仅一页"填基本信息"，且首启时在 SplashScreen 自动导入内置运动/食物数据、
/// 进入首页后才突兀地弹存储权限申请——流程割裂且缺乏解释。
/// 现改为顺序明确的四步：
///   第1页 App 功能简介；
///   第2页 存储权限用途说明+当场授权(不授权也可继续，进入首页后仍有兜底提示)；
///   第3页 是否加载内置运动动作/食物成分(可跳过；说明可在对应页面手动导入)；
///   第4页 填写基本信息(同旧版，姓名可留空用手机型号，身高体重有默认值)。
/// 完成后写入默认用户(userId=1)进首页；已有用户的升级安装不会看到本向导。
///
class InitGuidePage extends StatefulWidget {
  const InitGuidePage({super.key});

  @override
  State<InitGuidePage> createState() => _InitGuidePageState();
}

class _InitGuidePageState extends State<InitGuidePage> {
  final DBUserHelper _userHelper = DBUserHelper();

  // 四步向导的翻页控制(禁止左右滑动，只能按底部按钮推进)
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 第2页存储权限的当前授权状态
  bool _storageGranted = false;

  // 第3页内置数据的加载勾选(两项都取消等于跳过)
  bool _loadExercises = true;
  bool _loadFoods = true;

  // 用户输入的称呼
  final TextEditingController _usernameController = TextEditingController();
  // 用户选择的性别
  String selectedGender = "";

  double _currentWeight = 66;
  double _currentHeight = 170;

  // 初始化使用时的默认用户信息(根据用户是否有填写对应栏位修改对应栏位)
  var defaultUser = User(
    userId: 1,
    userName: "FF-user",
    userCode: "FF-user",
    gender: genderOptions.first.value,
    description: "一位富有爱心的 free-fitness 用户",
    password: "123456",
    dateOfBirth: "1994-07-02",
    height: 170,
    currentWeight: 66,
    targetWeight: 66,
    rdaGoal: 1800,
    proteinGoal: 120,
    fatGoal: 60,
    choGoal: 120,
    actionRestTime: 30,
  );

  // 2026-08-27 l10n 短别名(全部文案走 ARB，便于后续扩展语言)
  AppLocalizations get _l10n => CusAL.of(context);

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            children: [
              _buildStepHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  // 只能通过底部按钮逐步前进/返回，避免误滑过权限或导入页
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: [
                    _buildIntroPage(),
                    _buildPermissionPage(),
                    _buildBuiltinDataPage(),
                    _buildProfilePage(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== 顶部步骤指示 =====================

  Widget _buildStepHeader() {
    var stepNames = [
      _l10n.guideStepIntro,
      _l10n.guideStepStorage,
      _l10n.guideStepData,
      _l10n.guideStepProfile,
    ];

    return Padding(
      padding: EdgeInsets.only(top: 8.sp, bottom: 8.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 第1页没有可返回的内容，隐藏返回箭头
              if (_currentPage > 0)
                GestureDetector(
                  onTap: _goPrev,
                  child: Icon(Icons.arrow_back_ios_new, size: 18.sp),
                )
              else
                SizedBox(width: 18.sp),
              SizedBox(width: 10.sp),
              Text(
                _l10n.guideStepLabel(_currentPage + 1, stepNames[_currentPage]),
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          LinearProgressIndicator(value: (_currentPage + 1) / 4),
        ],
      ),
    );
  }

  void _goPrev() {
    if (_currentPage == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goNext() {
    if (_currentPage >= 3) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeIn,
    );
  }

  // ===================== 第1页：功能简介 =====================

  Widget _buildIntroPage() {
    var rows = [
      (
        Icons.fitness_center,
        _l10n.guideIntroTrainingTitle,
        _l10n.guideIntroTrainingDesc,
      ),
      (
        Icons.restaurant,
        _l10n.guideIntroDietaryTitle,
        _l10n.guideIntroDietaryDesc,
      ),
      (Icons.menu_book, _l10n.guideIntroDiaryTitle, _l10n.guideIntroDiaryDesc),
      (Icons.smart_toy, _l10n.guideIntroAiTitle, _l10n.guideIntroAiDesc),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          appLogoImageUrl,
          width: 72.sp,
          height: 72.sp,
          fit: BoxFit.cover,
        ),
        SizedBox(height: 8.sp),
        Text(
          CusAL.of(context).appTitle,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        SizedBox(height: 24.sp),
        ...rows.map(
          (r) => Padding(
            padding: EdgeInsets.symmetric(vertical: 10.sp),
            child: Row(
              children: [
                Icon(r.$1, size: 26.sp, color: Theme.of(context).primaryColor),
                SizedBox(width: 14.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.$2,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.sp),
                      Text(
                        r.$3,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===================== 第2页：存储权限说明 =====================

  Widget _buildPermissionPage() {
    var items = [
      _l10n.guideStorageReason1,
      _l10n.guideStorageReason2,
      _l10n.guideStorageReason3,
    ];

    return ListView(
      children: [
        SizedBox(height: 30.sp),
        Icon(
          Icons.folder_shared_outlined,
          size: 56.sp,
          color: Theme.of(context).primaryColor,
        ),
        SizedBox(height: 12.sp),
        Center(
          child: Text(
            _l10n.guideStorageTitle,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 16.sp),
        ...items.map(
          (t) => Padding(
            padding: EdgeInsets.symmetric(vertical: 6.sp),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18.sp,
                  color: Colors.green,
                ),
                SizedBox(width: 8.sp),
                Expanded(
                  child: Text(t, style: TextStyle(fontSize: 13.sp)),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.sp),
        Center(
          child: Text(
            _storageGranted
                ? _l10n.guideStorageGranted
                : _l10n.guideStorageSkippable,
            style: TextStyle(
              fontSize: 12.sp,
              color: _storageGranted ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // 当场发起授权(仅更新状态展示，无论结果都可继续流程)
  Future<void> _requestPermission() async {
    var granted = await requestStoragePermission();
    if (!mounted) return;
    setState(() {
      _storageGranted = granted;
    });
  }

  // ===================== 第3页：内置数据加载 =====================

  Widget _buildBuiltinDataPage() {
    return ListView(
      children: [
        SizedBox(height: 30.sp),
        Icon(
          Icons.dataset_outlined,
          size: 56.sp,
          color: Theme.of(context).primaryColor,
        ),
        SizedBox(height: 12.sp),
        Center(
          child: Text(
            _l10n.guideDataTitle,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 6.sp),
        Center(
          child: Text(
            _l10n.guideDataHint,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ),
        SizedBox(height: 16.sp),
        CheckboxListTile(
          value: _loadExercises,
          onChanged: (v) => setState(() => _loadExercises = v ?? false),
          title: Text(
            _l10n.guideDataExerciseTitle,
            style: TextStyle(fontSize: 15.sp),
          ),
          subtitle: Text(
            _l10n.guideDataExerciseDesc,
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
        CheckboxListTile(
          value: _loadFoods,
          onChanged: (v) => setState(() => _loadFoods = v ?? false),
          title: Text(
            _l10n.guideDataFoodTitle,
            style: TextStyle(fontSize: 15.sp),
          ),
          subtitle: Text(
            _l10n.guideDataFoodDesc,
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
        SizedBox(height: 12.sp),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.sp),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16.sp, color: Colors.grey),
              SizedBox(width: 6.sp),
              Expanded(
                child: Text(
                  _l10n.guideDataManualNote,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 按勾选带进度浮层导入(复用手动导入同一服务，内部自检重复)
  Future<void> _importBuiltinData(String languageCode) async {
    var closeOverlay = showImportProgressOverlay();
    try {
      if (_loadExercises) {
        await ExerciseImporterService().importEmbeddedExercises(languageCode);
      }
      if (_loadFoods) {
        await FoodImporterService().importEmbeddedFoods(languageCode);
      }
    } catch (_) {
      // 导入失败不打断引导，可稍后在对应页面手动重新导入
    } finally {
      closeOverlay();
    }
  }

  // 第3页主按钮：勾选了任一项就先导入再翻页
  Future<void> _onBuiltinDataProceed() async {
    if (_loadExercises || _loadFoods) {
      String languageCode = Localizations.localeOf(context).languageCode;
      await _importBuiltinData(languageCode);
    }
    if (!mounted) return;
    _goNext();
  }

  // ===================== 第4页：基本信息(沿用旧表单) =====================

  Widget _buildProfilePage() {
    String currentLanguage = Localizations.localeOf(context).languageCode;

    return ListView(
      children: [
        SizedBox(height: 30.sp),
        Text(CusAL.of(context).initInfo, textAlign: TextAlign.center),
        Padding(
          padding: EdgeInsets.all(10.sp),
          child: TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: CusAL.of(context).nameLabel,
              // 设置透明底色
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(10.sp),
          child: DropdownButtonFormField<CusLabel>(
            decoration: const InputDecoration(
              isDense: true,
              // 设置透明底色
              filled: true,
              fillColor: Colors.transparent,
            ),
            items: genderOptions.map((CusLabel gender) {
              return DropdownMenuItem<CusLabel>(
                value: gender,
                child: Text(
                  currentLanguage == 'zh' ? gender.cnLabel : gender.enLabel,
                ),
              );
            }).toList(),
            onChanged: (CusLabel? value) {
              setState(() {
                selectedGender = value?.value;
              });
            },
            hint: Text(CusAL.of(context).genderLabel),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(10.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Column(
                  children: [
                    Text(CusAL.of(context).heightLabel("(cm)")),
                    SizedBox(height: 10.sp),
                    DecimalNumberPicker(
                      value: _currentHeight,
                      minValue: 50,
                      maxValue: 240,
                      decimalPlaces: 1,
                      itemHeight: 30,
                      itemWidth: 60.sp,
                      onChanged: (value) =>
                          setState(() => _currentHeight = value),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(CusAL.of(context).weightLabel("(kg)")),
                    SizedBox(height: 10.sp),
                    DecimalNumberPicker(
                      value: _currentWeight,
                      minValue: 10,
                      maxValue: 300,
                      decimalPlaces: 1,
                      itemHeight: 30,
                      itemWidth: 60.sp,
                      onChanged: (value) =>
                          setState(() => _currentWeight = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.sp),
      ],
    );
  }

  // ===================== 底部导航区 =====================

  Widget _buildFooter() {
    var isLast = _currentPage == 3;

    // 各页主按钮文案
    String mainLabel = switch (_currentPage) {
      0 => _l10n.guideBtnNext,
      1 => _storageGranted ? _l10n.guideBtnGranted : _l10n.guideBtnGrant,
      2 =>
        (_loadExercises || _loadFoods)
            ? _l10n.guideBtnStartLoad
            : _l10n.guideBtnNoLoad,
      _ => CusAL.of(context).enterLabel,
    };

    Future<void> onMain() async {
      switch (_currentPage) {
        case 0:
          _goNext();
        case 1:
          if (!_storageGranted) {
            await _requestPermission();
            if (!mounted) return;
          }
          _goNext();
        case 2:
          await _onBuiltinDataProceed();
        default:
          await _finish(confirmByUser: true);
      }
    }

    // 第2/3/4页提供"跳过"次按钮(第4页跳过=用设备型号建用户)
    final showSkip = _currentPage >= 1;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (showSkip)
            TextButton(
              onPressed: () async {
                if (isLast) {
                  await _finish(confirmByUser: false);
                } else {
                  _goNext();
                }
              },
              child: Text(
                isLast ? CusAL.of(context).skipLabel : _l10n.guideBtnSkipStep,
                style: TextStyle(fontSize: 15.sp, color: Colors.grey),
              ),
            ),
          ElevatedButton(
            onPressed: onMain,
            style: ElevatedButton.styleFrom(minimumSize: Size(120.sp, 42.sp)),
            child: Text(mainLabel, style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }

  // ===================== 完成：落库进首页(逻辑同旧版) =====================

  Future<void> _finish({required bool confirmByUser}) async {
    if (confirmByUser) {
      final String username = _usernameController.text;
      // 用户有输入就用输入的，没有就使用默认的
      if (username.isNotEmpty) {
        defaultUser.userName = username;
      }
      if (selectedGender.isNotEmpty) {
        defaultUser.gender = selectedGender;
      }

      defaultUser.currentWeight = _currentWeight;
      defaultUser.height = _currentHeight;

      // ？？？这里应该检查保存是否成功
      await _userHelper.insertUserList([defaultUser]);
      // 注意用户编号类型要一致都用int，storage支持的类型String, int, double, Map and List
      await box.write(LocalStorageKey.userId, 1);
      await box.write(LocalStorageKey.userName, defaultUser.userName);

      var bmi = _currentWeight / (_currentHeight / 100 * _currentHeight / 100);
      // 新增体重趋势信息
      var temp = WeightTrend(
        userId: CacheUser.userId,
        weight: _currentWeight,
        weightUnit: 'kg',
        height: _currentHeight,
        heightUnit: 'cm',
        bmi: bmi,
        // 日期随机，带上一个插入时的time
        gmtCreate: getCurrentDateTime(),
      );

      // ？？？这里应该判断是否新增成功
      await _userHelper.insertWeightTrendList([temp]);
    } else {
      // 跳过：拿设备型号当用户名
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      var deviceName = "free-fitness-user";

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.utsname.machine;
      }

      defaultUser.userName = deviceName;
      defaultUser.description = "一位正在使用 Free-Fitness 的$deviceName用户";

      // ？？？这里应该检查保存是否成功
      await _userHelper.insertUserList([defaultUser]);
      // 注意用户编号类型要一致都用int，storage支持的类型String, int, double, Map and List
      await box.write(LocalStorageKey.userId, 1);
      await box.write(LocalStorageKey.userName, "$deviceName用户");
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }
}

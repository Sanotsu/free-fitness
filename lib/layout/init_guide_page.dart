import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:numberpicker/numberpicker.dart';

import '../common/global/constants.dart';
import '../common/utils/db_user_helper.dart';
import '../common/utils/tools.dart';
import '../models/cus_app_localizations.dart';
import '../models/user_state.dart';
import 'home.dart';

///
/// 首次使用的引导页面(占位)
///
/// 当用户首次进入app时，需要他填写一个用户名，作为默认的userId=1的初始用户。
///   不填的话就使用随机数或者获取手机型号？
///   填入或者自动获取手机型号之后，将这个唯一用户存入sqlite和storage，下次启动时获取storage的数据。
///
/// 如果启动app时获取storage的用户信息是空，就认为是首次使用，就跳动此登录页面。
///   如果能获取到，就从这里跳转到主页面去
class InitGuidePage extends StatefulWidget {
  const InitGuidePage({super.key});

  @override
  State<InitGuidePage> createState() => _InitGuidePageState();
}

class _InitGuidePageState extends State<InitGuidePage> {
  final DBUserHelper _userHelper = DBUserHelper();

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
    description: "一位富有爱心的free-fitness用户",
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

  @override
  Widget build(BuildContext context) {
    String currentLanguage = Localizations.localeOf(context).languageCode;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(CusAL.of(context).initInfo),
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
                      currentLanguage == "zh" ? gender.cnLabel : gender.enLabel,
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
            SizedBox(height: 20.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _login,
                  child: Text(
                    CusAL.of(context).enterLabel,
                    style: TextStyle(fontSize: 18.sp),
                  ),
                ),
                TextButton(
                  onPressed: _skip,
                  child: Text(
                    CusAL.of(context).skipLabel,
                    style: TextStyle(fontSize: 18.sp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _login() async {
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

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _skip() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    var deviceName = "free-fitness-user";

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.utsname.machine;
    }

    defaultUser.userName = "$deviceName 用户";
    defaultUser.userName = deviceName;
    defaultUser.description = "一位在使用free-fitness的$deviceName用户";

    // ？？？这里应该检查保存是否成功
    await _userHelper.insertUserList([defaultUser]);
    // 注意用户编号类型要一致都用int，storage支持的类型String, int, double, Map and List
    await box.write(LocalStorageKey.userId, 1);
    await box.write(LocalStorageKey.userName, "$deviceName用户");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common/global/constants.dart';
import '../common/utils/db_user_helper.dart';
import '../models/user_state.dart';
import 'home.dart';

///
/// 首次使用的引导页面(占位)
///
/// 当用户首次进入app时，需要他填写一个用户名，作为默认的userId=1的初始用户。
///   不填的话就使用随机数或者获取手机型号？
///   填入或者自动获取手机型号之后，讲这个唯一用户存入sqlite和storage，下次启动时获取storage的数据。
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

  // 初始化使用时的默认用户信息(根据用户是否有填写对应栏位修改对应栏位)
  var defaultUser = User(
    userId: 1,
    userName: "FF-user",
    userCode: "FF-user",
    gender: "雷霆战机",
    description: "一位极具爱心的free-fitness用户",
    password: "123456",
    dateOfBirth: "1994-07",
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("初次使用，可以提供一些信息方便称呼\n可以跳过，使用可随时修改的预设数据"),
            Padding(
              padding: EdgeInsets.all(10.sp),
              child: TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '怎么称呼您?',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.sp),
              child: DropdownButtonFormField<String>(
                items: genders.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? value) async {
                  setState(() {
                    selectedGender = value.toString();
                  });
                },
                hint: const Text('请选择性别'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
                TextButton(
                  onPressed: _skip,
                  child: const Text('Skip'),
                ),
              ],
            )
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

    // ？？？这里应该检查保存是否成功
    await _userHelper.insertUserList([defaultUser]);
    // 注意用户编号类型要一致都用int，storage支持的类型String, int, double, Map and List
    await box.write(LocalStorageKey.userId, 1);
    await box.write(LocalStorageKey.userName, username);

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
    await box.write(LocalStorageKey.userName, "$deviceName 用户");

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }
}

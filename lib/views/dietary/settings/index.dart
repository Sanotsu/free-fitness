// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/utils/sqlite_db_helper.dart';
import '../../../models/dietary_state.dart';
import 'base_info.dart';

class DietarySettings extends StatefulWidget {
  const DietarySettings({super.key});

  @override
  State<DietarySettings> createState() => _DietarySettingsState();
}

class _DietarySettingsState extends State<DietarySettings> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();

// ？？？登录用户信息，怎么在app中记录用户信息？缓存一个用户id每次都查？记住状态实时更新？……
  late DietaryUser userInfo;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _queryLoginedUserInfo();
  }

  // ？？？这里要传入用户信息供查询
  _queryLoginedUserInfo() async {
    // _dietaryHelper.deleteDb();
    // return;

    // // 测试，插入先
    // await _dietaryHelper.deleteDietaryUser(1);

    // var newItem = DietaryUser(
    //   userId: 1,
    //   userName: "张三",
    //   userCode: "测试code",
    //   gender: "雷霆战机",
    //   description: "测试描述",
    //   password: "123",
    //   dateOfBirth: "1994-07",
    //   height: 173,
    //   currentWeight: 68,
    //   targetWeight: 65.2,
    //   rdaGoal: 1200,
    //   proteinGoal: 85.5,
    //   fatGoal: 45.5,
    //   choGoal: 65.6,
    // );
    // var rst = await _dietaryHelper.insertDietaryUserList([newItem]);
    // print("_queryLoginedUserInfo-newItem: $newItem--rst: $rst");

    // return;

    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    var tempUser = await _dietaryHelper.queryDietaryUser(userId: 1);

    print("_queryLoginedUserInfo---tempUser: $tempUser");

    setState(() {
      userInfo = tempUser;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DietarySettings'),
        actions: [
          const Icon(Icons.menu),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.sp),
            child: const Icon(Icons.settings),
          )
        ],
      ),
      body: isLoading
          ? _buildLoader()
          : Container(
              color: Colors.white54,
              child: ListView(
                children: [
                  /// 用户信息区
                  SizedBox(height: 10.sp),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        maxRadius: 60.sp,
                        backgroundImage:
                            const AssetImage("assets/profile_icons/Avatar.jpg"),
                      ),
                      Positioned(
                        top: 40.sp,
                        right: 0.5.sw - 75.sp,
                        child: Icon(
                          userInfo.gender == "男"
                              ? Icons.male
                              : (userInfo.gender == "女"
                                  ? Icons.female
                                  : Icons.circle_outlined),
                          size: 30.sp,
                          color: userInfo.gender == "男"
                              ? Colors.red
                              : userInfo.gender == "女"
                                  ? Colors.green
                                  : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     CircleAvatar(
                  //       maxRadius: 65.sp,
                  //       backgroundImage:
                  //           const AssetImage("assets/profile_icons/Avatar.jpg"),
                  //     ),
                  //     SizedBox(width: 8.sp),
                  //     Icon(
                  //       userInfo.gender == "男"
                  //           ? Icons.male
                  //           : (userInfo.gender == "女"
                  //               ? Icons.female
                  //               : Icons.circle_outlined),
                  //       size: 30.sp,
                  //       color: userInfo.gender == "男"
                  //           ? Colors.red
                  //           : userInfo.gender == "女"
                  //               ? Colors.green
                  //               : Colors.black,
                  //     )
                  //   ],
                  // ),
                  SizedBox(height: 10.sp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        // maxRadius: 20.sp, // 最大半径
                        backgroundImage:
                            AssetImage("assets/profile_icons/Facebook.png"),
                      ),
                      SizedBox(width: 10.sp),
                      const CircleAvatar(
                        backgroundImage:
                            AssetImage("assets/profile_icons/GooglePlus.png"),
                      ),
                      SizedBox(width: 10.sp),
                      const CircleAvatar(
                        backgroundImage:
                            AssetImage("assets/profile_icons/Twitter.jpg"),
                      ),
                      SizedBox(width: 10.sp),
                      const CircleAvatar(
                        backgroundImage:
                            AssetImage("assets/profile_icons/LinkedIn.png"),
                      )
                    ],
                  ),
                  SizedBox(height: 10.sp),
                  // username
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userInfo.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 26.sp,
                        ),
                      )
                    ],
                  ),
                  // usercode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("@${userInfo.userCode ?? 'unkown'}"),
                    ],
                  ),
                  SizedBox(height: 10.sp),
                  // 用户简介 description
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userInfo.description ?? 'no description',
                        style: TextStyle(fontSize: 20.sp),
                      )
                    ],
                  ),
                  SizedBox(height: 10.sp),

                  /// 功能区
                  // 参看别的app大概留几个
                  CusSettingCard(
                    leadingIcon: Icons.account_circle_outlined,
                    title: '基本信息',
                    onTap: () {
                      // 处理相应的点击事件

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MyProfilePage(userInfo: userInfo),
                        ),
                      ).then((value) {
                        // 确认新增成功后重新加载当前日期的条目数据

                        print("我的设置返回带过来的结果$value");
                        _queryLoginedUserInfo();
                      });
                    },
                  ),
                  CusSettingCard(
                    leadingIcon: Icons.photo_album_outlined,
                    title: '摄入目标',
                    onTap: () {
                      // 处理相应的点击事件
                      print("(点击进入相册页面)……");
                    },
                  ),
                  CusSettingCard(
                    leadingIcon: Icons.photo_album_outlined,
                    title: '饮食相册',
                    onTap: () {
                      // 处理相应的点击事件
                      print("(点击进入相册页面)……");
                    },
                  ),
                  CusSettingCard(
                    leadingIcon: Icons.privacy_tip_sharp,
                    title: '语言选择(tbd)',
                    onTap: () {
                      // 处理相应的点击事件
                    },
                  ),
                  CusSettingCard(
                    leadingIcon: Icons.privacy_tip_sharp,
                    title: '到点提醒(tbd)',
                    onTap: () {
                      // 处理相应的点击事件
                    },
                  ),
                  CusSettingCard(
                    leadingIcon: Icons.privacy_tip_sharp,
                    title: '常见问题(tbd)',
                    onTap: () {
                      // 处理相应的点击事件
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoader() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Container();
    }
  }
}

// 每个设置card抽出来复用
class CusSettingCard extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final VoidCallback onTap;

  const CusSettingCard({
    Key? key,
    required this.leadingIcon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Colors.white70,
          margin: const EdgeInsets.only(left: 35, right: 35, bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: ListTile(
            leading: Icon(
              leadingIcon,
              color: Colors.black54,
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward, color: Colors.black54),
            onTap: onTap,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../models/user_state.dart';
import 'modify_user/index.dart';

class UserInfo extends StatefulWidget {
  const UserInfo({super.key});

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  final DBUserHelper _userHelper = DBUserHelper();

  late User user;
  // 用户头像路径
  String _avatarPath = "";

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _queryLoginedUserInfo();
  }

  _queryLoginedUserInfo() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    // 查询登录用户的信息一定会有的
    var tempUser = (await _userHelper.queryUser(userId: CacheUser.userId))!;

    print("_queryLoginedUserInfo---tempUser: $tempUser");

    setState(() {
      user = tempUser;
      if (tempUser.avatar != null) {
        _avatarPath = tempUser.avatar!;
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基本信息'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModifyUserPage(user: user),
                  ),
                ).then((value) {
                  // 确认新增成功后重新加载当前日期的条目数据

                  print("我的设置返回带过来的结果==========$value");
                  _queryLoginedUserInfo();
                });
              },
              child: const Text(
                "修改",
                style: TextStyle(color: Colors.white),
              ))
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : ListView(
              children: [
                SizedBox(height: 10.sp),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 没有修改头像，就用默认的
                    if (_avatarPath.isEmpty)
                      CircleAvatar(
                        maxRadius: 60.sp,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                            const AssetImage(defaultAvatarImageUrl),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey, width: 2.sp),
                          ),
                        ),
                      ),
                    if (_avatarPath.isNotEmpty)
                      CircleAvatar(
                        maxRadius: 60.sp,
                        backgroundImage: FileImage(File(_avatarPath)),
                      ),
                  ],
                ),
                Row(
                  children: [
                    _buildListItem('用户名称', user.userName),
                    _buildListItem('用户代号', user.userCode ?? ""),
                  ],
                ),
                Row(
                  children: [
                    _buildListItem(
                      '性别',
                      genderOptions
                          .firstWhere((e) => e.value == user.gender)
                          .cnLabel,
                    ),
                    _buildListItem('出生年月', user.dateOfBirth ?? ""),
                  ],
                ),
                Row(
                  children: [
                    _buildListItem('身高', '${user.height ?? ""} 公分'),
                    _buildListItem('体重', '${user.currentWeight ?? ""} 公斤'),
                  ],
                ),
                Row(
                  children: [
                    _buildListItem('RDA', '${user.rdaGoal ?? ""} 大卡'),
                    _buildListItem('锻炼休息时间', '${user.actionRestTime ?? ""} 秒'),
                  ],
                ),
                Row(
                  children: [
                    _buildListItem('简述', user.description ?? ""),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildListItem(String title, String value) {
    return Expanded(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/common/utils/tools.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../common/utils/tool_widgets.dart';
import '../../common/global/constants.dart';
import '../../common/utils/db_diary_helper.dart';
import '../../common/utils/db_dietary_helper.dart';
import '../../common/utils/db_training_helper.dart';
import '../../common/utils/db_user_helper.dart';
import '../../models/user_state.dart';
import '_feature_mock_data/index.dart';
import 'backup_and_restore/index.dart';
import 'intake_goals/intake_target.dart';
import 'training_setting/index.dart';
import 'user_gallery/meal_photo_gallery.dart';
import 'user_info/modify_user/index.dart';
import 'weight_change_record/index.dart';

class UserAndSettings extends StatefulWidget {
  const UserAndSettings({super.key});

  @override
  State<UserAndSettings> createState() => _UserAndSettingsState();
}

class _UserAndSettingsState extends State<UserAndSettings> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
  final DBTrainingHelper _trainingHelper = DBTrainingHelper();
  final DBDiaryHelper _diaryHelper = DBDiaryHelper();
  final DBUserHelper _userHelper = DBUserHelper();

  // 用户头像路径
  String _avatarPath = "";

  // 这里有修改，暂时不用get
  int currentUserId = 1;

// ？？？登录用户信息，怎么在app中记录用户信息？缓存一个用户id每次都查？记住状态实时更新？……
  late User userInfo;

  bool isLoading = false;

// 切换用户时，选择的用户
  User? selectedUser;

  @override
  void initState() {
    super.initState();

    setState(() {
      currentUserId = CacheUser.userId;
    });

    _queryLoginedUserInfo();
  }

  _queryLoginedUserInfo() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    // 查询登录用户的信息一定会有的
    var tempUser = (await _userHelper.queryUser(userId: currentUserId))!;

    print("_queryLoginedUserInfo---tempUser: $tempUser");

    setState(() {
      userInfo = tempUser;
      if (tempUser.avatar != null) {
        _avatarPath = tempUser.avatar!;
      }
      isLoading = false;
    });
  }

  // 弹窗切换用户
  _switchUser() async {
    var userList = await _userHelper.queryUserList();

    print("userList---$userList");

    if (!mounted) return;
    if (userList != null && userList.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text("无额外的用户信息"),
            actions: [
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
                child: const Text('确认'),
              ),
            ],
          );
        },
      );
    } else if (userList != null && userList.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('切换用户'),
            content: DropdownButtonFormField<User>(
              value: userList.firstWhere((e) => e.userId == currentUserId),
              items: userList.map((User user) {
                return DropdownMenuItem<User>(
                  value: user,
                  child: Text(user.userName),
                );
              }).toList(),
              onChanged: (User? value) async {
                setState(() {
                  selectedUser = value;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
                child: const Text('确认'),
              ),
            ],
          );
        },
      ).then((value) async {
        // 如果有返回值且为true，
        if (value != null && value) {
          // 修改缓存的用户编号
          CacheUser.updateUserId(selectedUser!.userId!);
          CacheUser.updateUserName(selectedUser!.userName);
          CacheUser.updateUserCode(selectedUser!.userCode ?? "");

          // 重新缓存当前用户编号和查询用户信息
          setState(() {
            currentUserId = CacheUser.userId;
            _queryLoginedUserInfo();
          });
        }
      });
    }
  }

  // 导出db中所有的数据
  _exportalldata() async {
    final status = await Permission.storage.request();
    // 用户没有授权，简单提示一下
    if (!mounted) return;
    if (!status.isGranted) {
      showSnackMessage(context, "用户已禁止访问内部存储,无法进行备份。");
      return;
    }

    // 用户选择指定文件夹
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    // 如果有选中文件夹，执行导出数据库的json文件，并添加到压缩档。
    if (selectedDirectory != null) {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      String tempZipName =
          "free-fitness-full-bak-${DateTime.now().millisecondsSinceEpoch}.zip";

      // 等到所有文件导出，都默认放在同一个文件夹下，所以就不用返回路径了
      await _userHelper.exportDatabase();
      await _dietaryHelper.exportDatabase();
      await _trainingHelper.exportDatabase();
      await _diaryHelper.exportDatabase();

      // 获取应用文档目录路径
      Directory appDocDir = await getApplicationDocumentsDirectory();

      // 存放所有json文件的文件夹
      String? filePath = p.join(appDocDir.path, "db_export/");

      // 创建或检索压缩包临时存放的文件夹
      var tempZipDir =
          await Directory(p.join(appDocDir.path, "temp_zip")).create();

      // 获取临时文件夹目录
      Directory tempDirectory = Directory(filePath);

      // 创建压缩文件
      final encoder = ZipFileEncoder();
      encoder.create(p.join(tempZipDir.path, tempZipName));

      // 遍历临时文件夹中的所有文件和子文件夹，并将它们添加到压缩文件中
      await for (FileSystemEntity entity
          in tempDirectory.list(recursive: true)) {
        if (entity is File) {
          encoder.addFile(entity);
        } else if (entity is Directory) {
          encoder.addDirectory(entity);
        }
      }

      // 完成并关闭压缩文件
      encoder.close();

      // 移动临时文件到用户选择的位置
      File sourceFile = File(p.join(tempZipDir.path, tempZipName));
      File destinationFile = File(p.join(selectedDirectory, tempZipName));

      if (destinationFile.existsSync()) {
        // 如果目标文件已经存在，则先删除
        destinationFile.deleteSync();
      }

      // 把文件从缓存的位置放到用户选择的位置
      sourceFile.copySync(p.join(selectedDirectory, tempZipName));
      print('文件已成功复制到：${p.join(selectedDirectory, tempZipName)}');

      // 导出完之后，清空文件夹中文件
      await deleteFilesInDirectory(filePath);
      // 删除临时zip文件
      if (sourceFile.existsSync()) {
        // 如果目标文件已经存在，则先删除
        sourceFile.deleteSync();
      }

      setState(() {
        isLoading = false;
      });

      if (!mounted) return;
      showSnackMessage(context, "已经保存到 $selectedDirectory");
    } else {
      print('保存操作已取消');
      return;
    }
  }

  // 修改头像
  // 选择图片来源
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _avatarPath = pickedFile.path;
      });

      var temp = userInfo;
      temp.avatar = _avatarPath;
      await _userHelper.updateUser(temp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户与设置'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeatureMockDemo(),
                ),
              );
            },
            icon: const Icon(Icons.bug_report),
          ),
          // 导出所有数据
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('全量备份'),
                    content: const Text("确认导出所有数据?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.pop(context, false);
                        },
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.pop(context, true);
                        },
                        child: const Text('确认'),
                      ),
                    ],
                  );
                },
              ).then((value) {
                print("value----------$value");

                if (value != null && value) _exportalldata();
              });
            },
            icon: const Icon(Icons.print),
          ),
          // 切换用户(切换后缓存的用户编号也得修改)
          IconButton(
            onPressed: _switchUser,
            icon: const Icon(Icons.toggle_on),
          ),
          // 新增用户(默认就一个用户，保存多个用户的数据就需要可以新增其他用户)
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModifyUserPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Container(
              color: Colors.white54,
              child: ListView(
                children: [
                  SizedBox(height: 10.sp),

                  /// 用户基本信息展示区域
                  ..._buildBaseUserInfoArea(userInfo),

                  /// 功能区
                  // 参看别的app大概留几个
                  _buildInfoAndWeightChangeRow(),

                  _buildIntakeGoalAndRestTimeRow(),

                  _buildMealPhotoAndQARow(),
                ],
              ),
            ),
    );
  }

  // 用户基本信息展示区域
  _buildBaseUserInfoArea(User userInfo) {
    return [
      Stack(
        alignment: Alignment.center,
        children: [
          // 没有修改头像，就用默认的
          if (_avatarPath.isEmpty)
            CircleAvatar(
              maxRadius: 60.sp,
              backgroundImage: const AssetImage(
                'assets/profile_icons/Avatar.jpg',
              ),
            ),
          if (_avatarPath.isNotEmpty)
            CircleAvatar(
              maxRadius: 60.sp,
              backgroundImage: FileImage(File(_avatarPath)),
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
      TextButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('指定选项'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.camera);
                    },
                    child: const Text('拍照'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.gallery);
                    },
                    child: const Text('相册'),
                  ),
                ],
              );
            },
          );
        },
        child: const Text('切换头像'),
      ),
      SizedBox(height: 10.sp),
      // username
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            userInfo.userName,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26.sp),
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20.sp),
          )
        ],
      ),
    ];
  }

  _buildInfoAndWeightChangeRow() {
    return Row(
      children: [
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.account_circle_outlined,
            title: '基本信息',
            onTap: () {
              // 处理相应的点击事件

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModifyUserPage(user: userInfo),
                ),
              ).then((value) {
                // 确认新增成功后重新加载当前日期的条目数据

                print("我的设置返回带过来的结果==========$value");
                _queryLoginedUserInfo();
              });
            },
          ),
        ),
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.flag_circle,
            title: '体重趋势',
            onTap: () {
              // 处理相应的点击事件
              print("(点击进入体重趋势页面)……");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeightChangeRecord(userInfo: userInfo),
                ),
              ).then((value) {
                // 确认新增成功后重新加载当前日期的条目数据

                print("运动设置返回带过来的结果$value");
                _queryLoginedUserInfo();
              });
            },
          ),
        ),
      ],
    );
  }

  _buildIntakeGoalAndRestTimeRow() {
    return Row(
      children: [
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.flag_circle,
            title: '摄入目标',
            onTap: () {
              // 处理相应的点击事件
              print("(点击进入摄入目标页面)……");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IntakeTargetPage(userInfo: userInfo),
                ),
              ).then((value) {
                // 确认新增成功后重新加载当前日期的条目数据

                print("我的设置返回带过来的结果$value");
                _queryLoginedUserInfo();
              });
            },
          ),
        ),
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.flag_circle,
            title: '运动设置',
            onTap: () {
              // 处理相应的点击事件
              print("(点击进入运动设置页面)……");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainingSetting(userInfo: userInfo),
                ),
              ).then((value) {
                // 确认新增成功后重新加载当前日期的条目数据

                print("运动设置返回带过来的结果$value");
                _queryLoginedUserInfo();
              });
            },
          ),
        ),
      ],
    );
  }

  _buildMealPhotoAndQARow() {
    return Row(
      children: [
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.photo_album_outlined,
            title: '饮食相册',
            onTap: () {
              // 处理相应的点击事件
              print("(点击进入饮食相册页面)……");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealPhotoGallery(),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.backup,
            title: '备份恢复',
            onTap: () {
              // 处理相应的点击事件
              print("(点击进入备份恢复页面)……");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupAndRestore(),
                ),
              );
            },
          ),
        ),
        // Expanded(
        //   child: NewCusSettingCard(
        //     leadingIcon: Icons.privacy_tip_sharp,
        //     title: '常见问题(tbd)',
        //     onTap: () {
        //       // 处理相应的点击事件
        //     },
        //   ),
        // ),
      ],
    );
  }
}

// 每个设置card抽出来复用
class NewCusSettingCard extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final VoidCallback onTap;

  const NewCusSettingCard({
    Key? key,
    required this.leadingIcon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.sp),
      // height: 100.sp,
      child: Card(
        elevation: 5,
        color: Colors.white70,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(leadingIcon, color: Colors.black54),
          title: Text(
            title,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

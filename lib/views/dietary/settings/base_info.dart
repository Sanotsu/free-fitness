// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../common/utils/sqlite_db_helper.dart';
import '../../../models/dietary_state.dart';

class MyProfilePage extends StatefulWidget {
  final DietaryUser userInfo;

  const MyProfilePage({super.key, required this.userInfo});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final DBDietaryHelper _dietaryHelper = DBDietaryHelper();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> genders = ['男', '女', '其他'];
  String selectedGender = "";

  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController rdaController = TextEditingController();

  late DietaryUser user;

  @override
  void initState() {
    super.initState();
    user = widget.userInfo;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 在这里执行返回按钮被点击时的逻辑
        // 比如执行 Navigator.pop() 返回前一个页面并携带数据
        Navigator.pop(context, {"refreshData": true});
        return true; // 返回true表示允许退出当前页面
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('基本信息'),
        ),
        body: ListView(
          children: [
            _buildListItem('用户名', user.userName, () {
              _showUserNameialog(context);
            }),
            _buildListItem('性别', user.gender ?? genders.first, () {
              _showGenderDialog(context);
            }),
            _buildListItem('出生年月', user.dateOfBirth ?? "", () {
              _showBirthdayDialog(context);
            }),
            _buildListItem('身高', '${user.height ?? ""} cm', () {
              _showHeightDialog(context);
            }),
            _buildListItem('体重', '${user.currentWeight ?? ""} kg', () {
              _showWeightDialog(context);
            }),
            _buildListItem('RDA', '${user.rdaGoal ?? ""} kcal', () {
              _showRDADialog(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String title, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      onTap: onTap,
    );
  }

  // ？？？弹窗关闭后就完成修改，还是点击保存再统一修改？2023-11-13选择前者
  // ？？？这里还是没有处理修改失败的问题

  void _showGenderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择性别'),
          content: DropdownButtonFormField<String>(
            value: user.gender,
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
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // 处理选中的性别
                setState(() {
                  user.gender = selectedGender;
                });

                print("user.gender --${user.gender}");

                await _dietaryHelper.updateDietaryUser(user);

                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  void _showBirthdayDialog(BuildContext context) {
    showDatePicker(
      context: context,
      // initialDate: DateTime.now(), // ？？？当前时间还是修改前时间
      initialDate: DateTime.tryParse(user.dateOfBirth ?? "") ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((DateTime? selectedDate) async {
      if (selectedDate != null) {
        setState(() {
          // 在这里更新用户的出生年月
          user.dateOfBirth = DateFormat('yyyy-MM-dd').format(selectedDate);
        });

        await _dietaryHelper.updateDietaryUser(user);
      }
    });
  }

  void _showUserNameialog(BuildContext context) {
    userNameController.text = user.userName;

    _showInputDialog(context, '修改用户名', '', userNameController, (value) async {
      setState(() {
        user.userName = value.toString();
      });

      await _dietaryHelper.updateDietaryUser(user);
    });
  }

  void _showWeightDialog(BuildContext context) {
    weightController.text = user.currentWeight.toString();

    _showInputDialog(context, '修改体重', 'kg', weightController, (value) async {
      // ？？？这里是回调函数中把修改后的数据保存到数据库？？？
      setState(() {
        double newWeight = double.parse(value);
        user.currentWeight = newWeight;
      });
      await _dietaryHelper.updateDietaryUser(user);
    });
  }

  void _showRDADialog(BuildContext context) {
    rdaController.text = user.rdaGoal.toString();

    _showInputDialog(context, '修改RDA值', '大卡', rdaController, (value) async {
      setState(() {
        int newRdaGoal = int.parse(value);
        user.rdaGoal = newRdaGoal;
      });
      await _dietaryHelper.updateDietaryUser(user);
    });
  }

  void _showHeightDialog(BuildContext context) {
    heightController.text = user.height.toString();

    _showInputDialog(context, '修改身高', 'cm', heightController, (value) async {
      setState(() {
        double newHeight = double.parse(value);
        user.height = newHeight;
      });
      await _dietaryHelper.updateDietaryUser(user);
    });
  }

  void _showInputDialog(
    BuildContext context,
    String title,
    String suffixText,
    TextEditingController controller,
    Function(dynamic) onConfirm,
  ) {
// 是否默认打开数字键盘（身高、体重、rda则打开，根据提示的单位来判断）

    bool showDecimal = false;
    if (suffixText.toLowerCase() == 'cm' ||
        suffixText.toLowerCase() == 'kg' ||
        suffixText.toLowerCase() == '大卡') {
      showDecimal = true;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: _formKey,
            // 注意：初始值和控制器不能同时存在
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                suffixText: suffixText,
              ),
              keyboardType:
                  TextInputType.numberWithOptions(decimal: showDecimal),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value!.isEmpty) {
                  return '请输入有效数值';
                }
                if (suffixText.toLowerCase() == 'kg' &&
                    double.tryParse(value) == null) {
                  return '请输入有效体重';
                }
                if (suffixText.toLowerCase() == 'cm' &&
                    double.tryParse(value) == null) {
                  return '请输入有效身高';
                }
                if (suffixText.toLowerCase() == '大卡' &&
                    double.tryParse(value) == null) {
                  return '请输入有效RDA';
                }
                return null;
              },
            ),
          ),
          // content: Row(
          //   children: <Widget>[
          //     Text(title),
          //     SizedBox(width: 8.sp),
          //     Expanded(
          //       child: TextFormField(
          //         controller: controller,
          //         decoration: InputDecoration(
          //           suffixText: suffixText,
          //         ),
          //         keyboardType: TextInputType.numberWithOptions(
          //           decimal: showDecimal,
          //         ),
          //         inputFormatters: <TextInputFormatter>[
          //           FilteringTextInputFormatter.allow(
          //             RegExp(r'^\d+\.?\d{0,2}'),
          //           ),
          //         ],
          //       ),
          //     ),
          //     // SizedBox(width: 8.sp),
          //     // Text(suffixText),
          //   ],
          // ),
          actions: <Widget>[
            TextButton(
              // 这里是点击保存把值给回调函数
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  onConfirm(controller.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }
}

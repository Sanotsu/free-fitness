import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

import '../../../../common/global/constants.dart';
import '../../../../common/utils/db_user_helper.dart';
import '../../../../common/utils/tool_widgets.dart';
import '../../../../models/user_state.dart';

class ModifyUserPage extends StatefulWidget {
  // 修改的时候可能会传用户信息
  final User? user;
  const ModifyUserPage({super.key, this.user});

  @override
  State<ModifyUserPage> createState() => _ModifyUserPageState();
}

class _ModifyUserPageState extends State<ModifyUserPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final DBUserHelper _userHelper = DBUserHelper();

  // 保存中
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果有传表单的初始对象值，就显示该值
      if (widget.user != null) {
        setState(() {
          _formKey.currentState?.patchValue(widget.user!.toStringMap());
        });
      } else {}
    });
  }

  _saveUser() async {
    if (_formKey.currentState!.saveAndValidate()) {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });

      var temp = _formKey.currentState!.value;

      var tempUser = User(
        userName: temp['user_name'],
        userCode: temp['user_code'],
        gender: (temp['gendar'] as CusLabel).value,
        dateOfBirth: temp['date_of_birth'] != null
            ? DateFormat(constDateFormat)
                .format(temp['date_of_birth'] as DateTime)
            : null,
        height: double.tryParse(temp['height']),
        currentWeight: double.tryParse(temp['current_weight']),
        rdaGoal: int.tryParse(temp['rda_goal']),
        actionRestTime: int.tryParse(temp['action_rest_time']),
        description: temp['description'],
      );

      try {
        if (widget.user == null) {
          await _userHelper.insertUserList([tempUser]);
        } else {
          tempUser.userId = widget.user!.userId!;
          await _userHelper.updateUser(tempUser);
        }

        if (!mounted) return;
        setState(() {
          isLoading = false;
        });

        Navigator.pop(context, true);
      } catch (e) {
        // 将错误信息展示给用户
        if (!mounted) return;
        commonExceptionDialog(context, "异常提醒", e.toString());

        setState(() {
          isLoading = false;
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? '新增用户信息' : '修改用户信息'),
        actions: [
          TextButton(
            onPressed: _saveUser,
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20.sp),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    ...buildFormDataColumns(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildFormDataColumns() {
    return [
      FormBuilderTextField(
        name: "user_name",
        decoration: const InputDecoration(labelText: "用户名"),
        keyboardType: TextInputType.name,
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(errorText: '用户名不可为空'),
        ]),
      ),
      FormBuilderTextField(
        name: "user_code",
        decoration: const InputDecoration(labelText: "用户代号"),
        keyboardType: TextInputType.name,
      ),
      FormBuilderDropdown<CusLabel>(
        name: "gendar",
        initialValue: widget.user == null
            ? genderOptions.first
            : genderOptions.firstWhere(
                (e) => e.value == widget.user?.gender,
                orElse: () => genderOptions.first,
              ),
        decoration: const InputDecoration(labelText: "性别"),
        items: genderOptions
            .map((unit) => DropdownMenuItem(
                  alignment: AlignmentDirectional.center,
                  value: unit,
                  child: Text(unit.cnLabel),
                ))
            .toList(),
      ),
      FormBuilderDateTimePicker(
        name: 'date_of_birth',
        initialEntryMode: DatePickerEntryMode.calendar,
        format: DateFormat(constDateFormat),
        initialValue: widget.user == null
            ? DateTime.now()
            : DateTime.tryParse(widget.user?.dateOfBirth ?? "1970-01-01"),
        inputType: InputType.date,
        decoration: InputDecoration(
          labelText: '出生年月',
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _formKey.currentState!.fields['date_of_birth']?.didChange(null);
            },
          ),
        ),
        locale: const Locale.fromSubtags(languageCode: 'zh'),
      ),
      Row(
        children: [
          Expanded(
            child: _buildDoubleTextField('height', "身高", "公分"),
          ),
          SizedBox(width: 10.sp),
          Expanded(
            child: _buildDoubleTextField('current_weight', "体重", "公斤"),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildDoubleTextField('rda_goal', "RDA", "大卡")),
          SizedBox(width: 10.sp),
          Expanded(
            child: _buildDoubleTextField('action_rest_time', "锻炼间隔休息时间", "秒"),
          ),
        ],
      ),
      FormBuilderTextField(
        name: "description",
        maxLines: 3,
        decoration: const InputDecoration(labelText: "简述"),
        keyboardType: TextInputType.name,
      ),
    ];
  }

  _buildDoubleTextField(String name, String labelText, String suffixText) {
    // 这里的只读就用全局的isEditing了，不作为参数传递了
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: labelText,
        suffixText: suffixText,
      ),
      // 正则来只允许输入数字和小数点
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
      ],
      keyboardType: TextInputType.number,
    );
  }
}

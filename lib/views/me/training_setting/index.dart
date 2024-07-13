import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_fitness/models/user_state.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../../common/utils/db_user_helper.dart';
import '../../../models/cus_app_localizations.dart';

class TrainingSetting extends StatefulWidget {
  final User userInfo;

  const TrainingSetting({super.key, required this.userInfo});

  @override
  State<TrainingSetting> createState() => _TrainingSettingState();
}

class _TrainingSettingState extends State<TrainingSetting> {
  final DBUserHelper _userHelper = DBUserHelper();

  // 当前的休息间隔时间
  int _currentNumber = 10;

  late User user;

  @override
  void initState() {
    super.initState();
    user = widget.userInfo;
    _currentNumber = user.actionRestTime ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CusAL.of(context).settingLabels('3')),
      ),
      body: ListView(
        children: [
          _buildListItem(
            CusAL.of(context).restIntervals,
            "${user.actionRestTime ?? 10}",
            () => _openActionRestTimeDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String title, dynamic value, VoidCallback onTap) {
    return Card(
      elevation: 5,
      child: ListTile(
        title: Text(title),
        subtitle: Text(value.toString()),
        onTap: onTap,
      ),
    );
  }

  Future _openActionRestTimeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            CusAL.of(context).chooseSeconds,
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return NumberPicker(
                itemCount: 3,
                minValue: 5,
                maxValue: 60,
                value: _currentNumber,
                // itemHeight: 40,
                // itemWidth: 40,
                // axis: Axis.horizontal,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.sp),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                onChanged: (value) => setState(() => _currentNumber = value),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(CusAL.of(context).cancelLabel),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  user.actionRestTime = _currentNumber;
                });

                await _userHelper.updateUser(user);

                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: Text(CusAL.of(context).confirmLabel),
            ),
          ],
        );
      },
    );
  }
}

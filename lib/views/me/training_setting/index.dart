// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:free_fitness/models/user_state.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../../common/utils/db_user_helper.dart';

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
        title: const Text('运动设置'),
      ),
      body: ListView(
        children: [
          _buildListItem(
            '跟练动作间隔休息时间',
            "${user.actionRestTime ?? 10} 秒",
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
          title: const Text('选择休息间隔(秒)', textAlign: TextAlign.center),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black26),
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
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  user.actionRestTime = _currentNumber;
                });

                await _userHelper.updateUser(user);

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
}

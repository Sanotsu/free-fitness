import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'modify_workouts_form.dart';

class TrainingWorkouts extends StatefulWidget {
  const TrainingWorkouts({super.key});

  @override
  State<TrainingWorkouts> createState() => _TrainingWorkoutsState();
}

class _TrainingWorkoutsState extends State<TrainingWorkouts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrainingWorkouts'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle: TextStyle(fontSize: 16.sp),
            ),
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext ctx) {
                    return const ModifyWorkoutsForm();
                  },
                ),
              );
            },
            child: const Text('新增'),
          )
        ],
      ),
      body: const Center(child: Text('TrainingWorkouts index')),
    );
  }
}

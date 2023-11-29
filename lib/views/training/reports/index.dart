import 'package:flutter/material.dart';

import '../exercise/_demos/image_demo.dart';

class TrainingReports extends StatefulWidget {
  const TrainingReports({super.key});

  @override
  State<TrainingReports> createState() => _TrainingReportsState();
}

class _TrainingReportsState extends State<TrainingReports> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrainingReports'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseImages(),
                ),
              );
            },
            child: const Text("图片示例"),
          ),
        ],
      ),
    );
  }
}

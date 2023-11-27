import 'package:flutter/material.dart';

import '_demos/cd_demo2.dart';

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
                  builder: (context) => const MyHomePage(),
                ),
              );
            },
            child: const Text("跟练示例"),
          ),
        ],
      ),
    );
  }
}

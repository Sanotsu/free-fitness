import 'package:flutter/material.dart';

class WorkoutReports extends StatefulWidget {
  const WorkoutReports({super.key});

  @override
  State<WorkoutReports> createState() => _WorkoutReportsState();
}

class _WorkoutReportsState extends State<WorkoutReports> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkoutReports'),
      ),
      body: const Center(child: Text('WorkoutReports index')),
    );
  }
}

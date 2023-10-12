import 'package:flutter/material.dart';

class WorkoutSettings extends StatefulWidget {
  const WorkoutSettings({super.key});

  @override
  State<WorkoutSettings> createState() => _WorkoutSettingsState();
}

class _WorkoutSettingsState extends State<WorkoutSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkoutSettings'),
      ),
      body: const Center(child: Text('WorkoutSettings index')),
    );
  }
}

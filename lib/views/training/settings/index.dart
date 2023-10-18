import 'package:flutter/material.dart';

class TrainingSettings extends StatefulWidget {
  const TrainingSettings({super.key});

  @override
  State<TrainingSettings> createState() => _TrainingSettingsState();
}

class _TrainingSettingsState extends State<TrainingSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrainingSettings'),
      ),
      body: const Center(child: Text('TrainingSettings index')),
    );
  }
}

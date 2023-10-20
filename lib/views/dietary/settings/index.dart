import 'package:flutter/material.dart';

class DietarySettings extends StatefulWidget {
  const DietarySettings({super.key});

  @override
  State<DietarySettings> createState() => _DietarySettingsState();
}

class _DietarySettingsState extends State<DietarySettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DietarySettings'),
      ),
      body: const Center(child: Text('DietarySettings index')),
    );
  }
}

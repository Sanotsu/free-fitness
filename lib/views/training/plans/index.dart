import 'package:flutter/material.dart';

class TrainingPlans extends StatefulWidget {
  const TrainingPlans({super.key});

  @override
  State<TrainingPlans> createState() => _TrainingPlansState();
}

class _TrainingPlansState extends State<TrainingPlans> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrainingPlans'),
      ),
      body: const Center(child: Text('TrainingPlans index')),
    );
  }
}

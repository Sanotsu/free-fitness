import 'package:flutter/material.dart';

class WorkoutPlans extends StatefulWidget {
  const WorkoutPlans({super.key});

  @override
  State<WorkoutPlans> createState() => _WorkoutPlansState();
}

class _WorkoutPlansState extends State<WorkoutPlans> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkoutPlans'),
      ),
      body: const Center(child: Text('WorkoutPlans index')),
    );
  }
}

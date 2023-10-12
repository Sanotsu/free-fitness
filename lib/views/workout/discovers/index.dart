import 'package:flutter/material.dart';

class WorkoutDiscovers extends StatefulWidget {
  const WorkoutDiscovers({super.key});

  @override
  State<WorkoutDiscovers> createState() => _WorkoutDiscoversState();
}

class _WorkoutDiscoversState extends State<WorkoutDiscovers> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkoutDiscovers'),
      ),
      body: const Center(child: Text('WorkoutDiscovers index')),
    );
  }
}

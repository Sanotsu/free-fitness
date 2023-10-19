import 'package:flutter/material.dart';

class DietaryReports extends StatefulWidget {
  const DietaryReports({super.key});

  @override
  State<DietaryReports> createState() => _DietaryReportsState();
}

class _DietaryReportsState extends State<DietaryReports> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DietaryReports'),
      ),
      body: const Center(child: Text('DietaryReports index')),
    );
  }
}

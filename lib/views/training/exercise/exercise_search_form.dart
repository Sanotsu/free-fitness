// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class ExerciseSearchForm extends StatefulWidget {
  const ExerciseSearchForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ExerciseSearchFormState createState() => _ExerciseSearchFormState();
}

class _ExerciseSearchFormState extends State<ExerciseSearchForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _showAdvancedOptions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Search'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    FormBuilderDropdown(
                      name: 'muscleGroup',
                      items: ['Chest', 'Back', 'Legs', 'Arms', 'Shoulders']
                          .map((muscle) => DropdownMenuItem(
                                value: muscle,
                                child: Text(muscle),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Muscle Group',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showAdvancedOptions = !_showAdvancedOptions;
                        });
                      },
                      child: Text(_showAdvancedOptions
                          ? 'Hide Advanced Options'
                          : 'Show Advanced Options'),
                    ),
                  ],
                ),
              ),
              if (_showAdvancedOptions) ...[
                // 更多查询条件
                FormBuilderTextField(
                  name: 'exerciseName',
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name',
                  ),
                ),
                // 其他表单字段
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // 执行查询操作
                    Map<String, dynamic> formData =
                        _formKey.currentState!.value;
                    print(formData); // 输出查询条件
                  }
                },
                child: const Text('Search'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

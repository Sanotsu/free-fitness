// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:free_fitness/models/training_state.dart';
// import 'package:intl/intl.dart';

import '../../../common/utils/sqlite_db_helper.dart';
// import '../../../common/utils/tools.dart';

enum ColorLabel {
  blue('Blue', Colors.blue),
  pink('Pink', Colors.pink),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  grey('Grey', Colors.grey);

  const ColorLabel(this.label, this.color);
  final String label;
  final Color color;
}

enum IconLabel {
  smile('Smile', Icons.sentiment_satisfied_outlined),
  cloud(
    'Cloud',
    Icons.cloud_outlined,
  ),
  brush('Brush', Icons.brush_outlined),
  heart('Heart', Icons.favorite);

  const IconLabel(this.label, this.icon);
  final String label;
  final IconData icon;
}

class TrainingExercise extends StatefulWidget {
  const TrainingExercise({super.key});

  @override
  State<TrainingExercise> createState() => _TrainingExerciseState();
}

class _TrainingExerciseState extends State<TrainingExercise> {
  final DBTrainHelper _dbHelper = DBTrainHelper();

  List<Exercise> exerciseList = [];

  @override
  void initState() {
    super.initState();
    _getAllExerciseList();
  }

  /// 获取数据库中已有的文件
  void _getAllExerciseList() async {
    print("11111111");

    var tempPdfStateList = await _dbHelper.queryExercise(
        // category: "12",
        // exerciseId: 123,
        // primaryMuscle: "abs",
        );

    print(tempPdfStateList);
    setState(() {
      exerciseList = tempPdfStateList;
    });
  }

  final TextEditingController colorController = TextEditingController();
  final TextEditingController iconController = TextEditingController();
  ColorLabel? selectedColor;
  IconLabel? selectedIcon;

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuEntry<ColorLabel>> colorEntries =
        <DropdownMenuEntry<ColorLabel>>[];
    for (final ColorLabel color in ColorLabel.values) {
      colorEntries.add(
        DropdownMenuEntry<ColorLabel>(
            value: color, label: color.label, enabled: color.label != 'Grey'),
      );
    }

    final List<DropdownMenuEntry<IconLabel>> iconEntries =
        <DropdownMenuEntry<IconLabel>>[];
    for (final IconLabel icon in IconLabel.values) {
      iconEntries
          .add(DropdownMenuEntry<IconLabel>(value: icon, label: icon.label));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrainingExercise'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DropdownMenu<ColorLabel>(
                    initialSelection: ColorLabel.green,
                    controller: colorController,
                    label: const Text('Color'),
                    dropdownMenuEntries: colorEntries,
                    onSelected: (ColorLabel? color) {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  DropdownMenu<IconLabel>(
                    controller: iconController,
                    enableFilter: true,
                    leadingIcon: const Icon(Icons.search),
                    label: const Text('Icon'),
                    dropdownMenuEntries: iconEntries,
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                    ),
                    onSelected: (IconLabel? icon) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                  )
                ],
              ),
            ),
            if (selectedColor != null && selectedIcon != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                      'You selected a ${selectedColor?.label} ${selectedIcon?.label}'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      selectedIcon?.icon,
                      color: selectedColor?.color,
                    ),
                  )
                ],
              )
            else
              const Text('Please select a color and an icon.')
          ],
        ),
      ),
      // body: Center(
      //   child: Column(
      //     children: [
      //       const Text('WorkoutDiscovers index'),
      //       TextButton(
      //         onPressed: () async {
      //           Exercise exercise = Exercise(
      //             category: "ok",
      //             exerciseCode: getRandomString(4),
      //             exerciseName: getRandomString(5),
      //             gmtCreate: DateFormat.yMMMd().format(DateTime.now()),
      //           );

      //           await _dbHelper.insertExercise(exercise);

      //           var list = await _dbHelper.queryExercise(
      //               // category: "12",
      //               // exerciseId: 123,
      //               // primaryMuscle: "abs",
      //               );

      //           print(list.length);
      //         },
      //         child: const Text('TextButton'),
      //       )
      //     ],
      //   ),
      // ),
    );
  }
}

import 'package:flutter/material.dart';

class PercentageWidget extends StatelessWidget {
  final double targetValue;
  final double actualValue;
  final int totalSquares;

  const PercentageWidget({
    super.key,
    required this.targetValue,
    required this.actualValue,
    this.totalSquares = 100,
  });

  @override
  Widget build(BuildContext context) {
    final filledSquares = (actualValue / targetValue * totalSquares).toInt();
    final emptySquares = totalSquares - filledSquares;

    return GridView.count(
      padding: const EdgeInsets.all(1),
      crossAxisCount: 10,
      childAspectRatio: 1.0, // 设置宽高比为1:1，使得每个格子都是正方形
      children: List.generate(
        totalSquares,
        (index) => Container(
          decoration: BoxDecoration(
            color: index < filledSquares ? Colors.black : Colors.transparent,
          ),
        ),
      )..addAll(
          List.generate(
            emptySquares,
            (index) => Container(),
          ),
        ),
    );
  }
}

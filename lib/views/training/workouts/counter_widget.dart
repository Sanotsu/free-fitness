import 'package:flutter/material.dart';

/// 用于动作配置时显示次数或者持续时间
///
class CounterWidget extends StatefulWidget {
  final bool isTimeMode;
  final int initialCount;
  final ValueChanged<int> onCountChanged;

  const CounterWidget({
    super.key,
    this.isTimeMode = false,
    this.initialCount = 0,
    required this.onCountChanged,
  });

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late int _count;
  bool get _isTimeMode => widget.isTimeMode;

  @override
  void initState() {
    super.initState();
    _count =
        widget.isTimeMode ? (widget.initialCount * 10) : widget.initialCount;
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _updateCount(int newCount) {
    if (_isTimeMode) {
      newCount = newCount < 10 ? 10 : newCount;
    } else {
      newCount = newCount < 1 ? 1 : newCount;
    }

    setState(() {
      _count = newCount;
      if (_isTimeMode) {
        widget.onCountChanged.call(_count ~/ 10);
      } else {
        widget.onCountChanged.call(_count);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: const Icon(
            Icons.remove_circle_outline,
            size: 36,
          ),
          // 最小值10秒或者1次，就不允许再点击
          onPressed: _count > (_isTimeMode ? 10 : 1)
              ? () {
                  _updateCount(_count - (_isTimeMode ? 10 : 1));
                }
              : null,
        ),
        Text(
          _isTimeMode ? _formatTime(_count) : _count.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 36.0),
        ),
        IconButton(
          icon: const Icon(
            Icons.add_circle_outline,
            size: 36,
          ),
          // 最大值300秒或者100次，就不允许再点击
          onPressed: _count < (_isTimeMode ? 300 : 100)
              ? () {
                  _updateCount(_count + (_isTimeMode ? 10 : 1));
                }
              : null,
        ),
      ],
    );
  }
}

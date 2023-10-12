import 'dart:math';

import 'package:intl/intl.dart';

// 10位的时间戳转字符串
String formatTimestampToString(int timestamp) {
  if (timestamp.toString().length == 10) {
    timestamp = timestamp * 1000;
  }

  if (timestamp.toString().length != 13) {
    return "输入的时间戳不是10位或者13位的整数";
  }

  return DateFormat.yMd('zh_CN')
      .add_Hms()
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
}

// 格式化Duration为 HH:MM:SS格式
formatDurationToString(Duration d) =>
    d.toString().split('.').first.padLeft(8, "0");

String formatDurationToString2(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

// 音频大小，从int的byte数值转为xxMB(保留2位小数)
String formatAudioSizeToString(int num) =>
    "${(num / 1024 / 1024).toStringAsFixed(2)} MB";

// 指定长度的随机字符串
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();
String getRandomString(int length) {
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );
}

// 获取文件大小（长度额bytes -> 字符串表示）
getFileSize(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

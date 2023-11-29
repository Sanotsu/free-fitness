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

// 格式化秒数为HH:mm:ss样式
String formatSeconds(double seconds, {String? formatString = "HH:mm:ss"}) {
  Duration duration = Duration(seconds: seconds.round());
  DateFormat formatter = DateFormat(formatString);
  return formatter.format(DateTime(0).add(duration));
}

// HH:mm:ss样式格式化为 Duration
Duration? convertToDuration(String timeStr, formatString) {
  List<String> parts = timeStr.split(':');

  if (formatString == "HH:mm:ss") {
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  if (formatString == "mm:ss") {
    return Duration(minutes: int.parse(parts[0]), seconds: int.parse(parts[1]));
  }

  if (formatString == "ss") {
    return Duration(seconds: int.parse(parts[1]));
  }

  // 如果传入的格式化不是HH:mm:ss的任何一种，返回null(之前的当前时间的duration)
  // return Duration(
  //   hours: DateTime.now().hour,
  //   minutes: DateTime.now().minute,
  //   seconds: DateTime.now().second,
  // );
  return null;
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

// 指定长度的范围的随机字符串(包含上面那个，最大最小同一个值即可)
String generateRandomString(int minLength, int maxLength) {
  int length = minLength + _rnd.nextInt(maxLength - minLength + 1);

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

// 获取当日格式化的日期字符串
String getCurrentDate() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd');
  final formattedDate = formatter.format(now);
  return formattedDate;
}

// 获取当前格式化的日期时间字符串
// 注意，这个格式化的规则才是固定的，尤其是时分秒
String getCurrentDateTime() =>
    DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

// 获取今天往前指定天数的所有日期字符串
List<String> getAdjacentDatesInRange(int days) {
  List<String> dateList = [];
  DateTime today = DateTime.now();
  DateFormat formatter = DateFormat('yyyy-MM-dd');

  for (int i = -days; i <= 0; i++) {
    DateTime date = today.add(Duration(days: i));
    String formattedDate = formatter.format(date);
    dateList.add(formattedDate);
  }

  return dateList;
}

// 小数转化为2位小数的字符串
//  如果转换为两位小数的字符串长度超过6(即999.99)，则四舍五入为整数
String formatDoubleToString(double number, {length = 6}) {
  String numberString = number.toStringAsFixed(2);
  return numberString.length > length
      ? number.toStringAsFixed(0)
      : numberString;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
/// 返回从[第一个]到[最后一个]（包括首尾两个）的[DateTime]对象列表。
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

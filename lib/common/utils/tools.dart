import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../global/constants.dart';

/// 默认的日历显示范围，当前月的前后3个月
final kToday = DateTime.now();
final kFirstDay = DateTime(2023, 10, 12);
final kLastDay = DateTime(kToday.year, kToday.month + 1, 15);

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
String formatSeconds(double seconds, {String? formatString = constTimeFormat}) {
  Duration duration = Duration(seconds: seconds.round());
  DateFormat formatter = DateFormat(formatString);
  return formatter.format(DateTime(0).add(duration));
}

// HH:mm:ss样式格式化为 Duration
Duration? convertToDuration(String timeStr, formatString) {
  List<String> parts = timeStr.split(':');

  if (formatString == constTimeFormat) {
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
  final formatter = DateFormat(constDateFormat);
  final formattedDate = formatter.format(now);
  return formattedDate;
}

// 格式化知道日期时间格式为指定字符串格式
String formatDateToString(
  DateTime dateTime, {
  String? formatter = constDateFormat,
}) =>
    DateFormat(formatter).format(dateTime);

// 获取当前格式化的日期时间字符串
// 注意，这个格式化的规则才是固定的，尤其是时分秒
String getCurrentDateTime() =>
    DateFormat(constDatetimeFormat).format(DateTime.now());

// 获取今天往前指定天数的所有日期字符串
List<String> getAdjacentDatesInRange(int days) {
  List<String> dateList = [];
  DateTime today = DateTime.now();
  DateFormat formatter = DateFormat(constDateFormat);

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

// 小数转化为2位小数的字符串
//  如果转换为两位小数的字符串长度超过6(即999.99)，则四舍五入为整数
String cusDoubleToString(double? number, {length = 6}) {
  if (number == null) return "";
  String numberString = number.toStringAsFixed(2);
  return numberString.length > length
      ? number.toStringAsFixed(0)
      : numberString;
}

// 如果传入的double没有小数部分，才转为整数字符串；否则就保留指定位数的小数字符串
String cusDoubleTryToIntString(double number, {int decimalLength = 2}) => number
    .toStringAsFixed(number.truncateToDouble() == number ? 0 : decimalLength);

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
/// 返回从[第一个]到[最后一个]（包括首尾两个）的[DateTime]对象列表。
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

// 默认的结束日期就是此时此刻；开始日期就是当前时刻 减去 指定天数
List<String> getStartEndDateString(int lastDays) {
  // 获取当前时间的字符串表示
  String endDate = DateFormat(constDatetimeFormat).format(DateTime.now());

  // 获取指定天数前的日期
  String startDate = DateFormat(constDatetimeFormat)
      .format(DateTime.now().subtract(Duration(days: lastDays)));

  return [startDate, endDate];
}

// 获取当月第一天和最后一天
List<String> getCurrentMonthStartEndDateString() {
  // 获取当前日期
  DateTime now = DateTime.now();

  // 获取当前月的第一天
  DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

  // 获取下个月的第一天，然后减去一天，即为当前月的最后一天
  DateTime lastDayOfMonth =
      DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));

  // 格式化日期为指定日期形式
  String startDate = DateFormat(constDateFormat).format(firstDayOfMonth);
  String endDate = DateFormat(constDateFormat).format(lastDayOfMonth);

  return [startDate, endDate];
}

// 指定某一天的日期，获取当前日期所在月份的第一天和最后一天的日期字符串
List<String> getMonthStartEndDateString(
  DateTime date, {
  String? formatterString = constDateFormat,
}) {
  // 获取指定月的第一天和最后一天
  DateTime firstDayOfMonth = DateTime(date.year, date.month, 1);
  DateTime lastDayOfMonth = DateTime(date.year, date.month + 1, 0);

  // 格式化为指定样式字符串
  DateFormat formatter = DateFormat(formatterString);
  String startDate = formatter.format(firstDayOfMonth);
  String endDate = formatter.format(lastDayOfMonth);

  return [startDate, endDate];
}

// formbuilder的图片地址拼接的字符串，要转回平台文件列表
List<PlatformFile> convertStringToPlatformFiles(String imagesString) {
  List<String> imageUrls = imagesString.split(','); // 拆分字符串
  // 如果本身就是空字符串，直接返回空平台文件数组
  if (imagesString.trim().isEmpty || imageUrls.isEmpty) {
    return [];
  }

  List<PlatformFile> platformFiles = []; // 存储 PlatformFile 对象的列表

  for (var imageUrl in imageUrls) {
    PlatformFile file = PlatformFile(
      name: imageUrl,
      path: imageUrl,
      size: 32, // 假设图片地址即为文件路径
    );
    platformFiles.add(file);
  }

  return platformFiles;
}

// 把驼峰命名法的栏位转为全小写下划线连接  snake_case 方式表示
String getPropName(String camelCaseName) {
  final pattern = RegExp(r'[A-Z]');
  return camelCaseName.splitMapJoin(pattern,
      onMatch: (m) => '_${m.group(0)?.toLowerCase()}');
}

// 删除指定文件夹下所有文件
Future<void> deleteFilesInDirectory(String directoryPath) async {
  final directory = Directory(directoryPath);
  if (await directory.exists()) {
    await for (var file in directory.list()) {
      if (file is File) {
        await file.delete();
      }
    }
  }
}

// 根据当前语言显示 CusLabel 的 中文或者英文
String showCusLableMapLabel(BuildContext context, CusLabel? cusLable) {
  String curLang = Localizations.localeOf(context).languageCode;
  return curLang == "zh" ? cusLable?.cnLabel ?? '' : cusLable?.enLabel ?? '';
}

// 根据当前语言显示自定义标签的文字(上面那个不传context版本)
String showCusLable(CusLabel cusLable) {
  return box.read('language') == "en" ? cusLable.enLabel : cusLable.cnLabel;
}

// 根据传入的值和对应的自定义标签列表，显示对应语言的标签
getCusLabelText(String item, List<CusLabel> options) {
  // 才根据数据库存的是英文，这里找到对应的中英文文显示
  var op = options.firstWhere(
    (element) => element.value == item,
    orElse: () => CusLabel(cnLabel: '[无]', enLabel: 'No Data', value: ''),
  );

  return box.read('language') == "en" ? op.enLabel : op.cnLabel;
}

// 只请求内部存储访问权限(食物营养素、锻炼动作导入；备份还原等)
Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    // 获取设备sdk版本
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt <= 32) {
      var storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else {
      var storageStatus = await Permission.manageExternalStorage.request();
      return (storageStatus.isGranted);
    }
  } else if (Platform.isIOS) {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.mediaLibrary,
      Permission.storage,
    ].request();
    return (statuses[Permission.mediaLibrary]!.isGranted &&
        statuses[Permission.storage]!.isGranted);
  } else {
    // 除了安卓和ios其他先不考虑
    return false;
  }
}

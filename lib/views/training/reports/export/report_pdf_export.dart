// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
// import 'package:printing/printing.dart';

import '../../../../common/global/constants.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/training_state.dart';

Map<String, CusLabel> _pdfLabelMap = {
  "title": CusLabel(
      enLabel: 'Export trained records', cnLabel: "运动日志条目导出", value: null),
  "headerLeft":
      CusLabel(enLabel: 'trained records', cnLabel: "运动条目记录", value: null),
  "headerRight": CusLabel(
      enLabel: 'exported by free-fitness',
      cnLabel: "由free-fitness导出",
      value: null),
  "number": CusLabel(enLabel: 'Page', cnLabel: "第", value: null),
  "page": CusLabel(enLabel: '', cnLabel: "页", value: null),
  "name": CusLabel(enLabel: 'Name', cnLabel: "训练名称", value: null),
  "dayNumber": CusLabel(enLabel: 'Day', cnLabel: "训练日", value: null),
  "startAndEnd":
      CusLabel(enLabel: 'Start & End Time', cnLabel: "训练起止时间", value: null),
  "trainedDuration": CusLabel(
      enLabel: 'Trained Dur. \n(mins)', cnLabel: "训练耗时(分钟)", value: null),
  "restDuration":
      CusLabel(enLabel: 'Rest Dur. \n(mins)', cnLabel: "休息耗时(分钟)", value: null),
  "pausedDuration": CusLabel(
      enLabel: 'Paused Dur. \n(mins)', cnLabel: "暂停耗时(分钟)", value: null),
  "total": CusLabel(enLabel: 'Total', cnLabel: "合计", value: null),
};

// 根据当前语言显示 CusLabel 的 中文或者英文
String _showLabel(String lang, CusLabel cusLable) {
  return lang == "en" ? cusLable.enLabel : cusLable.cnLabel;
}

Future<Uint8List> makeTrainedReportPdf(
  List<TrainedDetailLog> list,
  String startDate,
  String endDate, {
  String lang = "cn",
}) async {
  // 创建PDF文档
  final pdf = pw.Document(
    title: _showLabel(lang, _pdfLabelMap['title']!),
    author: "free-fitness",
    pageMode: PdfPageMode.fullscreen,
    theme: pw.ThemeData.withFont(
      // 谷歌字体不一定能够访问,但肯定是联网下载，且存在内存中，下一次导出会需要重新下载
      // https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management
      // base: await PdfGoogleFonts.notoSerifHKRegular(),
      // bold: await PdfGoogleFonts.notoSerifHKBold(),
      // 但是使用知道的本地字体，会增加app体积
      base: Font.ttf(await rootBundle.load("assets/MiSans-Regular.ttf")),
      fontFallback: [
        pw.Font.ttf(await rootBundle.load('assets/MiSans-Regular.ttf'))
      ],
    ),
  );

  // 1 先把条目按天分类，每天的所有餐次放到一致pdf中
  Map<String, List<TrainedDetailLog>> logGroupedByDate = {};
  for (var log in list) {
    // 日志的日期(不含时间)
    // 训练记录的训练日志存入的是完整的datetime，这里只取date部分
    var tempDate = log.trainedDate.split(" ")[0];

    if (logGroupedByDate.containsKey(tempDate)) {
      logGroupedByDate[tempDate]!.add(log);
    } else {
      logGroupedByDate[tempDate] = [log];
    }
  }

  for (var date in logGroupedByDate.keys) {
    final data = logGroupedByDate[date];

    if (data != null && data.isNotEmpty) {
      // 2 构建每天的数据页面(当天的记录列表，当天的日期，查询日志的起止范围)
      pdf.addPage(_buildPdfPage(data, date, startDate, endDate, lang));
    }
  }

  return pdf.save();
}

// 构建pdf的页面
_buildPdfPage(
  List<TrainedDetailLog> logData,
  String date,
  String startDate,
  String endDate,
  String lang,
) {
  var trainedDate = DateTime.parse(date);
  return pw.Page(
    // theme和format两者不能同时存在
    pageTheme: pw.PageTheme(margin: pw.EdgeInsets.all(10.sp)),
    // 页面展示横向显示
    // pageFormat: PdfPageFormat.a4.landscape,
    build: (context) {
      return pw.Column(
        children: [
          // 页首
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${_showLabel(lang, _pdfLabelMap['headerLeft']!)} $startDate ~ $endDate',
                ),
                pw.Text(_showLabel(lang, _pdfLabelMap['headerRight']!)),
              ],
            ),
          ),
          // 最上面显示日期
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 10.sp),
            child: pw.Text(
              DateFormat.yMMMMEEEEd().format(trainedDate),
              style: pw.TextStyle(fontSize: 12.sp),
              textAlign: pw.TextAlign.left,
            ),
          ),
          // 只有一行数据的表格当做标题
          _buildHeaderTable(lang),
          // // 分割线
          // pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
          // 具体运动日志的表格数据
          _buildBodyTable(logData, lang),

          // 页脚内容
          pw.Footer(
            margin: const pw.EdgeInsets.only(top: 0.5 * PdfPageFormat.cm),
            trailing: pw.Text(
              '${_showLabel(lang, _pdfLabelMap['number']!)} ${context.pageNumber}/${context.pagesCount} ${_showLabel(lang, _pdfLabelMap['page']!)}',
              style: pw.TextStyle(fontSize: 12.sp),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      );
    },
  );
}

// 构建pdf统计页面的标题部分(只有一行数据的表格当做标题)
_buildHeaderTable(String lang) {
  return pw.Table(
    // 表格的边框设置
    border: pw.TableBorder.all(color: PdfColors.black),
    children: [
      pw.TableRow(
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              _showLabel(lang, _pdfLabelMap['name']!),
              textAlign: pw.TextAlign.left,
            ),
          ),
          expandedHeadText(
            _showLabel(lang, _pdfLabelMap['startAndEnd']!),
            flex: 2,
          ),
          expandedHeadText(
            _showLabel(lang, _pdfLabelMap['trainedDuration']!),
            flex: 2,
          ),
          expandedHeadText(
            _showLabel(lang, _pdfLabelMap['restDuration']!),
            flex: 2,
          ),
          expandedHeadText(
            _showLabel(lang, _pdfLabelMap['pausedDuration']!),
            flex: 2,
          ),
        ],
      )
    ],
  );
}

// 构建每餐的子表格数据部分
_buildBodyTable(List<TrainedDetailLog> trainedData, String lang) {
  // 计算所有训练日志的累加时间
  int totalRest =
      trainedData.fold(0, (prev, item) => prev + item.totalRestTime);
  int totolPaused =
      trainedData.fold(0, (prev, item) => prev + item.totolPausedTime);
  int totalTrained =
      trainedData.fold(0, (prev, item) => prev + item.trainedDuration);

  return pw.Table(
    // 字数据可以不显示边框，更方便看？
    border: pw.TableBorder.all(color: PdfColors.black),
    children: [
      ...trainedData.map((e) {
        var name = (e.planName != null)
            ? "${e.planName} ${_showLabel(lang, _pdfLabelMap['dayNumber']!)} ${e.dayNumber}"
            : e.groupName ?? "";

        return pw.TableRow(
          // 行中数据垂直居中
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                name,
                style: pw.TextStyle(fontSize: 12.sp, color: PdfColors.black),
              ),
            ),
            expandedSubText(
              "${e.trainedStartTime.split(" ")[1]} - ${e.trainedEndTime.split(" ")[1]}",
              flex: 2,
            ),
            expandedSubText(
              cusDoubleTryToIntString(e.trainedDuration / 60),
              flex: 2,
            ),
            expandedSubText(
              cusDoubleTryToIntString(e.totalRestTime / 60),
              flex: 2,
            ),
            expandedSubText(
              cusDoubleTryToIntString(e.totolPausedTime / 60),
              flex: 2,
            ),
          ],
        );
      }),
      pw.TableRow(
        // 行中数据垂直居中
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              _showLabel(lang, _pdfLabelMap['total']!),
              textAlign: pw.TextAlign.right,
            ),
          ),
          expandedCountText('-', flex: 2),
          expandedCountText(cusDoubleTryToIntString(totalTrained / 60)),
          expandedCountText(cusDoubleTryToIntString(totalRest / 60)),
          expandedCountText(cusDoubleTryToIntString(totolPaused / 60)),
        ],
      )
    ],
  );
}

// 表格标题表格的文本
pw.Widget expandedHeadText(
  final String text, {
  final pw.TextAlign align = pw.TextAlign.center,
  int? flex = 1,
}) =>
    pw.Expanded(
      flex: flex ?? 1,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 12.sp, fontWeight: pw.FontWeight.bold),
        textAlign: align,
      ),
    );

// 表格正文表格的文本
pw.Widget expandedSubText(final String text, {int? flex = 1}) => pw.Expanded(
      flex: flex ?? 1,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10.sp),
        textAlign: pw.TextAlign.center,
      ),
    );

// 表格正文总计部分文字
pw.Widget expandedCountText(String text, {int? flex = 1}) => pw.Expanded(
      flex: flex ?? 1,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12.sp,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );

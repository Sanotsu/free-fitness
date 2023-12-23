import 'dart:typed_data';

// import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../models/training_state.dart';

Future<Uint8List> makeTrainedReportPdf(
  List<TrainedLogWithGroupBasic> list,
  String startDate,
  String endDate,
) async {
  // 创建PDF文档
  final pdf = pw.Document(
    title: "运动日志条目导出",
    author: "free-fitness",
    pageMode: PdfPageMode.fullscreen,
    theme: pw.ThemeData.withFont(
      // 谷歌字体不一定能够访问
      base: await PdfGoogleFonts.notoSerifHKRegular(),
      bold: await PdfGoogleFonts.notoSerifHKBold(),
      // 但是使用知道的本地字体，会增加app体积
      // fontFallback: [
      //   pw.Font.ttf(await rootBundle.load('assets/MiSans-Regular.ttf'))
      // ],
    ),
  );

  // 1 先把条目按天分类，每天的所有餐次放到一致pdf中
  Map<String, List<TrainedLogWithGroupBasic>> logGroupedByDate = {};
  for (var log in list) {
    // 日志的日期(不含时间)
    var tempDate = log.log.trainedDate;
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
      pdf.addPage(_buildPdfPage(data, date, startDate, endDate));
    }
  }

  return pdf.save();
}

// 构建pdf的页面
_buildPdfPage(
  List<TrainedLogWithGroupBasic> logData,
  String date,
  String startDate,
  String endDate,
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
                pw.Text('训练日志记录 $startDate ~ $endDate'),
                pw.Text('exported by free-fitness'),
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
          _buildHeaderTable(),
          // // 分割线
          // pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
          // 具体运动日志的表格数据
          _buildBodyTable(logData),

          // 页脚内容
          pw.Footer(
            margin: const pw.EdgeInsets.only(top: 0.5 * PdfPageFormat.cm),
            trailing: pw.Text(
              '第${context.pageNumber}/${context.pagesCount}页',
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
_buildHeaderTable() {
  return pw.Table(
    // 表格的边框设置
    border: pw.TableBorder.all(color: PdfColors.black),
    children: [
      pw.TableRow(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text("训练名称", textAlign: pw.TextAlign.left),
          ),
          expandedHeadText('训练起止时间', flex: 2),
          expandedHeadText('训练耗时(分钟)'),
          expandedHeadText('休息耗时(分钟)'),
          expandedHeadText('暂停耗时(分钟)'),
        ],
      )
    ],
  );
}

// 构建每餐的子表格数据部分
_buildBodyTable(List<TrainedLogWithGroupBasic> trainedData) {
  // 计算所有训练日志的累加时间
  int totalRest =
      trainedData.fold(0, (prev, item) => prev + item.log.totalRestTime);
  int totolPaused =
      trainedData.fold(0, (prev, item) => prev + item.log.totolPausedTime);
  int totalTrained =
      trainedData.fold(0, (prev, item) => prev + item.log.trainedDuration);

  return pw.Table(
    // 字数据可以不显示边框，更方便看？
    border: pw.TableBorder.all(color: PdfColors.black),
    children: [
      ...trainedData.map((e) {
        var log = e.log;

        var name = (e.plan != null)
            ? "${e.plan!.planName} 的第${log.dayNumber}个训练日"
            : e.group?.groupName ?? "";

        return pw.TableRow(
          // 行中数据垂直居中
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                name,
                style: pw.TextStyle(fontSize: 12.sp, color: PdfColors.black),
              ),
            ),
            expandedSubText(
              "${log.trainedStartTime.split(" ")[1]} - ${log.trainedEndTime.split(" ")[1]}",
              flex: 2,
            ),
            expandedSubText((log.trainedDuration / 60).toStringAsFixed(2)),
            expandedSubText((log.totalRestTime / 60).toStringAsFixed(2)),
            expandedSubText((log.totolPausedTime / 60).toStringAsFixed(2)),
          ],
        );
      }).toList(),
      pw.TableRow(
        // 行中数据垂直居中
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text("合计", textAlign: pw.TextAlign.right),
          ),
          expandedCountText('-', flex: 2),
          expandedCountText((totalTrained / 60).toStringAsFixed(2)),
          expandedCountText((totalRest / 60).toStringAsFixed(2)),
          expandedCountText((totolPaused / 60).toStringAsFixed(2)),
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

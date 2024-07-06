import 'dart:typed_data';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';

import 'package:flutter/services.dart' show rootBundle;
// import 'package:printing/printing.dart';

import '../../../../common/global/constants.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/dietary_state.dart';

Map<String, CusLabel> _pdfLabelMap = {
  "title": CusLabel(
      enLabel: 'Export dietary records', cnLabel: "饮食日记条目导出", value: null),
  "headerLeft":
      CusLabel(enLabel: 'dietary records', cnLabel: "饮食条目记录", value: null),
  "headerRight": CusLabel(
      enLabel: 'exported by free-fitness',
      cnLabel: "由free-fitness导出",
      value: null),
  "number": CusLabel(enLabel: 'Page', cnLabel: "第", value: null),
  "page": CusLabel(enLabel: '', cnLabel: "页", value: null),
  "enery":
      CusLabel(enLabel: 'Energy\n(kcal)', cnLabel: "能量\n(大卡)", value: null),
  "protein":
      CusLabel(enLabel: 'Protein\n(g)', cnLabel: "蛋白质\n(克)", value: null),
  "fat": CusLabel(enLabel: 'Fat\n(g)', cnLabel: "脂肪\n(克)", value: null),
  "cho": CusLabel(enLabel: 'CHO\n(g)', cnLabel: "碳水\n(克)", value: null),
  "sugar": CusLabel(enLabel: 'Sugar\n(g)', cnLabel: "糖\n(克)", value: null),
  "dietary_fibre":
      CusLabel(enLabel: 'DietaryFiber\n(g)', cnLabel: "膳食纤维\n(克)", value: null),
  "sodium": CusLabel(enLabel: 'Sodium\n(mg)', cnLabel: "钠\n(毫克)", value: null),
  "potassium":
      CusLabel(enLabel: 'Potassium\n(mg)', cnLabel: "钾\n(毫克)", value: null),
  "cholesterol":
      CusLabel(enLabel: 'Cholesterol\n(mg)', cnLabel: "胆固醇\n(毫克)", value: null),
  "subtotal": CusLabel(enLabel: 'Subtotal', cnLabel: "小计", value: null),
  "total": CusLabel(enLabel: 'Total', cnLabel: "小计", value: null),
};

// 根据当前语言显示 CusLabel 的 中文或者英文
String _showLabel(String lang, CusLabel cusLable) {
  return lang == "en" ? cusLable.enLabel : cusLable.cnLabel;
}

Future<Uint8List> makeReportPdf(
  List<DailyFoodItemWithFoodServing> list,
  String startDate,
  String endDate, {
  String lang = "cn",
}) async {
  // 创建PDF文档
  final pdf = pw.Document(
    title: _showLabel(lang, _pdfLabelMap['title']!),
    author: "free-fitness",
    pageMode: PdfPageMode.fullscreen,
    // 导出的不是中文就不用下载字体(但是正文中有中文还是无法显示)
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
  Map<String, List<DailyFoodItemWithFoodServing>> logGroupedByDate = {};
  for (var log in list) {
    // 日志的日期(不含时间)
    var tempDate = log.dailyFoodItem.date;
    if (logGroupedByDate.containsKey(tempDate)) {
      logGroupedByDate[tempDate]!.add(log);
    } else {
      logGroupedByDate[tempDate] = [log];
    }
  }

  for (var date in logGroupedByDate.keys) {
    final data = logGroupedByDate[date];

    if (data != null && data.isNotEmpty) {
      // 2 如果能有某天的饮食条目数据，还需要对餐次进行再次分组
      Map<String, List<DailyFoodItemWithFoodServing>> logGroupedByMeal = {};
      for (var item in data) {
        // 日志的日期(不含时间)
        var cate = item.dailyFoodItem.mealCategory;

        if (logGroupedByMeal.containsKey(cate)) {
          logGroupedByMeal[cate]!.add(item);
        } else {
          logGroupedByMeal[cate] = [item];
        }
      }
      // 构建每天的数据页面(当天的记录列表、当天按餐次分类的记录map，当天的日期)
      pdf.addPage(_buildPdfPage(
        data,
        logGroupedByMeal,
        date,
        startDate,
        endDate,
        lang,
      ));
    }
  }

  return pdf.save();
}

// 构建pdf的页面
_buildPdfPage(
  List<DailyFoodItemWithFoodServing> logData,
  Map<String, List<DailyFoodItemWithFoodServing>> logGroupedByMeal,
  String date,
  String startDate,
  String endDate,
  String lang,
) {
  var mealDate = DateTime.parse(date);
  return pw.Page(
    // 两者不能同时存在
    pageTheme: pw.PageTheme(
      margin: pw.EdgeInsets.all(10.sp),
    ),
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
              DateFormat.yMMMMEEEEd().format(mealDate),
              style: pw.TextStyle(fontSize: 12.sp),
              textAlign: pw.TextAlign.left,
            ),
          ),
          // 只有一行数据的表格当做标题
          _buildMealHeaderTable(lang),
          // // 分割线
          // pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
          // 具体餐次的表格数据
          ..._buildMealBodyTable(logGroupedByMeal, lang),
          // 当日总计的表格数据
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(vertical: 10.sp),
            child: _buildTotalCountSubBodyTable(logData, lang),
          ),
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
_buildMealHeaderTable(String lang) {
  return pw.Table(
    // 表格的边框设置
    border: pw.TableBorder.all(color: PdfColors.black),
    children: [
      pw.TableRow(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text("", textAlign: pw.TextAlign.left),
          ),
          expandedHeadText(_showLabel(lang, _pdfLabelMap['enery']!)),
          expandedHeadText(_showLabel(lang, _pdfLabelMap['protein']!)),
          expandedHeadText(_showLabel(lang, _pdfLabelMap['fat']!)),
          expandedHeadText(_showLabel(lang, _pdfLabelMap['cho']!)),
          expandedHeadText(_showLabel(lang, _pdfLabelMap['sugar']!)),
          expandedHeadText(_showLabel(lang, _pdfLabelMap['dietary_fibre']!)),
          expandedHeadText(_showLabel(lang, _pdfLabelMap['sodium']!)),
          expandedHeadText(_showLabel(lang, _pdfLabelMap['potassium']!)),
          expandedHeadText(_showLabel(lang, _pdfLabelMap['cholesterol']!)),
        ],
      )
    ],
  );
}

// 构建pdf统计页面的数据表格数据部分(每餐都算一个子表格，多个子表格组合当做数据表格部分)
_buildMealBodyTable(
  Map<String, List<DailyFoodItemWithFoodServing>> mealMap,
  String lang,
) {
  List<pw.Widget> rows = [];

  // 数据部分要严格早中晚小食的顺序进行遍历
  var tempMealList = [
    MealLabels.enBreakfast,
    MealLabels.enLunch,
    MealLabels.enDinner,
    MealLabels.enOther,
  ];

  for (var meal in tempMealList) {
    final mealData = mealMap[meal];

    if (mealData != null && mealData.isNotEmpty) {
      var tempMeal = mealtimeList.firstWhere((e) => e.enLabel == meal);

      rows.add(
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 10.sp),
              child: pw.Text(
                // 理论上这里一定找得到一日四餐对应的中文名称
                lang == "en" ? tempMeal.enLabel : tempMeal.cnLabel,
                style: pw.TextStyle(fontSize: 14.sp),
                textAlign: pw.TextAlign.left,
              ),
            ),
            _buildMealSubBodyTable(mealData, lang),
          ],
        ),
      );
    }
  }

  return rows;
}

// 构建每餐的子表格数据部分
_buildMealSubBodyTable(
  List<DailyFoodItemWithFoodServing> mealData,
  String lang,
) {
  var tempEnergy = 0.0;
  var tempProtein = 0.0;
  var tempFat = 0.0;
  var tempCHO = 0.0;
  // 这几个在底部总计可能用到
  var tempSodium = 0.0;
  var tempCholesterol = 0.0;
  var tempDietaryFiber = 0.0;
  var tempPotassium = 0.0;
  var tempSugar = 0.0;

  return pw.Table(
    // 字数据可以不显示边框，更方便看？
    // border: pw.TableBorder.all(color: PdfColors.black),
    children: [
      ...mealData.map((e) {
        var food = e.food;
        var log = e.dailyFoodItem;
        var serving = e.servingInfo;

        var foodIntakeSize = e.dailyFoodItem.foodIntakeSize;
        var servingInfo = e.servingInfo;
        tempEnergy += foodIntakeSize * servingInfo.energy;
        tempProtein += foodIntakeSize * servingInfo.protein;
        tempFat += foodIntakeSize * servingInfo.totalFat;
        tempCHO += foodIntakeSize * servingInfo.totalCarbohydrate;
        tempSodium += foodIntakeSize * servingInfo.sodium;
        tempCholesterol += foodIntakeSize * (servingInfo.cholesterol ?? 0);
        tempDietaryFiber += foodIntakeSize * (servingInfo.dietaryFiber ?? 0);
        tempPotassium += foodIntakeSize * (servingInfo.potassium ?? 0);
        tempSugar += foodIntakeSize * (servingInfo.sugar ?? 0);

        // 摄入量
        var intake =
            "${cusDoubleToString(log.foodIntakeSize)} x ${serving.servingUnit} ";

        return pw.TableRow(
          // 行中数据垂直居中
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            // expandedSubText(
            //   "${food.product} (${food.brand})\n $intake",
            //   isDouble: false,
            //   align: pw.TextAlign.left,
            // ),
            pw.Expanded(
              flex: 3,
              child: pw.RichText(
                textAlign: pw.TextAlign.left,
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: "${food.product} (${food.brand})",
                      style: pw.TextStyle(
                        fontSize: 12.sp,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.TextSpan(
                      text: "\n$intake",
                      style: pw.TextStyle(
                        fontSize: 10.sp,
                        color: PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            expandedSubText(
              log.foodIntakeSize * serving.energy / oneCalToKjRatio,
            ),
            expandedSubText(log.foodIntakeSize * serving.protein),
            expandedSubText(log.foodIntakeSize * serving.totalFat),
            expandedSubText(log.foodIntakeSize * serving.totalCarbohydrate),
            expandedSubText(log.foodIntakeSize * (serving.sugar ?? 0)),
            expandedSubText(log.foodIntakeSize * (serving.dietaryFiber ?? 0)),
            expandedSubText(log.foodIntakeSize * serving.sodium),
            expandedSubText(log.foodIntakeSize * (serving.potassium ?? 0)),
            expandedSubText(log.foodIntakeSize * (serving.cholesterol ?? 0)),
          ],
        );
      }),
      pw.TableRow(
        // 行中数据垂直居中
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              _showLabel(lang, _pdfLabelMap['subtotal']!),
              textAlign: pw.TextAlign.right,
            ),
          ),
          expandedSubCountText((tempEnergy / oneCalToKjRatio)),
          expandedSubCountText(tempProtein),
          expandedSubCountText(tempFat),
          expandedSubCountText(tempCHO),
          expandedSubCountText(tempSugar),
          expandedSubCountText(tempDietaryFiber),
          expandedSubCountText(tempSodium),
          expandedSubCountText(tempPotassium),
          expandedSubCountText(tempCholesterol),
        ],
      )
    ],
  );
}

// 构建当日总计的子表格数据部分
_buildTotalCountSubBodyTable(
  List<DailyFoodItemWithFoodServing> logData,
  String lang,
) {
  var tempCount = dailyFoodItemAccumulate(logData);

  return pw.Table(
    // 表格的边框设置
    // border: pw.TableBorder.all(color: PdfColors.black),
    children: [
      pw.TableRow(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              _showLabel(lang, _pdfLabelMap['total']!),
              textAlign: pw.TextAlign.left,
              style: pw.TextStyle(
                fontSize: 11.sp,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
          // 注意索引的准确使用
          expandedSubCountText(tempCount[1], color: PdfColors.black),
          expandedSubCountText(tempCount[2], color: PdfColors.black),
          expandedSubCountText(tempCount[3], color: PdfColors.black),
          expandedSubCountText(tempCount[4], color: PdfColors.black),
          expandedSubCountText(tempCount[5], color: PdfColors.black),
          expandedSubCountText(tempCount[6], color: PdfColors.black),
          expandedSubCountText(tempCount[7], color: PdfColors.black),
          expandedSubCountText(tempCount[8], color: PdfColors.black),
          expandedSubCountText(tempCount[9], color: PdfColors.black),
        ],
      )
    ],
  );
}

// 表格标题表格的文本
pw.Widget expandedHeadText(
  final String text, {
  final pw.TextAlign align = pw.TextAlign.center,
}) =>
    pw.Expanded(
      flex: 1,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 12.sp, fontWeight: pw.FontWeight.bold),
        textAlign: align,
      ),
    );

// 表格正文表格的文本
pw.Widget expandedSubText(
  final dynamic text, {
  final pw.TextAlign align = pw.TextAlign.center,
  bool? isDouble = true,
}) =>
    pw.Expanded(
      flex: 1,
      child: pw.Text(
        (isDouble ?? true) ? cusDoubleToString(text) : text,
        style: pw.TextStyle(fontSize: 10.sp),
        textAlign: align,
      ),
    );

// 表格正文总计部分文字
pw.Widget expandedSubCountText(
  final dynamic text, {
  final pw.TextAlign align = pw.TextAlign.center,
  bool? isDouble = true,
  PdfColor? color = PdfColors.green,
}) =>
    pw.Expanded(
      flex: 1,
      child: pw.Text(
        (isDouble ?? true) ? cusDoubleToString(text) : text,
        style: pw.TextStyle(
          fontSize: 11.sp,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
        textAlign: align,
      ),
    );

dailyFoodItemAccumulate(List<DailyFoodItemWithFoodServing> list) {
  var tempEnergy = 0.0;
  var tempProtein = 0.0;
  var tempFat = 0.0;
  var tempCHO = 0.0;
  // 这几个在底部总计可能用到
  var tempSodium = 0.0;
  var tempCholesterol = 0.0;
  var tempDietaryFiber = 0.0;
  var tempPotassium = 0.0;
  var tempSugar = 0.0;

  for (var e in list) {
    var foodIntakeSize = e.dailyFoodItem.foodIntakeSize;
    var servingInfo = e.servingInfo;
    tempEnergy += foodIntakeSize * servingInfo.energy;
    tempProtein += foodIntakeSize * servingInfo.protein;
    tempFat += foodIntakeSize * servingInfo.totalFat;
    tempCHO += foodIntakeSize * servingInfo.totalCarbohydrate;
    tempSodium += foodIntakeSize * servingInfo.sodium;
    tempCholesterol += foodIntakeSize * (servingInfo.cholesterol ?? 0);
    tempDietaryFiber += foodIntakeSize * (servingInfo.dietaryFiber ?? 0);
    tempPotassium += foodIntakeSize * (servingInfo.potassium ?? 0);
    tempSugar += foodIntakeSize * (servingInfo.sugar ?? 0);
  }

  var tempCalories = tempEnergy / oneCalToKjRatio;

  // 简单返回一个数组，取值时一定要注意索引
  return [
    tempEnergy,
    tempCalories,
    tempProtein,
    tempFat,
    tempCHO,
    tempDietaryFiber,
    tempSugar,
    tempSodium,
    tempPotassium,
    tempCholesterol,
  ];
}

import 'dart:typed_data';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';

import '../../../../common/global/constants.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/dietary_state.dart';

Future<Uint8List> makeReportPdf(List<DailyFoodItemWithFoodServing> list) async {
  // 创建PDF文档
  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(
      base: await PdfGoogleFonts.notoSerifHKRegular(),
      // base: pw.Font.ttf(await rootBundle.load('assets/MiSans-Regular.ttf')),
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
      // 构建每天的数据页面
      pdf.addPage(_buildPdfPage(logGroupedByMeal));
    }
  }

  return pdf.save();
}

// 构建pdf的页面
_buildPdfPage(
  Map<String, List<DailyFoodItemWithFoodServing>> logGroupedByMeal,
) {
  return pw.Page(
    orientation: pw.PageOrientation.landscape,
    build: (context) {
      return pw.Column(
        children: [
          // 只有一行数据的表格当做标题
          _buildMealHeaderTable(),
          // 分割线
          pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
          // 具体餐次的表格数据
          ..._buildMealBodyTable(logGroupedByMeal),
        ],
      );
    },
  );
}

// 构建pdf统计页面的标题部分(只有一行数据的表格当做标题)
_buildMealHeaderTable() {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black),
    children: [
      pw.TableRow(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text("", textAlign: pw.TextAlign.left),
          ),
          expandedHeadText('能量\n(大卡)'),
          expandedHeadText('蛋白质\n(克)'),
          expandedHeadText('脂肪\n(克)'),
          expandedHeadText('碳水\n(克)'),
          expandedHeadText('糖\n(克)'),
          expandedHeadText('膳食纤维\n(克)'),
          expandedHeadText('钠\n(毫克)'),
          expandedHeadText('钾\n(毫克)'),
          expandedHeadText('胆固醇\n(毫克)'),
        ],
      )
    ],
  );
}

// 构建pdf统计页面的数据表格数据部分(每餐都算一个子表格，多个子表格组合当做数据表格部分)
_buildMealBodyTable(Map<String, List<DailyFoodItemWithFoodServing>> mealMap) {
  List<pw.Widget> rows = [];

  // 数据部分要严格早中晚小食的顺序进行遍历
  var tempMealList = [
    mealNameMap[CusMeals.breakfast]!.enLabel,
    mealNameMap[CusMeals.lunch]!.enLabel,
    mealNameMap[CusMeals.dinner]!.enLabel,
    mealNameMap[CusMeals.other]!.enLabel,
  ];

  for (var meal in tempMealList) {
    final mealData = mealMap[meal];

    if (mealData != null && mealData.isNotEmpty) {
      rows.add(
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              // 理论上这里一定找得到一日四餐对应的中文名称
              mealtimeList.firstWhere((e) => e.enLabel == meal).cnLabel,
              style: pw.TextStyle(fontSize: 20.sp),
              textAlign: pw.TextAlign.left,
            ),
            _buildMealSubBodyTable(mealData),
          ],
        ),
      );
    }
  }

  return rows;
}

// 构建每餐的子表格数据部分
_buildMealSubBodyTable(List<DailyFoodItemWithFoodServing> mealData) {
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
    border: pw.TableBorder.all(color: PdfColors.black),
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
            expandedSubText(
              "${food.product}(${food.brand})\n $intake",
              isDouble: false,
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
      }).toList(),
      pw.TableRow(
        // 行中数据垂直居中
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text("总计", textAlign: pw.TextAlign.left),
          ),
          expandedSubText((tempEnergy / oneCalToKjRatio)),
          expandedSubText(tempProtein),
          expandedSubText(tempFat),
          expandedSubText(tempCHO),
          expandedSubText(tempSugar),
          expandedSubText(tempDietaryFiber),
          expandedSubText(tempSodium),
          expandedSubText(tempPotassium),
          expandedSubText(tempCholesterol),
        ],
      )
    ],
  );
}

// 表格标题表格的文本
pw.Widget expandedHeadText(
  final String text, {
  final pw.TextAlign align = pw.TextAlign.left,
}) =>
    pw.Expanded(
      flex: 1,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 14.sp),
        textAlign: align,
      ),
    );

// 表格正文表格的文本
pw.Widget expandedSubText(
  final dynamic text, {
  final pw.TextAlign align = pw.TextAlign.left,
  bool? isDouble = true,
}) =>
    pw.Expanded(
      flex: 1,
      child: pw.Text(
        (isDouble ?? true) ? cusDoubleToString(text) : text,
        style: pw.TextStyle(fontSize: 12.sp),
        textAlign: align,
      ),
    );

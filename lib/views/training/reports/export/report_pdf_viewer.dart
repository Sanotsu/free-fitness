import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../common/global/constants.dart';
import '../../../../common/utils/db_training_helper.dart';
import '../../../../common/utils/tool_widgets.dart';
import '../../../../models/cus_app_localizations.dart';
import '../../../../models/training_state.dart';
import 'report_pdf_export.dart';

///
/// 点击了导出按钮之后，先弹窗选择范围(pdf格式内容暂时不多样化)，在这里查询数据，构建pdf页面结构；
/// 然后在这里直接预览pdf，然后再使用组件自带功能进行下载保存
///
class TrainedReportPdfViewer extends StatefulWidget {
  // 传入查询条目的日期范围(用户编号则是全局缓存或者单独状态管理中去处理)
  // 默认就是年月日格式，这里就不判断和格式化了
  final String startDate;
  final String endDate;

  const TrainedReportPdfViewer({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<TrainedReportPdfViewer> createState() => _TrainedReportPdfViewerState();
}

class _TrainedReportPdfViewerState extends State<TrainedReportPdfViewer> {
  final DBTrainingHelper _trainingHelper = DBTrainingHelper();

  /// 根据条件查询的日记条目数据(所有数据的来源，格式化成VO可以在指定函数中去做)
  List<TrainedDetailLog> tdlList = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _queryTrainedDetailLogList();
  }

  /// 有指定日期查询指定日期的饮食记录条目，没有就当前日期
  _queryTrainedDetailLogList() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 理论上是默认查询当日的，有选择其他日期则查询指定日期？？？还要是登录者这个用户编号的
    var temp = await _trainingHelper.queryTrainedDetailLog(
      userId: CacheUser.userId,
      startDate: widget.startDate,
      endDate: widget.endDate,
      gmtCreateSort: "desc",
    );

    setState(() {
      tdlList = temp;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CusAL.of(context).trainedReportExport),
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : PdfPreview(
              initialPageFormat: PdfPageFormat.a4,
              build: (context) => makeTrainedReportPdf(
                tdlList,
                // 在pdf页首会显示查询数据的日期
                widget.startDate.split(" ")[0],
                widget.endDate.split(" ")[0],
                lang: box.read('language'),
              ),
            ),
    );
  }
}

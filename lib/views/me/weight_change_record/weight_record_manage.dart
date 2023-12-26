import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/user_state.dart';

class WeightRecordManage extends StatefulWidget {
  final User user;
  const WeightRecordManage({super.key, required this.user});

  @override
  State<WeightRecordManage> createState() => _WeightRecordManageState();
}

class _WeightRecordManageState extends State<WeightRecordManage> {
  final DBUserHelper _userHelper = DBUserHelper();
  bool isLoading = false;

  // 记录查到的体重数据，显示的时候需要根据索引显示日期
  List<WeightTrend> weightTrends = [];

  // 加载所有的体重趋势数据，并以此构建表格，同时设定默认为位选中状态
  int wtItemsNum = 0;
  List<bool> wtSelectedList = [false];

  // 提供一个用户自定义的筛选范围(默认最近14天)
  DateTime _startDate = DateTime.now().add(const Duration(days: -14));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    getWeightData();
  }

  getWeightData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    var tempList = await _userHelper.queryWeightTrendByUser(
      userId: widget.user.userId,
      startDate: formatDateToString(_startDate, formatter: constDatetimeFormat),
      // 因为选择的日期范围不带时间，默认是结束日期的00:00:00,所以查询时加一天才能查询到包含结束日期的数据
      endDate: formatDateToString(
        _endDate.add(const Duration(days: 1)),
        formatter: constDatetimeFormat,
      ),
      gmtCreateSort: 'DESC',
    );

    setState(() {
      weightTrends.clear();
      weightTrends.addAll(tempList);
      wtItemsNum = weightTrends.length;
      wtSelectedList = List<bool>.generate(wtItemsNum, (int index) => false);
      isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;

        getWeightData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CusAL.of(context).weightRecord),
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      "${formatDateToString(_startDate)} ~ ${formatDateToString(_endDate)}",
                    ),
                    ElevatedButton(
                      onPressed: _selectDateRange,
                      child: Text(CusAL.of(context).selectDateRange),
                    ),
                  ],
                ),
                _buildRemoveButton(),
                _buildExerciseDataTable(context),
              ],
            ),
    );
  }

  _buildRemoveButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            CusAL.of(context).allRecords,
            style: TextStyle(fontSize: CusFontSizes.itemContent),
            textAlign: TextAlign.start,
          ),
          TextButton(
            onPressed: () async {
              var rst = await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(CusAL.of(context).deleteConfirm),
                    content: Text(CusAL.of(context).deleteNote("")),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: Text(CusAL.of(context).cancelLabel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: Text(CusAL.of(context).confirmLabel),
                      ),
                    ],
                  );
                },
              );

              // 如果是取消，则直接返回
              if (rst == null || !rst) {
                return;
              }
              // 如果是确认删除，则进行删除

              // 先找到被选中的索引
              List<int> trueIndices =
                  List.generate(wtSelectedList.length, (index) => index)
                      .where((i) => wtSelectedList[i])
                      .toList();

              // 获取要删除的体重趋势数据
              List<WeightTrend> toDeletedWT = [];
              for (var element in trueIndices) {
                toDeletedWT.add(weightTrends[element]);
              }

              // 从数据库中移除选中的数据
              // ？？？应该有成功的判断
              await _userHelper.deleteWeightTrendList(toDeletedWT);

              setState(() {
                // 从列表中移除
                // 倒序遍历需要移除的索引列表，以避免索引变化导致的问题
                for (int i = trueIndices.length - 1; i >= 0; i--) {
                  weightTrends.removeAt(trueIndices[i]);
                }
                // 更新需要构建的表格的长度和每条数据的可选中状态
                wtItemsNum = weightTrends.length;
                wtSelectedList = List<bool>.generate(
                  wtItemsNum,
                  (int index) => false,
                );
              });
            },
            child: Text(
              CusAL.of(context).removeSelected,
              style: TextStyle(fontSize: CusFontSizes.buttonTiny),
            ),
          ),
        ],
      ),
    );
  }

  _buildExerciseDataTable(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: DataTable(
          dataRowMinHeight: 20.sp, // 设置行高范围
          // dataRowMaxHeight: 80.sp,
          headingRowHeight: 25.sp, // 设置表头行高
          horizontalMargin: 10.sp, // 设置水平边距
          columnSpacing: 5.sp, // 设置列间距
          columns: <DataColumn>[
            // DataColumn(label: Text('索引')),
            // 删除时查看是否删掉了
            DataColumn(
              label: Text(CusAL.of(context).serialLabel),
              numeric: true,
            ),
            DataColumn(
              label: Text(CusAL.of(context).measuredTime),
              numeric: true,
            ),
            DataColumn(
              label: Text(CusAL.of(context).weightLabel("(kg)")),
              numeric: true,
            ),
            const DataColumn(label: Text('BMI'), numeric: true),
          ],
          rows: List<DataRow>.generate(
            wtItemsNum,
            (int index) => DataRow(
              color: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                // All rows will have the same selected color.
                if (states.contains(MaterialState.selected)) {
                  return Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.08);
                }
                // Even rows will have a grey color.
                if (index.isEven) {
                  return Colors.grey.withOpacity(0.3);
                }
                return null; // Use default value for other states and odd rows.
              }),
              cells: <DataCell>[
                // DataCell(
                //   SizedBox(
                //     width: 25.sp,
                //     child: Text(
                //       '${index + 1} ',
                //       style: TextStyle(fontSize: 14.sp),
                //     ),
                //   ),
                // ),
                // 测试用
                DataCell(
                  SizedBox(
                    width: 25.sp,
                    child: Text(
                      '${weightTrends[index].weightTrendId} ',
                      style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataCell(
                  Wrap(
                    children: [
                      Text(
                        '${weightTrends[index].gmtCreate} ',
                        style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 60.sp,
                    child: Text(
                      cusDoubleTryToIntString(weightTrends[index].weight),
                      style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 60.sp,
                    child: Text(
                      cusDoubleTryToIntString(weightTrends[index].bmi),
                      style: TextStyle(fontSize: CusFontSizes.itemSubTitle),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
              selected: wtSelectedList[index],
              onSelectChanged: (bool? value) {
                setState(() {
                  wtSelectedList[index] = value!;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

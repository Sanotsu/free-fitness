// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/utils/db_user_helper.dart';
import '../../../common/utils/tool_widgets.dart';
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

  @override
  void initState() {
    super.initState();

    getWeightData();
  }

  getWeightData({String? startDate, String? endDate}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    var tempList = await _userHelper.queryWeightTrendByUser(
      userId: widget.user.userId,
      startDate: startDate,
      endDate: endDate,
      gmtCreateSort: 'DESC',
    );

    print("tempList---${tempList.length}");

    setState(() {
      weightTrends.clear();
      weightTrends.addAll(tempList);
      wtItemsNum = weightTrends.length;
      wtSelectedList = List<bool>.generate(wtItemsNum, (int index) => false);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WeightRecord'),
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const Text("这里应该预留一个日期范围选择的查询(todo)"),
                _buildRemoveButton(),
                _buildExerciseDataTable(),
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
            "所有的体重记录如下:",
            style: TextStyle(fontSize: 14.sp),
            textAlign: TextAlign.start,
          ),
          TextButton(
            onPressed: () async {
              var rst = await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('删除确认'),
                    content: const Text('确认删除选择的数据？'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('确认'),
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
            child: Text("移除选中动作", style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  _buildExerciseDataTable() {
    return Expanded(
      child: SingleChildScrollView(
        child: DataTable(
          dataRowMinHeight: 20.sp, // 设置行高范围
          // dataRowMaxHeight: 80.sp,
          headingRowHeight: 25, // 设置表头行高
          horizontalMargin: 10, // 设置水平边距
          columnSpacing: 5.sp, // 设置列间距
          columns: const <DataColumn>[
            // DataColumn(label: Text('索引')),
            // 删除时查看是否删掉了
            DataColumn(label: Text('编号'), numeric: true),
            DataColumn(label: Text('测量时间'), numeric: true),
            DataColumn(label: Text('体重(kg)'), numeric: true),
            DataColumn(label: Text('bmi'), numeric: true),
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
                      style: TextStyle(fontSize: 14.sp),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataCell(
                  Wrap(
                    children: [
                      Text(
                        '${weightTrends[index].gmtCreate} ',
                        style: TextStyle(fontSize: 14.sp),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 60.sp,
                    child: Text(
                      weightTrends[index].weight.toStringAsFixed(2),
                      style: TextStyle(fontSize: 14.sp),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 60.sp,
                    child: Text(
                      weightTrends[index].bmi.toStringAsFixed(2),
                      style: TextStyle(fontSize: 14.sp),
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

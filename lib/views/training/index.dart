import 'package:flutter/material.dart';

import '../../common/components/cus_cards.dart';
import '../../common/global/constants.dart';
import '../../models/cus_app_localizations.dart';
import 'exercise/index.dart';
import 'plans/index.dart';
import 'reports/index.dart';
import 'workouts/index.dart';

///
/// 2024-11-15
/// 几个概念说明，理论上：
///   1 个 plan 有多个 group(workout)
///   1 个 group(workout) 有多个 action
///   1 个 action 对应 1 个增强的 exercise (会有更多的属性)
/// group 和 workout 的区别 (内核上没啥区别，代码中大部分都是group)
///   group 是针对 plan 来的，一个 plan 有多个 group
///   但 group 的内容和 workout 是一样的，当 workout 被选中到某个 plan 中，就是该 plan 的一个 group
///   从plan中 删除 group 不影响数据库中的 workout ，该 workout 还可以被其他 plan 选择
///   从数据库删除 workout，那就是永久删除了，其他plan就没得选
///     如果 workout 被某个 plan 使用中，那就无法删除，除非先删除 plan
///
class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(CusAL.of(context).training)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: CusCoverCard(
              targetPage: const TrainingReports(),
              title: CusAL.of(context).trainingReports,
              subtitle: CusAL.of(context).trainingReportsSubtitle,
              imageUrl: reportImageUrl,
            ),
          ),
          Expanded(
            child: CusCoverCard(
              targetPage: const TrainingExercise(),
              title: CusAL.of(context).exerciseLabel,
              subtitle: CusAL.of(context).exerciseSubtitle,
              imageUrl: workoutWomanImageUrl,
            ),
          ),
          Expanded(
            child: CusCoverCard(
              targetPage: const TrainingWorkouts(),
              title: CusAL.of(context).workout,
              subtitle: CusAL.of(context).workoutSubtitle,
              imageUrl: workoutManImageUrl,
            ),
          ),
          Expanded(
            child: CusCoverCard(
              targetPage: const TrainingPlans(),
              title: CusAL.of(context).plan,
              subtitle: CusAL.of(context).planSubtitle,
              imageUrl: workoutCalendarImageUrl,
            ),
          ),
        ],
      ),
    );
  }
}

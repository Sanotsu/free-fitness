// 关于 训练trainnig 模块的model都放在这里，对照相关表栏位了解更多

/// --- 基础表
class Exercise {
  int? exerciseId; // 自增的，可以不传
  String exerciseCode, exerciseName, category, countingMode;
  String? force, level, mechanic, equipment, instructions, ttsNotes;
  String? primaryMuscles, secondaryMuscles, images;
  int standardDuration;
  bool? isCustom;
  String? contributor, gmtCreate, gmtModified;

  Exercise({
    this.exerciseId,
    required this.exerciseCode,
    required this.exerciseName,
    this.force,
    this.level,
    this.mechanic,
    this.equipment,
    required this.countingMode,
    required this.standardDuration,
    this.instructions,
    this.ttsNotes,
    required this.category,
    this.primaryMuscles,
    this.secondaryMuscles,
    this.images,
    this.isCustom,
    this.contributor,
    this.gmtCreate,
    this.gmtModified,
  });

  // 将一个 Exercise 转换成一个Map。键必须对应于数据库中的列名。
  Map<String, dynamic> toMap() {
    return {
      'exercise_id': exerciseId,
      'exercise_code': exerciseCode,
      'exercise_name': exerciseName,
      'force': force,
      'level': level,
      'mechanic': mechanic,
      'equipment': equipment,
      'counting_mode': countingMode,
      'standard_duration': standardDuration,
      'instructions': instructions,
      'tts_notes': ttsNotes,
      'category': category,
      'primary_muscles': primaryMuscles,
      'secondary_muscles': secondaryMuscles,
      'images': images,
      'is_custom': isCustom,
      'contributor': contributor,
      'gmt_create': gmtCreate,
      'gmt_modified': gmtModified,
    };
  }

// 用于从数据库行映射到 Exercise 对象的 fromMap 方法
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      exerciseId: map['exercise_id'] as int?,
      exerciseCode: map['exercise_code'] as String,
      exerciseName: map['exercise_name'] as String,
      force: map['force'] as String?,
      level: map['level'] as String?,
      mechanic: map['mechanic'] as String?,
      equipment: map['equipment'] as String?,
      countingMode: map['counting_mode'] as String,
      // ？？？明明sql语句设置了默认值，但是不传还是null
      standardDuration: map['standard_duration'] as int? ?? 1,
      instructions: map['instructions'] as String?,
      ttsNotes: map['tts_notes'] as String?,
      category: map['category'] as String,
      primaryMuscles: map['primary_muscles'] as String?,
      secondaryMuscles: map['secondary_muscles'] as String?,
      images: map['images'] as String?,
      // ？？？明明sql语句设置了默认值，但是不传还是null
      isCustom: bool.tryParse(map['is_custom'].toString()) ?? false,
      contributor: map['contributor'] as String?,
      gmtCreate: map['gmt_create'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  // 重写 toString 方法
  @override
  String toString() {
    return '''
    Exercise{
    exercise_id: $exerciseId, exercise_code: $exerciseCode, exercise_name: $exerciseName,
    force: $force, level: $level, mechanic: $mechanic,equipment: $equipment, 
    standard_duration: $standardDuration, instructions: $instructions, tts_notes: $ttsNotes, category: $category, 
    primary_muscles: $primaryMuscles, secondary_muscles: $secondaryMuscles, images: $images, 
    is_custom: $isCustom, contributor: $contributor, gmt_create: $gmtCreate, gmt_modified: $gmtModified }
    ''';
  }
}

// 动作表的 model（Action、Group、Plan可能都和flutter的预设部件重名了，都加上Training前缀）
class TrainingAction {
  int? actionId; // 自增的，可以不传
  int groupId, exerciseId;
  int? frequency, duration;
  double? equipmentWeight;

  TrainingAction({
    this.actionId,
    required this.groupId,
    required this.exerciseId,
    this.frequency,
    this.duration,
    this.equipmentWeight,
  });

  Map<String, dynamic> toMap() {
    return {
      'action_id': actionId,
      'group_id': groupId,
      'exercise_id': exerciseId,
      'frequency': frequency,
      'duration': duration,
      'equipment_weight': equipmentWeight,
    };
  }

  factory TrainingAction.fromMap(Map<String, dynamic> map) {
    return TrainingAction(
      actionId: map['action_id'] as int?,
      groupId: map['group_id'] as int,
      exerciseId: map['exercise_id'] as int,
      frequency: map['frequency'] as int?,
      duration: map['duration'] as int?,
      equipmentWeight: map['equipment_weight'] as double?,
    );
  }

  @override
  String toString() {
    return '''
    TrainingAction {
      action_id: $actionId, group_id: $groupId,exercise_id: $exerciseId, 
      frequency: $frequency, duration: $duration,equipment_weight: $equipmentWeight
    }
    ''';
  }
}

class TrainingGroup {
  int? groupId; // 自增的，可以不传
  String groupName, groupCategory, groupLevel;
  int? consumption, timeSpent;
  String? description, contributor, gmtCreate, gmtModified;

  TrainingGroup({
    this.groupId,
    required this.groupName,
    required this.groupCategory,
    required this.groupLevel,
    this.consumption,
    this.timeSpent,
    this.description,
    this.contributor,
    this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'group_category': groupCategory,
      'group_level': groupLevel,
      'consumption': consumption,
      'time_spent': timeSpent,
      'description': description,
      'contributor': contributor,
      'gmt_create': gmtCreate,
      'gmt_modified': gmtModified,
    };
  }

  factory TrainingGroup.fromMap(Map<String, dynamic> map) {
    return TrainingGroup(
      groupId: map['group_id'] as int?,
      groupName: map['group_name'] as String,
      groupCategory: map['group_category'] as String,
      groupLevel: map['group_level'] as String,
      consumption: map['consumption'] as int?,
      timeSpent: map['time_spent'] as int?,
      description: map['description'] as String?,
      contributor: map['contributor'] as String?,
      gmtCreate: map['gmt_create'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    TrainingGroup {
    group_id: $groupId, group_name: $groupName, group_category: $groupCategory, 
    group_level: $groupLevel, consumption: $consumption, time_spent: $timeSpent, 
    description: $description, contributor: $contributor, gmt_create: $gmtCreate, gmt_modified: $gmtModified }
    ''';
  }
}

class TrainingPlan {
  int? planId; // 自增的，可以不传
  int planPeriod;
  String planCode, planName, planCategory, planLevel;
  String? description, contributor, gmtCreate, gmtModified;

  TrainingPlan({
    this.planId,
    required this.planCode,
    required this.planName,
    required this.planCategory,
    required this.planLevel,
    required this.planPeriod,
    this.description,
    this.contributor,
    this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'plan_id': planId,
      'plan_code': planCode,
      'plan_name': planName,
      'plan_category': planCategory,
      'plan_level': planLevel,
      'plan_period': planPeriod,
      'description': description,
      'contributor': contributor,
      'gmt_create': gmtCreate,
      'gmt_modified': gmtModified,
    };
  }

  factory TrainingPlan.fromMap(Map<String, dynamic> map) {
    return TrainingPlan(
      planId: map['plan_id'] as int?,
      planCode: map['plan_code'] as String,
      planName: map['plan_name'] as String,
      planCategory: map['plan_category'] as String,
      planLevel: map['plan_level'] as String,
      planPeriod: map['plan_period'] as int? ?? 0,
      description: map['description'] as String?,
      contributor: map['contributor'] as String?,
      gmtCreate: map['gmt_create'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    TrainingPlan {planId: $planId, planCode: $planCode, planName: $planName,planCategory: $planCategory, 
    planLevel: $planLevel, planPeriod:$planPeriod, description: $description, contributor: $contributor, gmt_create: $gmtCreate, gmt_modified: $gmtModified }
    ''';
  }
}

class PlanHasGroup {
  int? planHasGroupId; // 自增的，可以不传
  int planId, groupId, dayNumber;

  PlanHasGroup({
    this.planHasGroupId,
    required this.planId,
    required this.groupId,
    required this.dayNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'plan_has_group_id': planHasGroupId,
      'plan_id': planId,
      'group_id': groupId,
      'day_number': dayNumber,
    };
  }

  factory PlanHasGroup.fromMap(Map<String, dynamic> map) {
    return PlanHasGroup(
      planHasGroupId: map['plan_has_group_id'] as int?,
      planId: map['plan_id'] as int,
      dayNumber: map['day_number'] as int,
      groupId: map['group_id'] as int,
    );
  }

  @override
  String toString() {
    return '''
    PlanHasGroup {
      plan_has_group_id: $planHasGroupId, plan_id: $planId, group_id: $groupId, day_number: $dayNumber
    }
    ''';
  }
}

// 2023-12-27 训练日志宽表，不再级联查询plan和group，这样后两者有删除也可以查看历史记录
class TrainedDetailLog {
  int? trainedDetailLogId; // 自增的，可以不传
  int? dayNumber, consumption;
  String? planName, planCategory, planLevel;
  String? groupName, groupCategory, groupLevel;
  String trainedDate, trainedStartTime, trainedEndTime;
  int userId, trainedDuration, totolPausedTime, totalRestTime;

  TrainedDetailLog({
    this.trainedDetailLogId,
    required this.trainedDate,
    required this.userId,
    this.planName,
    this.planCategory,
    this.planLevel,
    this.dayNumber,
    this.groupName,
    this.groupCategory,
    this.groupLevel,
    this.consumption,
    required this.trainedStartTime,
    required this.trainedEndTime,
    required this.trainedDuration,
    required this.totolPausedTime,
    required this.totalRestTime,
  });

  // 转换成一个Map。键必须对应于数据库中的列名。
  Map<String, dynamic> toMap() {
    return {
      'trained_detail_log_id': trainedDetailLogId,
      'trained_date': trainedDate,
      'user_id': userId,
      'plan_name': planName,
      'plan_category': planCategory,
      'plan_level': planLevel,
      'day_number': dayNumber,
      'group_name': groupName,
      'group_category': groupCategory,
      'group_level': groupLevel,
      'consumption': consumption,
      'trained_start_time': trainedStartTime,
      'trained_end_time': trainedEndTime,
      'trained_duration': trainedDuration,
      'totol_paused_time': totolPausedTime,
      'total_rest_time': totalRestTime,
    };
  }

// 用于从数据库行映射到 ServingInfo 对象的 fromMap 方法
  factory TrainedDetailLog.fromMap(Map<String, dynamic> map) {
    return TrainedDetailLog(
      trainedDetailLogId: map['trained_detail_log_id'] as int?,
      trainedDate: map['trained_date'] as String,
      userId: map['user_id'] as int,
      planName: map['plan_name'] as String?,
      planCategory: map['plan_category'] as String?,
      planLevel: map['plan_level'] as String?,
      dayNumber: map['day_number'] as int?,
      groupName: map['group_name'] as String?,
      groupCategory: map['group_category'] as String?,
      groupLevel: map['group_level'] as String?,
      consumption: map['consumption'] as int?,
      trainedStartTime: map['trained_start_time'] as String,
      trainedEndTime: map['trained_end_time'] as String,
      trainedDuration: map['trained_duration'] as int,
      totolPausedTime: map['totol_paused_time'] as int,
      totalRestTime: map['total_rest_time'] as int,
    );
  }

  // 重写 toString 方法
  @override
  String toString() {
    return '''
    TrainedDetailLog{
      trainedDetailLogId:$trainedDetailLogId, trainedDate:$trainedDate, userId:$userId, 
      planName:$planName, planCategory:$planCategory, planLevel:$planLevel, dayNumber:$dayNumber,
      groupName:$groupName, groupCategory:$groupCategory, groupLevel:$groupLevel, consumption:$consumption, 
      trainedStartTime:$trainedStartTime, trainedEndTime:$trainedEndTime, 
      trainedDuration:$trainedDuration, totolPausedTime:$totolPausedTime, totalRestTime:$totalRestTime
    }
    ''';
  }
}

/// --- 扩展表

// 动作和对应基础活动的扩展表
class ActionDetail {
  final Exercise exercise;
  final TrainingAction action;

  ActionDetail({required this.exercise, required this.action});

  @override
  String toString() {
    return '''
    ActionDetail {
      exercise: $exercise, action: $action
    ''';
  }
}

class GroupWithActions {
  final TrainingGroup group;
  final List<ActionDetail> actionDetailList;

  GroupWithActions({required this.group, required this.actionDetailList});

  @override
  String toString() {
    return '''
    ActionDetail {
      group: $group, actionDetailList: $actionDetailList
    ''';
  }
}

// plan : group : action -> 1 :N : N*N
class PlanWithGroups {
  final TrainingPlan plan;
  // 这里列表的索引，就是plan周期的训练日顺序了
  final List<GroupWithActions> groupDetailList;

  PlanWithGroups({required this.plan, required this.groupDetailList});

  @override
  String toString() {
    return '''
    PlanWithGroups {
      plan: $plan, groupDetailList: $groupDetailList,
    ''';
  }
}

// 跟练时需要的简单处理动作详情后的数据格式
// ？？？？
class ActionPractice {
  final TrainingPlan plan;
  // 这里列表的索引，就是plan周期的训练日顺序了
  final List<GroupWithActions> groupDetailList;

  ActionPractice({required this.plan, required this.groupDetailList});

  @override
  String toString() {
    return '''
    PlanWithGroups {
      plan: $plan, groupDetailList: $groupDetailList,
    ''';
  }
}

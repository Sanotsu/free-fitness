/// 关于 训练trainnig 模块的model都放在这里，对照相关表栏位了解更多

/// --- 基础表
class Exercise {
  int? exerciseId; // 自增的，可以不传
  String exerciseCode, exerciseName, category, countingMode, gmtCreate;
  String? force, level, mechanic, equipment, instructions, ttsNotes;
  String? primaryMuscles, secondaryMuscles, images, standardDuration;
  // standardDuration 应该是整数或者小数的，但这里用的字符串，虽然都是下拉选择的可以转，但看着不太好
  // int? standardDuration;
  String? gmtModified, isCustom, contributor;

  Exercise({
    this.exerciseId,
    required this.exerciseCode,
    required this.exerciseName,
    required this.category,
    required this.countingMode,
    required this.gmtCreate,
    this.force,
    this.level,
    this.mechanic,
    this.equipment,
    this.standardDuration,
    this.instructions,
    this.ttsNotes,
    this.primaryMuscles,
    this.secondaryMuscles,
    this.images,
    this.isCustom,
    this.contributor,
    this.gmtModified,
  });

  // 将一个 TxtState 转换成一个Map。键必须对应于数据库中的列名。
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

// 用于从数据库行映射到 ServingInfo 对象的 fromMap 方法
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      exerciseId: map['exercise_id'],
      exerciseCode: map['exercise_code'],
      exerciseName: map['exercise_name'],
      force: map['force'],
      level: map['level'],
      mechanic: map['mechanic'],
      equipment: map['equipment'],
      countingMode: map['counting_mode'],
      // ？？？明明sql语句设置了默认值，但是不传还是null
      standardDuration: map['standard_duration'] ?? "1",
      instructions: map['instructions'],
      ttsNotes: map['tts_notes'],
      category: map['category'],
      primaryMuscles: map['primary_muscles'],
      secondaryMuscles: map['secondary_muscles'],
      images: map['images'],
      // ？？？明明sql语句设置了默认值，但是不传还是null
      isCustom: map['is_custom'] ?? 'true',
      contributor: map['contributor'],
      gmtCreate: map['gmt_create'],
      gmtModified: map['gmt_modified'],
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

// 基础活动一些栏位的默认选项都具有label和value
class ExerciseDefaultOption {
  final String label;
  final String? name;
  final String value;

  ExerciseDefaultOption({
    required this.label,
    this.name,
    required this.value,
  });
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
  int? restInterval, consumption, timeSpent;
  String? description, contributor, gmtCreate, gmtModified;

  TrainingGroup({
    this.groupId,
    required this.groupName,
    required this.groupCategory,
    required this.groupLevel,
    this.restInterval,
    this.consumption,
    this.timeSpent,
    this.description,
    this.contributor,
    required this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'group_category': groupCategory,
      'group_level': groupLevel,
      'rest_interval': restInterval,
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
      restInterval: map['rest_interval'] as int?,
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
    group_level: $groupLevel, rest_interval: $restInterval, consumption: $consumption, time_spent: $timeSpent, 
    description: $description, contributor: $contributor, gmt_create: $gmtCreate, gmt_modified: $gmtModified }
    ''';
  }
}

class TrainingPlan {
  int? planId; // 自增的，可以不传
  int planPeriod;
  String planCode, planName, planCategory;
  String? planLevel, description, contributor, gmtCreate, gmtModified;

  TrainingPlan({
    this.planId,
    required this.planCode,
    required this.planName,
    required this.planCategory,
    this.planLevel,
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
      planPeriod: map['plan_period'] as int,
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

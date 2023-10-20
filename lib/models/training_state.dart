/// 关于 训练trainnig 模块的model都放在这里，对照相关表栏位了解更多

// 基础活动表的model
class Exercise {
  int? exerciseId; // 自增的，可以不传
  String exerciseCode, exerciseName, category, gmtCreate;
  String? force, level, mechanic, equipment, instructions, ttsNotes;
  String? primaryMuscles, secondaryMuscles, images, standardDuration;
  String? gmtModified, isCustom, contributor;

  Exercise({
    this.exerciseId,
    required this.exerciseCode,
    required this.exerciseName,
    required this.category,
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

// 动作表的 model
class Action {
  int? actionId; // 自增的，可以不传
  String actionCode, actionName, exerciseId, gmtCreate;
  String? frequency, duration, equipmentWeight, actionLevel, description;
  String? contributor, gmtModified;

  Action({
    this.actionId,
    required this.actionCode,
    required this.actionName,
    required this.exerciseId,
    this.frequency,
    this.duration,
    this.equipmentWeight,
    this.actionLevel,
    this.description,
    this.contributor,
    required this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'action_id': actionId,
      'action_code': actionCode,
      'action_name': actionName,
      'exercise_id': exerciseId,
      'frequency': frequency,
      'duration': duration,
      'equipment_weight': equipmentWeight,
      'action_level': actionLevel,
      'description': description,
      'contributor': contributor,
      'gmt_create': gmtCreate,
      'gmt_modified': gmtModified,
    };
  }

  @override
  String toString() {
    return '''
    Action {
    action_id: $exerciseId, action_code: $actionCode, action_name: $actionName,exercise_id: $exerciseId, 
    frequency: $frequency, duration: $duration,equipment_weight: $equipmentWeight, action_level: $actionLevel, 
    description: $description, contributor: $contributor, gmt_create: $gmtCreate, gmt_modified: $gmtModified }
    ''';
  }
}

class Group {
  int? groupId; // 自增的，可以不传
  String groupCode, groupName, groupCategory, gmtCreate;
  String? groupLevel, restInterval, consumption, timeSpent, description;
  String? contributor, gmtModified;

  Group({
    this.groupId,
    required this.groupCode,
    required this.groupName,
    required this.groupCategory,
    this.groupLevel,
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
      'group_code': groupCode,
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

  @override
  String toString() {
    return '''
    Group {
    group_id: $groupId, group_code: $groupCode, group_name: $groupName, group_category: $groupCategory, 
    group_level: $groupLevel, rest_interval: $restInterval, consumption: $consumption, time_spent: $timeSpent, 
    description: $description, contributor: $contributor, gmt_create: $gmtCreate, gmt_modified: $gmtModified }
    ''';
  }
}

class GroupHasAction {
  int? groupHasActionId; // 自增的，可以不传
  int groupId, actionId, actionOrder;

  GroupHasAction({
    this.groupHasActionId,
    required this.groupId,
    required this.actionId,
    required this.actionOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'group_has_action_id': groupHasActionId,
      'group_id': groupId,
      'action_id': actionId,
      'action_order': actionOrder,
    };
  }

  @override
  String toString() {
    return '''
    Group {group_has_action_id: $groupHasActionId, group_id: $groupId, action_id: $actionId, action_order: $actionOrder}
    ''';
  }
}

class Plan {
  int? planId; // 自增的，可以不传
  String planCode, planName, planCategory, gmtCreate;
  String? planLevel, description, contributor, gmtModified;

  Plan({
    this.planId,
    required this.planCode,
    required this.planName,
    required this.planCategory,
    this.planLevel,
    this.description,
    this.contributor,
    required this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'plan_id': planId,
      'plan_code': planCode,
      'plan_name': planName,
      'plan_category': planCategory,
      'plan_level': planLevel,
      'description': description,
      'contributor': contributor,
      'gmt_create': gmtCreate,
      'gmt_modified': gmtModified,
    };
  }

  @override
  String toString() {
    return '''
    Action {action_id: $planId, action_code: $planCode, action_name: $planName,exercise_id: $planCategory, 
    frequency: $planLevel, description: $description, contributor: $contributor, gmt_create: $gmtCreate, gmt_modified: $gmtModified }
    ''';
  }
}

class PlanHasGroup {
  int? planHasGroupId; // 自增的，可以不传
  int planId, groupId, groupOrder;

  PlanHasGroup({
    this.planHasGroupId,
    required this.planId,
    required this.groupId,
    required this.groupOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'plan_has_group_id': planHasGroupId,
      'plan_id': planId,
      'group_id': groupId,
      'group_order': groupOrder,
    };
  }

  @override
  String toString() {
    return '''
    Group {plan_has_group_id: $planHasGroupId, plan_id: $planId, group_id: $groupId, group_order: $groupOrder}
    ''';
  }
}

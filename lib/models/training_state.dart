/// 关于 workout 模块的model都放在这里，对照相关表栏位了解更多

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

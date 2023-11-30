/// json文件时自定义的栏位
/// 数据是参考  https://github.com/yuhonas/free-exercise-db
/// 但有一些栏位是内部需要的和设定的，可为空
/// 因为db设定id为int，这里的id导入时会被替换成code，所以这里就不需要code了
class CustomExercise {
  String? id;
  String? name;
  String? force;
  String? level;
  String? mechanic;
  String? equipment;
  List<String>? primaryMuscles;
  List<String>? secondaryMuscles;
  List<String>? instructions;
  String? category;
  List<String>? images;
  // 其他可能必要的栏位(不填导入时也有默认值)
  String? code; // 如果id和code都有，依次来
  String? countingMode;
  String? standardDuration;
  String? ttsNotes;
  String? isCustom;
  String? contributor;
  String? gmtCreate;
  String? gmtModified;

  CustomExercise({
    this.id,
    this.name,
    this.force,
    this.level,
    this.mechanic,
    this.equipment,
    this.primaryMuscles,
    this.secondaryMuscles,
    this.instructions,
    this.category,
    this.images,
    // 其他可能必要的栏位(不填导入时也有默认值)
    this.code,
    this.countingMode,
    this.standardDuration,
    this.ttsNotes,
    this.isCustom,
    this.contributor,
    this.gmtCreate,
    this.gmtModified,
  });

  CustomExercise.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    force = json['force'];
    level = json['level'];
    mechanic = json['mechanic'];
    equipment = json['equipment'];
    primaryMuscles = json['primaryMuscles']?.cast<String>();
    secondaryMuscles = json['secondaryMuscles']?.cast<String>();
    instructions = json['instructions']?.cast<String>();
    category = json['category'];
    images = json['images']?.cast<String>();
    // 其他可能必要的栏位(不填导入时也有默认值)
    code = json['code'];
    countingMode = json['countingMode'];
    standardDuration = json['standardDuration'];
    ttsNotes = json['ttsNotes'];
    isCustom = json['isCustom'];
    contributor = json['contributor'];
    gmtCreate = json['gmtCreate'];
    gmtModified = json['gmtModified'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['force'] = force;
    data['level'] = level;
    data['mechanic'] = mechanic;
    data['equipment'] = equipment;
    data['primaryMuscles'] = primaryMuscles;
    data['secondaryMuscles'] = secondaryMuscles;
    data['instructions'] = instructions;
    data['category'] = category;
    data['images'] = images;
    // 其他可能必要的栏位(不填导入时也有默认值)
    data['code'] = code;
    data["countingMode"] = countingMode;
    data["standardDuration"] = standardDuration;
    data["ttsNotes"] = ttsNotes;
    data["isCustom"] = isCustom;
    data["contributor"] = contributor;
    data["gmtCreate"] = gmtCreate;
    data["gmtModified"] = gmtModified;

    return data;
  }
}

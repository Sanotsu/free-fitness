import '../common/global/constants.dart';
import '../common/utils/tools.dart';

/// 用户基础信息和用户设置相关的表

/// 基础表表

// 用户基础信息表
class User {
  int? userId; // 自增的，可以不传
  String userName;
  String? userCode, gender, description, password, dateOfBirth;
  String? heightUnit, weightUnit, avatar;
  int? rdaGoal, actionRestTime;
  double? height, currentWeight, targetWeight, proteinGoal, fatGoal, choGoal;

  User({
    this.userId,
    required this.userName,
    this.userCode,
    this.gender,
    this.avatar,
    this.password,
    this.description,
    this.dateOfBirth,
    this.height,
    this.heightUnit,
    this.currentWeight,
    this.targetWeight,
    this.weightUnit,
    this.rdaGoal,
    this.proteinGoal,
    this.fatGoal,
    this.choGoal,
    this.actionRestTime,
  });

  Map<String, dynamic> toMap() {
    return {
      "user_id": userId,
      "user_name": userName,
      "user_code": userCode,
      "gender": gender,
      "avatar": avatar,
      "password": password,
      "description": description,
      "date_of_birth": dateOfBirth,
      "height": height,
      "height_unit": heightUnit,
      "current_weight": currentWeight,
      "target_weight": targetWeight,
      "weight_unit": weightUnit,
      "rda_goal": rdaGoal,
      "protein_goal": proteinGoal,
      "fat_goal": fatGoal,
      "cho_goal": choGoal,
      "action_rest_time": actionRestTime,
    };
  }

  // 给表单初始化值得时候，需要转类型
  Map<String, dynamic> toStringMap() {
    return {
      "user_id": userId,
      "user_name": userName,
      "user_code": userCode,
      "gender": gender,
      "avatar": avatar,
      "password": password,
      "description": description,
      "date_of_birth": DateTime.tryParse(dateOfBirth ?? unknownDateString),
      "height": cusDoubleTryToIntString(height ?? 0),
      "height_unit": heightUnit?.toString(),
      "current_weight": cusDoubleTryToIntString(currentWeight ?? 0),
      "target_weight": cusDoubleTryToIntString(targetWeight ?? 0),
      "weight_unit": weightUnit?.toString(),
      "rda_goal": rdaGoal?.toString(),
      "protein_goal": cusDoubleTryToIntString(proteinGoal ?? 0),
      "fat_goal": cusDoubleTryToIntString(fatGoal ?? 0),
      "cho_goal": cusDoubleTryToIntString(choGoal ?? 0),
      "action_rest_time": actionRestTime?.toString(),
    };
  }

// 用于从数据库行映射到 ServingInfo 对象的 fromMap 方法
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] as int?,
      userName: map['user_name'] as String,
      userCode: map['user_code'] as String?,
      gender: map['gender'] as String?,
      avatar: map['avatar'] as String?,
      password: map['password'] as String?,
      description: map['description'] as String?,
      dateOfBirth: map['date_of_birth'] as String?,
      height: map['height'] as double?,
      heightUnit: map['height_unit'] as String?,
      currentWeight: map['current_weight'] as double?,
      targetWeight: map['target_weight'] as double?,
      weightUnit: map['weight_unit'] as String?,
      rdaGoal: map['rda_goal'] as int?,
      proteinGoal: map['protein_goal'] as double?,
      fatGoal: map['fat_goal'] as double?,
      choGoal: map['cho_goal'] as double?,
      actionRestTime: map['action_rest_time'] as int?,
    );
  }

  @override
  String toString() {
    return '''
    User{
      userId: $userId, userName: $userName, userCode: $userCode, gender: $gender,avatar:$avatar,password: $password,
      description:$description, dateOfBirth: $dateOfBirth, height: $height,  heightUnit: $heightUnit, 
      currentWeight: $currentWeight, targetWeight: $targetWeight, targetWeight: $targetWeight, 
      rdaGoal: $rdaGoal, proteinGoal: $proteinGoal, fatGoal: $fatGoal,choGoal: $choGoal,
      actionRestTime: $actionRestTime
    }
    ''';
  }
}

// 饮食摄入目标
class IntakeDailyGoal {
  int? intakeDailyGoalId; // 自增的，可以不传
  int userId, rdaDailyGoal;
  String dayOfWeek;
  double proteinDailyGoal, fatDailyGoal, choDailyGoal;

  IntakeDailyGoal({
    this.intakeDailyGoalId,
    required this.userId,
    required this.dayOfWeek,
    required this.rdaDailyGoal,
    required this.proteinDailyGoal,
    required this.fatDailyGoal,
    required this.choDailyGoal,
  });

  Map<String, dynamic> toMap() {
    return {
      "intake_daily_goal_id": intakeDailyGoalId,
      "user_id": userId,
      "day_of_week": dayOfWeek,
      "rda_daily_goal": rdaDailyGoal,
      "protein_daily_goal": proteinDailyGoal,
      "fat_daily_goal": fatDailyGoal,
      "cho_daily_goal": choDailyGoal,
    };
  }

  factory IntakeDailyGoal.fromMap(Map<String, dynamic> map) {
    return IntakeDailyGoal(
      intakeDailyGoalId: map["intake_daily_goal_id"] as int?,
      userId: map["user_id"] as int,
      dayOfWeek: map["day_of_week"] as String,
      rdaDailyGoal: map["rda_daily_goal"] as int,
      proteinDailyGoal: map["protein_daily_goal"] as double,
      fatDailyGoal: map["fat_daily_goal"] as double,
      choDailyGoal: map["cho_daily_goal"] as double,
    );
  }

  @override
  String toString() {
    return '''
    IntakeDailyGoal{
      intakeDailyGoalId: $intakeDailyGoalId, userId: $userId, dayOfWeek: $dayOfWeek, 
      rdaDailyGoal: $rdaDailyGoal, rdaDailyGoal: $rdaDailyGoal, 
      proteinDailyGoal: $proteinDailyGoal, fatDailyGoal: $fatDailyGoal, choDailyGoal: $choDailyGoal , 
    }
    ''';
  }
}

class WeightTrend {
  int? weightTrendId; // 自增的，可以不传
  int userId;
  String weightUnit, heightUnit, gmtCreate;
  double weight, height, bmi;

  WeightTrend({
    this.weightTrendId,
    required this.userId,
    required this.weight,
    required this.weightUnit,
    required this.height,
    required this.heightUnit,
    required this.bmi,
    required this.gmtCreate,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight_trend_id': weightTrendId,
      'user_id': userId,
      'weight': weight,
      'weight_unit': weightUnit,
      'height': height,
      'height_unit ': heightUnit,
      'bmi': bmi,
      'gmt_create': gmtCreate,
    };
  }

// 用于从数据库行映射到 ServingInfo 对象的 fromMap 方法
  factory WeightTrend.fromMap(Map<String, dynamic> map) {
    return WeightTrend(
      weightTrendId: map['weight_trend_id'] as int?,
      userId: map['user_id'] as int,
      weight: map['weight'] as double,
      weightUnit: map['weight_unit'] as String,
      height: map['height'] as double,
      heightUnit: map['height_unit'] as String,
      bmi: map['bmi'] as double,
      gmtCreate: map['gmt_create'] as String,
    );
  }

  @override
  String toString() {
    return '''
    WeightTrend{
     weightTrendId: $weightTrendId, userId: $userId, weight: $weight, weightUnit: $weightUnit,
     height: $height, heightUnit: $heightUnit, bmi: $bmi, gmt_create: $gmtCreate 
    }
    ''';
  }
}

/// 扩展表

// 带有饮食摄入目标的用户信息
class UserWithIntakeDailyGoal {
  // 用户基本信息
  User user;
  // 一个用户最多有周一到周日7条每日摄入目标设定值
  List<IntakeDailyGoal> intakeGoals;

  UserWithIntakeDailyGoal({
    required this.user,
    required this.intakeGoals,
  });
  @override
  String toString() {
    return '''
    UserWithIntakeDailyGoal{ 
      "user": $user,
      "List<IntakeDailyGoal>": $intakeGoals
    }
    ''';
  }
}

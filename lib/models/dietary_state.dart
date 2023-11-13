// ignore_for_file: avoid_print

// 食物
class Food {
  int? foodId; // 自增的，可以不传
  String brand, product;
  String? photos, tags, category, contributor, gmtCreate;

  Food({
    this.foodId,
    required this.brand,
    required this.product,
    this.photos,
    this.tags,
    this.category,
    this.contributor,
    this.gmtCreate,
  });

  Map<String, dynamic> toMap() {
    return {
      'food_id': foodId,
      'brand': brand,
      'product': product,
      'photos': photos,
      'tags': tags,
      'category': category,
      'contributor': contributor,
      'gmt_create': gmtCreate,
    };
  }

// 用于从数据库行映射到 ServingInfo 对象的 fromMap 方法
  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      foodId: map['food_id'] as int?,
      brand: map['brand'] as String,
      product: map['product'] as String,
      photos: map['photos'] as String?,
      tags: map['tags'] as String?,
      category: map['category'] as String?,
      contributor: map['contributor'] as String?,
      gmtCreate: map['gmt_create'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    Food{
    food_id: $foodId, brand: $brand, product: $product, photos: $photos, tags: $tags, 
    category: $category, contributor: $contributor, gmt_create: $gmtCreate }
    ''';
  }
}

// 单份食物营养素
class ServingInfo {
  int? servingInfoId; // 自增的，可以不传
  int foodId, servingSize;
  String servingUnit;
  String? contributor, gmtCreate, updateUser, gmtModified;
  double energy, protein, totalFat, totalCarbohydrate, sodium;
  double? saturatedFat, transFat, polyunsaturatedFat, monounsaturatedFat;
  double? cholesterol, sugar, dietaryFiber, potassium;

  ServingInfo({
    this.servingInfoId,
    required this.foodId,
    required this.servingSize,
    required this.servingUnit,
    required this.energy,
    required this.protein,
    required this.totalFat,
    this.saturatedFat,
    this.transFat,
    this.polyunsaturatedFat,
    this.monounsaturatedFat,
    required this.totalCarbohydrate,
    this.sugar,
    this.dietaryFiber,
    required this.sodium,
    this.cholesterol,
    this.potassium,
    this.contributor,
    this.gmtCreate,
    this.updateUser,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      "serving_info_id": servingInfoId,
      "food_id": foodId,
      "serving_size": servingSize,
      "serving_unit": servingUnit,
      "energy": energy,
      "protein": protein,
      "total_fat": totalFat,
      "saturated_fat": saturatedFat,
      "trans_fat": transFat,
      "polyunsaturated_fat": polyunsaturatedFat,
      "monounsaturated_fat": monounsaturatedFat,
      "cholesterol": cholesterol,
      "total_carbohydrate": totalCarbohydrate,
      "sugar": sugar,
      "dietary_fiber": dietaryFiber,
      "sodium": sodium,
      "potassium": potassium,
      "contributor": contributor,
      "gmt_create": gmtCreate,
      "update_user": updateUser,
      "gmt_modified": gmtModified,
    };
  }

  factory ServingInfo.fromMap(Map<String, dynamic> map) {
    return ServingInfo(
      servingInfoId: map['serving_info_id'] as int?,
      foodId: map['food_id'] as int,
      servingSize: map['serving_size'] as int,
      servingUnit: map['serving_unit'] as String,
      energy: map['energy'] as double,
      protein: map['protein'] as double,
      totalFat: map['total_fat'] as double,
      totalCarbohydrate: map['total_carbohydrate'] as double,
      sodium: map['sodium'] as double,
      saturatedFat: map['saturated_fat'] as double?,
      transFat: map['trans_fat'] as double?,
      polyunsaturatedFat: map['polyunsaturated_fat'] as double?,
      monounsaturatedFat: map['monounsaturated_fat'] as double?,
      cholesterol: map['cholesterol'] as double?,
      sugar: map['sugar'] as double?,
      dietaryFiber: map['dietary_fiber'] as double?,
      potassium: map['potassium'] as double?,
      contributor: map['contributor'] as String?,
      gmtCreate: map['gmt_create'] as String?,
      updateUser: map['update_user'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    ServingInfo{
    "serving_info_id": $servingInfoId, "food_id": $foodId, 
      "serving_size": $servingSize, "serving_unit": $servingUnit,
      "energy": $energy, "protein": $protein, "total_fat": $totalFat, "saturated_fat": $saturatedFat, "trans_fat": $transFat, 
      "polyunsaturated_fat": $polyunsaturatedFat, "monounsaturated_fat": $monounsaturatedFat, "cholesterol": $cholesterol, 
      "total_carbohydrate": $totalCarbohydrate, "sugar": $sugar, "dietary_fiber": $dietaryFiber, "sodium": $sodium, "potassium": $potassium, 
      "contributor": $contributor, "gmt_create": $gmtCreate, "update_user": $updateUser, "gmt_modified": $gmtModified}
    ''';
  }
}

// 饮食日记条目
class DailyFoodItem {
  int? dailyFoodItemId; // 自增的，可以不传(如果设为必要的栏位再给默认值，新增时会被默认值替换数据库设置的自增导致无法插入)
  String date, mealCategory;
  int foodId, servingInfoId;
  double foodIntakeSize;
  String? contributor, gmtCreate, updateUser, gmtModified;

  DailyFoodItem({
    this.dailyFoodItemId,
    required this.date,
    required this.mealCategory,
    required this.foodId,
    required this.servingInfoId,
    required this.foodIntakeSize,
    this.contributor,
    this.gmtCreate,
    this.updateUser,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      "daily_food_item_id": dailyFoodItemId,
      "date": date,
      "meal_category": mealCategory,
      "food_id": foodId,
      "food_intake_size": foodIntakeSize,
      "serving_info_id": servingInfoId,
      "contributor": contributor,
      "gmt_create": gmtCreate,
      "update_user": updateUser,
      "gmt_modified": gmtModified,
    };
  }

  // 用于从数据库行映射到 DailyFoodItem 对象的 fromMap 方法
  factory DailyFoodItem.fromMap(Map<String, dynamic> map) {
    return DailyFoodItem(
      dailyFoodItemId: map['daily_food_item_id'] as int?,
      date: map['date'] as String,
      mealCategory: map['meal_category'] as String,
      foodId: map['food_id'] as int,
      foodIntakeSize: map['food_intake_size'] as double,
      servingInfoId: map['serving_info_id'] as int,
      contributor: map['contributor'] as String?,
      gmtCreate: map['gmt_create'] as String?,
      updateUser: map['update_user'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    DailyFoodItem {  
      "daily_food_item_id": $dailyFoodItemId,"date": $date,"meal_category": $mealCategory,
      "food_id": $foodId,"food_intake_size": $foodIntakeSize, serving_info_id:$servingInfoId,
      "contributor": $contributor,"gmt_create": $gmtCreate,"gmt_modified": $gmtModified
    }
    ''';
  }
}

// 用户基础信息表
// ？？？后续可以跟训练部分的基础表合二为一
class DietaryUser {
  int? userId; // 自增的，可以不传
  String userName;
  String? userCode, gender, description, password, dateOfBirth;
  int? rdaGoal;
  double? height, currentWeight, targetWeight, proteinGoal, fatGoal, choGoal;

  DietaryUser({
    this.userId,
    required this.userName,
    this.userCode,
    this.gender,
    this.description,
    this.password,
    this.dateOfBirth,
    this.height,
    this.currentWeight,
    this.targetWeight,
    this.rdaGoal,
    this.proteinGoal,
    this.fatGoal,
    this.choGoal,
  });

  Map<String, dynamic> toMap() {
    return {
      "user_id": userId,
      "user_name": userName,
      "user_code": userCode,
      "gender": gender,
      "description": description,
      "password": password,
      "date_of_birth": dateOfBirth,
      "height": height,
      "current_weight": currentWeight,
      "target_weight": targetWeight,
      "rda_goal": rdaGoal,
      "protein_goal": proteinGoal,
      "fat_goal": fatGoal,
      "cho_goal": choGoal,
    };
  }

// 用于从数据库行映射到 ServingInfo 对象的 fromMap 方法
  factory DietaryUser.fromMap(Map<String, dynamic> map) {
    return DietaryUser(
      userId: map['user_id'] as int?,
      userName: map['user_name'] as String,
      userCode: map['user_code'] as String?,
      gender: map['gender'] as String?,
      description: map['description'] as String?,
      password: map['password'] as String?,
      dateOfBirth: map['date_of_birth'] as String?,
      height: map['height'] as double?,
      currentWeight: map['current_weight'] as double?,
      targetWeight: map['target_weight'] as double?,
      rdaGoal: map['rda_goal'] as int?,
      proteinGoal: map['protein_goal'] as double?,
      fatGoal: map['fat_goal'] as double?,
      choGoal: map['cho_goal'] as double?,
    );
  }

  @override
  String toString() {
    return '''
    DietaryUser{
      userId: $userId, userName: $userName, userCode: $userCode, gender: $gender,  
      description:$description, password: $password, dateOfBirth: $dateOfBirth, 
      height: $height, currentWeight: $currentWeight, targetWeight: $targetWeight, 
      rdaGoal: $rdaGoal, proteinGoal: $proteinGoal, fatGoal: $fatGoal,choGoal: $choGoal
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

/// 扩展表

// 食物营养素详情 (食物带上对应的所有单份营养素列表)
class FoodAndServingInfo {
  final Food food;
  final List<ServingInfo> servingInfoList;

  FoodAndServingInfo({required this.food, required this.servingInfoList});

  @override
  String toString() {
    return '''
    FoodAndServingInfo { 
      "food": $food,
      "servingInfoList": $servingInfoList
    }
    ''';
  }
}

// 饮食日记条目详情 (日记条目带上食物和当前用到的那个营养素详情)
class DailyFoodItemWithFoodServing {
  DailyFoodItem dailyFoodItem;
  Food food;
  ServingInfo servingInfo;

  DailyFoodItemWithFoodServing({
    required this.dailyFoodItem,
    required this.food,
    required this.servingInfo,
  });

  @override
  String toString() {
    return '''
    DailyFoodItemWithFoodServing{ 
      "dailyFoodItem": $dailyFoodItem,
      "food": $food,
      "servingInfo": $servingInfo,
    }
    ''';
  }
}

// 在饮食日记报告分析时，需要每种营养素的值或者累加值信息，这些属性仅用于显示需要
class FoodNutrientVO {
  double energy, calorie, protein, totalFat, totalCarbohydrate, sodium;
  double? saturatedFat, transFat, polyunsaturatedFat, monounsaturatedFat;
  double? sugar, dietaryFiber, cholesterol, potassium;
  double? breakfastColories, lunchColories, dinnerColories, otherColories;

  FoodNutrientVO({
    required this.energy,
    required this.calorie,
    required this.protein,
    required this.totalFat,
    this.saturatedFat,
    this.transFat,
    this.polyunsaturatedFat,
    this.monounsaturatedFat,
    required this.totalCarbohydrate,
    this.sugar,
    this.dietaryFiber,
    required this.sodium,
    this.cholesterol,
    this.potassium,
    this.breakfastColories,
    this.lunchColories,
    this.dinnerColories,
    this.otherColories,
  });

// 初始化方法，返回所有属性为0的实例
  static FoodNutrientVO initWithZero() {
    return FoodNutrientVO(
      energy: 0,
      calorie: 0,
      protein: 0,
      totalFat: 0,
      totalCarbohydrate: 0,
      sodium: 0,
    );
  }

// 因为是VO，暂时可能不需要tomap或者frommap
  @override
  String toString() {
    return '''
    FoodNutrientVO{
      "energy": $energy, "calorie": $calorie, "protein": $protein,  "sodium": $sodium, "totalFat": $totalFat,
      "saturatedFat": $saturatedFat, "transFat": $transFat, "polyunsaturatedFat": $polyunsaturatedFat, 
      "monounsaturatedFat": $monounsaturatedFat, "totalCarbohydrate": $totalCarbohydrate, 
      "sugar": $sugar, "dietaryFiber": $dietaryFiber,"cholesterol": $cholesterol, "potassium": $potassium, 
    }
    ''';
  }
}

// 更单纯的一个类，记录累加量的
class FoodNutrientTotals {
  // 基本营养素
  double energy = 0.0;
  double protein = 0.0;
  double totalFat = 0.0;
  double totalCHO = 0.0;
  double sodium = 0.0;
  double cholesterol = 0.0;
  double dietaryFiber = 0.0;
  double potassium = 0.0;
  double sugar = 0.0;
  double transFat = 0.0;
  double saturatedFat = 0.0;
  double muFat = 0.0;
  double puFat = 0.0;
  // 对应卡路里数量
  double calorie = 0.0;
  // 三餐的能量数
  double bfEnergy = 0.0;
  double lunchEnergy = 0.0;
  double dinnerEnergy = 0.0;
  double otherEnergy = 0.0;
  // 三餐的卡路里数
  double bfCalorie = 0.0;
  double lunchCalorie = 0.0;
  double dinnerCalorie = 0.0;
  double otherCalorie = 0.0;

  Map<String, double> toMap() {
    return {
      'energy': energy,
      'protein': protein,
      'totalFat': totalFat,
      'totalCHO': totalCHO,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'dietaryFiber': dietaryFiber,
      'potassium': potassium,
      'sugar': sugar,
      'transFat': transFat,
      'saturatedFat': saturatedFat,
      'muFat': muFat,
      'puFat': puFat,
      'calorie': calorie,
      // 这几个不算营养素，暂时不放在这里
      // 'bfEnergy': bfEnergy,
      // 'lunchEnergy': lunchEnergy,
      // 'dinnerEnergy': dinnerEnergy,
      // 'otherEnergy': otherEnergy,
      // 'bfCalorie': bfCalorie,
      // 'lunchCalorie': lunchCalorie,
      // 'dinnerCalorie': dinnerCalorie,
      // 'otherCalorie': otherCalorie,
    };
  }
}

// 带有饮食摄入目标的用户信息
class DietaryUserWithIntakeDailyGoal {
  DietaryUser user;
  List<IntakeDailyGoal> goal;

  DietaryUserWithIntakeDailyGoal({
    required this.user,
    required this.goal,
  });
  @override
  String toString() {
    return '''
    DietaryUserWithIntakeDailyGoal{ 
      "user": $user,
      "List<IntakeDailyGoal>": $goal
    }
    ''';
  }
}

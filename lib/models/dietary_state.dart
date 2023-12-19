// ignore_for_file: avoid_print

// 食物
class Food {
  int? foodId; // 自增的，可以不传
  String brand, product;
  String? description, photos, tags, category, contributor, gmtCreate;
  bool isDeleted;

  Food({
    this.foodId,
    required this.brand,
    required this.product,
    this.description,
    this.photos,
    this.tags,
    this.category,
    this.contributor,
    this.gmtCreate,
    required this.isDeleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'food_id': foodId,
      'brand': brand,
      'product': product,
      'description': description,
      'photos': photos,
      'tags': tags,
      'category': category,
      'contributor': contributor,
      'gmt_create': gmtCreate,
      "is_deleted": isDeleted,
    };
  }

// 用于从数据库行映射到 ServingInfo 对象的 fromMap 方法
  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      foodId: map['food_id'] as int?,
      brand: map['brand'] as String,
      product: map['product'] as String,
      photos: map['photos'] as String?,
      description: map['description'] as String?,
      tags: map['tags'] as String?,
      category: map['category'] as String?,
      contributor: map['contributor'] as String?,
      gmtCreate: map['gmt_create'] as String?,
      isDeleted: map['is_deleted'] == 0 ? false : true,
    );
  }

  @override
  String toString() {
    return '''
    Food{
      food_id: $foodId, brand: $brand, product: $product,description:$description, photos: $photos, tags: $tags, 
      category: $category, contributor: $contributor, gmt_create: $gmtCreate, is_deleted: $isDeleted
    }
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
  bool isDeleted;

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
    required this.isDeleted,
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
      "is_deleted": isDeleted ? 1 : 0,
    };
  }

  // 2023-12-06 在修改单份营养素时，对已有的ServingInfo作为表单的初始化值时，可能会报错
  // 这里全部转为string的话，应该还行
  Map<String, dynamic> toStringMap() {
    return {
      "serving_info_id": servingInfoId,
      "food_id": foodId,
      "serving_size": servingSize,
      "serving_unit": servingUnit,
      "energy": energy.toStringAsFixed(2),
      "protein": protein.toStringAsFixed(2),
      "total_fat": totalFat.toStringAsFixed(2),
      "saturated_fat": saturatedFat?.toStringAsFixed(2),
      "trans_fat": transFat?.toStringAsFixed(2),
      "polyunsaturated_fat": polyunsaturatedFat?.toStringAsFixed(2),
      "monounsaturated_fat": monounsaturatedFat?.toStringAsFixed(2),
      "cholesterol": cholesterol?.toStringAsFixed(2),
      "total_carbohydrate": totalCarbohydrate.toStringAsFixed(2),
      "sugar": sugar?.toStringAsFixed(2),
      "dietary_fiber": dietaryFiber?.toStringAsFixed(2),
      "sodium": sodium.toStringAsFixed(2),
      "potassium": potassium?.toStringAsFixed(2),
      "contributor": contributor,
      "gmt_create": gmtCreate,
      "update_user": updateUser,
      "gmt_modified": gmtModified,
      "is_deleted": isDeleted,
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
      isDeleted: map['is_deleted'] == 0 ? false : true,
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
      "contributor": $contributor, "gmt_create": $gmtCreate, "update_user": $updateUser, "gmt_modified": $gmtModified,"is_deleted": $isDeleted
      }
    ''';
  }
}

// 饮食日记条目
class DailyFoodItem {
  int? dailyFoodItemId; // 自增的，可以不传(如果设为必要的栏位再给默认值，新增时会被默认值替换数据库设置的自增导致无法插入)
  String date, mealCategory;
  int userId, foodId, servingInfoId;
  double foodIntakeSize;
  String? gmtCreate, gmtModified;

  DailyFoodItem({
    this.dailyFoodItemId,
    required this.userId,
    required this.date,
    required this.mealCategory,
    required this.foodIntakeSize,
    required this.foodId,
    required this.servingInfoId,
    this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      "daily_food_item_id": dailyFoodItemId,
      "user_id": userId,
      "date": date,
      "meal_category": mealCategory,
      "food_intake_size": foodIntakeSize,
      "food_id": foodId,
      "serving_info_id": servingInfoId,
      "gmt_create": gmtCreate,
      "gmt_modified": gmtModified,
    };
  }

  // 用于从数据库行映射到 DailyFoodItem 对象的 fromMap 方法
  factory DailyFoodItem.fromMap(Map<String, dynamic> map) {
    return DailyFoodItem(
      dailyFoodItemId: map['daily_food_item_id'] as int?,
      userId: map['user_id'] as int,
      date: map['date'] as String,
      mealCategory: map['meal_category'] as String,
      foodIntakeSize: map['food_intake_size'] as double,
      foodId: map['food_id'] as int,
      servingInfoId: map['serving_info_id'] as int,
      gmtCreate: map['gmt_create'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    DailyFoodItem {  
      "daily_food_item_id": $dailyFoodItemId,"date": $date,"meal_category": $mealCategory,
      "food_id": $foodId,"food_intake_size": $foodIntakeSize, serving_info_id:$servingInfoId,
      "user_id": $userId,"gmt_create": $gmtCreate,"gmt_modified": $gmtModified
    }
    ''';
  }
}

/// 餐次对应的照片表
class MealPhoto {
  int? mealPhotoId; // 自增的，可以不传
  String date, mealCategory, photos, gmtCreate;
  int userId;

  MealPhoto({
    this.mealPhotoId,
    required this.userId,
    required this.date,
    required this.mealCategory,
    required this.photos, // 一次一餐可以传多个图片；如果照片为空，相当于删除整条记录
    required this.gmtCreate,
  });

  Map<String, dynamic> toMap() {
    return {
      "meal_photo_id": mealPhotoId,
      "user_id": userId,
      "date": date,
      "meal_category": mealCategory,
      "photos": photos,
      "gmt_create": gmtCreate,
    };
  }

// 用于从数据库行映射到 MealPhoto 对象的 fromMap 方法
  factory MealPhoto.fromMap(Map<String, dynamic> map) {
    return MealPhoto(
      mealPhotoId: map['meal_photo_id'] as int?,
      userId: map['user_id'] as int,
      date: map['date'] as String,
      mealCategory: map['meal_category'] as String,
      photos: map['photos'] as String,
      gmtCreate: map['gmt_create'] as String,
    );
  }

  @override
  String toString() {
    return '''
    MealPhoto{
      mealPhotoId: $mealPhotoId,userId: $userId, date: $date, mealCategory: $mealCategory, 
      photos: $photos,  gmt_create: $gmtCreate 
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

  // 定义一个方法用于累加另一个FoodNutrientTotals对象的值
  void add(FoodNutrientTotals other) {
    energy += other.energy;
    protein += other.protein;
    totalFat += other.totalFat;
    totalCHO += other.totalCHO;
    sodium += other.sodium;
    cholesterol += other.cholesterol;
    dietaryFiber += other.dietaryFiber;
    potassium += other.potassium;
    sugar += other.sugar;
    transFat += other.transFat;
    saturatedFat += other.saturatedFat;
    muFat += other.muFat;
    puFat += other.puFat;
    calorie += other.calorie;
    bfEnergy += other.bfEnergy;
    lunchEnergy += other.lunchEnergy;
    dinnerEnergy += other.dinnerEnergy;
    otherEnergy += other.otherEnergy;
    bfCalorie += other.bfCalorie;
    lunchCalorie += other.lunchCalorie;
    dinnerCalorie += other.dinnerCalorie;
    otherCalorie += other.otherCalorie;
  }

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

// ignore_for_file: avoid_print

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

class ServingInfo {
  int? servingInfoId; // 自增的，可以不传
  int foodId, servingSize;
  String servingUnit;
  String? contributor, gmtCreate, updUserId, gmtModified;
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
    this.updUserId,
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
      "upd_user_id": updUserId,
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
      updUserId: map['upd_user_id'] as String?,
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
      "contributor": $contributor, "gmt_create": $gmtCreate, "upd_user_id": $updUserId, "gmt_modified": $gmtModified}
    ''';
  }
}

class FoodDailyLog {
  int? foodDailyId; // 自增的，可以不传
  String date;
  int? breakfastMealId, lunchMealId, dinnerMealId, otherMealId;
  String? contributor, gmtCreate, gmtModified;

  FoodDailyLog({
    this.foodDailyId,
    required this.date,
    this.breakfastMealId,
    this.lunchMealId,
    this.dinnerMealId,
    this.otherMealId,
    this.contributor,
    this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      "food_daily_id": foodDailyId,
      "date": date,
      "breakfast_meal_id": breakfastMealId,
      "lunch_meal_id": lunchMealId,
      "dinner_meal_id": dinnerMealId,
      "other_meal_id": otherMealId,
      "contributor": contributor,
      "gmt_create": gmtCreate,
      "gmt_modified": gmtModified,
    };
  }

  // 用于从数据库行映射到 MealFoodItem 对象的 fromMap 方法
  factory FoodDailyLog.fromMap(Map<String, dynamic> map) {
    return FoodDailyLog(
      foodDailyId: map['food_daily_id'] as int?,
      date: map['date'] as String,
      breakfastMealId: map['breakfast_meal_id'] as int?,
      lunchMealId: map['lunch_meal_id'] as int?,
      dinnerMealId: map['dinner_meal_id'] as int?,
      otherMealId: map['other_meal_id'] as int?,
      contributor: map['contributor'] as String?,
      gmtCreate: map['gmt_create'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    FoodDailyLog{  "food_daily_id": $foodDailyId,"date": $date,"breakfast_meal_id": $breakfastMealId,"lunch_meal_id": $lunchMealId,
      "dinner_meal_id": $dinnerMealId,"other_meal_id": $otherMealId,"contributor": $contributor,"gmt_create": $gmtCreate,"gmt_modified": $gmtModified, }
    ''';
  }
}

class Meal {
  int? mealId; // 自增的，可以不传
  String mealName;
  String? description, contributor, gmtCreate, gmtModified;

  Meal({
    this.mealId,
    required this.mealName,
    this.description,
    this.contributor,
    this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      "meal_id": mealId,
      "meal_name": mealName,
      "description": description,
      "contributor": contributor,
      "gmt_create": gmtCreate,
      "gmt_modified": gmtModified,
    };
  }

  // 用于从数据库行映射到 Meal 对象的 fromMap 方法
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      mealId: map['meal_id'] as int?,
      mealName: map['meal_name'] as String,
      description: map['description'] as String?,
      contributor: map['contributor'] as String?,
      gmtCreate: map['gmt_create'] as String?,
      gmtModified: map['gmt_modified'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    Meal{ 
      "meal_id": $mealId,"meal_name": $mealName,"description": $description,
      "contributor": $contributor,"gmt_create": $gmtCreate,"gmt_modified": $gmtModified 
    }
    ''';
  }
}

class MealFoodItem {
  int? mealFoodItemId; // 自增的，可以不传
  int mealId, foodId, servingInfoId;
  double foodIntakeSize;

  MealFoodItem({
    this.mealFoodItemId,
    required this.mealId,
    required this.foodId,
    required this.servingInfoId,
    required this.foodIntakeSize,
  });

  Map<String, dynamic> toMap() {
    return {
      "meal_food_item_id": mealFoodItemId,
      "meal_id": mealId,
      "food_id": foodId,
      "serving_info_id": servingInfoId,
      "food_intake_size": foodIntakeSize,
    };
  }

// 用于从数据库行映射到 MealFoodItem 对象的 fromMap 方法
  factory MealFoodItem.fromMap(Map<String, dynamic> map) {
    return MealFoodItem(
      mealFoodItemId: map['meal_food_item_id'] as int?,
      mealId: map['meal_id'] as int,
      foodId: map['food_id'] as int,
      servingInfoId: map['serving_info_id'] as int,
      foodIntakeSize: map['food_intake_size'] as double,
    );
  }

  @override
  String toString() {
    return '''
    MealFoodItem{ 
      "meal_food_item_id": $mealFoodItemId,"meal_id": $mealId,
      "food_id": $foodId,"serving_info_id": $servingInfoId,"food_intake_size": $foodIntakeSize 
    }
    ''';
  }
}

/// 扩展表
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

/// 扩展表 - 饮食记录比较重要涉及
/// item 带 food 和serving info
class MealFoodItemDetail {
  MealFoodItem mealFoodItem;
  Food food;
  ServingInfo servingInfo;

  MealFoodItemDetail({
    required this.mealFoodItem,
    required this.food,
    required this.servingInfo,
  });

  @override
  String toString() {
    return '''
    MealFoodItemDetail{ 
      "mealFoodItem": $mealFoodItem,
      "food": $food,
      "servingInfo": $servingInfo
    }
    ''';
  }
}

// meal 带 item(已含food 和serving info)
class MealAndMealFoodItemDetail {
  final Meal meal;
  final List<MealFoodItemDetail> mealFoodItemDetailist;

  MealAndMealFoodItemDetail({
    required this.meal,
    required this.mealFoodItemDetailist,
  });

  @override
  String toString() {
    return '''
    MealAndMealFoodItemDetail{ 
      "meal": $meal,
      "mealFoodItemDetailist": $mealFoodItemDetailist
    }
    ''';
  }
}

// log 带 meal (已含item,再含 food 和serving info)
// 一个log，早中晚夜的meal也只有一个，但item有多个；
//      但一个item中只有1个food 和1个serving info
class FoodDailyLogRecord {
  FoodDailyLog foodDailyLog;
  MealAndMealFoodItemDetail? breakfastMealFoodItems;
  MealAndMealFoodItemDetail? lunchMealFoodItems;
  MealAndMealFoodItemDetail? dinnerMealFoodItems;
  MealAndMealFoodItemDetail? otherMealFoodItems;

  FoodDailyLogRecord({
    required this.foodDailyLog,
    this.breakfastMealFoodItems,
    this.lunchMealFoodItems,
    this.dinnerMealFoodItems,
    this.otherMealFoodItems,
  });

  @override
  String toString() {
    return '''
    FoodDailyLogRecord{ 
      "foodDailyLog": $foodDailyLog,
      "breakfastMealFoodItems": $breakfastMealFoodItems,
      "lunchMealFoodItems": $lunchMealFoodItems,
      "dinnerMealFoodItems": $dinnerMealFoodItems,
      "otherMealFoodItems": $otherMealFoodItems  
    }
    ''';
  }
}

class FoodIntakeRecord {
  int foodDailyId;
  String date;
  String? contributor;
  String? gmtCreate;
  String? gmtModified;
  Meal? breakfastMeal;
  Meal? lunchMeal;
  Meal? dinnerMeal;
  Meal? otherMeal;
  List<MealFoodItem> breakfastMealFoodItems;
  List<MealFoodItem> lunchMealFoodItems;
  List<MealFoodItem> dinnerMealFoodItems;
  List<MealFoodItem> otherMealFoodItems;

  FoodIntakeRecord({
    required this.foodDailyId,
    required this.date,
    this.contributor,
    this.gmtCreate,
    this.gmtModified,
    this.breakfastMeal,
    this.lunchMeal,
    this.dinnerMeal,
    this.otherMeal,
    this.breakfastMealFoodItems = const [],
    this.lunchMealFoodItems = const [],
    this.dinnerMealFoodItems = const [],
    this.otherMealFoodItems = const [],
  });

  @override
  String toString() {
    return '''
    FoodIntakeRecord{ 
      "foodDailyId": $foodDailyId,"date": $date,
      "contributor": $contributor,"gmtCreate": $gmtCreate,"gmtModified": $gmtModified,
      "breakfastMeal": $breakfastMeal,"lunchMeal": $lunchMeal,"dinnerMeal": $dinnerMeal,"otherMeal": $otherMeal,
      "breakfastMealFoodItems": $breakfastMealFoodItems,"lunchMealFoodItems": $lunchMealFoodItems,
      "dinnerMealFoodItems": $dinnerMealFoodItems,"otherMealFoodItems": $otherMealFoodItems
     }
    ''';
  }
}

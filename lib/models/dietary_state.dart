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
  int foodId;
  bool? isMetric;
  int? metricServingSize;
  String? servingSize, metricServingUnit;
  String? contributor, gmtCreate, updUserId, gmtModified;
  double energy, protein, totalFat, totalCarbohydrate, sodium;
  double? saturatedFat, transFat, polyunsaturatedFat, monounsaturatedFat;
  double? cholesterol, sugar, dietaryFiber, potassium;

  ServingInfo({
    this.servingInfoId,
    required this.foodId,
    this.isMetric,
    this.servingSize,
    this.metricServingSize,
    this.metricServingUnit,
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
      "is_metric": isMetric,
      "serving_size": servingSize,
      "metric_serving_size": metricServingSize,
      "metric_serving_unit": metricServingUnit,
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
      // int? 不是null或0 就转为bool的true
      isMetric: map['is_metric'] != null && map['is_metric'] != 0,
      servingSize: map['serving_size'] as String?,
      metricServingSize: map['metric_serving_size'] as int?,
      metricServingUnit: map['metric_serving_unit'] as String,
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
    "serving_info_id": $servingInfoId, "food_id": $foodId, "serving_size": $servingSize, "metric_serving_size": $metricServingSize,
      "energy": $energy, "protein": $protein, "total_fat": $totalFat, "saturated_fat": $saturatedFat, "trans_fat": $transFat, 
      "polyunsaturated_fat": $polyunsaturatedFat, "monounsaturated_fat": $monounsaturatedFat, "cholesterol": $cholesterol, 
      "total_carbohydrate": $totalCarbohydrate, "sugar": $sugar, "dietary_fiber": $dietaryFiber, "sodium": $sodium, "potassium": $potassium, 
      "contributor": $contributor, "gmt_create": $gmtCreate, "upd_user_id": $updUserId, "gmt_modified": $gmtModified}
    ''';
  }
}

class FoodAndServingInfo {
  final Food food;
  final List<ServingInfo> servingInfoList;

  FoodAndServingInfo({required this.food, required this.servingInfoList});
}

class Meal {
  int? mealId; // 自增的，可以不传
  String mealName, foodId, servingInfoId, intake;
  String? description, contributor, gmtCreate, gmtModified;

  Meal({
    this.mealId,
    required this.mealName,
    required this.foodId,
    required this.servingInfoId,
    required this.intake,
    this.description,
    this.contributor,
    this.gmtCreate,
    this.gmtModified,
  });

  Map<String, dynamic> toMap() {
    return {
      "meal_id": mealId,
      "meal_name": mealName,
      "food_id": foodId,
      "serving_info_id": servingInfoId,
      "intake": intake,
      "description": description,
      "contributor": contributor,
      "gmt_create": gmtCreate,
      "gmt_modified": gmtModified,
    };
  }

  @override
  String toString() {
    return '''
    Meal{ "meal_id": $mealId,"meal_name": $mealName,"food_id": $foodId,"serving_info_id": $servingInfoId,"intake": $intake,
      "description": $description,"contributor": $contributor,"gmt_create": $gmtCreate,"gmt_modified": $gmtModified }
    ''';
  }
}

class FoodDailyLog {
  int? foodDailyId; // 自增的，可以不传
  String date;
  String? breakfastMealId, lunchMealId, dinnerMealId, otherMealId;
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

  @override
  String toString() {
    return '''
    FoodDailyLog{  "food_daily_id": $foodDailyId,"date": $date,"breakfast_meal_id": $breakfastMealId,"lunch_meal_id": $lunchMealId,
      "dinner_meal_id": $dinnerMealId,"other_meal_id": $otherMealId,"contributor": $contributor,"gmt_create": $gmtCreate,"gmt_modified": $gmtModified, }
    ''';
  }
}

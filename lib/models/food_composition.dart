// json 文件转换时对应的类

// 食物营养素构成
class FoodComposition {
  String? foodCode;
  String? foodName;
  String? edible;
  String? water;
  String? energyKCal;
  String? energyKJ;
  String? protein;
  String? fat;
  String? cHO;
  String? dietaryFiber;
  String? cholesterol;
  String? ash;
  String? vitaminA;
  String? carotene;
  String? retinol;
  String? thiamin;
  String? riboflavin;
  String? niacin;
  String? vitaminC;
  String? vitaminETotal;
  String? vitaminE1;
  String? vitaminE2;
  String? vitaminE3;
  String? ca;
  String? p;
  String? k;
  String? na;
  String? mg;
  String? fe;
  String? zn;
  String? se;
  String? cu;
  String? mn;
  String? remark;
  // 上面是《中国食物成分表标准版第6版》书上的内容，下面这几个是内部数据库可以有的栏位
  List<String>? tags;
  List<String>? category;
  List<String>? photos;

  FoodComposition({
    this.foodCode,
    this.foodName,
    this.edible,
    this.water,
    this.energyKCal,
    this.energyKJ,
    this.protein,
    this.fat,
    this.cHO,
    this.dietaryFiber,
    this.cholesterol,
    this.ash,
    this.vitaminA,
    this.carotene,
    this.retinol,
    this.thiamin,
    this.riboflavin,
    this.niacin,
    this.vitaminC,
    this.vitaminETotal,
    this.vitaminE1,
    this.vitaminE2,
    this.vitaminE3,
    this.ca,
    this.p,
    this.k,
    this.na,
    this.mg,
    this.fe,
    this.zn,
    this.se,
    this.cu,
    this.mn,
    this.remark,
    this.photos,
    this.tags,
    this.category,
  });

  FoodComposition.fromJson(Map<String, dynamic> json) {
    foodCode = json['foodCode'];
    foodName = json['foodName'];
    edible = json['edible'];
    water = json['water'];
    energyKCal = json['energyKCal'];
    energyKJ = json['energyKJ'];
    protein = json['protein'];
    fat = json['fat'];
    cHO = json['CHO'];
    dietaryFiber = json['dietaryFiber'];
    cholesterol = json['cholesterol'];
    ash = json['ash'];
    vitaminA = json['vitaminA'];
    carotene = json['carotene'];
    retinol = json['retinol'];
    thiamin = json['thiamin'];
    riboflavin = json['riboflavin'];
    niacin = json['niacin'];
    vitaminC = json['vitaminC'];
    vitaminETotal = json['vitaminETotal'];
    vitaminE1 = json['vitaminE1'];
    vitaminE2 = json['vitaminE2'];
    vitaminE3 = json['vitaminE3'];
    ca = json['Ca'];
    p = json['P'];
    k = json['K'];
    na = json['Na'];
    mg = json['Mg'];
    fe = json['Fe'];
    zn = json['Zn'];
    se = json['Se'];
    cu = json['Cu'];
    mn = json['Mn'];
    remark = json['remark'];
    tags = json['tags']?.cast<String>();
    category = json['category']?.cast<String>();
    photos = json['photos']?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['foodCode'] = foodCode;
    data['foodName'] = foodName;
    data['edible'] = edible;
    data['water'] = water;
    data['energyKCal'] = energyKCal;
    data['energyKJ'] = energyKJ;
    data['protein'] = protein;
    data['fat'] = fat;
    data['CHO'] = cHO;
    data['dietaryFiber'] = dietaryFiber;
    data['cholesterol'] = cholesterol;
    data['ash'] = ash;
    data['vitaminA'] = vitaminA;
    data['carotene'] = carotene;
    data['retinol'] = retinol;
    data['thiamin'] = thiamin;
    data['riboflavin'] = riboflavin;
    data['niacin'] = niacin;
    data['vitaminC'] = vitaminC;
    data['vitaminETotal'] = vitaminETotal;
    data['vitaminE1'] = vitaminE1;
    data['vitaminE2'] = vitaminE2;
    data['vitaminE3'] = vitaminE3;
    data['Ca'] = ca;
    data['P'] = p;
    data['K'] = k;
    data['Na'] = na;
    data['Mg'] = mg;
    data['Fe'] = fe;
    data['Zn'] = zn;
    data['Se'] = se;
    data['Cu'] = cu;
    data['Mn'] = mn;
    data['remark'] = remark;
    data['tags'] = tags;
    data['category'] = category;
    data['photos'] = photos;

    return data;
  }
}

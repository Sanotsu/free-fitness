import 'package:flutter/material.dart';

import '../../../../models/dietary_state.dart';

class FoodDetail extends StatefulWidget {
  final FoodAndServingInfo foodItem;
  const FoodDetail({super.key, required this.foodItem});

  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Details - ${widget.foodItem.food.brand}'),
      ),
      body: Center(
        child: Text('Details of ${widget.foodItem.food.product}'),
      ),
    );
  }
}

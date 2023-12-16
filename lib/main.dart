import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'layout/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await GetStorage().write('language', 'en');
  runApp(const FreeFitnessApp());
}

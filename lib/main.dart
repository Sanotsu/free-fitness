import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'layout/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  // await GetStorage().write('language', 'en');
  // await GetStorage().write('language', 'cn');
  await GetStorage().write('language', 'system');
  // await GetStorage().write('mode', 'dark');
  // await GetStorage().write('mode', 'light');
  await GetStorage().write('mode', 'system');
  runApp(const FreeFitnessApp());
}

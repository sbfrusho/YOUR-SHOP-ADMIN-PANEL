import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/theme_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Get.putAsync(() => ThemeService().init(), permanent: true);
  await Get.putAsync(() => ConnectivityService().init(), permanent: true);

  runApp(const YourShopAdminApp());
}

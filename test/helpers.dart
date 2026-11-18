import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:your_shop_admin/app/routes/app_pages.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/core/services/auth_service.dart';
import 'package:your_shop_admin/core/services/session_service.dart';
import 'package:your_shop_admin/core/services/theme_service.dart';
import 'package:your_shop_admin/core/theme/app_theme.dart';
import 'package:your_shop_admin/data/repositories/auth_repository.dart';

/// Real services and repositories on Firebase fakes.
class TestBackend {
  TestBackend({bool signedIn = false, bool isAdmin = true})
    : auth = MockFirebaseAuth(
        signedIn: signedIn,
        mockUser: MockUser(uid: 'u1', email: 'admin@shop.test'),
      ) {
    db.collection('users').doc('u1').set({
      'uId': 'u1',
      'name': 'Rusho',
      'email': 'admin@shop.test',
      'isAdmin': isAdmin,
    });
  }

  final db = FakeFirebaseFirestore();
  final MockFirebaseAuth auth;

  Future<void> register() async {
    SharedPreferences.setMockInitialValues({});
    Get.put(await ThemeService().init(), permanent: true);
    Get.put(AuthRepository(auth: auth, firestore: db), permanent: true);
    final authService = Get.put(AuthService(auth: auth), permanent: true);
    Get.put(SessionService(authService, Get.find()), permanent: true);
  }
}

Widget testApp({String initialRoute = AppRoutes.splash}) => GetMaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  getPages: AppPages.routes,
  initialRoute: initialRoute,
);

/// Pumps frames without waiting for endless animations (spinners).
Future<void> settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Lets GetX snackbars finish so no timers are left pending.
Future<void> drainSnackbars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await settle(tester);
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/modules/auth/views/forgot_password_view.dart';

import '../helpers.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  tearDown(Get.reset);

  group('LoginView', () {
    testWidgets('validates before calling the server', (tester) async {
      final backend = TestBackend();
      await backend.register();
      await tester.pumpWidget(testApp(initialRoute: AppRoutes.login));
      await settle(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await settle(tester);

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(backend.auth.currentUser, isNull);
    });

    testWidgets('forgot password carries the typed email', (tester) async {
      await TestBackend().register();
      await tester.pumpWidget(testApp(initialRoute: AppRoutes.login));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'admin@shop.test',
      );
      await tester.tap(find.text('Forgot password?'));
      await settle(tester);

      expect(find.byType(ForgotPasswordView), findsOneWidget);
      expect(find.text('admin@shop.test'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
      await settle(tester);
      expect(find.text('Check your inbox'), findsOneWidget);
    });
  });

  group('ShellView', () {
    Future<void> openShell(WidgetTester tester) async {
      await TestBackend(signedIn: true).register();
      await tester.pumpWidget(testApp());
      await settle(tester);
    }

    testWidgets('phones use the bottom navigation bar', (tester) async {
      await _size(tester, const Size(400, 860));
      await openShell(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      await tester.tap(find.text('Orders'));
      await settle(tester);
      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('tablets and web use the side rail', (tester) async {
      await _size(tester, const Size(1280, 800));
      await openShell(tester);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.text('Products'));
      await settle(tester);
      expect(find.text('No products yet'), findsOneWidget);
    });
  });
}

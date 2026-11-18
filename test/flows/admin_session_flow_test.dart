import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/data/repositories/auth_repository.dart';
import 'package:your_shop_admin/modules/auth/views/login_view.dart';
import 'package:your_shop_admin/modules/shell/views/shell_view.dart';

import '../helpers.dart';

Future<void> _signIn(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'admin@shop.test',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'secret123',
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await settle(tester);
}

void main() {
  tearDown(Get.reset);

  testWidgets('admin signs in, opens settings and signs out', (tester) async {
    final backend = TestBackend();
    await backend.register();
    await tester.pumpWidget(testApp());
    await settle(tester);
    expect(find.byType(LoginView), findsOneWidget);

    await _signIn(tester);
    expect(Get.currentRoute, AppRoutes.shell);
    expect(find.byType(ShellView), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    expect(find.text('Rusho'), findsOneWidget);
    expect(find.text('admin@shop.test'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await settle(tester);

    expect(backend.auth.currentUser, isNull);
    expect(Get.currentRoute, AppRoutes.login);
  });

  testWidgets('customer account is refused', (tester) async {
    final backend = TestBackend(isAdmin: false);
    await backend.register();
    await tester.pumpWidget(testApp());
    await settle(tester);

    await _signIn(tester);

    expect(Get.currentRoute, AppRoutes.login);
    expect(backend.auth.currentUser, isNull);
    expect(find.text(AuthRepository.notAdminMessage), findsOneWidget);
    await drainSnackbars(tester);
  });

  testWidgets('remembered admin session opens the shell', (tester) async {
    final backend = TestBackend(signedIn: true);
    await backend.register();
    await tester.pumpWidget(testApp());
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.shell);
  });

  testWidgets('revoked admin is signed out live', (tester) async {
    final backend = TestBackend(signedIn: true);
    await backend.register();
    await tester.pumpWidget(testApp());
    await settle(tester);
    expect(Get.currentRoute, AppRoutes.shell);

    await backend.db.collection('users').doc('u1').update({'isAdmin': false});
    await settle(tester);

    expect(backend.auth.currentUser, isNull);
    expect(Get.currentRoute, AppRoutes.login);
    await drainSnackbars(tester);
  });

  testWidgets('guard sends a signed-out visitor to login', (tester) async {
    await TestBackend().register();
    await tester.pumpWidget(testApp(initialRoute: AppRoutes.shell));
    await settle(tester);
    expect(find.byType(LoginView), findsOneWidget);
  });
}

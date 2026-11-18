import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_pages.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/core/theme/app_theme.dart';
import 'package:your_shop_admin/modules/shell/view_models/shell_view_model.dart';

import '../fonts.dart';
import '../helpers.dart';

/// Tap targets, labels and text contrast on every main screen, light and
/// dark, on a phone (where targets matter most).
Future<void> _check(
  WidgetTester tester, {
  required String route,
  AdminSection? section,
  bool signedIn = true,
  bool dark = false,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final handle = tester.ensureSemantics();
  final b = TestBackend(signedIn: signedIn);
  await b.addCategory('shirts', 'Shirts');
  await b.addProduct('p1', 'Linen Overshirt', sale: '1890', isSale: true);
  await b.addProduct('p2', 'Everyday Cap', stock: '0');
  await b.addCustomer('c1', 'Nusrat Jahan', phone: '01712-345678');
  await b.addOrder(id: 'order1abc', createdAt: DateTime(2026, 11, 19, 9));
  await b.addBanner('b1', order: 0, createdAt: DateTime(2026, 11, 2));
  await b.register();
  mockPathProvider();
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      getPages: AppPages.routes,
      initialRoute: signedIn ? AppRoutes.splash : route,
    ),
  );
  await settle(tester);
  if (signedIn && route != AppRoutes.shell) Get.toNamed<void>(route);
  if (section != null) Get.find<ShellViewModel>().section.value = section;
  await settle(tester);

  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

void main() {
  setUpAll(loadAppFonts);
  tearDown(Get.reset);

  final screens = <String, (String, AdminSection?, bool)>{
    'login': (AppRoutes.login, null, false),
    'dashboard': (AppRoutes.shell, AdminSection.dashboard, true),
    'orders': (AppRoutes.shell, AdminSection.orders, true),
    'order detail': (AppRoutes.orderDetailFor('order1abc'), null, true),
    'products': (AppRoutes.shell, AdminSection.products, true),
    'product form': (AppRoutes.productEditFor('p1'), null, true),
    'catalogue': (AppRoutes.shell, AdminSection.catalogue, true),
    'category form': (AppRoutes.categoryEditFor('shirts'), null, true),
    'customers': (AppRoutes.shell, AdminSection.customers, true),
    'customer detail': (AppRoutes.customerDetailFor('c1'), null, true),
    'settings': (AppRoutes.settings, null, true),
  };
  for (final dark in [false, true]) {
    for (final MapEntry(key: name, value: (route, section, signedIn))
        in screens.entries) {
      testWidgets('$name${dark ? ' (dark)' : ''}', (tester) async {
        await _check(
          tester,
          route: route,
          section: section,
          signedIn: signedIn,
          dark: dark,
        );
      });
    }
  }
}

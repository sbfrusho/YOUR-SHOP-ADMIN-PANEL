// Renders key screens with fake data to PNGs for design review.
//
//   flutter test tool/screenshots_test.dart --update-goldens
//
// Output: tool/screenshots/*.png (not part of the normal test run).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_pages.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/core/theme/app_theme.dart';
import 'package:your_shop_admin/modules/shell/view_models/shell_view_model.dart';

import '../test/helpers.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  const dir = 'assets/fonts';
  await load('Manrope', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      '$dir/Manrope-$w.ttf',
  ]);
  await load('PlayfairDisplay', [
    '$dir/PlayfairDisplay-SemiBold.ttf',
    '$dir/PlayfairDisplay-Bold.ttf',
  ]);
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

/// Phone: 1080×2340 at 3x. Tablet / web: 2560×1600 at 2x.
const _phone = Size(1080, 2340);
const _wide = Size(2560, 1600);

Future<void> _shot(
  WidgetTester tester,
  String name, {
  required String route,
  Size size = _phone,
  bool signedIn = true,
  bool dark = false,
  AdminSection? section,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = size == _phone ? 3 : 2;
  addTearDown(tester.view.reset);
  Get.reset();
  await TestBackend(signedIn: signedIn).register();

  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
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
  await settle(tester, frames: 8);
  await expectLater(
    find.byType(GetMaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

void main() {
  setUpAll(_loadFonts);
  tearDown(Get.reset);

  testWidgets(
    'login',
    (t) => _shot(t, '01_login', route: AppRoutes.login, signedIn: false),
  );
  testWidgets(
    'login wide',
    (t) => _shot(
      t,
      '02_login_wide',
      route: AppRoutes.login,
      signedIn: false,
      size: _wide,
    ),
  );
  testWidgets('shell', (t) => _shot(t, '03_shell', route: AppRoutes.shell));
  testWidgets(
    'shell wide',
    (t) => _shot(
      t,
      '04_shell_wide',
      route: AppRoutes.shell,
      size: _wide,
      section: AdminSection.orders,
    ),
  );
  testWidgets(
    'settings',
    (t) => _shot(t, '05_settings', route: AppRoutes.settings),
  );
  testWidgets(
    'shell wide dark',
    (t) => _shot(
      t,
      '06_shell_wide_dark',
      route: AppRoutes.shell,
      size: _wide,
      dark: true,
    ),
  );
  testWidgets(
    'login dark',
    (t) => _shot(
      t,
      '07_login_dark',
      route: AppRoutes.login,
      signedIn: false,
      dark: true,
    ),
  );
}

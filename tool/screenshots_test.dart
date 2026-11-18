// Renders key screens with fake data to PNGs for design review.
//
//   flutter test tool/screenshots_test.dart --update-goldens
//
// Output: tool/screenshots/*.png (not part of the normal test run).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_pages.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/core/theme/app_theme.dart';
import 'package:your_shop_admin/modules/catalogue/view_models/catalogue_view_model.dart';
import 'package:your_shop_admin/modules/shell/view_models/shell_view_model.dart';

import '../test/fonts.dart';
import '../test/helpers.dart';

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
  bool seed = true,
  VoidCallback? prepare,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = size == _phone ? 3 : 2;
  addTearDown(tester.view.reset);
  // flutter_test paints shadows as solid outlines unless told otherwise.
  debugDisableShadows = false;
  Get.reset();
  final backend = TestBackend(signedIn: signedIn);
  if (seed) await _seed(backend);
  await backend.register();

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
  prepare?.call();
  await settle(tester, frames: 8);
  try {
    await expectLater(
      find.byType(GetMaterialApp),
      matchesGoldenFile('screenshots/$name.png'),
    );
  } finally {
    // Must be back on before the test ends (flutter_test checks it).
    debugDisableShadows = true;
  }
}

Future<void> _seed(TestBackend b) async {
  await b.addCategory('shirts', 'Shirts');
  await b.addCategory('caps', 'Caps');
  await b.addCategory('bags', 'Bags');
  await b.addCategory('panjabi', 'Panjabi');
  await b.addBanner('winter', order: 0, createdAt: DateTime(2026, 11, 2));
  await b.addBanner('eid', order: 1, createdAt: DateTime(2026, 11, 10));
  await b.addBanner('tote', order: 2, createdAt: DateTime(2026, 11, 17));
  await b.addProduct(
    'p1',
    'Linen Overshirt',
    sale: '1890',
    isSale: true,
    stock: '3',
    sizes: ['S', 'M', 'L', 'XL'],
  );
  await b.addProduct(
    'p2',
    'Everyday Cap',
    categoryId: 'caps',
    categoryName: 'Caps',
    full: '650',
    sale: '650',
    stock: '0',
    sizes: [],
  );
  await b.addProduct(
    'p3',
    'Heavyweight Tee',
    full: '790',
    sale: '790',
    stock: '40',
  );
  await b.addProduct(
    'p4',
    'Canvas Tote',
    categoryId: 'bags',
    categoryName: 'Bags',
    full: '590',
    sale: '390',
    isSale: true,
    stock: '18',
    sizes: [],
  );
  await b.addOrder(
    id: 'k3f9q2ma71',
    name: 'Nusrat Jahan',
    createdAt: DateTime(2026, 11, 19, 9, 42),
  );
  await b.addOrder(
    id: 'p8d2x1lw09',
    name: 'Rahim Uddin',
    phone: '01819-552310',
    status: 'Confirmed',
    paymentStatus: 'paid',
    total: 1290,
    createdAt: DateTime(2026, 11, 19, 8, 15),
  );
  await b.addOrder(
    id: 'z7c4m0ry55',
    name: 'Farhana Akter',
    phone: '01911-208877',
    status: 'Shipped',
    total: 4380,
    createdAt: DateTime(2026, 11, 18, 17, 3),
  );
  await b.addOrder(
    id: 'h2n6v8te33',
    name: 'Tanvir Hasan',
    phone: '01552-731004',
    status: 'Delivered',
    paymentStatus: 'paid',
    total: 790,
    createdAt: DateTime(2026, 11, 16, 12, 30),
  );
  await b.addOrder(
    id: 'q1w5e9ui27',
    customerDeleted: true,
    status: 'Cancelled',
    paymentStatus: 'void',
    total: 650,
    createdAt: DateTime(2026, 11, 15, 19, 48),
  );
  await b.addCustomer(
    'c1',
    'Nusrat Jahan',
    phone: '01712-345678',
    addresses: [
      {
        'label': 'Home',
        'fullName': 'Nusrat Jahan',
        'phone': '01712-345678',
        'address': 'House 12, Road 5',
        'city': 'Dhanmondi, Dhaka',
        'postalCode': '1205',
        'country': 'Bangladesh',
        'isDefault': true,
      },
      {
        'label': 'Office',
        'fullName': 'Nusrat Jahan',
        'phone': '01712-345678',
        'address': 'Level 7, Gulshan Avenue',
        'city': 'Dhaka',
        'postalCode': '1212',
        'country': 'Bangladesh',
      },
    ],
  );
  await b.addCustomer('c2', 'Rahim Uddin', phone: '01819-552310');
  await b.addCustomer('c3', 'Farhana Akter', phone: '01911-208877');
  await b.addCustomer('c4', 'Tanvir Hasan', phone: '01552-731004');
  await b.addCustomer('c5', 'Sadia Islam', disabled: true);
  await b.addCustomer('c6', 'Mehedi Hasan', email: 'mehedi.h@mail.test');
  // Older delivered orders so the dashboard chart has a shape.
  const history = [
    (6, 1890.0),
    (7, 3240.0),
    (8, 650.0),
    (9, 2780.0),
    (10, 4120.0),
    (11, 1590.0),
    (12, 2240.0),
    (13, 3880.0),
    (14, 1290.0),
    (17, 2960.0),
  ];
  for (final (day, total) in history) {
    await b.addOrder(
      id: 'hist$day',
      name: 'Sadia Islam',
      status: 'Delivered',
      paymentStatus: 'paid',
      total: total,
      createdAt: DateTime(2026, 11, day, 15),
    );
  }
  await b.db.doc('orders/z7c4m0ry55').update({
    'statusHistory': {
      'Pending': DateTime(2026, 11, 18, 17, 3),
      'Confirmed': DateTime(2026, 11, 18, 18, 20),
      'Shipped': DateTime(2026, 11, 19, 10, 5),
    },
  });
}

void main() {
  setUpAll(() async {
    mockPathProvider();
    await loadAppFonts();
  });
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
  testWidgets(
    'orders',
    (t) => _shot(
      t,
      '08_orders',
      route: AppRoutes.shell,
      section: AdminSection.orders,
    ),
  );
  testWidgets(
    'orders wide',
    (t) => _shot(
      t,
      '09_orders_wide',
      route: AppRoutes.shell,
      size: _wide,
      section: AdminSection.orders,
    ),
  );
  testWidgets(
    'order detail',
    (t) => _shot(
      t,
      '10_order_detail',
      route: AppRoutes.orderDetailFor('z7c4m0ry55'),
    ),
  );
  testWidgets(
    'order detail wide',
    (t) => _shot(
      t,
      '11_order_detail_wide',
      route: AppRoutes.orderDetailFor('z7c4m0ry55'),
      size: _wide,
    ),
  );
  testWidgets(
    'orders wide dark',
    (t) => _shot(
      t,
      '12_orders_wide_dark',
      route: AppRoutes.shell,
      size: _wide,
      dark: true,
      section: AdminSection.orders,
    ),
  );
  testWidgets(
    'products',
    (t) => _shot(
      t,
      '13_products',
      route: AppRoutes.shell,
      section: AdminSection.products,
    ),
  );
  testWidgets(
    'products wide',
    (t) => _shot(
      t,
      '14_products_wide',
      route: AppRoutes.shell,
      size: _wide,
      section: AdminSection.products,
    ),
  );
  testWidgets(
    'product form',
    (t) => _shot(t, '15_product_form', route: AppRoutes.productEditFor('p1')),
  );
  testWidgets(
    'product form wide',
    (t) => _shot(
      t,
      '16_product_form_wide',
      route: AppRoutes.productEditFor('p1'),
      size: _wide,
    ),
  );
  testWidgets(
    'catalogue',
    (t) => _shot(
      t,
      '17_catalogue',
      route: AppRoutes.shell,
      section: AdminSection.catalogue,
    ),
  );
  testWidgets(
    'catalogue wide',
    (t) => _shot(
      t,
      '18_catalogue_wide',
      route: AppRoutes.shell,
      size: _wide,
      section: AdminSection.catalogue,
    ),
  );
  testWidgets(
    'banners',
    (t) => _shot(
      t,
      '19_banners',
      route: AppRoutes.shell,
      section: AdminSection.catalogue,
      prepare: () =>
          Get.find<CatalogueViewModel>().tab.value = CatalogueTab.banners,
    ),
  );
  testWidgets(
    'banners wide dark',
    (t) => _shot(
      t,
      '20_banners_wide_dark',
      route: AppRoutes.shell,
      size: _wide,
      dark: true,
      section: AdminSection.catalogue,
      prepare: () =>
          Get.find<CatalogueViewModel>().tab.value = CatalogueTab.banners,
    ),
  );
  testWidgets(
    'category form',
    (t) => _shot(
      t,
      '21_category_form',
      route: AppRoutes.categoryEditFor('shirts'),
    ),
  );
  testWidgets(
    'dashboard',
    (t) => _shot(t, '22_dashboard', route: AppRoutes.shell),
  );
  testWidgets(
    'dashboard wide',
    (t) => _shot(t, '23_dashboard_wide', route: AppRoutes.shell, size: _wide),
  );
  testWidgets(
    'customers',
    (t) => _shot(
      t,
      '24_customers',
      route: AppRoutes.shell,
      section: AdminSection.customers,
    ),
  );
  testWidgets(
    'customers wide',
    (t) => _shot(
      t,
      '25_customers_wide',
      route: AppRoutes.shell,
      size: _wide,
      section: AdminSection.customers,
    ),
  );
  testWidgets(
    'customer detail wide',
    (t) => _shot(
      t,
      '26_customer_detail_wide',
      route: AppRoutes.customerDetailFor('c1'),
      size: _wide,
    ),
  );
  testWidgets(
    'customer detail',
    (t) => _shot(
      t,
      '27_customer_detail',
      route: AppRoutes.customerDetailFor('c1'),
    ),
  );
}

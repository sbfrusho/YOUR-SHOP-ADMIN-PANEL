import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/modules/dashboard/view_models/dashboard_view_model.dart';
import 'package:your_shop_admin/modules/orders/views/order_detail_view.dart';
import 'package:your_shop_admin/modules/products/views/product_form_view.dart';
import 'package:your_shop_admin/modules/shell/view_models/shell_view_model.dart';

import '../helpers.dart';

/// One working day across every area, on real view models and repositories
/// over Firebase fakes: sign in, confirm an order from the dashboard,
/// restock a product, disable a customer, sign out.
void main() {
  tearDown(Get.reset);

  testWidgets('a day at the shop', (tester) async {
    tester.view
      ..physicalSize = const Size(1400, 1100)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final b = TestBackend();
    await b.addCategory('shirts', 'Shirts');
    await b.addProduct('p1', 'Linen Overshirt', stock: '2');
    await b.addCustomer('c1', 'Nusrat Jahan', phone: '01712-345678');
    await b.addOrder(id: 'order1abc', createdAt: DateTime(2026, 11, 19, 9));
    await b.register();
    mockPathProvider();
    await tester.pumpWidget(testApp());
    await settle(tester);

    // Sign in.
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
    expect(Get.currentRoute, AppRoutes.shell);
    final dashboard = Get.find<DashboardViewModel>();
    expect(dashboard.stats.value!.toConfirm, 1);
    expect(dashboard.stats.value!.lowStock.single.id, 'p1');

    // Dashboard → pending orders → confirm the order.
    await tester.tap(find.text('To confirm'));
    await settle(tester);
    await tester.tap(find.text('Nusrat Jahan'));
    await settle(tester);
    expect(find.byType(OrderDetailView), findsOneWidget);
    await tester.tap(find.text('Mark as Confirmed'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Mark as Confirmed'));
    await settle(tester);
    expect((await b.db.doc('orders/order1abc').get())['status'], 'Confirmed');
    await drainSnackbars(tester);
    Get.back<void>();
    await settle(tester);

    final shell = Get.find<ShellViewModel>()
      ..section.value = AdminSection.dashboard;
    await settle(tester);
    expect(dashboard.stats.value!.toConfirm, 0);
    expect(dashboard.stats.value!.toShip, 1);

    // Low stock → restock the overshirt.
    await tester.tap(find.text('Linen Overshirt').last);
    await settle(tester);
    expect(find.byType(ProductFormView), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'In stock'),
      '25',
    );
    await tester.tap(find.text('Save changes'));
    await settle(tester);
    expect((await b.db.doc('products/p1').get())['quantity'], '25');
    expect(find.byType(ProductFormView), findsNothing);
    await drainSnackbars(tester);
    expect(dashboard.stats.value!.lowStock, isEmpty);

    // Customers → disable an account.
    shell.section.value = AdminSection.customers;
    await settle(tester);
    await tester.tap(find.text('Nusrat Jahan'));
    await settle(tester);
    await tester.tap(find.text('Disable account'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Disable'));
    await settle(tester);
    expect((await b.db.doc('users/c1').get())['disabled'], isTrue);
    await drainSnackbars(tester);
    Get.back<void>();
    await settle(tester);

    // Sign out from settings.
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await settle(tester);
    expect(b.auth.currentUser, isNull);
    expect(Get.currentRoute, AppRoutes.login);
  });
}

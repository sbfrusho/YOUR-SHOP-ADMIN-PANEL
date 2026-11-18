import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/modules/orders/views/order_detail_view.dart';
import 'package:your_shop_admin/modules/shell/view_models/shell_view_model.dart';

import '../helpers.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<TestBackend> _openOrders(WidgetTester tester) async {
  final backend = TestBackend(signedIn: true);
  await backend.addOrder(id: 'pending1', name: 'Nusrat Jahan');
  await backend.addOrder(
    id: 'shipped1',
    name: 'Rahim Uddin',
    status: 'Shipped',
    paymentStatus: 'paid',
    createdAt: DateTime(2026, 11, 17),
  );
  await backend.register();
  await tester.pumpWidget(testApp());
  await settle(tester);
  Get.find<ShellViewModel>().section.value = AdminSection.orders;
  await settle(tester);
  return backend;
}

Future<void> _openDetail(WidgetTester tester, String id) async {
  Get.toNamed<void>(AppRoutes.orderDetailFor(id));
  await settle(tester);
}

void main() {
  tearDown(Get.reset);

  testWidgets('phone list filters by status and search', (tester) async {
    await _size(tester, const Size(400, 900));
    await _openOrders(tester);

    expect(find.text('Nusrat Jahan'), findsOneWidget);
    expect(find.text('Rahim Uddin'), findsOneWidget);

    await tester.ensureVisible(find.text('Shipped (1)'));
    await tester.tap(find.text('Shipped (1)'));
    await settle(tester);
    expect(find.text('Nusrat Jahan'), findsNothing);
    expect(find.text('Rahim Uddin'), findsOneWidget);

    await tester.ensureVisible(find.text('All (2)'));
    await tester.tap(find.text('All (2)'));
    await tester.enterText(find.byType(TextField), '01712');
    await settle(tester, frames: 5);
    expect(find.text('Rahim Uddin'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nobody');
    await settle(tester, frames: 5);
    expect(find.text('No matching orders'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await settle(tester);
    expect(find.text('Nusrat Jahan'), findsOneWidget);
  });

  testWidgets('wide screens show a data table', (tester) async {
    await _size(tester, const Size(1400, 900));
    await _openOrders(tester);

    expect(find.byType(DataTable), findsOneWidget);
    await tester.tap(find.text('#PENDIN'));
    await settle(tester);
    expect(find.byType(OrderDetailView), findsOneWidget);
    expect(find.text('Linen Overshirt'), findsOneWidget);
  });

  testWidgets('advance asks first, then writes the next status', (
    tester,
  ) async {
    await _size(tester, const Size(400, 1400));
    final backend = await _openOrders(tester);
    await _openDetail(tester, 'pending1');

    await tester.tap(find.widgetWithText(FilledButton, 'Mark as Confirmed'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await settle(tester);
    var doc = await backend.db.doc('orders/pending1').get();
    expect(doc['status'], 'Pending');

    await tester.tap(find.widgetWithText(FilledButton, 'Mark as Confirmed'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Mark as Confirmed'));
    await settle(tester);

    doc = await backend.db.doc('orders/pending1').get();
    expect(doc['status'], 'Confirmed');
    expect(
      find.widgetWithText(FilledButton, 'Mark as Shipped'),
      findsOneWidget,
    );
    await drainSnackbars(tester);
  });

  testWidgets('cancel goes through the server after confirmation', (
    tester,
  ) async {
    await _size(tester, const Size(400, 1400));
    final backend = await _openOrders(tester);
    await _openDetail(tester, 'shipped1');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel order'));
    await settle(tester);
    expect(find.text('Cancel this order?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel order'));
    await settle(tester);

    expect(backend.calls, hasLength(1));
    expect(find.text('By admin'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel order'), findsNothing);
    await drainSnackbars(tester);
  });

  testWidgets('deleted customers show no personal details', (tester) async {
    await _size(tester, const Size(400, 1400));
    final backend = TestBackend(signedIn: true);
    await backend.addOrder(id: 'gone1', customerDeleted: true);
    await backend.register();
    await tester.pumpWidget(testApp());
    await settle(tester);
    await _openDetail(tester, 'gone1');

    expect(find.textContaining('deleted their account'), findsOneWidget);
    expect(find.text('Address'), findsNothing);
  });

  testWidgets('unknown order IDs show not found', (tester) async {
    await TestBackend(signedIn: true).register();
    await tester.pumpWidget(testApp());
    await settle(tester);
    await _openDetail(tester, 'missing');
    expect(find.text('Order not found'), findsOneWidget);
  });
}

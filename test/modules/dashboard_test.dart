import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/data/models/order_model.dart';
import 'package:your_shop_admin/modules/orders/view_models/orders_view_model.dart';
import 'package:your_shop_admin/modules/products/view_models/products_view_model.dart';
import 'package:your_shop_admin/modules/shell/view_models/shell_view_model.dart';

import '../helpers.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// "Now" is 19 Nov 2026, 14:00 (see [TestBackend.clock]).
Future<TestBackend> _start(WidgetTester tester, {bool seed = true}) async {
  final b = TestBackend(signedIn: true);
  if (seed) {
    await b.addProduct('p1', 'Linen Overshirt', stock: '3');
    await b.addProduct('p2', 'Everyday Cap', stock: '0');
    await b.addProduct('p3', 'Heavyweight Tee', stock: '40');
    // Today: one cash order (counts), one cancelled (doesn't).
    await b.addOrder(id: 'today1', createdAt: DateTime(2026, 11, 19, 9));
    await b.addOrder(
      id: 'today2',
      status: 'Cancelled',
      paymentStatus: 'void',
      createdAt: DateTime(2026, 11, 19, 10),
    );
    // Yesterday, confirmed and paid.
    await b.addOrder(
      id: 'yday',
      status: 'Confirmed',
      paymentStatus: 'paid',
      total: 1290,
      createdAt: DateTime(2026, 11, 18, 16),
      items: const [
        {
          'product_id': 'p1',
          'product_name': 'Linen Overshirt',
          'price': '1290',
          'quantity': 1,
        },
      ],
    );
  }
  await b.register();
  mockPathProvider();
  await tester.pumpWidget(testApp());
  await settle(tester);
  return b;
}

void main() {
  tearDown(Get.reset);

  testWidgets('opens on the dashboard with live figures', (tester) async {
    await _size(tester, const Size(1400, 1100));
    await _start(tester);

    expect(Get.find<ShellViewModel>().section.value, AdminSection.dashboard);
    expect(find.text('Good afternoon, Rusho'), findsOneWidget);
    // Today's revenue (one Tk 2,540 cash order) and yesterday's.
    expect(find.text('Tk 2,540'), findsWidgets);
    expect(find.text('Yesterday Tk 1,290'), findsOneWidget);
    expect(find.text('Last 14 days: Tk 3,830'), findsOneWidget);

    // Best sellers: the overshirt sold twice (today and yesterday).
    expect(find.text('2 sold'), findsOneWidget);
    expect(find.text('Everyday Cap'), findsWidgets);
    // Low stock lists the cap (out) before the overshirt (3 left).
    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.text('3 in stock'), findsOneWidget);
    expect(find.text('1 product is out of stock'), findsOneWidget);
  });

  testWidgets('shortcuts open filtered orders and products', (tester) async {
    await _size(tester, const Size(1400, 1100));
    await _start(tester);

    await tester.tap(find.text('To confirm'));
    await settle(tester);
    final shell = Get.find<ShellViewModel>();
    expect(shell.section.value, AdminSection.orders);
    expect(
      Get.find<OrdersViewModel>().filter.value.status,
      OrderStatus.pending,
    );

    shell.section.value = AdminSection.dashboard;
    await settle(tester);
    await tester.tap(find.text('To ship'));
    await settle(tester);
    expect(
      Get.find<OrdersViewModel>().filter.value.status,
      OrderStatus.confirmed,
    );

    shell.section.value = AdminSection.dashboard;
    await settle(tester);
    await tester.tap(find.text('See all'));
    await settle(tester);
    expect(shell.section.value, AdminSection.products);
    expect(Get.find<ProductsViewModel>().stock.value, StockFilter.low);
  });

  testWidgets('empty shop on a phone: no overflow, friendly empties', (
    tester,
  ) async {
    await _size(tester, const Size(360, 1800));
    await _start(tester, seed: false);

    expect(find.text('No sales yet'), findsOneWidget);
    expect(find.text('No sales in the last 30 days yet.'), findsOneWidget);
    expect(find.text('Everything is well stocked.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new order shows up live', (tester) async {
    await _size(tester, const Size(1400, 1100));
    final b = await _start(tester, seed: false);
    expect(find.text('Tk 0'), findsWidgets);

    await b.addOrder(
      id: 'live',
      total: 990,
      createdAt: DateTime(2026, 11, 19, 13),
    );
    await settle(tester);
    expect(find.text('Tk 990'), findsWidgets);
  });
}

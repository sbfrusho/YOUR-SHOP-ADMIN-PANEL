import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/data/models/user_model.dart';
import 'package:your_shop_admin/modules/customers/views/customer_detail_view.dart';
import 'package:your_shop_admin/modules/orders/views/order_detail_view.dart';
import 'package:your_shop_admin/modules/shell/view_models/shell_view_model.dart';

import '../helpers.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<TestBackend> _start(WidgetTester tester, {bool seed = true}) async {
  final b = TestBackend(signedIn: true);
  if (seed) {
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
          'city': 'Dhaka',
          'postalCode': '1205',
          'country': 'Bangladesh',
          'isDefault': true,
        },
      ],
    );
    await b.addCustomer('c2', 'Rahim Uddin', phone: '01819-552310');
    await b.addCustomer('c3', 'Farhana Akter', disabled: true);
    await b.addOrder(id: 'o1abc', total: 2540);
    await b.addOrder(
      id: 'o2def',
      status: 'Delivered',
      paymentStatus: 'paid',
      total: 1290,
      createdAt: DateTime(2026, 11, 10),
    );
    await b.addOrder(
      id: 'o3ghi',
      status: 'Cancelled',
      paymentStatus: 'void',
      total: 990,
      createdAt: DateTime(2026, 11, 5),
    );
    await b.addOrder(id: 'other', customerId: 'c2', total: 650);
  }
  await b.register();
  mockPathProvider();
  await tester.pumpWidget(testApp());
  await settle(tester);
  Get.find<ShellViewModel>().section.value = AdminSection.customers;
  await settle(tester);
  return b;
}

void main() {
  tearDown(Get.reset);

  test('initials and search', () {
    const u = UserModel(
      uid: 'c1',
      email: 'nusrat@mail.test',
      name: 'Nusrat Jahan',
      phone: '01712-345678',
    );
    expect(u.initials, 'NJ');
    expect(const UserModel(uid: 'x', email: 'tanvir@x.com').initials, 'TX');
    expect(u.matchesQuery('nusrat'), isTrue);
    expect(u.matchesQuery('345 678'), isTrue);
    expect(u.matchesQuery('rahim'), isFalse);
  });

  testWidgets('list leaves out admins; search and disabled filter', (
    tester,
  ) async {
    await _size(tester, const Size(400, 900));
    await _start(tester);

    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Rusho'), findsNothing); // the signed-in admin
    expect(find.text('Nusrat Jahan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '01819');
    await settle(tester);
    expect(find.text('Rahim Uddin'), findsOneWidget);
    expect(find.text('Nusrat Jahan'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Disabled (1)'));
    await settle(tester);
    expect(find.text('Farhana Akter'), findsOneWidget);
    expect(find.text('Rahim Uddin'), findsNothing);
  });

  testWidgets('wide screens use a table', (tester) async {
    await _size(tester, const Size(1400, 900));
    await _start(tester);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Active'), findsNWidgets(2));
  });

  testWidgets('detail: profile, address, history and totals', (tester) async {
    await _size(tester, const Size(1400, 1000));
    await _start(tester);
    await tester.tap(find.text('Nusrat Jahan'));
    await settle(tester);

    expect(find.byType(CustomerDetailView), findsOneWidget);
    expect(find.text('nusrat@mail.test'), findsOneWidget);
    expect(find.textContaining('House 12, Road 5, Dhaka'), findsOneWidget);
    // Three orders; cancelled ones don't count towards spent.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Tk 3,830'), findsOneWidget);
    expect(find.text('#O1ABC'), findsOneWidget);
    expect(find.text('#OTHER'), findsNothing);

    await tester.tap(find.text('#O1ABC'));
    await settle(tester);
    expect(find.byType(OrderDetailView), findsOneWidget);
  });

  testWidgets('disable asks first, then calls the server', (tester) async {
    await _size(tester, const Size(1400, 1000));
    final b = await _start(tester);
    Get.toNamed<void>(AppRoutes.customerDetailFor('c1'));
    await settle(tester);

    await tester.tap(find.text('Disable account'));
    await settle(tester);
    expect(find.text('Disable Nusrat Jahan?'), findsOneWidget);
    expect(find.textContaining('Their open order stays open'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Disable'));
    await settle(tester);

    expect(b.calls.single.url.path, '/adminSetCustomerDisabled');
    expect((await b.db.doc('users/c1').get())['disabled'], isTrue);
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.text('Enable account'), findsOneWidget);
    await drainSnackbars(tester);

    await tester.tap(find.text('Enable account'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Enable'));
    await settle(tester);
    expect((await b.db.doc('users/c1').get())['disabled'], isFalse);
    await drainSnackbars(tester);
  });

  testWidgets('deleted customers and admins show not found', (tester) async {
    await _start(tester);
    Get.toNamed<void>(AppRoutes.customerDetailFor('gone'));
    await settle(tester);
    expect(find.text('Customer not found'), findsOneWidget);

    Get.back<void>();
    await settle(tester);
    Get.toNamed<void>(AppRoutes.customerDetailFor('u1')); // the admin
    await settle(tester);
    expect(find.text('Customer not found'), findsOneWidget);
  });

  testWidgets('empty shop', (tester) async {
    await _size(tester, const Size(400, 900));
    await _start(tester, seed: false);
    expect(find.text('No customers yet'), findsOneWidget);
  });
}

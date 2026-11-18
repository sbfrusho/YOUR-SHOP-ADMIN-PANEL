import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/modules/products/views/product_form_view.dart';
import 'package:your_shop_admin/modules/shell/view_models/shell_view_model.dart';

import '../helpers.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<TestBackend> _start(WidgetTester tester, {bool products = true}) async {
  final b = TestBackend(signedIn: true);
  await b.addCategory('shirts', 'Shirts');
  await b.addCategory('caps', 'Caps');
  if (products) {
    await b.addProduct(
      'p1',
      'Linen Overshirt',
      sale: '1890',
      isSale: true,
      stock: '3',
    );
    await b.addProduct('p2', 'Everyday Cap', categoryId: 'caps', stock: '0');
    await b.addProduct('p3', 'Old Tote', archived: true);
  }
  await b.register();
  await tester.pumpWidget(testApp());
  await settle(tester);
  Get.find<ShellViewModel>().section.value = AdminSection.products;
  await settle(tester);
  return b;
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  tearDown(Get.reset);

  testWidgets('list hides archived products and filters by stock', (
    tester,
  ) async {
    await _size(tester, const Size(400, 900));
    await _start(tester);

    expect(find.text('Linen Overshirt'), findsOneWidget);
    expect(find.text('Everyday Cap'), findsOneWidget);
    expect(find.text('Old Tote'), findsNothing);
    expect(find.text('3 in stock'), findsOneWidget);
    expect(find.text('-24%'), findsOneWidget);

    await tester.ensureVisible(find.text('Out of stock (1)'));
    await tester.tap(find.text('Out of stock (1)'));
    await settle(tester);
    expect(find.text('Linen Overshirt'), findsNothing);

    await tester.ensureVisible(find.text('Archived (1)'));
    await tester.tap(find.text('Archived (1)'));
    await settle(tester);
    expect(find.text('Old Tote'), findsOneWidget);
  });

  testWidgets('archive asks first', (tester) async {
    await _size(tester, const Size(1400, 900));
    final b = await _start(tester);
    expect(find.byType(DataTable), findsOneWidget);

    await tester.tap(find.byTooltip('More').first);
    await settle(tester);
    await tester.tap(find.text('Archive').last);
    await settle(tester);
    expect(find.textContaining('disappears from the shop'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Archive'));
    await settle(tester);

    final doc = await b.db.doc('products/p2').get();
    expect(doc['isArchived'], isTrue);
    await drainSnackbars(tester);
  });

  testWidgets('new product: validates, uploads, writes legacy formats', (
    tester,
  ) async {
    await _size(tester, const Size(1400, 1600));
    final b = await _start(tester, products: false);
    Get.toNamed<void>(AppRoutes.productNew);
    await settle(tester);
    expect(find.byType(ProductFormView), findsOneWidget);

    await tester.tap(find.text('Add product').last);
    await settle(tester);
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Add at least one image.'), findsOneWidget);

    await tester.enterText(_field('Name'), 'Linen Overshirt');
    await tester.enterText(_field('Full price'), '2490');
    await tester.enterText(_field('In stock'), '12');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await settle(tester);
    await tester.tap(find.text('Shirts').last);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'M'));
    await tester.tap(find.widgetWithText(FilterChip, 'L'));
    await tester.tap(find.text('Add'));
    await settle(tester);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('Tk 2,241'), findsOneWidget);

    await tester.tap(find.text('Add product').last);
    await settle(tester);

    final docs = (await b.db.collection('products').get()).docs;
    expect(docs, hasLength(1));
    final p = docs.single.data();
    expect(p['productName'], 'Linen Overshirt');
    expect(p['categoryName'], 'Shirts');
    expect(p['fullPrice'], '2490');
    expect(p['salePrice'], '2241');
    expect(p['salePercent'], 10);
    expect(p['isSale'], isTrue);
    expect(p['quantity'], '12');
    expect(p['productSizes'], ['M', 'L']);
    expect(p['email'], 'admin@shop.test');
    expect(p['productImages'], hasLength(1));
    expect(b.images.uploads.single, startsWith('products/${docs.single.id}/'));
    expect(find.byType(ProductFormView), findsNothing);
    await drainSnackbars(tester);
  });

  testWidgets('edit loads the product and keeps its seller', (tester) async {
    await _size(tester, const Size(400, 2400));
    final b = await _start(tester);
    Get.toNamed<void>(AppRoutes.productEditFor('p1'));
    await settle(tester);

    expect(find.text('Linen Overshirt'), findsOneWidget);
    expect(find.text('24%'), findsOneWidget);
    expect(find.text('Cover'), findsOneWidget);

    await tester.enterText(_field('In stock'), '20');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await settle(tester);

    final p = (await b.db.doc('products/p1').get()).data()!;
    expect(p['quantity'], '20');
    expect(p['salePrice'], '1890');
    expect(p['email'], 'seller@shop.test');
    expect(b.images.uploads, isEmpty);
    await drainSnackbars(tester);
  });
}

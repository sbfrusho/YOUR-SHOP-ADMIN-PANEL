import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_shop_admin/app/routes/app_routes.dart';
import 'package:your_shop_admin/modules/catalogue/views/category_form_view.dart';
import 'package:your_shop_admin/modules/shell/view_models/shell_view_model.dart';

import '../helpers.dart';

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<TestBackend> _start(
  WidgetTester tester, {
  Future<void> Function(TestBackend b)? seed,
}) async {
  final b = TestBackend(signedIn: true);
  await b.addCategory('shirts', 'Shirts');
  await b.addCategory('caps', 'Caps');
  await b.addProduct('p1', 'Linen Overshirt');
  await b.addProduct('p2', 'Old Shirt', archived: true);
  await seed?.call(b);
  await b.register();
  mockPathProvider();
  await tester.pumpWidget(testApp());
  await settle(tester);
  Get.find<ShellViewModel>().section.value = AdminSection.catalogue;
  await settle(tester);
  return b;
}

Future<void> _menu(WidgetTester tester, int index, String item) async {
  await tester.tap(find.byTooltip('More').at(index));
  await settle(tester);
  await tester.tap(find.text(item).last);
  await settle(tester);
}

Future<void> _openBanners(WidgetTester tester) async {
  await tester.tap(find.textContaining('Banners ('));
  await settle(tester);
}

Finder _name() => find.widgetWithText(TextFormField, 'Name');

void main() {
  tearDown(Get.reset);

  group('Categories', () {
    testWidgets('list shows product counts, archived included', (tester) async {
      await _size(tester, const Size(400, 900));
      await _start(tester);

      expect(find.text('Categories (2)'), findsOneWidget);
      expect(find.text('2 products'), findsOneWidget); // Shirts
      expect(find.text('0 products'), findsOneWidget); // Caps

      await tester.enterText(find.byType(TextField), 'cap');
      await settle(tester);
      expect(find.text('Shirts'), findsNothing);
      expect(find.text('Caps'), findsOneWidget);
    });

    testWidgets('a category with products is not deleted', (tester) async {
      await _size(tester, const Size(1400, 900));
      final b = await _start(tester);

      // Sorted by name: Caps, then Shirts.
      await _menu(tester, 1, 'Delete');
      expect(find.text('Can\'t delete "Shirts"'), findsOneWidget);
      expect(find.textContaining('2 products still use'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect((await b.db.doc('categories/shirts').get()).exists, isTrue);
    });

    testWidgets('an empty category is deleted after confirming', (
      tester,
    ) async {
      await _size(tester, const Size(1400, 900));
      final b = await _start(tester);

      await _menu(tester, 0, 'Delete');
      expect(find.text('Delete "Caps"?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await settle(tester);
      expect((await b.db.doc('categories/caps').get()).exists, isFalse);
      expect(find.text('Categories (1)'), findsOneWidget);
      await drainSnackbars(tester);
    });

    testWidgets('new category: needs an image and a unique name', (
      tester,
    ) async {
      await _size(tester, const Size(400, 900));
      final b = await _start(tester);
      await tester.tap(find.text('Add category'));
      await settle(tester);
      expect(find.byType(CategoryFormView), findsOneWidget);

      await tester.tap(find.text('Add category'));
      await settle(tester);
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Add an image.'), findsOneWidget);

      await tester.enterText(_name(), 'shirts');
      await tester.tap(find.text('Choose image').last);
      await settle(tester);
      await tester.tap(find.text('Add category'));
      await settle(tester);
      expect(
        find.text('A category with this name already exists.'),
        findsOneWidget,
      );

      await tester.enterText(_name(), 'Bags');
      await tester.tap(find.text('Add category'));
      await settle(tester);

      final bags = (await b.db.collection('categories').get()).docs
          .where((d) => d['categoryName'] == 'Bags')
          .single;
      expect(bags['categoryId'], bags.id);
      expect(bags['categoryImg'], startsWith('https://img.test/categories/'));
      expect(b.images.uploads.single, startsWith('categories/${bags.id}/'));
      expect(find.byType(CategoryFormView), findsNothing);
      await drainSnackbars(tester);
    });

    testWidgets('rename keeps the image and updates its products', (
      tester,
    ) async {
      await _size(tester, const Size(400, 900));
      final b = await _start(tester);
      Get.toNamed<void>(AppRoutes.categoryEditFor('shirts'));
      await settle(tester);

      expect(find.text('Shirts'), findsOneWidget);
      expect(find.text('Change image'), findsOneWidget);
      expect(find.textContaining('2 products are in this'), findsOneWidget);

      await tester.enterText(_name(), 'Shirts & Tops');
      await tester.tap(find.text('Save changes'));
      await settle(tester);

      final cat = await b.db.doc('categories/shirts').get();
      expect(cat['categoryName'], 'Shirts & Tops');
      expect(cat['categoryImg'], 'https://img.test/categories/shirts.jpg');
      expect(b.images.uploads, isEmpty);
      final p = await b.db.doc('products/p1').get();
      expect(p['categoryName'], 'Shirts & Tops');
      await drainSnackbars(tester);
    });

    testWidgets('unknown category shows not found', (tester) async {
      await _start(tester);
      Get.toNamed<void>(AppRoutes.categoryEditFor('nope'));
      await settle(tester);
      expect(find.text('Category not found'), findsOneWidget);
    });
  });

  group('Banners', () {
    testWidgets('empty state, then added banners appear', (tester) async {
      await _size(tester, const Size(400, 900));
      final b = await _start(tester);
      await _openBanners(tester);
      expect(find.text('No banners yet'), findsOneWidget);

      b.picker.next = [b.picker.next.first, b.picker.next.first];
      await tester.tap(find.text('Add banners'));
      await settle(tester);

      expect(find.text('Banner 1'), findsOneWidget);
      expect(find.text('Banner 2'), findsOneWidget);
      expect(b.images.uploads, hasLength(2));
      await drainSnackbars(tester);
    });

    testWidgets('legacy banners are numbered before new ones go last', (
      tester,
    ) async {
      await _size(tester, const Size(1400, 900));
      final b = await _start(
        tester,
        seed: (b) async {
          await b.addBanner('legacyA');
          await b.addBanner('legacyB');
        },
      );
      await _openBanners(tester);
      await tester.tap(find.text('Add banners'));
      await settle(tester);

      final docs = (await b.db.collection('banners').get()).docs;
      final order = {for (final d in docs) d.id: d['sortOrder']};
      expect(order['legacyA'], 0);
      expect(order['legacyB'], 1);
      expect(order.values.toSet(), {0, 1, 2});
      await drainSnackbars(tester);
    });

    testWidgets('move down and delete', (tester) async {
      await _size(tester, const Size(1400, 900));
      final b = await _start(
        tester,
        seed: (b) async {
          await b.addBanner('a', order: 0, createdAt: DateTime(2026, 11, 1));
          await b.addBanner('b', order: 1);
          await b.addBanner('c', order: 2);
        },
      );
      await _openBanners(tester);
      expect(find.text('Added 01/11/2026'), findsOneWidget);

      // The first banner can't move up; the last can't move down.
      await tester.tap(find.byTooltip('More').first);
      await settle(tester);
      expect(find.text('Move up'), findsNothing);
      await tester.tap(find.text('Move down'));
      await settle(tester);
      var docs = (await b.db.collection('banners').get()).docs;
      expect(
        {for (final d in docs) d.id: d['sortOrder']},
        {'b': 0, 'a': 1, 'c': 2},
      );

      await _menu(tester, 2, 'Delete');
      expect(find.text('Delete banner 3?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await settle(tester);
      docs = (await b.db.collection('banners').get()).docs;
      expect(docs.map((d) => d.id), unorderedEquals(['a', 'b']));
      await drainSnackbars(tester);
    });
  });
}

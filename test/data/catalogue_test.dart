import 'package:flutter_test/flutter_test.dart';
import 'package:your_shop_admin/data/models/banner_model.dart';
import 'package:your_shop_admin/data/models/category_model.dart';
import 'package:your_shop_admin/data/repositories/catalog_repository.dart';

import '../helpers.dart';

void main() {
  group('BannerModel', () {
    test('reads the position and tolerates legacy banners', () {
      final b = BannerModel.fromMap({
        'imageUrl': 'https://x/b.jpg',
        'sortOrder': '2',
      }, id: 'b1');
      expect(b.sortOrder, 2);
      expect(BannerModel.fromMap({}, id: 'b2').sortOrder, isNull);
    });

    test('carousel order: by position, unnumbered last, then by ID', () {
      const list = [
        BannerModel(id: 'z', imageUrl: ''),
        BannerModel(id: 'c', imageUrl: '', sortOrder: 1),
        BannerModel(id: 'a', imageUrl: ''),
        BannerModel(id: 'b', imageUrl: '', sortOrder: 0),
      ];
      final sorted = list.toList()..sort(BannerModel.compare);
      expect(sorted.map((b) => b.id), ['b', 'c', 'a', 'z']);
    });
  });

  group('CatalogRepository: categories', () {
    late TestBackend b;
    late CatalogRepository repo;

    setUp(() async {
      b = TestBackend();
      repo = CatalogRepository(firestore: b.db, images: b.images);
      await b.addCategory('shirts', 'Shirts');
      await b.addCategory('caps', 'Caps');
      await b.addProduct('p1', 'Linen Overshirt');
      await b.addProduct('p2', 'Old Shirt', archived: true);
      await b.addProduct('p3', 'Cap', categoryId: 'caps', categoryName: 'Caps');
    });

    test('a rename updates the copied name on its products only', () async {
      await repo.saveCategory(
        const CategoryModel(id: 'shirts', name: 'Shirts & Tops'),
        isNew: false,
      );
      final cat = await b.db.doc('categories/shirts').get();
      expect(cat['categoryName'], 'Shirts & Tops');
      expect(cat.data()!.containsKey('updatedAt'), isTrue);
      for (final id in ['p1', 'p2']) {
        final p = await b.db.doc('products/$id').get();
        expect(p['categoryName'], 'Shirts & Tops');
      }
      final cap = await b.db.doc('products/p3').get();
      expect(cap['categoryName'], 'Caps');
    });

    test('a new category writes the legacy fields', () async {
      final id = repo.newCategoryId();
      await repo.saveCategory(
        CategoryModel(id: id, name: 'Bags', imageUrl: 'https://x/b.jpg'),
        isNew: true,
      );
      final doc = await b.db.doc('categories/$id').get();
      expect(doc['categoryId'], id);
      expect(doc['categoryName'], 'Bags');
      expect(doc['categoryImg'], 'https://x/b.jpg');
      expect(doc.data()!.containsKey('createdAt'), isTrue);
    });

    test('delete refuses while products (archived too) use it', () async {
      await expectLater(
        repo.deleteCategory('shirts'),
        throwsA(
          isA<CategoryInUseException>()
              .having((e) => e.productCount, 'count', 2)
              .having((e) => e.message, 'message', startsWith('2 products')),
        ),
      );
      expect((await b.db.doc('categories/shirts').get()).exists, isTrue);
    });

    test('delete removes an empty category', () async {
      await b.addCategory('bags', 'Bags');
      await repo.deleteCategory('bags');
      expect((await b.db.doc('categories/bags').get()).exists, isFalse);
    });

    test('category images go to categories/<id>/', () async {
      final url = await repo.uploadCategoryImage(
        'bags',
        ImageUpload(bytes: transparentPng, contentType: 'image/png'),
      );
      expect(b.images.uploads.single, startsWith('categories/bags/'));
      expect(url, startsWith('https://img.test/categories/bags/'));
    });
  });

  group('CatalogRepository: banners', () {
    late TestBackend b;
    late CatalogRepository repo;

    setUp(() {
      b = TestBackend();
      repo = CatalogRepository(firestore: b.db, images: b.images);
    });

    test('added banners go to the end, in pick order', () async {
      await b.addBanner('first', order: 0);
      final png = ImageUpload(bytes: transparentPng, contentType: 'image/png');
      await repo.addBanners([png, png], after: 1);

      final list = await repo.watchBanners().first;
      expect(list, hasLength(3));
      expect(list.first.id, 'first');
      expect(list.map((x) => x.sortOrder), [0, 1, 2]);
      expect(b.images.uploads, everyElement(startsWith('banners/')));
      expect(list.last.imageUrl, startsWith('https://img.test/banners/'));
    });

    test('reorder numbers every banner; delete removes one', () async {
      await b.addBanner('a');
      await b.addBanner('b');
      await b.addBanner('c', order: 0);
      await repo.reorderBanners(['b', 'c', 'a']);
      var list = await repo.watchBanners().first;
      expect(list.map((x) => x.id), ['b', 'c', 'a']);

      await repo.deleteBanner('c');
      list = await repo.watchBanners().first;
      expect(list.map((x) => x.id), ['b', 'a']);
    });
  });
}

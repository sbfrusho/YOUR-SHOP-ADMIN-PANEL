import 'package:flutter_test/flutter_test.dart';
import 'package:your_shop_admin/core/utils/pricing.dart';
import 'package:your_shop_admin/data/models/product_model.dart';
import 'package:your_shop_admin/data/repositories/catalog_repository.dart';

import '../helpers.dart';

void main() {
  group('Pricing', () {
    test('sale price rounds to whole Taka and caps the discount', () {
      expect(Pricing.salePrice(2490, 25), 1868);
      expect(Pricing.salePrice(1000, 0), 1000);
      expect(Pricing.salePrice(1000, 95), 100);
    });

    test('percent off from legacy prices', () {
      expect(Pricing.percentOff(2490, 1890), 24);
      expect(Pricing.percentOff(500, 500), 0);
      expect(Pricing.percentOff(0, 10), 0);
    });

    test('legacy strings drop a trailing .0', () {
      expect(Pricing.legacyString(1290), '1290');
      expect(Pricing.legacyString(12.5), '12.50');
    });
  });

  group('ProductModel', () {
    test('reads legacy strings and derives the percent', () {
      final p = ProductModel.fromMap({
        'productName': 'Linen Overshirt',
        'fullPrice': '2490',
        'salePrice': '1890',
        'isSale': true,
        'quantity': '3',
      }, id: 'p1');
      expect(p.id, 'p1');
      expect(p.price, 1890);
      expect(p.salePercent, 24);
      expect(p.stock, 3);
      expect(p.isLowStock, isTrue);
    });

    test('writes legacy formats with the computed sale price', () {
      final map = const ProductModel(
        id: 'p1',
        name: 'Cap',
        fullPrice: 1000,
        isSale: true,
        salePercent: 15,
        stock: 7,
        sizes: ['M'],
      ).toMap();
      expect(map['fullPrice'], '1000');
      expect(map['salePrice'], '850');
      expect(map['quantity'], '7');
      expect(map['isSale'], isTrue);
      expect(map['salePercent'], 15);
    });

    test('not on sale: sale price equals full price', () {
      final map = const ProductModel(
        id: 'p1',
        name: 'Cap',
        fullPrice: 650,
        salePercent: 20,
      ).toMap();
      expect(map['salePrice'], '650');
      expect(map['isSale'], isFalse);
      expect(map['salePercent'], 0);
    });
  });

  group('CatalogRepository', () {
    late TestBackend backend;
    late CatalogRepository repo;

    setUp(() {
      backend = TestBackend();
      repo = CatalogRepository(firestore: backend.db, images: backend.images);
    });

    test('lists every product sorted by name', () async {
      await backend.addProduct('b', 'tote');
      await backend.addProduct('a', 'Cap', archived: true);
      final list = await repo.watchProducts().first;
      expect(list.map((p) => p.name), ['Cap', 'tote']);
      expect(list.first.isArchived, isTrue);
    });

    test('new products get createdAt; edits keep unknown fields', () async {
      final id = repo.newProductId();
      await repo.saveProduct(
        ProductModel(id: id, name: 'Cap', fullPrice: 650),
        isNew: true,
      );
      var doc = (await backend.db.doc('products/$id').get()).data()!;
      expect(doc['createdAt'], isNotNull);
      expect(doc['updatedAt'], isNotNull);

      await backend.db.doc('products/$id').update({'rating': 4.5});
      await repo.saveProduct(
        ProductModel(id: id, name: 'Cap 2', fullPrice: 700),
        isNew: false,
      );
      doc = (await backend.db.doc('products/$id').get()).data()!;
      expect(doc['productName'], 'Cap 2');
      expect(doc['fullPrice'], '700');
      expect(doc['rating'], 4.5);
    });

    test('archive and restore', () async {
      await backend.addProduct('p1', 'Cap');
      await repo.setArchived('p1', true);
      expect((await repo.fetchProduct('p1'))!.isArchived, isTrue);
      await repo.setArchived('p1', false);
      expect((await repo.fetchProduct('p1'))!.isArchived, isFalse);
    });

    test('images upload under the product folder', () async {
      final url = await repo.uploadProductImage(
        'p1',
        ImageUpload(bytes: transparentPng, contentType: 'image/png'),
      );
      expect(backend.images.uploads.single, startsWith('products/p1/'));
      expect(url, startsWith('https://img.test/products/p1/'));
    });
  });
}

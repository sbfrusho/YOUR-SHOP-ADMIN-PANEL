import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/image_storage.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

/// A picked image waiting to be uploaded.
class ImageUpload {
  const ImageUpload({
    required this.bytes,
    required this.contentType,
    this.extension = 'jpg',
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;
}

/// An image in a form: already uploaded ([url]) or picked ([upload]).
class FormImage {
  const FormImage.remote(String this.url) : upload = null;
  const FormImage.local(ImageUpload this.upload) : url = null;

  final String? url;
  final ImageUpload? upload;
}

/// Products, categories and banners (Firestore) and their images (Storage).
class CatalogRepository {
  CatalogRepository({FirebaseFirestore? firestore, ImageStorage? images})
    : _db = firestore ?? FirebaseFirestore.instance,
      _images = images ?? FirebaseImageStorage();

  final FirebaseFirestore _db;
  final ImageStorage _images;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(FirestorePaths.products);
  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection(FirestorePaths.categories);
  CollectionReference<Map<String, dynamic>> get _banners =>
      _db.collection(FirestorePaths.banners);

  /// Firestore allows 500 writes per batch.
  static const _batchLimit = 450;

  /// Every product, archived included, sorted by name.
  Stream<List<ProductModel>> watchProducts() => _products.snapshots().map(
    (s) => s.docs.map((d) => ProductModel.fromMap(d.data(), id: d.id)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
  );

  Stream<List<CategoryModel>> watchCategories() => _categories.snapshots().map(
    (s) => s.docs.map((d) => CategoryModel.fromMap(d.data(), id: d.id)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
  );

  Future<ProductModel?> fetchProduct(String id) async {
    try {
      final doc = await _products.doc(id).get();
      final data = doc.data();
      return data == null ? null : ProductModel.fromMap(data, id: doc.id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// A fresh product ID (used for the image folder before the first save).
  String newProductId() => _products.doc().id;

  Future<String> uploadProductImage(String productId, ImageUpload image) {
    final name = DateTime.now().microsecondsSinceEpoch;
    return _images.upload(
      'products/$productId/$name.${image.extension}',
      image.bytes,
      image.contentType,
    );
  }

  /// Creates or replaces the form-owned fields of [product]. `createdAt` is
  /// set once; `updatedAt` on every save.
  Future<void> saveProduct(ProductModel product, {required bool isNew}) async {
    try {
      final data = {
        ...product.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      };
      final ref = _products.doc(product.id);
      if (isNew) {
        await ref.set(data);
      } else {
        await ref.set(data, SetOptions(merge: true));
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Archived products are hidden from the shop but kept for old orders.
  Future<void> setArchived(String productId, bool archived) async {
    try {
      await _products.doc(productId).update({
        'isArchived': archived,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ----- Categories -------------------------------------------------------

  Future<CategoryModel?> fetchCategory(String id) async {
    try {
      final doc = await _categories.doc(id).get();
      final data = doc.data();
      return data == null ? null : CategoryModel.fromMap(data, id: doc.id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  String newCategoryId() => _categories.doc().id;

  Future<String> uploadCategoryImage(String categoryId, ImageUpload image) {
    final name = DateTime.now().microsecondsSinceEpoch;
    return _images.upload(
      'categories/$categoryId/$name.${image.extension}',
      image.bytes,
      image.contentType,
    );
  }

  /// Saves [category]. Products keep a copy of the category name
  /// (`categoryName`, shown in the shop), so a rename updates them too.
  Future<void> saveCategory(
    CategoryModel category, {
    required bool isNew,
  }) async {
    try {
      final ref = _categories.doc(category.id);
      final data = {
        ...category.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      };
      if (isNew) {
        await ref.set(data);
        return;
      }
      await ref.set(data, SetOptions(merge: true));
      final stale = await _productsIn(category.id);
      final renamed = stale.where(
        (d) => d.data()['categoryName'] != category.name,
      );
      await _inBatches(
        renamed.toList(),
        (batch, doc) =>
            batch.update(doc.reference, {'categoryName': category.name}),
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Products (archived included) that belong to [categoryId].
  Future<int> countProductsIn(String categoryId) async {
    try {
      return (await _productsIn(categoryId)).length;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Refuses while any product, archived included, still uses the
  /// category: the shop and old products would point at nothing.
  Future<void> deleteCategory(String categoryId) async {
    final count = await countProductsIn(categoryId);
    if (count > 0) throw CategoryInUseException(count);
    try {
      await _categories.doc(categoryId).delete();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _productsIn(
    String categoryId,
  ) async =>
      (await _products.where('categoryId', isEqualTo: categoryId).get()).docs;

  // ----- Banners ----------------------------------------------------------

  /// Banners in carousel order (see [BannerModel.compare]).
  Stream<List<BannerModel>> watchBanners() => _banners.snapshots().map(
    (s) =>
        s.docs.map((d) => BannerModel.fromMap(d.data(), id: d.id)).toList()
          ..sort(BannerModel.compare),
  );

  /// Uploads each image and adds it as a banner at the end of the carousel.
  /// [after] is how many banners the carousel already has.
  Future<void> addBanners(
    List<ImageUpload> images, {
    required int after,
  }) async {
    try {
      for (final (i, image) in images.indexed) {
        final ref = _banners.doc();
        final name = DateTime.now().microsecondsSinceEpoch;
        final url = await _images.upload(
          'banners/${ref.id}/$name.${image.extension}',
          image.bytes,
          image.contentType,
        );
        await ref.set({
          'imageUrl': url,
          'sortOrder': after + i,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Writes `sortOrder` 0, 1, 2… in the order of [ids].
  Future<void> reorderBanners(List<String> ids) async {
    try {
      await _inBatches([
        for (final (i, id) in ids.indexed) (i, id),
      ], (batch, e) => batch.update(_banners.doc(e.$2), {'sortOrder': e.$1}));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// The image stays in Storage (same policy as product images).
  Future<void> deleteBanner(String id) async {
    try {
      await _banners.doc(id).delete();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> _inBatches<T>(
    List<T> items,
    void Function(WriteBatch batch, T item) write,
  ) async {
    for (var i = 0; i < items.length; i += _batchLimit) {
      final batch = _db.batch();
      for (final item in items.skip(i).take(_batchLimit)) {
        write(batch, item);
      }
      await batch.commit();
    }
  }
}

/// A category still has products, so it can't be deleted.
class CategoryInUseException extends AppException {
  CategoryInUseException(this.productCount)
    : super(
        productCount == 1
            ? '1 product still uses this category. Move it to another '
                      'category first.'
                  .tr
            : '@count products still use this category. Move them to '
                      'another category first.'
                  .trParams({'count': '$productCount'}),
      );

  final int productCount;
}

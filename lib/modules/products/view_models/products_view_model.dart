import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/catalog_repository.dart';

enum StockFilter {
  active('All active'),
  inStock('In stock'),
  low('Low stock'),
  out('Out of stock'),
  archived('Archived');

  const StockFilter(this.label);
  final String label;

  bool matches(ProductModel p) => switch (this) {
    active => !p.isArchived,
    inStock => !p.isArchived && !p.isOutOfStock,
    low => !p.isArchived && p.isLowStock,
    out => !p.isArchived && p.isOutOfStock,
    archived => p.isArchived,
  };
}

/// Live product list with search, category and stock filters.
class ProductsViewModel extends GetxController {
  ProductsViewModel(this._repo);

  final CatalogRepository _repo;

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  final RxString query = ''.obs;
  final RxnString categoryId = RxnString();
  final Rx<StockFilter> stock = StockFilter.active.obs;

  StreamSubscription<List<ProductModel>>? _productsSub;
  StreamSubscription<List<CategoryModel>>? _categoriesSub;

  List<ProductModel> get visible {
    final q = query.value.trim().toLowerCase();
    return products.where((p) {
      if (!stock.value.matches(p)) return false;
      if (categoryId.value != null && p.categoryId != categoryId.value) {
        return false;
      }
      return q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q);
    }).toList();
  }

  int count(StockFilter f) => products.where(f.matches).length;

  String categoryName(ProductModel p) {
    if (p.categoryName.isNotEmpty) return p.categoryName;
    return categories.firstWhereOrNull((c) => c.id == p.categoryId)?.name ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  void listen() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    isLoading.value = true;
    error.value = null;
    _productsSub = _repo.watchProducts().listen(
      (list) {
        products.assignAll(list);
        isLoading.value = false;
      },
      onError: (Object e) {
        error.value = AppException.from(e).message;
        isLoading.value = false;
      },
    );
    _categoriesSub = _repo.watchCategories().listen(
      categories.assignAll,
      onError: (_) {},
    );
  }

  void clearFilters() {
    query.value = '';
    categoryId.value = null;
    stock.value = StockFilter.active;
  }

  void create() => Get.toNamed<void>(AppRoutes.productNew);
  void edit(ProductModel p) =>
      Get.toNamed<void>(AppRoutes.productEditFor(p.id));

  /// The view confirms before archiving.
  Future<void> setArchived(ProductModel p, bool archived) async {
    try {
      await _repo.setArchived(p.id, archived);
      AppSnackbar.success(
        archived
            ? '"@name" is hidden from the shop.'.trParams({'name': p.name})
            : '"@name" is back in the shop.'.trParams({'name': p.name}),
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
    }
  }

  @override
  void onClose() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    super.onClose();
  }
}

import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/catalog_repository.dart';

enum CatalogueTab { categories, banners }

/// Categories (with product counts) and home banners, both live.
class CatalogueViewModel extends GetxController {
  CatalogueViewModel(this._repo, this._picker);

  final CatalogRepository _repo;
  final ImagePickerService _picker;

  final Rx<CatalogueTab> tab = CatalogueTab.categories.obs;

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<BannerModel> banners = <BannerModel>[].obs;
  final RxMap<String, int> _productCounts = <String, int>{}.obs;

  final RxBool categoriesLoading = true.obs;
  final RxBool bannersLoading = true.obs;
  final RxnString categoriesError = RxnString();
  final RxnString bannersError = RxnString();

  /// Banners being uploaded right now (shown as placeholders).
  final RxInt uploading = 0.obs;

  final RxString query = ''.obs;

  final _subs = <StreamSubscription<Object?>>[];

  List<CategoryModel> get visibleCategories {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return categories;
    return categories.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  /// Products (archived included) in [c], from the live product list.
  int productCount(CategoryModel c) => _productCounts[c.id] ?? 0;

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  void listen() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    categoriesLoading.value = bannersLoading.value = true;
    categoriesError.value = bannersError.value = null;
    _subs
      ..add(
        _repo.watchCategories().listen(
          (list) {
            categories.assignAll(list);
            categoriesLoading.value = false;
          },
          onError: (Object e) {
            categoriesError.value = AppException.from(e).message;
            categoriesLoading.value = false;
          },
        ),
      )
      ..add(
        _repo.watchBanners().listen(
          (list) {
            banners.assignAll(list);
            bannersLoading.value = false;
          },
          onError: (Object e) {
            bannersError.value = AppException.from(e).message;
            bannersLoading.value = false;
          },
        ),
      )
      ..add(_repo.watchProducts().listen(_countProducts, onError: (_) {}));
  }

  void _countProducts(List<ProductModel> products) {
    final counts = <String, int>{};
    for (final p in products) {
      counts[p.categoryId] = (counts[p.categoryId] ?? 0) + 1;
    }
    _productCounts.assignAll(counts);
  }

  // ----- Categories -------------------------------------------------------

  void createCategory() => Get.toNamed<void>(AppRoutes.categoryNew);
  void editCategory(CategoryModel c) =>
      Get.toNamed<void>(AppRoutes.categoryEditFor(c.id));

  /// The view confirms first. The repository checks again for products, so
  /// a product added meanwhile still blocks the delete.
  Future<void> deleteCategory(CategoryModel c) async {
    try {
      await _repo.deleteCategory(c.id);
      AppSnackbar.success('"@name" deleted.'.trParams({'name': c.name}));
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
    }
  }

  // ----- Banners ----------------------------------------------------------

  /// Picks one or more images and adds them at the end of the carousel.
  Future<void> addBanners() async {
    if (uploading.value > 0) return;
    try {
      final picked = await _picker.pickImages();
      if (picked.isEmpty) return;
      uploading.value = picked.length;
      // Legacy banners have no position; number them first so the new
      // ones really go last.
      if (banners.any((b) => b.sortOrder == null)) {
        await _repo.reorderBanners([for (final b in banners) b.id]);
      }
      await _repo.addBanners(picked, after: banners.length);
      AppSnackbar.success(
        picked.length == 1
            ? 'Banner added.'.tr
            : '@count banners added.'.trParams({'count': '${picked.length}'}),
      );
    } catch (e) {
      AppSnackbar.error(AppException.from(e).message.tr);
    } finally {
      uploading.value = 0;
    }
  }

  /// Moves the banner at [from] to position [to] and saves the order.
  Future<void> moveBanner(int from, int to) async {
    if (from == to || from < 0 || from >= banners.length) return;
    final list = banners.toList();
    final moved = list.removeAt(from);
    list.insert(to.clamp(0, list.length), moved);
    banners.assignAll(list); // Shown at once; the stream confirms it.
    try {
      await _repo.reorderBanners([for (final b in list) b.id]);
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
      listen(); // Back to what is stored.
    }
  }

  /// The view confirms first.
  Future<void> deleteBanner(BannerModel b) async {
    try {
      await _repo.deleteBanner(b.id);
      AppSnackbar.success('Banner removed from the shop.'.tr);
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
    }
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/json_parsing.dart';
import '../../../core/utils/pricing.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/catalog_repository.dart';

/// Create or edit a product. [productId] `null` means a new product.
class ProductFormViewModel extends GetxController {
  ProductFormViewModel(
    this._repo,
    this._picker,
    this._session, {
    this.productId,
  });

  final CatalogRepository _repo;
  final ImagePickerService _picker;
  final SessionService _session;
  final String? productId;

  static const presetSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const defaultDelivery = '2–4 working days';

  bool get isNew => productId == null;

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final description = TextEditingController();
  final fullPrice = TextEditingController();
  final stock = TextEditingController(text: '0');
  final deliveryTime = TextEditingController(text: defaultDelivery);
  final customSize = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool notFound = false.obs;
  final RxnString categoryId = RxnString();
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<String> sizes = <String>[].obs;
  final RxList<FormImage> images = <FormImage>[].obs;
  final RxBool isSale = false.obs;
  final RxInt salePercent = 10.obs;

  /// Mirrors [fullPrice] so the computed sale price updates live.
  final RxDouble fullPriceValue = 0.0.obs;
  final RxBool imagesMissing = false.obs;

  ProductModel? _original;
  late final String _id = productId ?? _repo.newProductId();
  StreamSubscription<List<CategoryModel>>? _categoriesSub;

  /// Shown live in the form. Matches what [save] writes.
  double get salePrice {
    final o = _original;
    if (o != null &&
        o.isSale &&
        o.fullPrice == fullPriceValue.value &&
        o.salePercent == salePercent.value) {
      return o.salePrice;
    }
    return Pricing.salePrice(fullPriceValue.value, salePercent.value);
  }

  @override
  void onInit() {
    super.onInit();
    fullPrice.addListener(
      () => fullPriceValue.value = asDouble(fullPrice.text),
    );
    _categoriesSub = _repo.watchCategories().listen(
      categories.assignAll,
      onError: (_) {},
    );
    if (!isNew) _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final p = await _repo.fetchProduct(_id);
      if (p == null) {
        notFound.value = true;
        return;
      }
      _original = p;
      name.text = p.name;
      description.text = p.description;
      fullPrice.text = Pricing.legacyString(p.fullPrice);
      stock.text = '${p.stock}';
      deliveryTime.text = p.deliveryTime;
      categoryId.value = p.categoryId.isEmpty ? null : p.categoryId;
      sizes.assignAll(p.sizes);
      images.assignAll(p.images.map(FormImage.remote));
      isSale.value = p.isSale && p.salePercent > 0;
      if (p.salePercent > 0) salePercent.value = p.salePercent;
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSize(String size) =>
      sizes.contains(size) ? sizes.remove(size) : sizes.add(size);

  void addCustomSize() {
    final s = customSize.text.trim().toUpperCase();
    if (s.isNotEmpty && !sizes.contains(s)) sizes.add(s);
    customSize.clear();
  }

  Future<void> pickImages() async {
    try {
      final picked = await _picker.pickImages();
      images.addAll(picked.map(FormImage.local));
      if (images.isNotEmpty) imagesMissing.value = false;
    } catch (e) {
      AppSnackbar.error(AppException.from(e).message.tr);
    }
  }

  void removeImage(int index) => images.removeAt(index);

  /// The first image is the cover shown in the shop.
  void makeCover(int index) {
    if (index <= 0 || index >= images.length) return;
    images.insert(0, images.removeAt(index));
  }

  void setSalePercent(double value) =>
      salePercent.value = value.round().clamp(1, Pricing.maxPercent);

  /// Uploads new images, then writes the product. Returns `true` when saved.
  Future<bool> save() async {
    if (isSaving.value) return false;
    final valid = formKey.currentState?.validate() ?? false;
    imagesMissing.value = images.isEmpty;
    if (!valid || images.isEmpty) return false;
    isSaving.value = true;
    try {
      final urls = <String>[];
      for (final img in images) {
        urls.add(img.url ?? await _repo.uploadProductImage(_id, img.upload!));
      }
      // Keep uploaded URLs so a failed save doesn't upload them twice.
      images.assignAll(urls.map(FormImage.remote));
      final category = categories.firstWhereOrNull(
        (c) => c.id == categoryId.value,
      );
      final full = asDouble(fullPrice.text);
      final original = _original;
      // Re-saving a legacy product must not nudge its price (2490 at 24%
      // is 1892, but it was stored as 1890).
      final keepSalePrice =
          original != null &&
          original.isSale &&
          original.fullPrice == full &&
          original.salePercent == salePercent.value;
      final product = ProductModel(
        id: _id,
        name: name.text.trim(),
        description: description.text.trim(),
        categoryId: categoryId.value ?? '',
        categoryName: category?.name ?? _original?.categoryName ?? '',
        fullPrice: full,
        salePrice: isSale.value && keepSalePrice
            ? original.salePrice
            : Pricing.salePrice(full, salePercent.value),
        isSale: isSale.value,
        salePercent: isSale.value ? salePercent.value : 0,
        stock: asInt(stock.text),
        sizes: sizes.toList(),
        images: urls,
        sellerEmail:
            _original?.sellerEmail ?? _session.admin.value?.email ?? '',
        deliveryTime: deliveryTime.text.trim(),
        isArchived: _original?.isArchived ?? false,
      );
      await _repo.saveProduct(product, isNew: isNew);
      AppSnackbar.success(isNew ? 'Product added.'.tr : 'Product saved.'.tr);
      return true;
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    _categoriesSub?.cancel();
    for (final c in [
      name,
      description,
      fullPrice,
      stock,
      deliveryTime,
      customSize,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}

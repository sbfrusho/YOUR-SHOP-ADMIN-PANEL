import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/image_picker_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/catalog_repository.dart';

/// Create or edit a category. [categoryId] `null` means a new category.
class CategoryFormViewModel extends GetxController {
  CategoryFormViewModel(this._repo, this._picker, {this.categoryId});

  final CatalogRepository _repo;
  final ImagePickerService _picker;
  final String? categoryId;

  bool get isNew => categoryId == null;

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool notFound = false.obs;
  final Rxn<FormImage> image = Rxn<FormImage>();
  final RxBool imageMissing = false.obs;

  /// Products in this category; a rename updates their copy of the name.
  final RxInt productCount = 0.obs;

  final RxList<CategoryModel> _all = <CategoryModel>[].obs;
  late final String _id = categoryId ?? _repo.newCategoryId();
  StreamSubscription<List<CategoryModel>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repo.watchCategories().listen(_all.assignAll, onError: (_) {});
    if (!isNew) _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final c = await _repo.fetchCategory(_id);
      if (c == null) {
        notFound.value = true;
        return;
      }
      name.text = c.name;
      if (c.imageUrl.isNotEmpty) image.value = FormImage.remote(c.imageUrl);
      productCount.value = await _repo.countProductsIn(_id);
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Required, and unique ignoring case (the shop lists them side by side).
  String? validateName(String? value) {
    final missing = Validators.required(value, field: 'Name');
    if (missing != null) return missing;
    final n = value!.trim().toLowerCase();
    final taken = _all.any((c) => c.id != _id && c.name.toLowerCase() == n);
    return taken ? 'A category with this name already exists.'.tr : null;
  }

  Future<void> pickImage() async {
    try {
      final picked = await _picker.pickImage();
      if (picked == null) return;
      image.value = FormImage.local(picked);
      imageMissing.value = false;
    } catch (e) {
      AppSnackbar.error(AppException.from(e).message.tr);
    }
  }

  /// Uploads a new image if one was picked, then writes the category.
  /// Returns `true` when saved.
  Future<bool> save() async {
    if (isSaving.value) return false;
    final valid = formKey.currentState?.validate() ?? false;
    final img = image.value;
    imageMissing.value = img == null;
    if (!valid || img == null) return false;
    isSaving.value = true;
    try {
      final url = img.url ?? await _repo.uploadCategoryImage(_id, img.upload!);
      // Keep the URL so a failed save doesn't upload it twice.
      image.value = FormImage.remote(url);
      await _repo.saveCategory(
        CategoryModel(id: _id, name: name.text.trim(), imageUrl: url),
        isNew: isNew,
      );
      AppSnackbar.success(isNew ? 'Category added.'.tr : 'Category saved.'.tr);
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
    _sub?.cancel();
    name.dispose();
    super.onClose();
  }
}

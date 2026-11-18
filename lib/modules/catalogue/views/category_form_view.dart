import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/state_views.dart';
import '../view_models/category_form_view_model.dart';

class CategoryFormView extends GetView<CategoryFormViewModel> {
  const CategoryFormView({super.key});

  static const maxWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return Scaffold(
      appBar: AppTopBar(
        title: controller.isNew ? 'New category'.tr : 'Edit category'.tr,
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        if (controller.notFound.value) {
          return const EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Category not found',
            message: 'It may have been deleted.',
          );
        }
        return Form(
          key: controller.formKey,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _ImagePicker(),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: controller.name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            validator: controller.validateName,
                            decoration: InputDecoration(labelText: 'Name'.tr),
                          ),
                          Obx(() {
                            final n = controller.productCount.value;
                            if (n == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                n == 1
                                    ? '1 product is in this category. A new '
                                              'name shows on it too.'
                                          .tr
                                    : '@count products are in this category. '
                                              'A new name shows on them too.'
                                          .trParams({'count': '$n'}),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => LoadingButton(
                      label: controller.isNew ? 'Add category' : 'Save changes',
                      isLoading: controller.isSaving.value,
                      onPressed: () async {
                        if (await controller.save() && context.mounted) {
                          // Not Get.back: it would close the snackbar.
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Round preview (as the shop shows it) with a change button.
class _ImagePicker extends GetView<CategoryFormViewModel> {
  const _ImagePicker();

  static const size = 132.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Obx(() {
      final image = controller.image.value;
      final upload = image?.upload;
      final missing = controller.imageMissing.value;
      final radius = BorderRadius.circular(size / 2);
      return Column(
        children: [
          Semantics(
            button: true,
            label: 'Choose image'.tr,
            child: InkWell(
              onTap: controller.pickImage,
              customBorder: const CircleBorder(),
              child: Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: missing ? scheme.error : scheme.outline,
                    width: missing ? 2 : 1,
                  ),
                ),
                child: image == null
                    ? Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 36,
                        color: context.palette.mutedText,
                      )
                    : upload != null
                    ? ClipRRect(
                        borderRadius: radius,
                        child: Image.memory(upload.bytes, fit: BoxFit.cover),
                      )
                    : AppNetworkImage(image.url, borderRadius: radius),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: controller.pickImage,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(image == null ? 'Choose image'.tr : 'Change image'.tr),
          ),
          Text(
            missing
                ? 'Add an image.'.tr
                : 'Square images work best. The shop shows them in a circle.'
                      .tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: missing ? scheme.error : context.palette.mutedText,
            ),
          ),
        ],
      );
    });
  }
}

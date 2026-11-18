import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/json_parsing.dart';
import '../../../core/utils/pricing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../view_models/product_form_view_model.dart';

class ProductFormView extends GetView<ProductFormViewModel> {
  const ProductFormView({super.key});

  static const wideBreakpoint = 900.0;
  static const maxWidth = 1160.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: controller.isNew ? 'New product'.tr : 'Edit product'.tr,
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        if (controller.notFound.value) {
          return const EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Product not found',
            message: 'It may have been removed.',
          );
        }
        return Form(
          key: controller.formKey,
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= wideBreakpoint;
              const left = [_DetailsCard(), _ImagesCard()];
              const right = [_PricingCard(), _StockCard()];
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 24 : 20,
                      8,
                      wide ? 24 : 20,
                      32,
                    ),
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _column(left)),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _column(right)),
                          ],
                        )
                      else
                        _column([...left, ...right]),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: wide ? 320 : double.infinity,
                          ),
                          child: Obx(
                            () => LoadingButton(
                              label: controller.isNew
                                  ? 'Add product'
                                  : 'Save changes',
                              isLoading: controller.isSaving.value,
                              onPressed: () async {
                                if (await controller.save() &&
                                    context.mounted) {
                                  // Not Get.back: it would close the snackbar.
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  static Widget _column(List<Widget> cards) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, card) in cards.indexed) ...[
        if (i > 0) const SizedBox(height: 16),
        card,
      ],
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.hint});

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title.tr, style: theme.textTheme.titleMedium),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends GetView<ProductFormViewModel> {
  const _DetailsCard();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, field: 'Name'),
            decoration: InputDecoration(labelText: 'Name'.tr),
          ),
          const SizedBox(height: 16),
          Obx(
            () => DropdownButtonFormField<String>(
              key: ValueKey(controller.categories.length),
              initialValue:
                  controller.categories.any(
                    (c) => c.id == controller.categoryId.value,
                  )
                  ? controller.categoryId.value
                  : null,
              items: [
                for (final c in controller.categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (id) => controller.categoryId.value = id,
              validator: (v) => v == null ? 'Choose a category'.tr : null,
              decoration: InputDecoration(
                labelText: 'Category'.tr,
                helperText: controller.categories.isEmpty
                    ? 'Add categories under Catalogue first.'.tr
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller.description,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Description'.tr,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagesCard extends GetView<ProductFormViewModel> {
  const _ImagesCard();

  static const tile = 112.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Section(
      title: 'Images',
      hint: 'The first image is the cover. Tap another to make it the cover.',
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (i, img) in controller.images.indexed)
                  _ImageTile(
                    image: img,
                    isCover: i == 0,
                    onTap: () => controller.makeCover(i),
                    onRemove: () => controller.removeImage(i),
                  ),
                SizedBox.square(
                  dimension: tile,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: controller.pickImages,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined),
                        const SizedBox(height: 6),
                        Text('Add'.tr),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (controller.imagesMissing.value) ...[
              const SizedBox(height: 10),
              Text(
                'Add at least one image.'.tr,
                style: TextStyle(color: scheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.image,
    required this.isCover,
    required this.onTap,
    required this.onRemove,
  });

  final FormImage image;
  final bool isCover;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.md);
    final upload = image.upload;
    return SizedBox.square(
      dimension: _ImagesCard.tile,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: upload != null
                ? ClipRRect(
                    borderRadius: radius,
                    child: Image.memory(upload.bytes, fit: BoxFit.cover),
                  )
                : AppNetworkImage(image.url, borderRadius: radius),
          ),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Cover'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: scheme.onPrimary),
                ),
              ),
            ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              tooltip: 'Remove image'.tr,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends GetView<ProductFormViewModel> {
  const _PricingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Section(
      title: 'Pricing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller.fullPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (v) =>
                asDouble(v) > 0 ? null : 'Enter a price above 0'.tr,
            decoration: InputDecoration(
              labelText: 'Full price'.tr,
              prefixText: 'Tk ',
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('On sale'.tr),
              value: controller.isSale.value,
              onChanged: controller.isSale.call,
            ),
          ),
          Obx(() {
            if (!controller.isSale.value) return const SizedBox.shrink();
            final percent = controller.salePercent.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Discount'.tr, style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Text('$percent%', style: theme.textTheme.titleMedium),
                  ],
                ),
                Slider(
                  value: percent.toDouble(),
                  min: 1,
                  max: Pricing.maxPercent.toDouble(),
                  divisions: Pricing.maxPercent - 1,
                  label: '$percent%',
                  onChanged: controller.setSalePercent,
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sale price'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.price(controller.salePrice),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StockCard extends GetView<ProductFormViewModel> {
  const _StockCard();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Stock and sizes',
      hint: 'All sizes share one stock count.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller.stock,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) =>
                (v ?? '').isEmpty ? 'Enter the stock count'.tr : null,
            decoration: InputDecoration(labelText: 'In stock'.tr),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final custom = controller.sizes
                .where((s) => !ProductFormViewModel.presetSizes.contains(s))
                .toList();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in [
                  ...ProductFormViewModel.presetSizes,
                  ...custom,
                ])
                  FilterChip(
                    label: Text(s),
                    selected: controller.sizes.contains(s),
                    onSelected: (_) => controller.toggleSize(s),
                  ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.customSize,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => controller.addCustomSize(),
                  decoration: InputDecoration(
                    labelText: 'Other size'.tr,
                    hintText: 'e.g. 32, Free size'.tr,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Add size'.tr,
                onPressed: controller.addCustomSize,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller.deliveryTime,
            decoration: InputDecoration(labelText: 'Delivery time'.tr),
          ),
        ],
      ),
    );
  }
}

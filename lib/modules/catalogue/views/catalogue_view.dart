import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/models/category_model.dart';
import '../../shell/views/settings_button.dart';
import '../view_models/catalogue_view_model.dart';

/// Categories and home banners, as two tabs.
class CatalogueView extends GetView<CatalogueViewModel> {
  const CatalogueView({super.key});

  @override
  Widget build(BuildContext context) {
    // Icons make the labels wrap on phones.
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: const AppTopBar.large(
        title: 'Catalogue',
        actions: [SettingsButton()],
      ),
      floatingActionButton: Obx(
        () => controller.tab.value == CatalogueTab.categories
            ? FloatingActionButton.extended(
                heroTag: 'add-category',
                onPressed: controller.createCategory,
                icon: const Icon(Icons.add_rounded),
                label: Text('Add category'.tr),
              )
            : FloatingActionButton.extended(
                heroTag: 'add-banners',
                onPressed: controller.uploading.value > 0
                    ? null
                    : controller.addBanners,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text('Add banners'.tr),
              ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Obx(
                () => SegmentedButton<CatalogueTab>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: CatalogueTab.categories,
                      icon: narrow ? null : const Icon(Icons.category_outlined),
                      label: Text(
                        '${'Categories'.tr} (${controller.categories.length})',
                      ),
                    ),
                    ButtonSegment(
                      value: CatalogueTab.banners,
                      icon: narrow
                          ? null
                          : const Icon(Icons.view_carousel_outlined),
                      label: Text(
                        '${'Banners'.tr} (${controller.banners.length})',
                      ),
                    ),
                  ],
                  selected: {controller.tab.value},
                  onSelectionChanged: (s) => controller.tab.value = s.first,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => controller.tab.value == CatalogueTab.categories
                  ? const _CategoriesTab()
                  : const _BannersTab(),
            ),
          ),
        ],
      ),
    );
  }
}

// ----- Categories -----------------------------------------------------------

class _CategoriesTab extends GetView<CatalogueViewModel> {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.categoriesLoading.value) return const LoadingView();
      final error = controller.categoriesError.value;
      if (error != null) {
        return ErrorView(message: error, onRetry: controller.listen);
      }
      if (controller.categories.isEmpty) {
        return const EmptyView(
          icon: Icons.category_outlined,
          title: 'No categories yet',
          message:
              'Add one before adding products. The shop shows them as '
              'round tiles on the home screen.',
        );
      }
      final visible = controller.visibleCategories;
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverToBoxAdapter(
              child: TextField(
                onChanged: controller.query.call,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search categories'.tr,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          if (visible.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.search_off_rounded,
                title: 'No matching categories',
                message: 'Try another search.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 96,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: visible.length,
                itemBuilder: (_, i) => _CategoryCard(visible[i]),
              ),
            ),
        ],
      );
    });
  }
}

class _CategoryCard extends GetView<CatalogueViewModel> {
  const _CategoryCard(this.category);

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = controller.productCount(category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.editCategory(category),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              AppNetworkImage(
                category.imageUrl,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 1
                          ? '1 product'.tr
                          : '@count products'.trParams({'count': '$count'}),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More'.tr,
                onSelected: (action) => action == 'edit'
                    ? controller.editCategory(category)
                    : _delete(context),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text('Edit'.tr)),
                  PopupMenuItem(value: 'delete', child: Text('Delete'.tr)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final count = controller.productCount(category);
    if (count > 0) {
      // Explain instead of offering a delete that would be refused.
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Can\'t delete "@name"'.trParams({'name': category.name}),
          ),
          content: Text(
            count == 1
                ? '1 product still uses this category. Move it to another '
                          'category first.'
                      .tr
                : '@count products still use this category. Move them to '
                          'another category first.'
                      .trParams({'count': '$count'}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'.tr),
            ),
          ],
        ),
      );
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Delete "@name"?'.trParams({'name': category.name}),
      message: 'It disappears from the shop. This can\'t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) await controller.deleteCategory(category);
  }
}

// ----- Banners --------------------------------------------------------------

class _BannersTab extends GetView<CatalogueViewModel> {
  const _BannersTab();

  static const maxWidth = 960.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.bannersLoading.value) return const LoadingView();
      final error = controller.bannersError.value;
      if (error != null) {
        return ErrorView(message: error, onRetry: controller.listen);
      }
      final banners = controller.banners.toList();
      final uploading = controller.uploading.value;
      if (banners.isEmpty && uploading == 0) {
        return const EmptyView(
          icon: Icons.view_carousel_outlined,
          title: 'No banners yet',
          message:
              'Banners slide across the top of the shop\'s home screen. '
              'Wide images (2:1) work best.',
        );
      }
      // Left-aligned, in line with the tabs above.
      return Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
            header: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Shown on the shop\'s home screen in this order. Drag to '
                        'reorder. Wide images (2:1) work best.'
                    .tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.mutedText,
                ),
              ),
            ),
            footer: uploading > 0 ? _UploadingCard(count: uploading) : null,
            itemCount: banners.length,
            onReorderItem: controller.moveBanner,
            itemBuilder: (_, i) => Padding(
              key: ValueKey(banners[i].id),
              padding: const EdgeInsets.only(bottom: 12),
              child: _BannerCard(
                banner: banners[i],
                index: i,
                isLast: i == banners.length - 1,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _BannerCard extends GetView<CatalogueViewModel> {
  const _BannerCard({
    required this.banner,
    required this.index,
    required this.isLast,
  });

  final BannerModel banner;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final imageWidth = c.maxWidth >= 600 ? 280.0 : 128.0;
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: 'Drag to reorder'.tr,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.drag_indicator_rounded, color: muted),
                    ),
                  ),
                ),
                AppNetworkImage(
                  banner.imageUrl,
                  width: imageWidth,
                  height: imageWidth / 2,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Banner @n'.trParams({'n': '${index + 1}'}),
                        style: theme.textTheme.titleMedium,
                      ),
                      if (banner.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Added @date'.trParams({
                            'date': Formatters.date(banner.createdAt),
                          }),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More'.tr,
                  onSelected: (action) => switch (action) {
                    'up' => controller.moveBanner(index, index - 1),
                    'down' => controller.moveBanner(index, index + 1),
                    _ => _delete(context),
                  },
                  itemBuilder: (_) => [
                    if (index > 0)
                      PopupMenuItem(value: 'up', child: Text('Move up'.tr)),
                    if (!isLast)
                      PopupMenuItem(value: 'down', child: Text('Move down'.tr)),
                    PopupMenuItem(value: 'delete', child: Text('Delete'.tr)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete banner @n?'.trParams({'n': '${index + 1}'}),
      message: 'It disappears from the shop\'s home screen.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) await controller.deleteBanner(banner);
  }
}

class _UploadingCard extends StatelessWidget {
  const _UploadingCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              count == 1
                  ? 'Uploading 1 banner…'.tr
                  : 'Uploading @count banners…'.trParams({'count': '$count'}),
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

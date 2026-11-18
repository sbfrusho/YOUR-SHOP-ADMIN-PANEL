import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/product_model.dart';
import '../../shell/view_models/shell_view_model.dart';
import '../../shell/views/settings_button.dart';
import '../view_models/products_view_model.dart';
import 'price_text.dart';
import 'product_chips.dart';

class ProductsView extends GetView<ProductsViewModel> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar.large(
        title: 'Products',
        actions: [SettingsButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.create,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add product'.tr),
      ),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const LoadingView();
              final error = controller.error.value;
              if (error != null) {
                return ErrorView(message: error, onRetry: controller.listen);
              }
              final products = controller.visible;
              if (products.isEmpty) {
                final empty = controller.products.isEmpty;
                return EmptyView(
                  icon: Icons.checkroom_outlined,
                  title: empty ? 'No products yet' : 'No matching products',
                  message: empty
                      ? 'Add your first product to start selling.'
                      : 'Try another filter or search.',
                  action: empty
                      ? null
                      : OutlinedButton(
                          onPressed: controller.clearFilters,
                          child: Text('Clear filters'.tr),
                        ),
                );
              }
              return LayoutBuilder(
                builder: (context, c) =>
                    c.maxWidth >= ShellViewModel.wideBreakpoint - 120
                    ? _ProductsTable(products: products)
                    : _ProductsList(products: products),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends GetView<ProductsViewModel> {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: controller.query.call,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search products'.tr,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  for (final f in StockFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: Text('${f.label.tr} (${controller.count(f)})'),
                        selected: controller.stock.value == f,
                        onSelected: (_) => controller.stock.value = f,
                      ),
                    ),
                  if (controller.categories.isNotEmpty)
                    PopupMenuButton<String?>(
                      tooltip: 'Category'.tr,
                      onSelected: (id) => controller.categoryId.value = id,
                      itemBuilder: (_) => [
                        PopupMenuItem(child: Text('All categories'.tr)),
                        for (final c in controller.categories)
                          PopupMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.category_outlined, size: 16),
                        label: Text(
                          controller.categories
                                  .firstWhereOrNull(
                                    (c) => c.id == controller.categoryId.value,
                                  )
                                  ?.name ??
                              'All categories'.tr,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends GetView<ProductsViewModel> {
  const _Actions({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More'.tr,
      onSelected: (action) async {
        if (action == 'edit') return controller.edit(product);
        if (product.isArchived) {
          return controller.setArchived(product, false);
        }
        final ok = await showConfirmDialog(
          context,
          title: 'Archive "@name"?'.trParams({'name': product.name}),
          message:
              'It disappears from the shop and can no longer be ordered. '
              'Past orders keep it. You can restore it later.',
          confirmLabel: 'Archive',
          destructive: true,
        );
        if (ok) await controller.setArchived(product, true);
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text('Edit'.tr)),
        PopupMenuItem(
          value: 'archive',
          child: Text(product.isArchived ? 'Restore'.tr : 'Archive'.tr),
        ),
      ],
    );
  }
}

class _ProductsList extends GetView<ProductsViewModel> {
  const _ProductsList({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = products[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => controller.edit(p),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Row(
                children: [
                  AppNetworkImage(
                    p.thumbnail,
                    width: 72,
                    height: 72,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          controller.categoryName(p),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.palette.mutedText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        PriceText(p),
                        const SizedBox(height: 6),
                        StockChip(p),
                      ],
                    ),
                  ),
                  _Actions(product: p),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductsTable extends GetView<ProductsViewModel> {
  const _ProductsTable({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 96),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 28,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 80,
                headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                  color: muted,
                ),
                columns: [
                  DataColumn(label: Text('Product'.tr)),
                  DataColumn(label: Text('Category'.tr)),
                  DataColumn(label: Text('Price'.tr)),
                  DataColumn(label: Text('Sizes'.tr)),
                  DataColumn(label: Text('Stock'.tr)),
                  const DataColumn(label: SizedBox.shrink()),
                ],
                rows: [
                  for (final p in products)
                    DataRow(
                      onSelectChanged: (_) => controller.edit(p),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              AppNetworkImage(
                                p.thumbnail,
                                width: 52,
                                height: 52,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 220,
                                ),
                                child: Text(
                                  p.name,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(controller.categoryName(p))),
                        DataCell(PriceText(p, stacked: true)),
                        DataCell(
                          Text(p.sizes.isEmpty ? '-' : p.sizes.join(', ')),
                        ),
                        DataCell(StockChip(p)),
                        DataCell(_Actions(product: p)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/models/order_model.dart';
import '../../products/views/product_chips.dart';
import '../../shell/views/settings_button.dart';
import '../view_models/dashboard_view_model.dart';
import 'revenue_chart.dart';

class DashboardView extends GetView<DashboardViewModel> {
  const DashboardView({super.key});

  /// Content width at which the chart and best sellers sit side by side.
  static const wideContent = 900.0;
  static const maxWidth = 1400.0;

  @override
  Widget build(BuildContext context) {
    final name = controller.adminName;
    return Scaffold(
      appBar: AppTopBar.large(
        title: 'Dashboard',
        subtitle: name.isEmpty
            ? controller.greeting.tr
            : '@greeting, @name'.trParams({
                'greeting': controller.greeting.tr,
                'name': name,
              }),
        actions: const [SettingsButton()],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        final error = controller.error.value;
        final stats = controller.stats.value;
        if (error != null || stats == null) {
          return ErrorView(
            message: error ?? 'Something went wrong. Please try again.',
            onRetry: controller.listen,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => controller.listen(),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= wideContent;
              final pad = wide ? 24.0 : 20.0;
              return ListView(
                padding: EdgeInsets.fromLTRB(pad, 4, pad, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Kpis(stats: stats, columns: wide ? 4 : 2),
                          const SizedBox(height: 16),
                          if (wide)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _RevenueCard(stats: stats),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: _BestSellersCard(stats: stats),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            _RevenueCard(stats: stats),
                            const SizedBox(height: 16),
                            _BestSellersCard(stats: stats),
                          ],
                          const SizedBox(height: 16),
                          _LowStockCard(stats: stats, wide: wide),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}

// ----- KPI tiles ------------------------------------------------------------

class _Kpis extends GetView<DashboardViewModel> {
  const _Kpis({required this.stats, required this.columns});

  final DashboardStats stats;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final yesterday = stats.yesterdayRevenue;
    final tiles = [
      _Kpi(
        icon: Icons.payments_outlined,
        label: 'Revenue today',
        value: Formatters.price(stats.todayRevenue),
        note: 'Yesterday @amount'.trParams({
          'amount': Formatters.price(yesterday),
        }),
        onTap: controller.openTodaysOrders,
      ),
      _Kpi(
        icon: Icons.shopping_bag_outlined,
        label: 'Orders today',
        value: '${stats.todayOrders}',
        note: 'Paid or cash on delivery',
        onTap: controller.openTodaysOrders,
      ),
      _Kpi(
        icon: Icons.inbox_outlined,
        label: 'To confirm',
        value: '${stats.toConfirm}',
        note: stats.awaitingPayment == 0
            ? 'Pending orders'
            : '@n more awaiting card payment'.trParams({
                'n': '${stats.awaitingPayment}',
              }),
        highlight: stats.toConfirm > 0,
        onTap: () => controller.openOrders(status: OrderStatus.pending),
      ),
      _Kpi(
        icon: Icons.local_shipping_outlined,
        label: 'To ship',
        value: '${stats.toShip}',
        note: 'Confirmed orders',
        highlight: stats.toShip > 0,
        onTap: () => controller.openOrders(status: OrderStatus.confirmed),
      ),
    ];
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, c) {
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;
  final VoidCallback onTap;

  /// Something is waiting: the icon uses the warning colour.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: highlight ? palette.warning : palette.mutedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label.tr,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.mutedText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 4),
              Text(
                note.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.mutedText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----- Cards ----------------------------------------------------------------

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.tr, style: theme.textTheme.titleMedium),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.palette.mutedText,
                          ),
                        ),
                    ],
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Revenue',
      subtitle: 'Last @n days: @amount'.trParams({
        'n': '${DashboardStats.chartDays}',
        'amount': Formatters.price(stats.chartTotal),
      }),
      child: SizedBox(
        height: 220,
        child: RevenueChart(days: stats.revenueByDay),
      ),
    );
  }
}

class _BestSellersCard extends GetView<DashboardViewModel> {
  const _BestSellersCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return _Panel(
      title: 'Best sellers',
      subtitle: 'Units sold, last @n days'.trParams({
        'n': '${DashboardStats.bestSellerDays}',
      }),
      action: Obx(
        () => controller.itemsLoading.value
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const SizedBox.shrink(),
      ),
      child: stats.bestSellers.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No sales in the last @n days yet.'.trParams({
                  'n': '${DashboardStats.bestSellerDays}',
                }),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            )
          : Column(
              children: [
                for (final (i, b) in stats.bestSellers.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onTap: controller.hasProduct(b.productId)
                        ? () => controller.openProduct(b.productId)
                        : null,
                    leading: SizedBox(
                      width: 72,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${i + 1}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                          AppNetworkImage(
                            b.imageUrl,
                            width: 44,
                            height: 44,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: Text(Formatters.price(b.revenue)),
                    trailing: Text(
                      b.units == 1
                          ? '1 sold'.tr
                          : '@n sold'.trParams({'n': '${b.units}'}),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _LowStockCard extends GetView<DashboardViewModel> {
  const _LowStockCard({required this.stats, required this.wide});

  final DashboardStats stats;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    final out = stats.outOfStockCount;
    return _Panel(
      title: 'Low stock',
      subtitle: out == 0
          ? 'Active products running low'.tr
          : (out == 1
                ? '1 product is out of stock'.tr
                : '@n products are out of stock'.trParams({'n': '$out'})),
      action: TextButton(
        onPressed: controller.openLowStock,
        child: Text('See all'.tr),
      ),
      child: stats.lowStock.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Everything is well stocked.'.tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            )
          : LayoutBuilder(
              builder: (context, c) {
                final columns = wide ? 3 : 1;
                final width = (c.maxWidth - 16 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    for (final p in stats.lowStock)
                      SizedBox(
                        width: width,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onTap: () => controller.openProduct(p.id),
                          leading: AppNetworkImage(
                            p.thumbnail,
                            width: 44,
                            height: 44,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          title: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          trailing: StockChip(p),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/order_model.dart';
import '../../shell/view_models/shell_view_model.dart';
import '../../shell/views/settings_button.dart';
import '../view_models/orders_view_model.dart';
import 'order_chips.dart';
import 'orders_filter_bar.dart';

class OrdersView extends GetView<OrdersViewModel> {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar.large(
        title: 'Orders',
        subtitle: 'Live. Newest first.',
        actions: [SettingsButton()],
      ),
      body: Column(
        children: [
          const OrdersFilterBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const LoadingView();
              final error = controller.error.value;
              if (error != null) {
                return ErrorView(message: error, onRetry: controller.listen);
              }
              final orders = controller.visible;
              if (orders.isEmpty) {
                final filtered = controller.filter.value.isActive;
                return EmptyView(
                  icon: Icons.receipt_long_outlined,
                  title: filtered ? 'No matching orders' : 'No orders yet',
                  message: filtered
                      ? 'Try another filter or search.'
                      : 'New orders appear here as soon as they are placed.',
                  action: filtered
                      ? OutlinedButton(
                          onPressed: controller.clearFilters,
                          child: Text('Clear filters'.tr),
                        )
                      : null,
                );
              }
              return LayoutBuilder(
                builder: (context, c) =>
                    c.maxWidth >= ShellViewModel.wideBreakpoint - 120
                    ? _OrdersTable(orders: orders)
                    : _OrdersList(orders: orders),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends GetView<OrdersViewModel> {
  const _OrdersList({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final o = orders[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => controller.open(o),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.displayName.tr,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Formatters.price(o.totalPrice),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${o.shortId} · ${Formatters.dateTime(o.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [OrderStatusChip(o.orderStatus), PaymentChip(o)],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrdersTable extends GetView<OrdersViewModel> {
  const _OrdersTable({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                  color: muted,
                ),
                columns: [
                  DataColumn(label: Text('Order'.tr)),
                  DataColumn(label: Text('Placed'.tr)),
                  DataColumn(label: Text('Customer'.tr)),
                  DataColumn(label: Text('Payment'.tr)),
                  DataColumn(label: Text('Total'.tr), numeric: true),
                  DataColumn(label: Text('Status'.tr)),
                ],
                rows: [
                  for (final o in orders)
                    DataRow(
                      onSelectChanged: (_) => controller.open(o),
                      cells: [
                        DataCell(
                          Text(
                            '#${o.shortId}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        DataCell(Text(Formatters.dateTime(o.createdAt))),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.displayName.tr),
                              if (!o.customerDeleted &&
                                  o.customerPhone.isNotEmpty)
                                Text(
                                  o.customerPhone,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        DataCell(PaymentChip(o)),
                        DataCell(Text(Formatters.price(o.totalPrice))),
                        DataCell(OrderStatusChip(o.orderStatus)),
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/order_filter.dart';
import '../../../data/models/order_model.dart';
import '../view_models/orders_view_model.dart';

/// Search, status chips, payment and date filters above the orders list.
class OrdersFilterBar extends GetView<OrdersViewModel> {
  const OrdersFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller.searchController,
            onChanged: controller.onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, email or order ID'.tr,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final f = controller.filter.value;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _PaymentMenu(selected: f.payment),
                _DateButton(filter: f),
                if (f.isActive)
                  TextButton(
                    onPressed: controller.clearFilters,
                    child: Text('Clear'.tr),
                  ),
              ],
            );
          }),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() {
              final f = controller.filter.value;
              final counts = controller.counts;
              return Row(
                children: [
                  _chip(
                    label: '${'All'.tr} (${controller.orders.length})',
                    selected: f.status == null,
                    onTap: () => controller.setStatus(null),
                  ),
                  for (final s in OrderStatus.values)
                    _chip(
                      label: '${s.label.tr} (${counts[s] ?? 0})',
                      selected: f.status == s,
                      onTap: () => controller.setStatus(s),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    ),
  );
}

class _PaymentMenu extends GetView<OrdersViewModel> {
  const _PaymentMenu({required this.selected});

  final PaymentFilter selected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PaymentFilter>(
      tooltip: 'Payment'.tr,
      initialValue: selected,
      onSelected: controller.setPayment,
      itemBuilder: (_) => [
        for (final p in PaymentFilter.values)
          PopupMenuItem(value: p, child: Text(p.label.tr)),
      ],
      child: _FilterPill(
        icon: Icons.payments_outlined,
        label: selected.label,
        active: selected != PaymentFilter.any,
      ),
    );
  }
}

class _DateButton extends GetView<OrdersViewModel> {
  const _DateButton({required this.filter});

  final OrderFilter filter;

  @override
  Widget build(BuildContext context) {
    final from = filter.from;
    final label = from == null
        ? 'Any date'
        : (filter.to == null || filter.to == from)
        ? Formatters.date(from)
        : '${Formatters.date(from)} – ${Formatters.date(filter.to)}';
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final now = DateTime.now();
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: now,
          initialDateRange: from == null
              ? null
              : DateTimeRange(start: from, end: filter.to ?? from),
        );
        if (range != null) controller.setRange(range.start, range.end);
      },
      child: _FilterPill(
        icon: Icons.calendar_today_outlined,
        label: label,
        active: from != null,
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active ? scheme.secondaryContainer : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label.tr, style: Theme.of(context).textTheme.labelLarge),
          const Icon(Icons.arrow_drop_down_rounded, size: 20),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/order_model.dart';
import '../view_models/order_detail_view_model.dart';
import 'order_chips.dart';

class OrderDetailView extends GetView<OrderDetailViewModel> {
  const OrderDetailView({super.key});

  static const wideBreakpoint = 900.0;
  static const maxWidth = 1160.0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final order = controller.order.value;
      return Scaffold(
        appBar: AppTopBar(
          title: order == null ? 'Order'.tr : '${'Order'.tr} #${order.shortId}',
        ),
        body: _body(context, order),
      );
    });
  }

  Widget _body(BuildContext context, OrderModel? order) {
    if (controller.isLoading.value) return const LoadingView();
    final error = controller.error.value;
    if (error != null && order == null) {
      return ErrorView(message: error, onRetry: controller.load);
    }
    if (order == null) {
      return const EmptyView(
        icon: Icons.search_off_rounded,
        title: 'Order not found',
        message: 'It may have been removed.',
      );
    }
    final main = [_ItemsCard(order: order)];
    final side = [
      _ActionsCard(order: order),
      _TimelineCard(order: order),
      _CustomerCard(order: order),
      _PaymentCard(order: order),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= wideBreakpoint;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: wide
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _column(main)),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _column(side)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _column([side.first, ...main, ...side.skip(1)]),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _column(List<Widget> cards) => Column(
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
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.mutedText,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '-' : value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends GetView<OrderDetailViewModel> {
  const _ActionsCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order.orderStatus;
    final next = status.next;
    return _Section(
      title: 'Status',
      child: Obx(() {
        final busy = controller.isUpdating.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [OrderStatusChip(status), PaymentChip(order)],
                  ),
                ),
                if (busy)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy ? null : () => _confirmAdvance(context, next),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  'Mark as @status'.trParams({'status': next.label.tr}),
                ),
              ),
            ],
            if (status.canCancel) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                onPressed: busy || !controller.canCancelOnServer
                    ? null
                    : () => _confirmCancel(context),
                icon: const Icon(Icons.close_rounded),
                label: Text('Cancel order'.tr),
              ),
              if (!controller.canCancelOnServer) ...[
                const SizedBox(height: 8),
                Text(
                  'Cancelling needs the Cloud Functions '
                          '(FUNCTIONS_BASE_URL).'
                      .tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.palette.mutedText,
                  ),
                ),
              ],
            ],
          ],
        );
      }),
    );
  }

  Future<void> _confirmAdvance(BuildContext context, OrderStatus next) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Mark as @status?'.trParams({'status': next.label.tr}),
      message: 'The customer gets an email and a notification.',
      confirmLabel: 'Mark as @status'.trParams({'status': next.label.tr}),
    );
    if (ok) await controller.advance();
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final paidByCard =
        order.paymentStatus == PaymentStatusValue.paid &&
        order.paymentGateway == GatewayId.stripe;
    final ok = await showConfirmDialog(
      context,
      title: 'Cancel this order?',
      message: paidByCard
          ? 'Stock is put back and the card payment is refunded. This '
                "can't be undone."
          : "Stock is put back. This can't be undone.",
      confirmLabel: 'Cancel order',
      cancelLabel: 'Keep order',
      destructive: true,
    );
    if (ok) await controller.cancel();
  }
}

class _ItemsCard extends GetView<OrderDetailViewModel> {
  const _ItemsCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.palette.mutedText;
    return _Section(
      title: 'Items',
      child: Obx(() {
        final items = controller.items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (items.isEmpty)
              Text(
                'No items recorded for this order.'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    AppNetworkImage(
                      item.imageUrl,
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (item.size.isNotEmpty)
                                '${'Size'.tr} ${item.size}',
                              '${item.quantity} × '
                                  '${Formatters.price(item.unitPrice)}',
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.price(item.total),
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            const Divider(height: 8),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Total'.tr, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  Formatters.price(order.totalPrice),
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final current = order.orderStatus;
    final reached = OrderStatus.timeline.indexOf(current);
    final steps = <(OrderStatus, bool, DateTime?)>[
      for (final (i, s) in OrderStatus.timeline.indexed)
        if (!order.isCancelled || order.statusHistory.containsKey(s) || i == 0)
          (
            s,
            order.isCancelled
                ? order.statusHistory.containsKey(s) || i == 0
                : i <= reached,
            s == OrderStatus.pending
                ? order.statusHistory[s] ?? order.createdAt
                : order.statusHistory[s],
          ),
      if (order.isCancelled)
        (
          OrderStatus.cancelled,
          true,
          order.statusHistory[OrderStatus.cancelled],
        ),
    ];
    return _Section(
      title: 'Timeline',
      child: Column(
        children: [
          for (final (i, step) in steps.indexed)
            _TimelineStep(
              status: step.$1,
              done: step.$2,
              at: step.$3,
              isLast: i == steps.length - 1,
              note: step.$1 == OrderStatus.cancelled && order.cancelledBy != ''
                  ? 'By @who'.trParams({'who': order.cancelledBy.tr})
                  : null,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.done,
    required this.at,
    required this.isLast,
    this.note,
  });

  final OrderStatus status;
  final bool done;
  final DateTime? at;
  final bool isLast;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = context.palette.mutedText;
    final color = status == OrderStatus.cancelled
        ? scheme.error
        : done
        ? scheme.primary
        : scheme.outlineVariant;
    final subtitle = [
      if (at != null) Formatters.dateTime(at),
      ?note,
    ].join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: done ? color : null,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: color)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: done ? null : muted,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    if (order.customerDeleted) {
      return _Section(
        title: 'Customer',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_off_outlined, color: context.palette.mutedText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'The customer deleted their account. Their personal details '
                        'were removed; the order is kept for your records.'
                    .tr,
              ),
            ),
          ],
        ),
      );
    }
    return _Section(
      title: 'Customer',
      child: Column(
        children: [
          _Row('Name', order.customerName),
          _Row('Phone', order.customerPhone),
          _Row('Email', order.customerEmail),
          _Row('Address', order.customerAddress),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Payment and delivery',
      child: Column(
        children: [
          _Row('Method', order.paymentMethod.tr),
          _Row('Payment', order.paymentSummary.tr),
          if (order.paymentReference != null)
            _Row('Reference', order.paymentReference!),
          _Row('Delivery', order.deliveryType),
          _Row('Expected', order.deliveryDate),
          _Row('Placed', Formatters.dateTime(order.createdAt)),
          _Row('Order ID', order.id),
        ],
      ),
    );
  }
}

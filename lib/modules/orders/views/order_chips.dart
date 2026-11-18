import 'package:flutter/material.dart';

import '../../../core/widgets/status_chip.dart';
import '../../../data/models/order_model.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: status.label,
    tone: switch (status) {
      OrderStatus.delivered => StatusTone.success,
      OrderStatus.shipped || OrderStatus.confirmed => StatusTone.info,
      OrderStatus.cancelled => StatusTone.error,
      OrderStatus.pending => StatusTone.warning,
    },
  );
}

class PaymentChip extends StatelessWidget {
  const PaymentChip(this.order, {super.key});

  final OrderModel order;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: order.paymentSummary,
    tone: switch (order.paymentStatus) {
      PaymentStatusValue.paid => StatusTone.success,
      PaymentStatusValue.awaitingPayment => StatusTone.warning,
      PaymentStatusValue.refunded => StatusTone.info,
      _ => StatusTone.neutral,
    },
  );
}

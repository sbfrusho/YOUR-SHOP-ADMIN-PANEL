import 'order_model.dart';

/// Payment filter choices for the orders list.
enum PaymentFilter {
  any('Any payment'),
  paid('Paid'),
  unpaid('Cash on delivery'),
  awaiting('Awaiting payment'),
  refunded('Refunded'),
  voided('Not charged');

  const PaymentFilter(this.label);
  final String label;

  bool matches(String paymentStatus) => switch (this) {
    any => true,
    paid => paymentStatus == PaymentStatusValue.paid,
    unpaid => paymentStatus == PaymentStatusValue.unpaid,
    awaiting => paymentStatus == PaymentStatusValue.awaitingPayment,
    refunded => paymentStatus == PaymentStatusValue.refunded,
    voided => paymentStatus == PaymentStatusValue.voided,
  };
}

/// Status, payment, date range and text search, applied in memory to the
/// live order list.
class OrderFilter {
  const OrderFilter({
    this.status,
    this.payment = PaymentFilter.any,
    this.from,
    this.to,
    this.query = '',
  });

  /// `null` means every status.
  final OrderStatus? status;
  final PaymentFilter payment;

  /// Inclusive day range on `createdAt` (local dates).
  final DateTime? from;
  final DateTime? to;
  final String query;

  bool get isActive =>
      status != null ||
      payment != PaymentFilter.any ||
      from != null ||
      query.trim().isNotEmpty;

  bool matches(OrderModel o) {
    if (status != null && o.orderStatus != status) return false;
    if (!payment.matches(o.paymentStatus)) return false;
    if (from != null) {
      final created = o.createdAt;
      if (created == null) return false;
      final start = DateTime(from!.year, from!.month, from!.day);
      final end = to == null
          ? null
          : DateTime(to!.year, to!.month, to!.day).add(const Duration(days: 1));
      if (created.isBefore(start)) return false;
      if (end != null && !created.isBefore(end)) return false;
    }
    return o.matchesQuery(query.trim().toLowerCase());
  }

  List<OrderModel> apply(List<OrderModel> orders) =>
      orders.where(matches).toList();

  OrderFilter copyWith({
    OrderStatus? Function()? status,
    PaymentFilter? payment,
    (DateTime?, DateTime?)? range,
    String? query,
  }) => OrderFilter(
    status: status == null ? this.status : status(),
    payment: payment ?? this.payment,
    from: range == null ? from : range.$1,
    to: range == null ? to : range.$2,
    query: query ?? this.query,
  );
}

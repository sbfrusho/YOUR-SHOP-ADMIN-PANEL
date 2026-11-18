import 'order_model.dart';
import 'product_model.dart';

/// Revenue for one calendar day (local time).
class DayRevenue {
  const DayRevenue(this.day, this.revenue, this.orders);

  final DateTime day;
  final double revenue;
  final int orders;
}

/// A product ranked by units sold.
class BestSeller {
  const BestSeller({
    required this.productId,
    required this.name,
    required this.units,
    required this.revenue,
    this.imageUrl = '',
  });

  final String productId;
  final String name;
  final int units;
  final double revenue;
  final String imageUrl;
}

/// Dashboard figures, computed from orders, their items and products.
///
/// **A sale** is an order that is not cancelled and whose money is not
/// gone: cash on delivery (`unpaid`) and `paid` count; card orders still
/// `awaiting_payment` (they may expire), `void` and `refunded` don't.
class DashboardStats {
  const DashboardStats({
    required this.today,
    required this.todayRevenue,
    required this.todayOrders,
    required this.yesterdayRevenue,
    required this.toConfirm,
    required this.toShip,
    required this.awaitingPayment,
    required this.revenueByDay,
    required this.bestSellers,
    required this.lowStock,
    required this.outOfStockCount,
  });

  /// Days in the revenue chart.
  static const chartDays = 14;

  /// Days covered by best sellers.
  static const bestSellerDays = 30;
  static const bestSellerCount = 5;
  static const lowStockCount = 6;

  final DateTime today;
  final double todayRevenue;
  final int todayOrders;
  final double yesterdayRevenue;

  /// Open orders waiting on the admin (any age). [toConfirm] leaves out
  /// card orders still awaiting payment; those are [awaitingPayment].
  final int toConfirm;
  final int toShip;
  final int awaitingPayment;

  /// Oldest first, [chartDays] long, ending today.
  final List<DayRevenue> revenueByDay;
  final List<BestSeller> bestSellers;

  /// Active products that are low or out of stock, emptiest first.
  final List<ProductModel> lowStock;
  final int outOfStockCount;

  double get chartTotal => revenueByDay.fold(0, (sum, d) => sum + d.revenue);

  static bool isSale(OrderModel o) =>
      !o.isCancelled &&
      const {
        PaymentStatusValue.unpaid,
        PaymentStatusValue.paid,
      }.contains(o.paymentStatus);

  static DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  /// [days] calendar days before [day] (safe across DST changes).
  static DateTime daysBefore(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day - days);

  /// Start of the window [recent] must cover (best sellers are longest).
  static DateTime since(DateTime now) =>
      daysBefore(dayOf(now), bestSellerDays - 1);

  /// [recent]: orders from [since] on. [open]: every Pending or Confirmed
  /// order, however old. [items]: line items by order ID (orders without
  /// an entry yet are left out of best sellers).
  factory DashboardStats.compute({
    required DateTime now,
    required List<OrderModel> recent,
    required List<OrderModel> open,
    required Map<String, List<OrderItemModel>> items,
    required List<ProductModel> products,
  }) {
    final today = dayOf(now);
    final yesterday = daysBefore(today, 1);
    final chartStart = daysBefore(today, chartDays - 1);
    final bestStart = since(now);

    final byDay = <DateTime, (double, int)>{};
    final units = <String, int>{};
    final revenue = <String, double>{};
    final names = <String, String>{};
    final images = <String, String>{};

    for (final o in recent) {
      final at = o.createdAt;
      if (at == null || !isSale(o)) continue;
      final day = dayOf(at);
      if (!day.isBefore(chartStart)) {
        final (r, n) = byDay[day] ?? (0.0, 0);
        byDay[day] = (r + o.totalPrice, n + 1);
      }
      if (day.isBefore(bestStart)) continue;
      for (final item in items[o.id] ?? const <OrderItemModel>[]) {
        final key = item.productId.isEmpty ? item.name : item.productId;
        units[key] = (units[key] ?? 0) + item.quantity;
        revenue[key] = (revenue[key] ?? 0) + item.total;
        names.putIfAbsent(key, () => item.name);
        if (item.imageUrl.isNotEmpty) {
          images.putIfAbsent(key, () => item.imageUrl);
        }
      }
    }

    final productsById = {for (final p in products) p.id: p};
    final best =
        [
          for (final key in units.keys)
            BestSeller(
              productId: key,
              // The live name wins; the order keeps the name at the time.
              name: productsById[key]?.name ?? names[key] ?? '',
              units: units[key]!,
              revenue: revenue[key]!,
              imageUrl: productsById[key]?.thumbnail ?? images[key] ?? '',
            ),
        ]..sort((a, b) {
          final byUnits = b.units.compareTo(a.units);
          return byUnits != 0 ? byUnits : b.revenue.compareTo(a.revenue);
        });

    final active = products.where((p) => !p.isArchived);
    final low = active.where((p) => p.isOutOfStock || p.isLowStock).toList()
      ..sort(
        (a, b) => a.stock != b.stock
            ? a.stock.compareTo(b.stock)
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    final todayFigures = byDay[today] ?? (0.0, 0);
    return DashboardStats(
      today: today,
      todayRevenue: todayFigures.$1,
      todayOrders: todayFigures.$2,
      yesterdayRevenue: (byDay[yesterday] ?? (0.0, 0)).$1,
      // Unpaid card orders are Pending too, but not ready to confirm.
      toConfirm: open
          .where(
            (o) => o.orderStatus == OrderStatus.pending && !o.isAwaitingPayment,
          )
          .length,
      toShip: open.where((o) => o.orderStatus == OrderStatus.confirmed).length,
      awaitingPayment: open.where((o) => o.isAwaitingPayment).length,
      revenueByDay: [
        for (var i = 0; i < chartDays; i++)
          () {
            final day = DateTime(
              chartStart.year,
              chartStart.month,
              chartStart.day + i,
            );
            final (r, n) = byDay[day] ?? (0.0, 0);
            return DayRevenue(day, r, n);
          }(),
      ],
      bestSellers: best.take(bestSellerCount).toList(),
      lowStock: low.take(lowStockCount).toList(),
      outOfStockCount: active.where((p) => p.isOutOfStock).length,
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:your_shop_admin/data/models/dashboard_stats.dart';
import 'package:your_shop_admin/data/models/order_model.dart';
import 'package:your_shop_admin/data/models/product_model.dart';

final _now = DateTime(2026, 11, 19, 14);

OrderModel _order(
  String id, {
  required DateTime at,
  double total = 1000,
  String status = 'Pending',
  String payment = 'unpaid',
}) => OrderModel(
  id: id,
  customerId: 'c1',
  customerEmail: '',
  customerName: '',
  customerPhone: '',
  customerAddress: '',
  paymentMethod: 'Cash on Delivery',
  deliveryDate: '',
  totalPrice: total,
  status: status,
  paymentStatus: payment,
  createdAt: at,
);

OrderItemModel _item(String id, String name, int qty, double price) =>
    OrderItemModel(productId: id, name: name, unitPrice: price, quantity: qty);

void main() {
  final today = DateTime(2026, 11, 19, 9);
  final yesterday = DateTime(2026, 11, 18, 20);

  final recent = [
    _order('cod', at: today, total: 1000),
    _order('card', at: today, total: 500, payment: 'awaiting_payment'),
    _order('cancel', at: today, total: 700, status: 'Cancelled'),
    _order('refund', at: today, total: 300, payment: 'refunded'),
    _order(
      'paid',
      at: yesterday,
      total: 2000,
      status: 'Delivered',
      payment: 'paid',
    ),
    _order('old', at: DateTime(2026, 10, 30), total: 900, payment: 'paid'),
  ];
  final open = [
    recent[0],
    recent[1],
    _order('conf', at: DateTime(2026, 9, 1), status: 'Confirmed'),
    _order('ancient', at: DateTime(2026, 8, 1)),
  ];
  final items = {
    'cod': [_item('p1', 'Linen Overshirt', 1, 1000)],
    'paid': [
      _item('p2', 'Cap', 2, 650),
      _item('p1', 'Linen Overshirt', 1, 700),
    ],
    'old': [_item('gone', 'Old Tote', 3, 300)],
    // Not a sale: must not count.
    'cancel': [_item('p2', 'Cap', 9, 650)],
  };
  const products = [
    ProductModel(id: 'p1', name: 'Linen Overshirt v2', stock: 2),
    ProductModel(id: 'p2', name: 'Cap', stock: 0),
    ProductModel(id: 'p3', name: 'Tee', stock: 40),
    ProductModel(id: 'p4', name: 'Archived', stock: 0, isArchived: true),
  ];

  final stats = DashboardStats.compute(
    now: _now,
    recent: recent,
    open: open,
    items: items,
    products: products,
  );

  test('a sale: not cancelled, cash on delivery or paid', () {
    expect(DashboardStats.isSale(recent[0]), isTrue); // COD
    expect(DashboardStats.isSale(recent[1]), isFalse); // awaiting card
    expect(DashboardStats.isSale(recent[2]), isFalse); // cancelled
    expect(DashboardStats.isSale(recent[3]), isFalse); // refunded
    expect(DashboardStats.isSale(recent[4]), isTrue); // paid
  });

  test("today's figures count sales only; yesterday for comparison", () {
    expect(stats.todayOrders, 1);
    expect(stats.todayRevenue, 1000);
    expect(stats.yesterdayRevenue, 2000);
  });

  test('to-dos include old open orders; unpaid card orders are apart', () {
    expect(stats.toConfirm, 2); // cod + ancient
    expect(stats.awaitingPayment, 1);
    expect(stats.toShip, 1);
  });

  test('the chart has 14 days ending today, zero-filled', () {
    expect(stats.revenueByDay, hasLength(DashboardStats.chartDays));
    expect(stats.revenueByDay.first.day, DateTime(2026, 11, 6));
    expect(stats.revenueByDay.last.day, DateTime(2026, 11, 19));
    expect(stats.revenueByDay.last.revenue, 1000);
    expect(stats.revenueByDay[12].revenue, 2000);
    expect(stats.revenueByDay[0].revenue, 0);
    // 30 Oct is outside the chart.
    expect(stats.chartTotal, 3000);
  });

  test('best sellers: by units over 30 days, live name, sales only', () {
    final best = stats.bestSellers;
    expect(best.map((b) => b.productId), ['gone', 'p1', 'p2']);
    expect(best[0].name, 'Old Tote'); // deleted: name from the order
    expect(best[1].name, 'Linen Overshirt v2'); // renamed: live name
    expect(best[1].units, 2);
    expect(best[1].revenue, 1700);
    expect(best[2].units, 2); // the cancelled order's 9 don't count
  });

  test('best sellers skip orders older than 30 days', () {
    final s = DashboardStats.compute(
      now: _now,
      recent: [_order('x', at: DateTime(2026, 10, 1), payment: 'paid')],
      open: const [],
      items: {
        'x': [_item('p1', 'Linen', 1, 100)],
      },
      products: const [],
    );
    expect(s.bestSellers, isEmpty);
    expect(DashboardStats.since(_now), DateTime(2026, 10, 21));
  });

  test('low stock: active products, emptiest first', () {
    expect(stats.lowStock.map((p) => p.id), ['p2', 'p1']);
    expect(stats.outOfStockCount, 1);
  });

  test('day maths uses calendar days across month ends', () {
    expect(
      DashboardStats.daysBefore(DateTime(2026, 3, 1), 1),
      DateTime(2026, 2, 28),
    );
  });
}

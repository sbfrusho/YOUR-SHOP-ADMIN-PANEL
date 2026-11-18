import 'package:flutter_test/flutter_test.dart';
import 'package:your_shop_admin/core/errors/app_exception.dart';
import 'package:your_shop_admin/core/services/functions_client.dart';
import 'package:your_shop_admin/data/models/order_filter.dart';
import 'package:your_shop_admin/data/models/order_model.dart';
import 'package:your_shop_admin/data/repositories/order_repository.dart';

import '../helpers.dart';

OrderModel _order({
  String id = 'abc123xyz',
  String status = 'Pending',
  String paymentStatus = 'unpaid',
  String name = 'Nusrat Jahan',
  String phone = '01712-345678',
  DateTime? createdAt,
}) => OrderModel.fromMap({
  'customerName': name,
  'customerPhone': phone,
  'uniqueId': 'nusrat@mail.test',
  'status': status,
  'paymentStatus': paymentStatus,
  'createdAt': createdAt ?? DateTime(2026, 11, 18, 10),
}, id: id);

void main() {
  group('OrderStatus', () {
    test('moves one step at a time and stops at Delivered', () {
      expect(OrderStatus.pending.next, OrderStatus.confirmed);
      expect(OrderStatus.confirmed.next, OrderStatus.shipped);
      expect(OrderStatus.shipped.next, OrderStatus.delivered);
      expect(OrderStatus.delivered.next, isNull);
      expect(OrderStatus.cancelled.next, isNull);
    });

    test('can be cancelled until delivered', () {
      expect(OrderStatus.shipped.canCancel, isTrue);
      expect(OrderStatus.delivered.canCancel, isFalse);
      expect(OrderStatus.cancelled.canCancel, isFalse);
    });
  });

  group('OrderModel', () {
    test('deleted customers are labelled and legacy fields parse', () {
      final o = OrderModel.fromMap({
        'customerDeleted': true,
        'totalPrice': '1290',
        'status': 'shipped',
        'cancelledBy': 'null',
      }, id: 'x');
      expect(o.displayName, 'Deleted customer');
      expect(o.totalPrice, 1290);
      expect(o.orderStatus, OrderStatus.shipped);
      expect(o.cancelledBy, '');
    });

    test('search matches ID, name, email and phone digits', () {
      final o = _order();
      expect(o.matchesQuery('abc1'), isTrue);
      expect(o.matchesQuery('nusrat'), isTrue);
      expect(o.matchesQuery('mail.test'), isTrue);
      expect(o.matchesQuery('01712345'), isTrue);
      expect(o.matchesQuery('rahim'), isFalse);
    });
  });

  group('OrderFilter', () {
    final orders = [
      _order(id: 'a', createdAt: DateTime(2026, 11, 17, 23, 59)),
      _order(
        id: 'b',
        status: 'Shipped',
        paymentStatus: 'paid',
        createdAt: DateTime(2026, 11, 18),
      ),
      _order(id: 'c', status: 'Cancelled', paymentStatus: 'void'),
    ];

    test('status and payment', () {
      const shipped = OrderFilter(status: OrderStatus.shipped);
      expect(shipped.apply(orders).map((o) => o.id), ['b']);
      const paid = OrderFilter(payment: PaymentFilter.paid);
      expect(paid.apply(orders).map((o) => o.id), ['b']);
    });

    test('date range is inclusive of whole days', () {
      final day = OrderFilter(
        from: DateTime(2026, 11, 18),
        to: DateTime(2026, 11, 18),
      );
      expect(day.apply(orders).map((o) => o.id), ['b', 'c']);
    });

    test('copyWith can clear the status', () {
      const f = OrderFilter(status: OrderStatus.pending);
      expect(f.copyWith(status: () => null).status, isNull);
      expect(f.copyWith(query: 'x').status, OrderStatus.pending);
      expect(const OrderFilter().isActive, isFalse);
      expect(f.isActive, isTrue);
    });
  });

  group('OrderRepository', () {
    late TestBackend backend;
    late OrderRepository repo;

    setUp(() {
      backend = TestBackend(signedIn: true);
      repo = OrderRepository(
        firestore: backend.db,
        functions: backend.functions,
      );
    });

    test('lists newest first with items fetched separately', () async {
      await backend.addOrder(id: 'old', createdAt: DateTime(2026, 1, 1));
      await backend.addOrder(id: 'new', createdAt: DateTime(2026, 11, 1));

      final list = await repo.watchOrders().first;
      expect(list.map((o) => o.id), ['new', 'old']);
      expect(await repo.fetchItems('new'), hasLength(2));
    });

    test('advance writes only the status', () async {
      final id = await backend.addOrder();
      final before = (await backend.db.doc('orders/$id').get()).data()!;
      final order = (await repo.watchOrder(id).first)!;

      await repo.advance(order, OrderStatus.confirmed);

      final after = (await backend.db.doc('orders/$id').get()).data()!;
      expect(after['status'], 'Confirmed');
      expect({...after}..remove('status'), {...before}..remove('status'));
    });

    test('advance refuses skipping steps', () async {
      final id = await backend.addOrder();
      final order = (await repo.watchOrder(id).first)!;
      await expectLater(
        repo.advance(order, OrderStatus.delivered),
        throwsA(isA<AppException>()),
      );
    });

    test('cancel calls adminCancelOrder with the order ID', () async {
      final id = await backend.addOrder(status: 'Confirmed');
      final order = (await repo.watchOrder(id).first)!;

      expect(await repo.cancel(order), isFalse);

      final call = backend.calls.single;
      expect(call.url.path, '/adminCancelOrder');
      expect(call.headers['Authorization'], startsWith('Bearer '));
      expect(call.body, contains(id));
    });

    test('cancel needs the server and an open order', () async {
      final offline = OrderRepository(
        firestore: backend.db,
        functions: FunctionsClient(baseUrl: ''),
      );
      final id = await backend.addOrder();
      final order = (await repo.watchOrder(id).first)!;
      await expectLater(offline.cancel(order), throwsA(isA<AppException>()));

      final done = _order(status: 'Delivered');
      await expectLater(repo.cancel(done), throwsA(isA<AppException>()));
      expect(backend.calls, isEmpty);
    });
  });
}

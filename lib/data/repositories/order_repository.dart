import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/functions_client.dart';
import '../models/order_model.dart';

/// `orders/{id}` and its `items` for the admin panel.
///
/// Status changes write `status` only; the `onOrderWritten` Cloud Function
/// records `statusHistory`, emails the customer and sends the push. Cancel
/// goes through `adminCancelOrder` so stock and refunds happen on the
/// server.
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore, FunctionsClient? functions})
    : _db = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FunctionsClient();

  final FirebaseFirestore _db;
  final FunctionsClient _functions;

  /// Most recent orders kept live in the list.
  static const liveLimit = 500;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(FirestorePaths.orders);

  bool get canCancel => _functions.isConfigured;

  /// Newest first. Filters and search are applied by the view model, so one
  /// listener serves every filter without composite indexes.
  Stream<List<OrderModel>> watchOrders({int limit = liveLimit}) => _orders
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => OrderModel.fromMap(d.data(), id: d.id)).toList(),
      );

  /// Orders placed from [from] on, newest first. A range and order on
  /// `createdAt` alone, so no composite index is needed.
  Stream<List<OrderModel>> watchOrdersSince(DateTime from) => _orders
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => OrderModel.fromMap(d.data(), id: d.id)).toList(),
      );

  /// Every Pending or Confirmed order, however old (dashboard to-dos).
  Stream<List<OrderModel>> watchOpenOrders() => _orders
      .where(
        'status',
        whereIn: [OrderStatus.pending.label, OrderStatus.confirmed.label],
      )
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => OrderModel.fromMap(d.data(), id: d.id)).toList(),
      );

  Stream<OrderModel?> watchOrder(String id) =>
      _orders.doc(id).snapshots().map((s) {
        final data = s.data();
        return data == null ? null : OrderModel.fromMap(data, id: s.id);
      });

  Future<List<OrderItemModel>> fetchItems(String orderId) async {
    try {
      final snap = await _orders
          .doc(orderId)
          .collection(FirestorePaths.orderItems)
          .get();
      return snap.docs.map((d) => OrderItemModel.fromMap(d.data())).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Moves [order] one step along the happy path. Anything else (skipping,
  /// going back, cancelling) is refused.
  Future<void> advance(OrderModel order, OrderStatus to) async {
    if (order.orderStatus.next != to) {
      throw const AppException('That status change is not allowed.');
    }
    try {
      await _orders.doc(order.id).update({'status': to.label});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Cancels with restock (and a Stripe refund when paid by card). Returns
  /// whether a refund was issued.
  Future<bool> cancel(OrderModel order) async {
    if (!order.orderStatus.canCancel) {
      throw const AppException('This order can no longer be cancelled.');
    }
    if (!canCancel) {
      throw const AppException(
        'Cancelling needs the server. Set FUNCTIONS_BASE_URL and deploy the '
        'Cloud Functions.',
      );
    }
    final res = await _functions.call('adminCancelOrder', {
      'orderId': order.id,
    });
    return res['refunded'] == true;
  }
}

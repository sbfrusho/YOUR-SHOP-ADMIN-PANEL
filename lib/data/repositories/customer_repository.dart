import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/functions_client.dart';
import '../models/address_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

/// Customers (`users/{uid}`, read-only here), their addresses and orders.
/// Disabling an account goes through the `adminSetCustomerDisabled` Cloud
/// Function: only the Admin SDK can disable an Auth account.
class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore, FunctionsClient? functions})
    : _db = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FunctionsClient();

  final FirebaseFirestore _db;
  final FunctionsClient _functions;

  /// Profiles kept live in the list; search runs in memory.
  static const liveLimit = 2000;

  /// Orders shown in a customer's history.
  static const historyLimit = 100;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);

  bool get canDisable => _functions.isConfigured;

  /// Customers (admins left out), sorted by name.
  Stream<List<UserModel>> watchCustomers() => _users
      .limit(liveLimit)
      .snapshots()
      .map(
        (s) =>
            s.docs
                .map((d) => UserModel.fromMap(d.data(), uid: d.id))
                .where((u) => !u.isAdmin)
                .toList()
              ..sort(
                (a, b) => a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                ),
              ),
      );

  Stream<UserModel?> watchCustomer(String uid) =>
      _users.doc(uid).snapshots().map((s) {
        final data = s.data();
        return data == null ? null : UserModel.fromMap(data, uid: s.id);
      });

  /// Newest first. Uses the `customerId` + `createdAt` index the customer
  /// app already deploys.
  Stream<List<OrderModel>> watchOrders(String uid) => _db
      .collection(FirestorePaths.orders)
      .where('customerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(historyLimit)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => OrderModel.fromMap(d.data(), id: d.id)).toList(),
      );

  Future<List<AddressModel>> fetchAddresses(String uid) async {
    try {
      final snap = await _users.doc(uid).collection('addresses').get();
      return snap.docs
          .map((d) => AddressModel.fromMap(d.data(), id: d.id))
          .toList()
        ..sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> setDisabled(String uid, {required bool disabled}) async {
    if (!canDisable) {
      throw const AppException(
        'Disabling accounts needs the server. Set FUNCTIONS_BASE_URL and '
        'deploy the Cloud Functions.',
      );
    }
    await _functions.call('adminSetCustomerDisabled', {
      'uid': uid,
      'disabled': disabled,
    });
  }
}

import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/address_model.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/customer_repository.dart';

/// One customer: profile, saved addresses and order history (live), plus
/// disabling the account through the server.
class CustomerDetailViewModel extends GetxController {
  CustomerDetailViewModel(this._repo, this.uid);

  final CustomerRepository _repo;
  final String uid;

  final Rxn<UserModel> customer = Rxn<UserModel>();
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<AddressModel> addresses = <AddressModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool notFound = false.obs;
  final RxnString error = RxnString();
  final RxBool isUpdating = false.obs;

  final _subs = <StreamSubscription<Object?>>[];

  bool get canDisable => _repo.canDisable;

  /// Orders that count as sales (same rule as the dashboard).
  Iterable<OrderModel> get _sales => orders.where(DashboardStats.isSale);
  int get orderCount => orders.length;
  double get totalSpent => _sales.fold(0, (sum, o) => sum + o.totalPrice);
  DateTime? get lastOrderAt => orders.isEmpty ? null : orders.first.createdAt;
  DateTime? get firstOrderAt => orders.isEmpty ? null : orders.last.createdAt;

  /// Open orders (not delivered or cancelled).
  int get openOrders => orders.where((o) => o.orderStatus.canCancel).length;

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  void listen() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    isLoading.value = true;
    error.value = null;
    _subs
      ..add(
        _repo.watchCustomer(uid).listen((u) {
          customer.value = u;
          notFound.value = u == null || u.isAdmin;
          isLoading.value = false;
        }, onError: _fail),
      )
      ..add(_repo.watchOrders(uid).listen(orders.assignAll, onError: _fail));
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      addresses.assignAll(await _repo.fetchAddresses(uid));
    } on AppException catch (e) {
      AppLogger.error('Addresses failed', e);
    }
  }

  void _fail(Object e) {
    AppLogger.error('Customer detail failed', e);
    error.value = AppException.from(e).message;
    isLoading.value = false;
  }

  void openOrder(OrderModel o) =>
      Get.toNamed<void>(AppRoutes.orderDetailFor(o.id));

  /// The view confirms first. The profile stream shows the new state.
  Future<void> setDisabled(bool disabled) async {
    if (isUpdating.value) return;
    isUpdating.value = true;
    try {
      await _repo.setDisabled(uid, disabled: disabled);
      AppSnackbar.success(
        disabled
            ? 'Account disabled. They are signed out everywhere.'.tr
            : 'Account enabled. They can sign in again.'.tr,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}

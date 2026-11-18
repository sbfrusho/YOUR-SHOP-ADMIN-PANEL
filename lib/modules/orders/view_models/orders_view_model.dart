import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/order_filter.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

/// Live order list with in-memory filters and search.
class OrdersViewModel extends GetxController {
  OrdersViewModel(this._repo);

  final OrderRepository _repo;

  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final Rx<OrderFilter> filter = const OrderFilter().obs;
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  final searchController = TextEditingController();

  StreamSubscription<List<OrderModel>>? _sub;
  Timer? _debounce;

  List<OrderModel> get visible => filter.value.apply(orders);

  /// Orders per status, for the filter chips.
  Map<OrderStatus, int> get counts {
    final out = <OrderStatus, int>{};
    for (final o in orders) {
      out[o.orderStatus] = (out[o.orderStatus] ?? 0) + 1;
    }
    return out;
  }

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  void listen() {
    _sub?.cancel();
    isLoading.value = true;
    error.value = null;
    _sub = _repo.watchOrders().listen(
      (list) {
        orders.assignAll(list);
        isLoading.value = false;
        error.value = null;
      },
      onError: (Object e) {
        AppLogger.error('Orders stream failed', e);
        error.value = AppException.from(e).message;
        isLoading.value = false;
      },
    );
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => filter.value = filter.value.copyWith(query: value),
    );
  }

  void setStatus(OrderStatus? status) =>
      filter.value = filter.value.copyWith(status: () => status);

  void setPayment(PaymentFilter payment) =>
      filter.value = filter.value.copyWith(payment: payment);

  void setRange(DateTime? from, DateTime? to) =>
      filter.value = filter.value.copyWith(range: (from, to));

  void clearFilters() {
    _debounce?.cancel();
    searchController.clear();
    filter.value = const OrderFilter();
  }

  /// Clears every filter, then shows only [status] and [payment] (used by
  /// the dashboard shortcuts).
  void showOnly({
    OrderStatus? status,
    PaymentFilter payment = PaymentFilter.any,
  }) {
    clearFilters();
    filter.value = OrderFilter(status: status, payment: payment);
  }

  void open(OrderModel order) =>
      Get.toNamed<void>(AppRoutes.orderDetailFor(order.id));

  @override
  void onClose() {
    _debounce?.cancel();
    _sub?.cancel();
    searchController.dispose();
    super.onClose();
  }
}

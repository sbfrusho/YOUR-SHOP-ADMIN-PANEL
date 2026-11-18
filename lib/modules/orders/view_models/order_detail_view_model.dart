import 'dart:async';

import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

/// One order, live, with its items and the admin actions.
class OrderDetailViewModel extends GetxController {
  OrderDetailViewModel(this._repo, this.orderId);

  final OrderRepository _repo;
  final String orderId;

  final Rxn<OrderModel> order = Rxn<OrderModel>();
  final RxList<OrderItemModel> items = <OrderItemModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool notFound = false.obs;
  final RxnString error = RxnString();
  final RxBool isUpdating = false.obs;

  StreamSubscription<OrderModel?>? _sub;

  bool get canCancelOnServer => _repo.canCancel;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    _sub?.cancel();
    isLoading.value = true;
    error.value = null;
    _sub = _repo
        .watchOrder(orderId)
        .listen(
          (o) {
            order.value = o;
            notFound.value = o == null;
            isLoading.value = false;
          },
          onError: (Object e) {
            error.value = AppException.from(e).message;
            isLoading.value = false;
          },
        );
    try {
      items.assignAll(await _repo.fetchItems(orderId));
    } on AppException catch (e) {
      error.value = e.message;
    }
  }

  /// Moves the order to its next status. The view confirms first.
  Future<void> advance() async {
    final current = order.value;
    final next = current?.orderStatus.next;
    if (current == null || next == null || isUpdating.value) return;
    isUpdating.value = true;
    try {
      await _repo.advance(current, next);
      AppSnackbar.success(
        'Order marked as @status. The customer is notified.'.trParams({
          'status': next.label.tr,
        }),
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
    } finally {
      isUpdating.value = false;
    }
  }

  /// Cancels with restock and refund. The view confirms first.
  Future<void> cancel() async {
    final current = order.value;
    if (current == null || isUpdating.value) return;
    isUpdating.value = true;
    try {
      final refunded = await _repo.cancel(current);
      AppSnackbar.success(
        refunded
            ? 'Order cancelled, stock restored and the card refunded.'.tr
            : 'Order cancelled and stock restored.'.tr,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

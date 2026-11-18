import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/customer_repository.dart';

enum CustomerFilter {
  all('All'),
  disabled('Disabled');

  const CustomerFilter(this.label);
  final String label;

  bool matches(UserModel u) => this == all || u.disabled;
}

/// Live, searchable customer list (read-only).
class CustomersViewModel extends GetxController {
  CustomersViewModel(this._repo);

  final CustomerRepository _repo;

  final RxList<UserModel> customers = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxString query = ''.obs;
  final Rx<CustomerFilter> filter = CustomerFilter.all.obs;

  StreamSubscription<List<UserModel>>? _sub;

  List<UserModel> get visible {
    final q = query.value.trim().toLowerCase();
    return customers
        .where((u) => filter.value.matches(u) && u.matchesQuery(q))
        .toList();
  }

  int count(CustomerFilter f) => customers.where(f.matches).length;

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  void listen() {
    _sub?.cancel();
    isLoading.value = true;
    error.value = null;
    _sub = _repo.watchCustomers().listen(
      (list) {
        customers.assignAll(list);
        isLoading.value = false;
      },
      onError: (Object e) {
        AppLogger.error('Customers stream failed', e);
        error.value = AppException.from(e).message;
        isLoading.value = false;
      },
    );
  }

  void clearFilters() {
    query.value = '';
    filter.value = CustomerFilter.all;
  }

  void open(UserModel u) =>
      Get.toNamed<void>(AppRoutes.customerDetailFor(u.uid));

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

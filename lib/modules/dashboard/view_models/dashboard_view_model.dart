import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/clock.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/models/order_filter.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../orders/view_models/orders_view_model.dart';
import '../../products/view_models/products_view_model.dart';
import '../../shell/view_models/shell_view_model.dart';

/// Live dashboard: the last 30 days of orders, open orders and products.
/// Line items (for best sellers) are read once per order and cached.
class DashboardViewModel extends GetxController {
  DashboardViewModel(
    this._orders,
    this._catalog,
    this._session, {
    Clock clock = const Clock(),
  }) : _clock = clock;

  final OrderRepository _orders;
  final CatalogRepository _catalog;
  final SessionService _session;
  final Clock _clock;

  DateTime _now() => _clock.now();

  /// Item reads in flight at once.
  static const _parallelReads = 10;

  final Rxn<DashboardStats> stats = Rxn<DashboardStats>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// Best sellers are still being worked out (items loading).
  final RxBool itemsLoading = false.obs;

  List<OrderModel> _recent = const [];
  List<OrderModel> _open = const [];
  List<ProductModel> _products = const [];
  bool _recentLoaded = false, _openLoaded = false, _productsLoaded = false;
  final _items = <String, List<OrderItemModel>>{};
  final _subs = <StreamSubscription<Object?>>[];
  DateTime? _day;

  String get adminName {
    final name = _session.admin.value?.name.trim() ?? '';
    return name.isEmpty ? '' : name.split(' ').first;
  }

  /// Greeting for the local time of day.
  String get greeting {
    final hour = _now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  DateTime get now => _now();

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
    _recentLoaded = _openLoaded = _productsLoaded = false;
    isLoading.value = true;
    error.value = null;
    _day = DashboardStats.dayOf(_now());
    _subs
      ..add(
        _orders.watchOrdersSince(DashboardStats.since(_now())).listen((list) {
          _recent = list;
          _recentLoaded = true;
          _loadItems();
          _recompute();
        }, onError: _fail),
      )
      ..add(
        _orders.watchOpenOrders().listen((list) {
          _open = list;
          _openLoaded = true;
          _recompute();
        }, onError: _fail),
      )
      ..add(
        _catalog.watchProducts().listen((list) {
          _products = list;
          _productsLoaded = true;
          _recompute();
        }, onError: _fail),
      );
  }

  void _fail(Object e) {
    AppLogger.error('Dashboard stream failed', e);
    error.value = AppException.from(e).message;
    isLoading.value = false;
  }

  /// Reads items for sales not seen yet. Orders are immutable once placed,
  /// so each order is read once.
  Future<void> _loadItems() async {
    final missing = _recent
        .where((o) => DashboardStats.isSale(o) && !_items.containsKey(o.id))
        .toList();
    if (missing.isEmpty) return;
    itemsLoading.value = true;
    try {
      for (var i = 0; i < missing.length; i += _parallelReads) {
        final chunk = missing.skip(i).take(_parallelReads);
        await Future.wait([
          for (final o in chunk)
            _orders.fetchItems(o.id).then((items) => _items[o.id] = items),
        ]);
        if (isClosed) return;
        _recompute();
      }
    } on AppException catch (e) {
      AppLogger.error('Dashboard items failed', e);
    } finally {
      if (!isClosed) itemsLoading.value = false;
    }
  }

  void _recompute() {
    if (!_recentLoaded || !_openLoaded || !_productsLoaded) return;
    // Past midnight the 30-day window has moved: query again.
    if (DashboardStats.dayOf(_now()) != _day) {
      listen();
      return;
    }
    stats.value = DashboardStats.compute(
      now: _now(),
      recent: _recent,
      open: _open,
      items: _items,
      products: _products,
    );
    isLoading.value = false;
  }

  // ----- Shortcuts --------------------------------------------------------

  void openOrders({
    OrderStatus? status,
    PaymentFilter payment = PaymentFilter.any,
  }) {
    Get.find<OrdersViewModel>().showOnly(status: status, payment: payment);
    Get.find<ShellViewModel>().section.value = AdminSection.orders;
  }

  void openTodaysOrders() {
    final orders = Get.find<OrdersViewModel>()..clearFilters();
    final today = DashboardStats.dayOf(_now());
    orders.setRange(today, today);
    Get.find<ShellViewModel>().section.value = AdminSection.orders;
  }

  void openLowStock() {
    Get.find<ProductsViewModel>()
      ..clearFilters()
      ..stock.value = StockFilter.low;
    Get.find<ShellViewModel>().section.value = AdminSection.products;
  }

  /// Best sellers can be products that were deleted since.
  bool hasProduct(String id) => _products.any((p) => p.id == id);

  void openProduct(String id) =>
      Get.toNamed<void>(AppRoutes.productEditFor(id));

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}

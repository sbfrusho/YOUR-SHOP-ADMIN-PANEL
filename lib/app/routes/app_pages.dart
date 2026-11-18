import 'package:get/get.dart';

import '../../core/services/clock.dart';
import '../../core/services/image_picker_service.dart';
import '../../data/repositories/order_repository.dart';
import '../../modules/auth/bindings/auth_bindings.dart';
import '../../modules/auth/views/forgot_password_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/catalogue/view_models/catalogue_view_model.dart';
import '../../modules/catalogue/view_models/category_form_view_model.dart';
import '../../modules/catalogue/views/category_form_view.dart';
import '../../modules/dashboard/view_models/dashboard_view_model.dart';
import '../../modules/orders/view_models/order_detail_view_model.dart';
import '../../modules/orders/view_models/orders_view_model.dart';
import '../../modules/orders/views/order_detail_view.dart';
import '../../modules/products/view_models/product_form_view_model.dart';
import '../../modules/products/view_models/products_view_model.dart';
import '../../modules/products/views/product_form_view.dart';
import '../../modules/settings/view_models/settings_view_model.dart';
import '../../modules/settings/views/settings_view.dart';
import '../../modules/shell/view_models/shell_view_model.dart';
import '../../modules/shell/views/shell_view.dart';
import '../../modules/splash/view_models/splash_view_model.dart';
import '../../modules/splash/views/splash_view.dart';
import '../middlewares/admin_middleware.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage<void>(
      name: AppRoutes.splash,
      page: SplashView.new,
      binding: BindingsBuilder.put(() => SplashViewModel(Get.find())),
    ),
    GetPage<void>(
      name: AppRoutes.login,
      page: LoginView.new,
      binding: LoginBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.forgotPassword,
      page: ForgotPasswordView.new,
      binding: ForgotPasswordBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.shell,
      page: ShellView.new,
      binding: BindingsBuilder(() {
        Get.put(ShellViewModel());
        Get.put(
          DashboardViewModel(
            Get.find(),
            Get.find(),
            Get.find(),
            clock: Get.find<Clock>(),
          ),
        );
        Get.put(OrdersViewModel(Get.find()));
        Get.put(ProductsViewModel(Get.find()));
        Get.put(CatalogueViewModel(Get.find(), Get.find()));
      }),
      middlewares: [AdminMiddleware()],
    ),
    GetPage<void>(
      name: AppRoutes.settings,
      page: SettingsView.new,
      binding: BindingsBuilder.put(
        () => SettingsViewModel(Get.find(), Get.find()),
      ),
      middlewares: [AdminMiddleware()],
    ),
    GetPage<void>(
      name: AppRoutes.orderDetail,
      page: OrderDetailView.new,
      binding: BindingsBuilder.put(
        () => OrderDetailViewModel(
          Get.find<OrderRepository>(),
          Get.parameters['id'] ?? '',
        ),
      ),
      middlewares: [AdminMiddleware()],
    ),
    GetPage<void>(
      name: AppRoutes.productNew,
      page: ProductFormView.new,
      binding: BindingsBuilder.put(
        () => ProductFormViewModel(Get.find(), Get.find(), Get.find()),
      ),
      middlewares: [AdminMiddleware()],
    ),
    GetPage<void>(
      name: AppRoutes.productEdit,
      page: ProductFormView.new,
      binding: BindingsBuilder.put(
        () => ProductFormViewModel(
          Get.find(),
          Get.find<ImagePickerService>(),
          Get.find(),
          productId: Get.parameters['id'],
        ),
      ),
      middlewares: [AdminMiddleware()],
    ),
    GetPage<void>(
      name: AppRoutes.categoryNew,
      page: CategoryFormView.new,
      binding: BindingsBuilder.put(
        () => CategoryFormViewModel(Get.find(), Get.find()),
      ),
      middlewares: [AdminMiddleware()],
    ),
    GetPage<void>(
      name: AppRoutes.categoryEdit,
      page: CategoryFormView.new,
      binding: BindingsBuilder.put(
        () => CategoryFormViewModel(
          Get.find(),
          Get.find(),
          categoryId: Get.parameters['id'],
        ),
      ),
      middlewares: [AdminMiddleware()],
    ),
  ];
}

import 'package:get/get.dart';

import '../../data/repositories/order_repository.dart';
import '../../modules/auth/bindings/auth_bindings.dart';
import '../../modules/auth/views/forgot_password_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/orders/view_models/order_detail_view_model.dart';
import '../../modules/orders/view_models/orders_view_model.dart';
import '../../modules/orders/views/order_detail_view.dart';
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
        Get.put(OrdersViewModel(Get.find()));
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
  ];
}

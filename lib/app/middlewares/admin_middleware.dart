import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/services/session_service.dart';
import '../routes/app_routes.dart';

/// Guards every admin route: only a session that passed the `isAdmin`
/// check gets through. Everyone else lands on the login screen.
class AdminMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = Get.find<SessionService>();
    return session.isAdmin ? null : const RouteSettings(name: AppRoutes.login);
  }
}

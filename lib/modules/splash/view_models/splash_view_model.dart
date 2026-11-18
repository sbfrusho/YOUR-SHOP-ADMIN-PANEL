import 'package:get/get.dart';

import '../../../core/services/session_service.dart';

/// Decides where the app opens: the dashboard for a valid admin session,
/// otherwise the login screen.
class SplashViewModel extends GetxController {
  SplashViewModel(this._session);

  final SessionService _session;

  @override
  void onReady() {
    super.onReady();
    route();
  }

  Future<void> route() async {
    final destination = await _session.restore();
    Get.offAllNamed<void>(destination);
  }
}

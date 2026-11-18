import 'package:get/get.dart';

import '../view_models/forgot_password_view_model.dart';
import '../view_models/login_view_model.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoginViewModel(Get.find(), Get.find()));
  }
}

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    final email = Get.arguments;
    Get.lazyPut(
      () => ForgotPasswordViewModel(
        Get.find(),
        initialEmail: email is String ? email : null,
      ),
    );
  }
}

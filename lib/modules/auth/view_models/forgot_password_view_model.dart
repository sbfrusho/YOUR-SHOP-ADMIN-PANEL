import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/repositories/auth_repository.dart';

class ForgotPasswordViewModel extends GetxController {
  ForgotPasswordViewModel(this._authRepo, {String? initialEmail})
    : emailController = TextEditingController(text: initialEmail);

  final AuthRepository _authRepo;

  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController;

  final RxBool isLoading = false.obs;
  final RxBool sent = false.obs;

  Future<void> send() async {
    if (isLoading.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    try {
      await _authRepo.sendPasswordReset(emailController.text.trim());
      sent.value = true;
    } on AppException catch (e) {
      AppSnackbar.error(e.message.tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}

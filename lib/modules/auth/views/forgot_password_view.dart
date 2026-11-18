import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/loading_button.dart';
import '../view_models/forgot_password_view_model.dart';
import 'auth_header.dart';
import 'auth_layout.dart';

class ForgotPasswordView extends GetView<ForgotPasswordViewModel> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      appBar: const AppTopBar(),
      child: Obx(
        () => controller.sent.value
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: 'Check your inbox',
                    subtitle: 'We sent a reset link to @email.'.trParams({
                      'email': controller.emailController.text.trim(),
                    }),
                  ),
                  OutlinedButton(
                    onPressed: Get.back<void>,
                    child: Text('Back to sign in'.tr),
                  ),
                ],
              )
            : Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Reset password',
                      subtitle: "Enter your email and we'll send a reset link.",
                    ),
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                      onFieldSubmitted: (_) => controller.send(),
                      decoration: InputDecoration(
                        labelText: 'Email'.tr,
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(
                      label: 'Send reset link',
                      isLoading: controller.isLoading.value,
                      onPressed: controller.send,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

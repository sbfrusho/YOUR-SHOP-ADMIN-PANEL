import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_button.dart';
import '../view_models/login_view_model.dart';
import 'auth_header.dart';
import 'auth_layout.dart';

class LoginView extends GetView<LoginViewModel> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Form(
        key: controller.formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                title: 'Admin sign in',
                subtitle: 'Manage orders, products and customers.',
              ),
              TextFormField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                decoration: InputDecoration(
                  labelText: 'Email'.tr,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => TextFormField(
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword.value,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => Validators.required(v, field: 'Password'),
                  onFieldSubmitted: (_) => controller.signIn(),
                  decoration: InputDecoration(
                    labelText: 'Password'.tr,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: controller.obscurePassword.value
                          ? 'Show password'.tr
                          : 'Hide password'.tr,
                      onPressed: controller.obscurePassword.toggle,
                      icon: Icon(
                        controller.obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.toNamed<void>(
                    AppRoutes.forgotPassword,
                    arguments: controller.emailController.text.trim(),
                  ),
                  child: Text('Forgot password?'.tr),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => LoadingButton(
                  label: 'Sign in',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.signIn,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Only accounts with admin access can sign in.'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/brand/app_logo.dart';
import '../view_models/splash_view_model.dart';

class SplashView extends GetView<SplashViewModel> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 72, showWordmark: true, axis: Axis.vertical),
            SizedBox(height: 32),
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

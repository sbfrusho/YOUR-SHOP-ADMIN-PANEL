import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../view_models/shell_view_model.dart';

/// Settings shortcut for page top bars on phones. On wide screens the rail
/// has its own, so this renders nothing.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= ShellViewModel.wideBreakpoint) {
      return const SizedBox.shrink();
    }
    return AppIconButton(
      icon: Icons.settings_outlined,
      tooltip: 'Settings',
      onPressed: () => Get.toNamed<void>(AppRoutes.settings),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../view_models/shell_view_model.dart';

/// Page shell for an area that is not built yet: large serif title, the
/// settings button on phones, and what is coming.
class SectionPlaceholderView extends StatelessWidget {
  const SectionPlaceholderView({
    super.key,
    required this.section,
    required this.message,
  });

  final AdminSection section;
  final String message;

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= ShellViewModel.wideBreakpoint;
    return Scaffold(
      appBar: AppTopBar.large(
        title: section.label,
        actions: [
          if (!wide)
            AppIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onPressed: () => Get.toNamed<void>(AppRoutes.settings),
            ),
        ],
      ),
      body: EmptyView(
        icon: section.icon,
        title: 'Coming soon',
        message: message,
      ),
    );
  }
}

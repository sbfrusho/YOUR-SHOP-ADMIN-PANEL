import 'package:flutter/material.dart';

import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../view_models/shell_view_model.dart';
import 'settings_button.dart';

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
    return Scaffold(
      appBar: AppTopBar.large(
        title: section.label,
        actions: const [SettingsButton()],
      ),
      body: EmptyView(
        icon: section.icon,
        title: 'Coming soon',
        message: message,
      ),
    );
  }
}

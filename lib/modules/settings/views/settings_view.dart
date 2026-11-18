import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../view_models/settings_view_model.dart';

class SettingsView extends GetView<SettingsViewModel> {
  const SettingsView({super.key});

  static const maxWidth = 640.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = controller.admin;
    final name = (admin?.name.isNotEmpty ?? false) ? admin!.name : 'Admin';
    return Scaffold(
      appBar: AppTopBar(title: 'Settings'.tr),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    foregroundColor: theme.colorScheme.onTertiaryContainer,
                    child: Text(name.characters.first.toUpperCase()),
                  ),
                  title: Text(name, style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    admin?.email ?? '',
                    style: TextStyle(color: context.palette.mutedText),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Appearance'.tr, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Obx(
                () => SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'.tr),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'.tr),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'.tr),
                    ),
                  ],
                  selected: {controller.themeMode.value},
                  onSelectionChanged: (s) => controller.setThemeMode(s.first),
                ),
              ),
              const SizedBox(height: 32),
              Obx(
                () => OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  onPressed: controller.isSigningOut.value
                      ? null
                      : () => _confirmSignOut(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text('Sign out'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign out?'.tr),
        content: Text('You will need your password to sign in again.'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign out'.tr),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.signOut();
  }
}

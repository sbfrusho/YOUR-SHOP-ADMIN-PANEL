import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Asks before an action. [destructive] paints the confirm button in the
/// error colour. Returns `true` only when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title.tr),
        content: Text(message.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel.tr),
          ),
          TextButton(
            style: destructive
                ? TextButton.styleFrom(foregroundColor: scheme.error)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel.tr),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

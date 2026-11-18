import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_palette.dart';

/// Muted pill with a dot, for order and payment states. Same look as the
/// customer app's `OrderStatusChip`.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      StatusTone.success => palette.success,
      StatusTone.info => palette.info,
      StatusTone.warning => palette.warning,
      StatusTone.error => scheme.error,
      StatusTone.neutral => palette.mutedText,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label.tr,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusTone { success, info, warning, error, neutral }

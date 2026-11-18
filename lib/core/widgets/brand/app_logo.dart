import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../theme/app_typography.dart';
import 'brand_mark_painter.dart';

/// Brand mark, optionally with the "Your Shop" wordmark and a badge.
/// Theme-aware.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.showWordmark = false,
    this.axis = Axis.horizontal,
    this.badge,
  });

  final double size;
  final bool showWordmark;
  final Axis axis;

  /// Small label next to the wordmark, e.g. "Admin".
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: BrandMarkPainter(
          bagColor: scheme.primary,
          letterColor: scheme.surface,
        ),
      ),
    );
    if (!showWordmark) {
      return Semantics(label: AppConfig.appName, child: mark);
    }

    final wordmark = Text(
      AppConfig.appName,
      style: TextStyle(
        fontFamily: AppTypography.serif,
        fontWeight: FontWeight.w700,
        fontSize: size * (axis == Axis.horizontal ? 0.5 : 0.42),
        letterSpacing: -0.5,
        color: scheme.onSurface,
        height: 1,
      ),
    );
    return Semantics(
      label: badge == null ? AppConfig.appName : '${AppConfig.appName} $badge',
      excludeSemantics: true,
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.25, height: size * 0.25),
          wordmark,
          if (badge != null) ...[
            SizedBox(width: size * 0.2, height: size * 0.15),
            _Badge(label: badge!, size: size),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.16,
        vertical: size * 0.05,
      ),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(size),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: (size * 0.22).clamp(10, 16),
          letterSpacing: 0.6,
          color: scheme.onTertiaryContainer,
          height: 1.2,
        ),
      ),
    );
  }
}

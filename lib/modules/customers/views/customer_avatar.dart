import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/models/user_model.dart';

/// Profile photo, or initials on the accent colour.
class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar(this.user, {super.key, this.size = 44});

  final UserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 2);
    if (user.photoUrl.isNotEmpty) {
      return AppNetworkImage(
        user.photoUrl,
        width: size,
        height: size,
        borderRadius: radius,
      );
    }
    final palette = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: 0.35),
          borderRadius: radius,
        ),
        child: Text(
          user.initials,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: size * 0.36,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

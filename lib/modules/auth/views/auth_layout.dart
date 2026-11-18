import 'package:flutter/material.dart';

import '../../../core/widgets/brand/app_logo.dart';

/// Centred, width-limited column for the auth screens. On wide screens the
/// form sits on a card so it doesn't float in empty space.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.appBar});

  final Widget child;
  final PreferredSizeWidget? appBar;

  static const maxWidth = 440.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: AppLogo(size: 44, showWordmark: true, badge: 'ADMIN'),
        ),
        const SizedBox(height: 40),
        child,
      ],
    );
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: wide
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: content,
                      ),
                    )
                  : content,
            ),
          ),
        ),
      ),
    );
  }
}

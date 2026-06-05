import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

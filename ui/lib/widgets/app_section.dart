import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        child,
      ],
    );
  }
}

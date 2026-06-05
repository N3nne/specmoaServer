import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadows.blueTint,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.onPrimary, size: 20),
                  const SizedBox(width: AppSpacing.x2),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.onPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

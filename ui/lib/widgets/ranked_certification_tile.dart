import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RankedCertificationTile extends StatelessWidget {
  const RankedCertificationTile({
    required this.rank,
    required this.title,
    required this.organization,
    this.badge,
    this.trendingUp = false,
    super.key,
  });

  final int rank;
  final String title;
  final String organization;
  final String? badge;
  final bool trendingUp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: textTheme.titleLarge?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  organization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x2,
                vertical: AppSpacing.x1,
              ),
              decoration: BoxDecoration(
                color: trendingUp
                    ? AppColors.errorContainer
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                children: [
                  Icon(
                    trendingUp
                        ? Icons.trending_up_rounded
                        : Icons.new_releases_rounded,
                    size: 13,
                    color: trendingUp ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    badge!,
                    style: textTheme.labelSmall?.copyWith(
                      color: trendingUp ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

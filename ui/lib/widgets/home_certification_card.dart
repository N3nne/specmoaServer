import 'package:flutter/material.dart';

import '../models/home_data.dart';
import '../theme/app_theme.dart';

class HomeCertificationCard extends StatelessWidget {
  const HomeCertificationCard({
    required this.item,
    this.onTap,
    super.key,
  });

  final HomeUserCertification item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final certified = item.certified;
    final accent = certified ? AppColors.tertiary : AppColors.primary;
    final stateLabel = certified ? '취득' : '준비중';
    final statusText = certified
        ? '취득 완료'
        : item.nextExam == null
            ? '시험 일정 확인 중'
            : 'D-${item.nextExam!.dDay}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.x5),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                certified
                    ? Icons.workspace_premium_rounded
                    : Icons.event_available_rounded,
                color: accent,
              ),
            ),
            const SizedBox(width: AppSpacing.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.certification.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Wrap(
                    spacing: AppSpacing.x2,
                    runSpacing: AppSpacing.x1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusTag(
                        label: stateLabel,
                        color: accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3,
                vertical: AppSpacing.x2,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                statusText,
                style: textTheme.labelMedium?.copyWith(color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/certification.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.status,
    super.key,
  });

  final CertificationStatus status;

  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      CertificationStatus.certified => (
          label: '인증 완료',
          icon: Icons.workspace_premium_rounded,
          color: AppColors.tertiary,
          background: AppColors.tertiary.withValues(alpha: 0.1),
        ),
      CertificationStatus.scheduled => (
          label: '시험 예정',
          icon: Icons.event_available_rounded,
          color: AppColors.secondary,
          background: AppColors.secondaryContainer,
        ),
      CertificationStatus.inProgress => (
          label: '진행 중',
          icon: Icons.trending_up_rounded,
          color: AppColors.primary,
          background: AppColors.primary.withValues(alpha: 0.1),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: data.color),
          const SizedBox(width: AppSpacing.x1),
          Text(
            data.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: data.color,
                ),
          ),
        ],
      ),
    );
  }
}

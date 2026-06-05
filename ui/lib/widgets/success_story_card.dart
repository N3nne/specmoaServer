import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SuccessStoryCard extends StatelessWidget {
  const SuccessStoryCard({
    required this.title,
    required this.subtitle,
    required this.likes,
    required this.comments,
    required this.views,
    this.studyTime = '평일 3시간, 주말 8시간 (총 3주)',
    this.studyMethod = '민트책 이론 1회독 + 기출 5개년 무한 반복',
    this.score = '82점 (합격 기준 60점)',
    this.dateLabel = '오늘',
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final int likes;
  final int comments;
  final int views;
  final String studyTime;
  final String studyMethod;
  final String score;
  final String dateLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x5,
            AppSpacing.x5,
            AppSpacing.x4,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E7F4),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.storage_rounded,
                      color: Color(0xFF8E3EB0),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x5),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.42),
              ),
              const SizedBox(height: AppSpacing.x4),
              _InfoLine(
                icon: Icons.schedule_rounded,
                label: '공부 시간',
                value: studyTime,
              ),
              const SizedBox(height: AppSpacing.x3),
              _InfoLine(
                icon: Icons.menu_book_rounded,
                label: '공부 방법',
                value: studyMethod,
              ),
              const SizedBox(height: AppSpacing.x3),
              _InfoLine(
                icon: Icons.fact_check_outlined,
                label: '합격 성적',
                value: score,
              ),
              const Spacer(),
              Row(
                children: [
                  _MetaIcon(
                    icon: Icons.favorite_rounded,
                    value: likes,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.x4),
                  _MetaIcon(
                    icon: Icons.mode_comment_outlined,
                    value: comments,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.x4),
                  _MetaIcon(
                    icon: Icons.visibility_outlined,
                    value: views,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  Text(
                    dateLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.72,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
          color: AppColors.brandBlue.withValues(alpha: 0.78),
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.x2),
        Text(
          '$value',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

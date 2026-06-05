import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CommunityQuestionCard extends StatelessWidget {
  const CommunityQuestionCard({
    required this.author,
    required this.question,
    required this.comments,
    required this.likes,
    required this.views,
    this.certificationName = '정보처리기사',
    this.questionPreview = '',
    this.answerAuthorName,
    this.answerPreview = '',
    this.createdAgo = '30분 전',
    this.onTap,
    super.key,
  });

  final String author;
  final String question;
  final int comments;
  final int likes;
  final int views;
  final String certificationName;
  final String questionPreview;
  final String? answerAuthorName;
  final String? answerPreview;
  final String createdAgo;
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
                  const _QaMark(label: 'Q.', color: AppColors.error),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                          ),
                        ),
                        if (questionPreview.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.x2),
                          Text(
                            questionPreview.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.48,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (answerPreview?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: AppSpacing.x4),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.42),
                ),
                const SizedBox(height: AppSpacing.x4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _QaMark(label: 'A.', color: AppColors.primary),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.x2),
                              Expanded(
                                child: Text(
                                  "멘토 '${answerAuthorName ?? author}'",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x2),
                          Text(
                            answerPreview!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.58,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
                    createdAgo,
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

class _QaMark extends StatelessWidget {
  const _QaMark({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
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

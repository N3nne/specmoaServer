import 'package:flutter/material.dart';

import '../models/certification.dart';
import '../theme/app_theme.dart';
import 'status_chip.dart';

class CertificationCard extends StatefulWidget {
  const CertificationCard({
    required this.certification,
    this.compact = false,
    super.key,
  });

  final Certification certification;
  final bool compact;

  @override
  State<CertificationCard> createState() => _CertificationCardState();
}

class _CertificationCardState extends State<CertificationCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final certification = widget.certification;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.x5),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: _pressed ? AppShadows.soft : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certification.category,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          certification.title,
                          style: textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: certification.status),
                ],
              ),
              if (!widget.compact) ...[
                const SizedBox(height: AppSpacing.x3),
                Text(
                  certification.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x5),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: certification.progress,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: [
                  Text(
                    '${(certification.progress * 100).round()}%',
                    style: textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    certification.examDate,
                    style: textTheme.labelMedium?.copyWith(
                      color:
                          certification.status == CertificationStatus.certified
                              ? AppColors.tertiary
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Text(
                    '${certification.score}점',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

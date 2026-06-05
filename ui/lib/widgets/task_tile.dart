import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    super.key,
  });

  final StudyTask task;

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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: task.completed
                  ? AppColors.tertiary.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Icon(
              task.completed
                  ? Icons.check_rounded
                  : Icons.hourglass_top_rounded,
              color: task.completed ? AppColors.tertiary : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  task.caption,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Text(
            '${task.minutes}분',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

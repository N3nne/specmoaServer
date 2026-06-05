import 'package:flutter/material.dart';

import '../models/home_data.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_page.dart';

class SuccessStoryDetailScreen extends StatelessWidget {
  const SuccessStoryDetailScreen({
    required this.story,
    super.key,
  });

  final HomeSuccessStory story;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StoryHeaderDelegate(onBack: Navigator.of(context).pop),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.x4),
                    _StoryHeroCard(story: story),
                    const SizedBox(height: AppSpacing.x4),
                    _StudySummaryCard(story: story),
                    const SizedBox(height: AppSpacing.x4),
                    _BodyCard(story: story),
                    const SizedBox(height: AppSpacing.x4),
                    _ReactionBar(story: story),
                    const SizedBox(height: 118),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StoryHeaderDelegate({required this.onBack});

  final VoidCallback onBack;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.surface.withValues(alpha: 0.94),
      child: ResponsivePage(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
        child: Row(
          children: [
            IconButton(
              tooltip: '뒤로가기',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: AppSpacing.x1),
            Text(
              '합격 후기',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StoryHeaderDelegate oldDelegate) =>
      oldDelegate.onBack != onBack;
}

class _StoryHeroCard extends StatelessWidget {
  const _StoryHeroCard({required this.story});

  final HomeSuccessStory story;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1E7F4),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.storage_rounded,
              color: Color(0xFF8E3EB0),
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CertificationBadge(label: story.certificationName),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  story.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  story.description.isEmpty
                      ? '통계 포기자도 가능한 데이터 분석'
                      : story.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  '${story.authorName} · 오늘 · 조회 ${story.viewCount}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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

class _StudySummaryCard extends StatelessWidget {
  const _StudySummaryCard({required this.story});

  final HomeSuccessStory story;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.schedule_rounded,
            label: '공부 시간',
            value: '${story.studyPeriodDays}일 집중',
          ),
          const SizedBox(height: AppSpacing.x4),
          _SummaryRow(
            icon: Icons.menu_book_rounded,
            label: '공부 방법',
            value: story.studyMethod.isEmpty ? story.body : story.studyMethod,
          ),
          const SizedBox(height: AppSpacing.x4),
          _SummaryRow(
            icon: Icons.fact_check_outlined,
            label: '합격 성적',
            value:
                story.score.isEmpty ? '${story.examAttempt} 합격' : story.score,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
        Icon(icon, color: AppColors.brandBlue, size: 22),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({required this.story});

  final HomeSuccessStory story;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '본문',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            _bodyText(story),
            style: textTheme.bodyMedium?.copyWith(height: 1.68),
          ),
        ],
      ),
    );
  }

  String _bodyText(HomeSuccessStory story) {
    if (!story.dummy && story.body.isNotEmpty) {
      return story.body;
    }

    return '처음에는 통계 용어가 낯설어서 이론서를 끝까지 읽는 것부터 막혔습니다. 그래서 모든 내용을 깊게 이해하려고 하기보다, 기출에 반복해서 나오는 개념을 먼저 표시하고 문제를 풀면서 익히는 방식으로 바꿨어요.\n\n1주차에는 이론을 빠르게 훑고 자주 나오는 공식과 용어를 정리했습니다. 2주차부터는 기출을 매일 풀면서 틀린 문제만 따로 모았고, 마지막 주에는 오답 위주로 반복했습니다.\n\n가장 도움이 됐던 건 공부 시간을 길게 잡는 것보다 매일 같은 시간에 문제를 푸는 루틴이었습니다. 비전공자라도 출제 패턴을 빨리 잡으면 충분히 합격권까지 갈 수 있다고 느꼈습니다.';
  }
}

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({required this.story});

  final HomeSuccessStory story;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          _ActionPill(
            icon: Icons.favorite_rounded,
            label: '${story.likeCount}',
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.x2),
          _ActionPill(
            icon: Icons.mode_comment_outlined,
            label: '${story.commentCount}',
            color: AppColors.onSurfaceVariant,
          ),
          const Spacer(),
          IconButton(
            tooltip: '저장',
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border_rounded),
          ),
        ],
      ),
    );
  }
}

class _CertificationBadge extends StatelessWidget {
  const _CertificationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.x1),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/certification_search_data.dart';
import '../models/home_data.dart';
import '../services/community_qna_api_client.dart';
import '../services/home_api_client.dart';
import '../services/success_story_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo_icon.dart';
import '../widgets/community_question_card.dart';
import '../widgets/home_certification_card.dart';
import '../widgets/home_search_hero.dart';
import '../widgets/responsive_page.dart';
import '../widgets/success_story_card.dart';
import 'certification_detail_screen.dart';
import 'certification_register_screen.dart';
import 'community_question_detail_screen.dart';
import 'community_questions_screen.dart';
import 'popular_certifications_screen.dart';
import 'success_stories_screen.dart';
import 'success_story_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.userId,
    super.key,
  });

  final String? userId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = _fetchHome();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _homeFuture = _fetchHome();
    }
  }

  Future<HomeData> _fetchHome() {
    return const HomeApiClient().fetchHome(userId: widget.userId);
  }

  Future<void> _refreshHome() async {
    final nextFuture = _fetchHome();
    setState(() => _homeFuture = nextFuture);
    try {
      await nextFuture;
    } catch (_) {
      // FutureBuilder displays the error state; keep refresh gestures quiet.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refreshHome,
        child: FutureBuilder<HomeData>(
          future: _homeFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            final data = snapshot.data;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeHeaderDelegate(onRefresh: _refreshHome),
                ),
                SliverToBoxAdapter(
                  child: ResponsivePage(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.x4),
                        HomeSearchHero(
                          onCertificationSelected:
                              _openSearchedCertificationDetail,
                        ),
                        const SizedBox(height: AppSpacing.x8),
                        if (snapshot.hasError)
                          const _HomeError()
                        else if (loading)
                          const _HomeLoading()
                        else ...[
                          _MyCertificationsSection(
                            items: data?.myCertifications ?? const [],
                            onAdd: _openCertificationRegister,
                            onOpen: _openUserCertificationDetail,
                          ),
                          const SizedBox(height: AppSpacing.x8),
                          _PopularCertificationsSection(
                            items: data?.popularCertifications ?? const [],
                            onOpen: _openPopularCertificationDetail,
                            onViewAll: _openPopularCertifications,
                          ),
                          const SizedBox(height: AppSpacing.x8),
                          _PopularQuestionsSection(
                            items: data?.popularQuestions ?? const [],
                            onOpen: _openCommunityQuestion,
                            onViewMore: _openCommunityQuestions,
                          ),
                          const SizedBox(height: AppSpacing.x8),
                          _SuccessStoriesSection(
                            items: data?.successStories ?? const [],
                            onOpen: _openSuccessStory,
                            onViewMore: _openSuccessStories,
                          ),
                        ],
                        const SizedBox(height: 118),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCertificationRegister() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CertificationRegisterScreen(),
      ),
    );
    if (mounted) {
      _refreshHome();
    }
  }

  void _openCertificationDetail({
    String? id,
    String name = '정보처리기사',
    String category = '정보기술',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CertificationDetailScreen(
          certificationId: id,
          certificationName: name,
          category: category,
        ),
      ),
    );
  }

  void _openUserCertificationDetail(HomeUserCertification item) {
    _openCertificationDetail(
      id: item.certification.id,
      name: item.certification.name,
      category: item.certification.category,
    );
  }

  void _openPopularCertificationDetail(HomePopularCertification item) {
    _openCertificationDetail(
      id: item.id,
      name: item.name,
      category: item.category,
    );
  }

  void _openSearchedCertificationDetail(CertificationSearchResult item) {
    _openCertificationDetail(
      id: item.id,
      name: item.name,
      category: item.category,
    );
  }

  void _openPopularCertifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PopularCertificationsScreen(),
      ),
    );
  }

  Future<void> _openCommunityQuestion(HomeCommunityPost post) async {
    var targetPost = post;
    if (!post.dummy) {
      try {
        final item = await const CommunityQnaApiClient().recordView(post.id);
        targetPost = HomeCommunityPost(
          id: item.id,
          title: item.title,
          body: item.body,
          certificationName: item.certificationName,
          authorName: item.authorName,
          likeCount: item.likeCount,
          commentCount: item.answerCount,
          viewCount: item.viewCount,
          acceptedAnswerBody: item.acceptedAnswer?.body ?? '',
          acceptedAnswerAuthorName: item.acceptedAnswer?.authorName ?? '익명',
          dummy: item.dummy,
        );
      } catch (_) {
        targetPost = HomeCommunityPost(
          id: post.id,
          title: post.title,
          body: post.body,
          certificationName: post.certificationName,
          authorName: post.authorName,
          likeCount: post.likeCount,
          commentCount: post.commentCount,
          viewCount: post.viewCount + 1,
          acceptedAnswerBody: post.acceptedAnswerBody,
          acceptedAnswerAuthorName: post.acceptedAnswerAuthorName,
          dummy: post.dummy,
        );
      }
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityQuestionDetailScreen(post: targetPost),
      ),
    );
  }

  void _openCommunityQuestions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CommunityQuestionsScreen(),
      ),
    );
  }

  Future<void> _openSuccessStory(HomeSuccessStory story) async {
    var targetStory = story;
    if (!story.dummy) {
      try {
        final item = await const SuccessStoryApiClient().recordView(story.id);
        targetStory = HomeSuccessStory(
          id: item.id,
          title: item.title,
          description: item.subtitle.isEmpty ? item.body : item.subtitle,
          body: item.body,
          certificationName: item.certificationName,
          studyPeriodDays: item.studyPeriodDays,
          studyMethod: item.studyMethod,
          score: item.score,
          examAttempt: item.examAttempt,
          authorName: item.authorName,
          likeCount: item.likeCount,
          commentCount: item.commentCount,
          viewCount: item.viewCount,
          dummy: item.dummy,
        );
      } catch (_) {
        targetStory = HomeSuccessStory(
          id: story.id,
          title: story.title,
          description: story.description,
          body: story.body,
          certificationName: story.certificationName,
          studyPeriodDays: story.studyPeriodDays,
          studyMethod: story.studyMethod,
          score: story.score,
          examAttempt: story.examAttempt,
          authorName: story.authorName,
          likeCount: story.likeCount,
          commentCount: story.commentCount,
          viewCount: story.viewCount + 1,
          dummy: story.dummy,
        );
      }
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SuccessStoryDetailScreen(story: targetStory),
      ),
    );
  }

  void _openSuccessStories() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SuccessStoriesScreen(),
      ),
    );
  }
}

class _MyCertificationsSection extends StatefulWidget {
  const _MyCertificationsSection({
    required this.items,
    required this.onAdd,
    required this.onOpen,
  });

  final List<HomeUserCertification> items;
  final VoidCallback onAdd;
  final ValueChanged<HomeUserCertification> onOpen;

  @override
  State<_MyCertificationsSection> createState() =>
      _MyCertificationsSectionState();
}

class _MyCertificationsSectionState extends State<_MyCertificationsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleItems =
        _expanded ? widget.items : widget.items.take(3).toList(growable: false);
    final hiddenCount = widget.items.length - visibleItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: '내 자격증', actionLabel: '', onPressed: () {}),
        const SizedBox(height: AppSpacing.x3),
        for (final item in visibleItems) ...[
          HomeCertificationCard(item: item, onTap: () => widget.onOpen(item)),
          const SizedBox(height: AppSpacing.x3),
        ],
        if (widget.items.length > 3) ...[
          _ShowMoreCertificationsButton(
            expanded: _expanded,
            hiddenCount: hiddenCount,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
        _AddCertificationCard(onTap: widget.onAdd),
      ],
    );
  }
}

class _ShowMoreCertificationsButton extends StatelessWidget {
  const _ShowMoreCertificationsButton({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.x1),
              Text(
                expanded ? '접기' : '더보기 $hiddenCount개',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularCertificationsSection extends StatelessWidget {
  const _PopularCertificationsSection({
    required this.items,
    required this.onOpen,
    required this.onViewAll,
  });

  final List<HomePopularCertification> items;
  final ValueChanged<HomePopularCertification> onOpen;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '인기 자격증',
          actionLabel: '전체보기',
          onPressed: onViewAll,
        ),
        const SizedBox(height: AppSpacing.x3),
        _HorizontalCardScroller(
          height: 188,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _PopularCertificationCard(
                  item: items[index],
                  onTap: () => onOpen(items[index]),
                ),
                if (index != items.length - 1)
                  const SizedBox(width: AppSpacing.x3),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PopularQuestionsSection extends StatelessWidget {
  const _PopularQuestionsSection({
    required this.items,
    required this.onOpen,
    required this.onViewMore,
  });

  final List<HomeCommunityPost> items;
  final ValueChanged<HomeCommunityPost> onOpen;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '인기 질문',
          actionLabel: '더보기',
          onPressed: onViewMore,
        ),
        const SizedBox(height: AppSpacing.x3),
        _HorizontalCardScroller(
          height: 276,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                SizedBox(
                  width: 260,
                  child: CommunityQuestionCard(
                    author: items[index].authorName,
                    question: items[index].title,
                    certificationName: items[index].certificationName,
                    questionPreview: items[index].body,
                    answerAuthorName: items[index].acceptedAnswerAuthorName,
                    answerPreview: items[index].acceptedAnswerBody.isEmpty
                        ? ''
                        : items[index].acceptedAnswerBody,
                    comments: items[index].commentCount,
                    likes: items[index].likeCount,
                    views: items[index].viewCount,
                    onTap: () => onOpen(items[index]),
                  ),
                ),
                if (index != items.length - 1)
                  const SizedBox(width: AppSpacing.x3),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SuccessStoriesSection extends StatelessWidget {
  const _SuccessStoriesSection({
    required this.items,
    required this.onOpen,
    required this.onViewMore,
  });

  final List<HomeSuccessStory> items;
  final ValueChanged<HomeSuccessStory> onOpen;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '합격 후기',
          actionLabel: '더보기',
          onPressed: onViewMore,
        ),
        const SizedBox(height: AppSpacing.x3),
        _HorizontalCardScroller(
          height: 310,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                SizedBox(
                  width: 330,
                  child: SuccessStoryCard(
                    title: items[index].title,
                    subtitle: items[index].description,
                    likes: items[index].likeCount,
                    comments: items[index].commentCount,
                    views: items[index].viewCount,
                    studyTime: '${items[index].studyPeriodDays}일 집중',
                    studyMethod: items[index].studyMethod.isEmpty
                        ? items[index].body
                        : items[index].studyMethod,
                    score: items[index].score.isEmpty
                        ? '${items[index].examAttempt} 합격'
                        : items[index].score,
                    onTap: () => onOpen(items[index]),
                  ),
                ),
                if (index != items.length - 1)
                  const SizedBox(width: AppSpacing.x3),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HorizontalCardScroller extends StatelessWidget {
  const _HorizontalCardScroller({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          right: AppSpacing.x5,
          bottom: AppSpacing.x3,
        ),
        child: child,
      ),
    );
  }
}

class _PopularCertificationCard extends StatelessWidget {
  const _PopularCertificationCard({
    required this.item,
    required this.onTap,
  });

  final HomePopularCertification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        width: 178,
        padding: const EdgeInsets.all(AppSpacing.x4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${item.rank}',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall,
            ),
            const Spacer(),
            Text(
              item.category.isEmpty ? '자격증' : item.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.x1),
            Text(
              '응시자 ${_formatCount(item.examineeCount)}명',
              style: textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCertificationCard extends StatelessWidget {
  const _AddCertificationCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x5,
            vertical: AppSpacing.x5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.52),
              ),
              const SizedBox(width: AppSpacing.x2),
              Text(
                '자격증 추가하기',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.x12),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        '홈 데이터를 불러오지 못했어요. 서버가 실행 중인지 확인해주세요.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeaderDelegate({required this.onRefresh});

  final Future<void> Function() onRefresh;

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
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRect(
      child: ColoredBox(
        color: colorScheme.surface.withValues(alpha: 0.92),
        child: ResponsivePage(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
          child: Row(
            children: [
              const AppLogoIcon(size: 32),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  '스펙모아.zip',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: '검색',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.x1),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: Text(title, style: textTheme.titleMedium)),
        if (actionLabel.isNotEmpty)
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
            ),
            child: Text(actionLabel),
          ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.md),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 8;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _formatCount(int value) {
  if (value >= 10000) {
    final fixed = (value / 10000).toStringAsFixed(1);
    final compact =
        fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
    return '$compact만';
  }

  return '$value';
}

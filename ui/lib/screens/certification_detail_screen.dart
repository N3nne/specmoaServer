import 'package:flutter/material.dart';

import '../models/community_qna_data.dart';
import '../models/certification_detail_data.dart';
import '../models/home_data.dart';
import '../models/success_story_list_data.dart';
import '../services/community_qna_api_client.dart';
import '../services/certification_detail_api_client.dart';
import '../services/success_story_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_gradient_button.dart';
import '../widgets/community_question_card.dart';
import '../widgets/responsive_page.dart';
import '../widgets/success_story_card.dart';
import 'community_question_detail_screen.dart';
import 'success_story_detail_screen.dart';

class CertificationDetailScreen extends StatefulWidget {
  const CertificationDetailScreen({
    this.certificationId,
    this.certificationName = '정보처리기사',
    this.category = '정보기술',
    super.key,
  });

  final String? certificationId;
  final String certificationName;
  final String category;

  @override
  State<CertificationDetailScreen> createState() =>
      _CertificationDetailScreenState();
}

class _CertificationDetailScreenState extends State<CertificationDetailScreen> {
  int _selectedTab = 0;
  late final Future<CertificationDetailData?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = widget.certificationId == null
        ? Future.value(null)
        : const CertificationDetailApiClient()
            .fetchDetailPage(widget.certificationId!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CertificationDetailData?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final name = detail?.name ?? widget.certificationName;
        final category = detail?.category ?? widget.category;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _DetailHeaderDelegate(title: name),
                ),
                SliverToBoxAdapter(
                  child: ResponsivePage(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.x5),
                        _HeroInfoCard(
                          certificationName: name,
                          category: category,
                          nextExam: _nextExam(detail?.schedules ?? const []),
                          loading:
                              snapshot.connectionState != ConnectionState.done,
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        _DetailTabs(
                          selectedIndex: _selectedTab,
                          onChanged: (index) =>
                              setState(() => _selectedTab = index),
                        ),
                        const SizedBox(height: AppSpacing.x6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: KeyedSubtree(
                            key: ValueKey(_selectedTab),
                            child: switch (_selectedTab) {
                              0 => _InfoTabContent(
                                  certificationName: name,
                                  category: category,
                                  detail: detail,
                                  loading: snapshot.connectionState !=
                                      ConnectionState.done,
                                  error: snapshot.error,
                                ),
                              1 => _ScheduleTabContent(
                                  schedules: detail?.schedules ?? const [],
                                ),
                              2 => _CertificationQuestionsTab(
                                  certificationId: widget.certificationId,
                                  certificationName: name,
                                ),
                              _ => _CertificationSuccessStoriesTab(
                                  certificationId: widget.certificationId,
                                  certificationName: name,
                                ),
                            },
                          ),
                        ),
                        const SizedBox(height: 118),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DetailHeaderDelegate({required this.title});

  final String title;

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
      color: AppColors.surface.withValues(alpha: 0.92),
      child: ResponsivePage(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primary,
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DetailHeaderDelegate oldDelegate) =>
      title != oldDelegate.title;
}

class _HeroInfoCard extends StatelessWidget {
  const _HeroInfoCard({
    required this.certificationName,
    required this.category,
    required this.nextExam,
    required this.loading,
  });

  final String certificationName;
  final String category;
  final CertificationScheduleData? nextExam;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -46,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.16),
                borderRadius:
                    const BorderRadius.only(bottomLeft: Radius.circular(96)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeroPill(
                    label: loading ? '불러오는 중' : '상세 정보',
                    background: AppColors.secondaryContainer,
                    foreground: AppColors.onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  if (nextExam?.startDate != null)
                    _HeroPill(
                      label: 'D-${_daysUntil(nextExam!.startDate!)}',
                      background: AppColors.errorContainer,
                      foreground: AppColors.error,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x5),
              Text(certificationName, style: textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.x1),
              Text(
                category.isEmpty ? '자격증' : category,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              AppGradientButton(
                label: '학습 시작하기',
                icon: Icons.menu_book_rounded,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.x3),
              Center(
                child: Text(
                  nextExam?.startDate == null
                      ? '등록된 시험 일정이 없습니다'
                      : '다음 일정: ${_formatDate(nextExam!.startDate!)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const tabs = ['정보', '일정', '질문', '합격수기'];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceHigh)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
                  decoration: BoxDecoration(
                    border: i == selectedIndex
                        ? const Border(
                            bottom:
                                BorderSide(color: AppColors.primary, width: 2),
                          )
                        : null,
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: i == selectedIndex
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoTabContent extends StatelessWidget {
  const _InfoTabContent({
    required this.certificationName,
    required this.category,
    required this.detail,
    required this.loading,
    required this.error,
  });

  final String certificationName;
  final String category;
  final CertificationDetailData? detail;
  final bool loading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x10),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return const _InfoMessage(
        title: '상세 정보를 불러오지 못했어요',
        description: '잠시 후 다시 시도해주세요.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoSection(
          icon: Icons.info_rounded,
          title: '자격증 소개',
          child: _LongText(
            text: detail?.description ??
                '$certificationName은(는) $category 분야와 연결된 자격증입니다.',
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text('응시 자격 / 경력', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x3),
        _InfoSection(
          icon: Icons.school_rounded,
          title: '응시 자격',
          child: _LongText(
            text: detail?.eligibility ?? '등록된 응시 자격 정보가 없습니다.',
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text('시험과목 정보', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x3),
        _InfoSection(
          icon: Icons.fact_check_rounded,
          title: '시험과목 및 배점',
          child: _ExamInfoTable(
            text: detail?.examSubjects ?? '등록된 시험과목 정보가 없습니다.',
          ),
        ),
      ],
    );
  }
}

class _ScheduleTabContent extends StatefulWidget {
  const _ScheduleTabContent({required this.schedules});

  final List<CertificationScheduleData> schedules;

  @override
  State<_ScheduleTabContent> createState() => _ScheduleTabContentState();
}

class _ScheduleTabContentState extends State<_ScheduleTabContent> {
  late int _selectedYear;
  late int _selectedMonth;

  List<int> get _years {
    final years = widget.schedules
        .map((schedule) => schedule.startDate?.year)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    return years;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final years = _years;
    _selectedYear = years.contains(now.year)
        ? now.year
        : years.isNotEmpty
            ? years.first
            : now.year;
    _selectedMonth = _firstMonthForYear(_selectedYear) ?? now.month;
  }

  @override
  void didUpdateWidget(covariant _ScheduleTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schedules != widget.schedules) {
      final years = _years;
      if (years.isNotEmpty && !years.contains(_selectedYear)) {
        _selectedYear = years.first;
        _selectedMonth = _firstMonthForYear(_selectedYear) ?? 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final years = _years;
    final monthSchedules = widget.schedules
        .where((schedule) =>
            _isScheduleInMonth(schedule, _selectedYear, _selectedMonth))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.x5),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary),
              const SizedBox(width: AppSpacing.x3),
              Expanded(child: Text('시험 일정', style: textTheme.titleLarge)),
              if (years.isNotEmpty)
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    items: [
                      for (final year in years)
                        DropdownMenuItem(
                          value: year,
                          child: Text('$year년'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedYear = value;
                        _selectedMonth = _firstMonthForYear(value) ?? 1;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        _CalendarCard(
          year: _selectedYear,
          month: _selectedMonth,
          schedules: widget.schedules,
          onPreviousMonth: _selectedMonth == 1
              ? null
              : () => setState(() => _selectedMonth -= 1),
          onNextMonth: _selectedMonth == 12
              ? null
              : () => setState(() => _selectedMonth += 1),
        ),
        const SizedBox(height: AppSpacing.x4),
        if (widget.schedules.isEmpty)
          const _InfoMessage(
            title: '등록된 시험 일정이 없습니다',
            description: '캘린더는 유지하고, DB에 일정이 들어오면 날짜가 강조됩니다.',
          )
        else if (monthSchedules.isEmpty)
          const _InfoMessage(
            title: '이 달에는 일정이 없습니다',
            description: '상단 화살표로 다른 달을 확인해보세요.',
          )
        else
          _ScheduleCarousel(schedules: monthSchedules),
      ],
    );
  }

  int? _firstMonthForYear(int year) {
    final months = widget.schedules
        .map((schedule) => schedule.startDate)
        .whereType<DateTime>()
        .where((date) => date.year == year)
        .map((date) => date.month)
        .toList()
      ..sort();
    return months.isEmpty ? null : months.first;
  }
}

class _CertificationQuestionsTab extends StatelessWidget {
  const _CertificationQuestionsTab({
    required this.certificationId,
    required this.certificationName,
  });

  final String? certificationId;
  final String certificationName;

  @override
  Widget build(BuildContext context) {
    if (certificationId == null || certificationId!.isEmpty) {
      return const _InfoMessage(
        title: '질문을 불러올 수 없습니다',
        description: '자격증 정보가 연결되지 않았습니다.',
      );
    }

    return FutureBuilder<CommunityQnaPage>(
      future: const CommunityQnaApiClient().fetchQuestions(
        query: certificationName,
        certificationId: certificationId,
        sort: 'popular',
        limit: 10,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _TabLoading();
        }
        if (snapshot.hasError) {
          return const _InfoMessage(
            title: '질문을 불러오지 못했어요',
            description: '잠시 후 다시 시도해주세요.',
          );
        }

        final items = snapshot.data?.items ?? const [];
        if (items.isEmpty) {
          return _InfoMessage(
            title: '아직 연결된 질문이 없습니다',
            description: '$certificationName 질문이 등록되면 이곳에 표시됩니다.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TabSectionHeader(
              icon: Icons.forum_rounded,
              title: '$certificationName 질문',
              count: items.length,
            ),
            const SizedBox(height: AppSpacing.x3),
            for (final item in items) ...[
              SizedBox(
                height: 276,
                child: CommunityQuestionCard(
                  author: item.authorName,
                  question: item.title,
                  certificationName: item.certificationName.isEmpty
                      ? certificationName
                      : item.certificationName,
                  comments: item.answerCount,
                  likes: item.likeCount,
                  views: item.viewCount,
                  questionPreview: item.body,
                  answerAuthorName: item.acceptedAnswer?.authorName,
                  answerPreview: item.acceptedAnswer?.body ?? '',
                  createdAgo: '오늘',
                  onTap: () => _openQuestion(context, item),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openQuestion(
      BuildContext context, CommunityQnaItem item) async {
    var targetItem = item;
    if (!item.dummy) {
      try {
        targetItem = await const CommunityQnaApiClient().recordView(item.id);
      } catch (_) {
        targetItem = CommunityQnaItem(
          id: item.id,
          title: item.title,
          body: item.body,
          authorName: item.authorName,
          certificationName: item.certificationName,
          likeCount: item.likeCount,
          answerCount: item.answerCount,
          viewCount: item.viewCount + 1,
          acceptedAnswer: item.acceptedAnswer,
          dummy: item.dummy,
        );
      }
    }

    if (!context.mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityQuestionDetailScreen(
          post: HomeCommunityPost(
            id: targetItem.id,
            title: targetItem.title,
            body: targetItem.body,
            certificationName: targetItem.certificationName.isEmpty
                ? certificationName
                : targetItem.certificationName,
            authorName: targetItem.authorName,
            likeCount: targetItem.likeCount,
            commentCount: targetItem.answerCount,
            viewCount: targetItem.viewCount,
            acceptedAnswerBody: targetItem.acceptedAnswer?.body ?? '',
            acceptedAnswerAuthorName:
                targetItem.acceptedAnswer?.authorName ?? '익명',
            dummy: targetItem.dummy,
          ),
        ),
      ),
    );
  }
}

class _CertificationSuccessStoriesTab extends StatelessWidget {
  const _CertificationSuccessStoriesTab({
    required this.certificationId,
    required this.certificationName,
  });

  final String? certificationId;
  final String certificationName;

  @override
  Widget build(BuildContext context) {
    if (certificationId == null || certificationId!.isEmpty) {
      return const _InfoMessage(
        title: '합격 수기를 불러올 수 없습니다',
        description: '자격증 정보가 연결되지 않았습니다.',
      );
    }

    return FutureBuilder<SuccessStoryPage>(
      future: const SuccessStoryApiClient().fetchStories(
        query: certificationName,
        certificationId: certificationId,
        sort: 'popular',
        limit: 10,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _TabLoading();
        }
        if (snapshot.hasError) {
          return const _InfoMessage(
            title: '합격 수기를 불러오지 못했어요',
            description: '잠시 후 다시 시도해주세요.',
          );
        }

        final items = snapshot.data?.items ?? const [];
        if (items.isEmpty) {
          return _InfoMessage(
            title: '아직 연결된 합격 수기가 없습니다',
            description: '$certificationName 합격 수기가 등록되면 이곳에 표시됩니다.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TabSectionHeader(
              icon: Icons.workspace_premium_rounded,
              title: '$certificationName 합격 수기',
              count: items.length,
            ),
            const SizedBox(height: AppSpacing.x3),
            for (final item in items) ...[
              SizedBox(
                height: 310,
                child: SuccessStoryCard(
                  title: item.title,
                  subtitle: item.body.isNotEmpty
                      ? item.body
                      : item.certificationName.isEmpty
                          ? certificationName
                          : item.certificationName,
                  likes: item.likeCount,
                  comments: item.commentCount,
                  views: item.viewCount,
                  studyTime: '${item.studyPeriodDays}일 집중',
                  studyMethod:
                      item.studyMethod.isEmpty ? item.body : item.studyMethod,
                  score: item.score.isEmpty
                      ? '${item.examAttempt} 합격'
                      : item.score,
                  onTap: () => _openStory(context, item),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openStory(BuildContext context, SuccessStoryItem item) async {
    var targetItem = item;
    if (!item.dummy) {
      try {
        targetItem = await const SuccessStoryApiClient().recordView(item.id);
      } catch (_) {
        targetItem = SuccessStoryItem(
          id: item.id,
          title: item.title,
          body: item.body,
          subtitle: item.subtitle,
          authorName: item.authorName,
          certificationName: item.certificationName,
          likeCount: item.likeCount,
          commentCount: item.commentCount,
          viewCount: item.viewCount + 1,
          studyPeriodDays: item.studyPeriodDays,
          studyMethod: item.studyMethod,
          score: item.score,
          examAttempt: item.examAttempt,
          dummy: item.dummy,
        );
      }
    }

    if (!context.mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SuccessStoryDetailScreen(
          story: HomeSuccessStory(
            id: targetItem.id,
            title: targetItem.title,
            description: targetItem.subtitle.isEmpty
                ? targetItem.body
                : targetItem.subtitle,
            body: targetItem.body,
            certificationName: targetItem.certificationName.isEmpty
                ? certificationName
                : targetItem.certificationName,
            studyPeriodDays: targetItem.studyPeriodDays,
            studyMethod: targetItem.studyMethod,
            score: targetItem.score,
            examAttempt: targetItem.examAttempt,
            authorName: targetItem.authorName,
            likeCount: targetItem.likeCount,
            commentCount: targetItem.commentCount,
            viewCount: targetItem.viewCount,
            dummy: targetItem.dummy,
          ),
        ),
      ),
    );
  }
}

class _TabSectionHeader extends StatelessWidget {
  const _TabSectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$count개',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLoading extends StatelessWidget {
  const _TabLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.x10),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      icon: Icons.info_outline_rounded,
      title: title,
      child: _LongText(text: description),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style:
            Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.x2),
              Expanded(child: Text(title, style: textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          child,
        ],
      ),
    );
  }
}

class _LongText extends StatelessWidget {
  const _LongText({
    required this.text,
    this.breakBeforeCircledNumbers = false,
  });

  final String text;
  final bool breakBeforeCircledNumbers;

  @override
  Widget build(BuildContext context) {
    final displayText =
        breakBeforeCircledNumbers ? _breakBeforeCircledNumbers(text) : text;

    return Text(
      displayText,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.65,
          ),
    );
  }
}

class _ExamInfoTable extends StatelessWidget {
  const _ExamInfoTable({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final sections = _parseExamInfoSections(text);

    if (sections.isEmpty) {
      return _LongText(text: text, breakBeforeCircledNumbers: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          _ExamInfoSectionView(section: sections[index]),
          if (index != sections.length - 1)
            const SizedBox(height: AppSpacing.x4),
        ],
      ],
    );
  }
}

class _ExamInfoSectionView extends StatelessWidget {
  const _ExamInfoSectionView({required this.section});

  final _ParsedExamInfoSection section;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section.icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.x2),
            Text(
              section.title,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              for (var index = 0; index < section.rows.length; index++) ...[
                _ExamInfoRowView(row: section.rows[index]),
                if (index != section.rows.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.x2,
                    ),
                    child: Divider(
                      height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.24),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExamInfoRowView extends StatelessWidget {
  const _ExamInfoRowView({required this.row});

  final _ParsedExamInfoRow row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: row.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          alignment: Alignment.center,
          child: Text(
            row.label,
            style: textTheme.labelSmall?.copyWith(
              color: row.color,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Text(
            row.content,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.65,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParsedExamInfoSection {
  const _ParsedExamInfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_ParsedExamInfoRow> rows;
}

class _ParsedExamInfoRow {
  const _ParsedExamInfoRow({
    required this.label,
    required this.content,
    required this.color,
  });

  final String label;
  final String content;
  final Color color;
}

List<_ParsedExamInfoSection> _parseExamInfoSections(String value) {
  final source = _normalizeExamInfoText(value);
  final sectionRegex = RegExp(r'(시험과목|검정방법|합격기준)');
  final matches = sectionRegex.allMatches(source).toList();

  if (matches.isEmpty) {
    return const [];
  }

  final sections = <_ParsedExamInfoSection>[];
  for (var index = 0; index < matches.length; index++) {
    final match = matches[index];
    final title = match.group(1)!;
    final nextStart =
        index + 1 < matches.length ? matches[index + 1].start : source.length;
    final body = source.substring(match.end, nextStart);
    final rows = _parseExamInfoRows(body);

    if (rows.isEmpty) {
      continue;
    }

    sections.add(
      _ParsedExamInfoSection(
        title: title,
        icon: _examInfoSectionIcon(title),
        rows: rows,
      ),
    );
  }

  return sections;
}

List<_ParsedExamInfoRow> _parseExamInfoRows(String value) {
  final cleaned = _cleanExamInfoBody(value);
  final rowRegex = RegExp(r'(필\s*기|실\s*기|작업형)\s*[:：]?');
  final matches = rowRegex.allMatches(cleaned).toList();

  if (matches.isEmpty) {
    final fallback = _cleanExamInfoContent(cleaned);
    return fallback.isEmpty
        ? const []
        : [
            _ParsedExamInfoRow(
              label: '기타',
              content: fallback,
              color: AppColors.primary,
            ),
          ];
  }

  final rows = <_ParsedExamInfoRow>[];
  for (var index = 0; index < matches.length; index++) {
    final match = matches[index];
    final rawLabel = match.group(1) ?? '';
    final nextStart =
        index + 1 < matches.length ? matches[index + 1].start : cleaned.length;
    final content = _cleanExamInfoContent(
      cleaned.substring(match.end, nextStart),
    );

    if (content.isEmpty) {
      continue;
    }

    final isPractical =
        rawLabel.replaceAll(RegExp(r'\s+'), '').contains('실기') ||
            rawLabel.contains('작업형');
    rows.add(
      _ParsedExamInfoRow(
        label: isPractical ? '실기' : '필기',
        content: content,
        color: isPractical ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
      ),
    );
  }

  return rows;
}

String _normalizeExamInfoText(String value) {
  var output = value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (match) => String.fromCharCode(int.tryParse(match.group(1)!) ?? 0),
      )
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
      .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'BODY\s*\{[\s\S]*?\}', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'[A-Z][A-Z0-9.-]*\s*\{[^}]*\}'), ' ')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
          RegExp(r'</(p|div|li|tr|table|ul|ol|h[1-6])>', caseSensitive: false),
          '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&ldquo;', '"')
      .replaceAll('&rdquo;', '"')
      .replaceAll('&lsquo;', "'")
      .replaceAll('&rsquo;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&middot;', '·');

  final tailMarkers = [
    '작업형 실기시험 기본정보',
    '안전등급(safety Level)',
    '안전등급(safety level)',
    '시험장소 구분',
    '주요시설 및 장비',
    '보호구',
    '반드시 수험자 지참공구',
  ];
  final tailIndexes = tailMarkers
      .map(output.indexOf)
      .where((index) => index >= 0)
      .toList()
    ..sort();
  if (tailIndexes.isNotEmpty) {
    output = output.substring(0, tailIndexes.first);
  }

  final normalized = output
      .replaceAllMapped(
        RegExp(r'\s*([①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳])'),
        (match) => '\n${match.group(1)} ',
      )
      .replaceAllMapped(
        RegExp(r'\s*(?:[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳]\s*)?(시험과목|검정방법|합격기준)\s*'),
        (match) => '\n${match.group(1)} ',
      )
      .replaceAllMapped(
        RegExp(r'\s*-\s*(필\s*기|실\s*기|작업형)\s*[:：]?'),
        (match) => '\n${match.group(1)}: ',
      )
      .replaceAllMapped(
        RegExp(r'\s+(?=(?:필\s*기|실\s*기|작업형)\s*[:：])'),
        (_) => '\n',
      )
      .replaceAllMapped(
        RegExp(r'\s+(?=\d+[.)]\s*[가-힣A-Za-z])'),
        (_) => '\n',
      )
      .replaceAllMapped(
        RegExp(r'(?<=[가-힣)])(?=\d+[.)]\s*[가-힣A-Za-z])'),
        (_) => '\n',
      )
      .replaceAllMapped(
        RegExp(r'\s*([□○ㅇ])\s*'),
        (_) => '\n',
      )
      .replaceAllMapped(
        RegExp(r'\s*※\s*'),
        (_) => '\n※ ',
      )
      .replaceAll(RegExp(r'▼\s*위험\s*경고\s*주의\s*관심'), ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s+'), '\n')
      .replaceAll(RegExp(r'\n{2,}'), '\n')
      .trim();

  return _removeStandaloneExamMarkers(normalized);
}

String _cleanExamInfoBody(String value) {
  return value
      .replaceAll(RegExp(r'^[\s:：\-·□○ㅇ①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳]+'), ' ')
      .trim();
}

String _cleanExamInfoContent(String value) {
  final cleaned = value
      .replaceAllMapped(
        RegExp(r'\s+(?=\d+[.)]\s*)'),
        (_) => '\n',
      )
      .replaceAllMapped(
        RegExp(r'(?<=[가-힣)])(?=\d+[.)]\s*[가-힣A-Za-z])'),
        (_) => '\n',
      )
      .replaceAllMapped(
        RegExp(r'\s*([□○ㅇ])\s*'),
        (_) => '\n',
      )
      .replaceAllMapped(
        RegExp(r'\s*※\s*'),
        (_) => '\n※ ',
      )
      .replaceAll(RegExp(r'^[\s:：\-·□○ㅇ]+'), '')
      .replaceAll(RegExp(r'\n[\s:：\-·□○ㅇ]+'), '\n')
      .replaceAllMapped(
        RegExp(r'([가-힣])\s+([,.)])'),
        (match) => '${match.group(1)}${match.group(2)}',
      )
      .replaceAllMapped(
        RegExp(r'\s+([,.)])'),
        (match) => match.group(1)!,
      )
      .replaceAllMapped(
        RegExp(r'([([])\s+'),
        (match) => match.group(1)!,
      )
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s+'), '\n')
      .replaceAll(RegExp(r'\n{2,}'), '\n')
      .trim();

  return _removeStandaloneExamMarkers(cleaned);
}

String _removeStandaloneExamMarkers(String value) {
  return value
      .split('\n')
      .map((line) => line.trim())
      .where((line) =>
          line.isNotEmpty &&
          !RegExp(r'^[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳]$').hasMatch(line))
      .join('\n')
      .trim();
}

IconData _examInfoSectionIcon(String title) {
  return switch (title) {
    '시험과목' => Icons.fact_check_rounded,
    '검정방법' => Icons.assignment_rounded,
    '합격기준' => Icons.verified_rounded,
    _ => Icons.info_outline_rounded,
  };
}

String _breakBeforeCircledNumbers(String value) {
  return value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAllMapped(
        RegExp(r'(?<!^)(?<!\n)\s*([①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳])'),
        (match) => '\n${match.group(1)}',
      )
      .trim();
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.year,
    required this.month,
    required this.schedules,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final int year;
  final int month;
  final List<CertificationScheduleData> schedules;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = _calendarDays(year, month);
    final weeks = _calendarWeeks(days);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '이전 달',
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '$year년 $month월',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: '다음 달',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              for (final weekday in ['일', '월', '화', '수', '목', '금', '토'])
                Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          for (final week in weeks) ...[
            _CalendarWeekRow(
              week: week,
              month: month,
              schedules: schedules,
            ),
            const SizedBox(height: 2),
          ],
          const SizedBox(height: AppSpacing.x3),
          const _ScheduleCompactLegend(),
        ],
      ),
    );
  }
}

class _ScheduleCompactLegend extends StatelessWidget {
  const _ScheduleCompactLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.x3,
      runSpacing: AppSpacing.x2,
      children: [
        _ScheduleLegendDot(type: 'registration', label: '접수'),
        _ScheduleLegendDot(type: 'written', label: '필기'),
        _ScheduleLegendDot(type: 'practical', label: '실기'),
        _ScheduleLegendDot(type: 'result', label: '발표'),
        _ScheduleLegendDot(type: 'custom', label: '서류'),
      ],
    );
  }
}

class _ScheduleLegendDot extends StatelessWidget {
  const _ScheduleLegendDot({
    required this.type,
    required this.label,
  });

  final String type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _scheduleColor(type);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _CalendarWeekRow extends StatelessWidget {
  const _CalendarWeekRow({
    required this.week,
    required this.month,
    required this.schedules,
  });

  final List<DateTime> week;
  final int month;
  final List<CertificationScheduleData> schedules;

  @override
  Widget build(BuildContext context) {
    final weekSchedules = schedules
        .where((schedule) => _isScheduleInWeek(schedule, week))
        .toList()
      ..sort((a, b) {
        final startCompare = (a.startDate ?? DateTime(1900))
            .compareTo(b.startDate ?? DateTime(1900));
        if (startCompare != 0) {
          return startCompare;
        }
        return _scheduleLabel(a.type).compareTo(_scheduleLabel(b.type));
      });
    final visibleSchedules = weekSchedules.take(4).toList();
    const hiddenCount = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;

        return SizedBox(
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.44),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              for (var index = 0; index < visibleSchedules.length; index++)
                _WeekScheduleBar(
                  schedule: visibleSchedules[index],
                  week: week,
                  cellWidth: cellWidth,
                  top: 50 + index * 5,
                ),
              Row(
                children: [
                  for (final date in week)
                    Expanded(
                      child: _CalendarDayBackground(
                        date: date,
                        inMonth: date.month == month,
                      ),
                    ),
                ],
              ),
              if (hiddenCount > 0)
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 5,
                  child: Text(
                    '+$hiddenCount개 일정',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarDayBackground extends StatelessWidget {
  const _CalendarDayBackground({
    required this.date,
    required this.inMonth,
  });

  final DateTime date;
  final bool inMonth;

  @override
  Widget build(BuildContext context) {
    final today = _isToday(date);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: inMonth
            ? Colors.transparent
            : AppColors.surface.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: today ? const Color(0xFFDBEAFE) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '${date.day}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: today
                        ? const Color(0xFF1D4ED8)
                        : inMonth
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant
                                .withValues(alpha: 0.38),
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
          ),
          if (today) ...[
            const SizedBox(width: 4),
            Text(
              '오늘',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF1D4ED8),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekScheduleBar extends StatelessWidget {
  const _WeekScheduleBar({
    required this.schedule,
    required this.week,
    required this.cellWidth,
    required this.top,
  });

  final CertificationScheduleData schedule;
  final List<DateTime> week;
  final double cellWidth;
  final double top;

  @override
  Widget build(BuildContext context) {
    final first = _dateOnly(week.first);
    final last = _dateOnly(week.last);
    final start = _dateOnly(schedule.startDate!);
    final end = _dateOnly(schedule.endDate ?? schedule.startDate!);
    final visibleStart = start.isAfter(first) ? start : first;
    final visibleEnd = end.isBefore(last) ? end : last;
    final startIndex = visibleStart.difference(first).inDays;
    final endIndex = visibleEnd.difference(first).inDays;
    final left = startIndex * cellWidth + 5;
    final width = ((endIndex - startIndex + 1) * cellWidth - 10)
        .clamp(18.0, double.infinity);
    final startsHere = visibleStart == start;
    final endsHere = visibleEnd == end;
    final color = _scheduleColor(schedule.type);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: 7,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.95),
          borderRadius: BorderRadius.horizontal(
            left: startsHere ? const Radius.circular(8) : Radius.zero,
            right: endsHere ? const Radius.circular(8) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCarousel extends StatelessWidget {
  const _ScheduleCarousel({required this.schedules});

  final List<CertificationScheduleData> schedules;

  @override
  Widget build(BuildContext context) {
    final sorted = [...schedules]..sort(
        (a, b) => (a.startDate ?? DateTime(1900))
            .compareTo(b.startDate ?? DateTime(1900)),
      );
    final nearest = _nearestSchedule(sorted);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '이 달의 일정',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${sorted.length}개',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x3),
            itemBuilder: (context, index) {
              final schedule = sorted[index];
              return _ScheduleCarouselCard(
                schedule: schedule,
                highlighted: identical(schedule, nearest),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScheduleCarouselCard extends StatelessWidget {
  const _ScheduleCarouselCard({
    required this.schedule,
    required this.highlighted,
  });

  final CertificationScheduleData schedule;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _scheduleColor(schedule.type);
    final days =
        schedule.startDate == null ? null : _daysUntil(schedule.startDate!);
    final dDay = days == null
        ? null
        : days == 0
            ? 'D-Day'
            : days > 0
                ? 'D-$days'
                : '종료';

    return Container(
      width: 248,
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.18)
            : AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: highlighted ? 0.26 : 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _scheduleIcon(schedule.type),
                  color: _scheduleStrongColor(schedule.type),
                  size: 22,
                ),
              ),
              const Spacer(),
              if (highlighted)
                const _ScheduleBadge(
                  label: '가까운 일정',
                  color: AppColors.primary,
                )
              else
                _ScheduleBadge(
                  label: _scheduleLabel(schedule.type),
                  color: _scheduleStrongColor(schedule.type),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            schedule.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            _scheduleDateText(schedule),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Container(
                width: 26,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const Spacer(),
              if (dDay != null)
                Text(
                  dDay,
                  style: textTheme.labelLarge?.copyWith(
                    color: highlighted
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleBadge extends StatelessWidget {
  const _ScheduleBadge({
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
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}

String _scheduleDateText(CertificationScheduleData schedule) {
  final start = schedule.startDate;
  final end = schedule.endDate;
  final label = _scheduleLabel(schedule.type);

  if (start == null) {
    return label;
  }
  if (end == null || _dateOnly(start) == _dateOnly(end)) {
    return '${_formatDate(start)} · $label';
  }
  return '${_formatDate(start)} ~ ${_formatDate(end)} · $label';
}

String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

String _scheduleLabel(String type) => switch (type) {
      'registration' => '접수',
      'written' => '필기',
      'practical' => '실기',
      'result' => '발표',
      _ => '서류제출',
    };

Color _scheduleColor(String type) => switch (type) {
      'registration' => const Color(0xFFBFDBFE),
      'written' => const Color(0xFFDDD6FE),
      'practical' => const Color(0xFFBBF7D0),
      'result' => const Color(0xFFFECACA),
      _ => const Color(0xFFFDE68A),
    };

Color _scheduleStrongColor(String type) => switch (type) {
      'registration' => const Color(0xFF1D4ED8),
      'written' => const Color(0xFF6D28D9),
      'practical' => const Color(0xFF047857),
      'result' => const Color(0xFFB91C1C),
      _ => const Color(0xFFB45309),
    };

IconData _scheduleIcon(String type) => switch (type) {
      'registration' => Icons.how_to_reg_rounded,
      'written' => Icons.edit_note_rounded,
      'practical' => Icons.build_rounded,
      'result' => Icons.verified_rounded,
      _ => Icons.event_note_rounded,
    };

List<DateTime> _calendarDays(int year, int month) {
  final firstDay = DateTime(year, month);
  final firstVisible = firstDay.subtract(Duration(days: firstDay.weekday % 7));
  return List.generate(42, (index) => firstVisible.add(Duration(days: index)));
}

List<List<DateTime>> _calendarWeeks(List<DateTime> days) {
  return [
    for (var index = 0; index < days.length; index += 7)
      days.sublist(index, index + 7),
  ];
}

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

bool _isScheduleInWeek(
  CertificationScheduleData schedule,
  List<DateTime> week,
) {
  final start = schedule.startDate;
  if (start == null) {
    return false;
  }

  final weekStart = _dateOnly(week.first);
  final weekEnd = _dateOnly(week.last);
  final scheduleStart = _dateOnly(start);
  final scheduleEnd = _dateOnly(schedule.endDate ?? start);

  return !scheduleEnd.isBefore(weekStart) && !scheduleStart.isAfter(weekEnd);
}

bool _isScheduleInMonth(
  CertificationScheduleData schedule,
  int year,
  int month,
) {
  final start = schedule.startDate;
  if (start == null) {
    return false;
  }

  final monthStart = DateTime(year, month);
  final monthEnd = DateTime(year, month + 1, 0);
  final scheduleStart = _dateOnly(start);
  final scheduleEnd = _dateOnly(schedule.endDate ?? start);

  return !scheduleEnd.isBefore(monthStart) && !scheduleStart.isAfter(monthEnd);
}

CertificationScheduleData? _nextExam(
    List<CertificationScheduleData> schedules) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final upcoming = schedules
      .where((schedule) => schedule.startDate != null)
      .where((schedule) => !_dateOnly(schedule.startDate!).isBefore(today))
      .toList()
    ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
  return upcoming.isEmpty ? null : upcoming.first;
}

CertificationScheduleData? _nearestSchedule(
    List<CertificationScheduleData> schedules) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final upcoming = schedules
      .where((schedule) => schedule.startDate != null)
      .where((schedule) => !_dateOnly(schedule.startDate!).isBefore(today))
      .toList()
    ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
  return upcoming.isNotEmpty
      ? upcoming.first
      : schedules.isEmpty
          ? null
          : schedules.first;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int _daysUntil(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  return target.difference(today).inDays;
}

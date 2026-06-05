import 'dart:async';

import 'package:flutter/material.dart';

import '../models/certification_search_data.dart';
import '../models/home_data.dart';
import '../models/success_story_list_data.dart';
import '../services/certification_search_api_client.dart';
import '../services/success_story_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_page.dart';
import '../widgets/success_story_card.dart';
import 'success_story_detail_screen.dart';
import 'success_story_write_screen.dart';

class SuccessStoriesScreen extends StatefulWidget {
  const SuccessStoriesScreen({
    this.initialCertificationId,
    this.initialCertificationName,
    super.key,
  });

  final String? initialCertificationId;
  final String? initialCertificationName;

  @override
  State<SuccessStoriesScreen> createState() => _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends State<SuccessStoriesScreen> {
  final _storyClient = const SuccessStoryApiClient();
  final _certClient = const CertificationSearchApiClient();
  final _certificationSearchController = TextEditingController();
  Timer? _certificationDebounce;
  List<CertificationSearchResult> _certifications = const [];
  String? _selectedCertificationId;
  String? _selectedCertificationName;
  String _sort = 'popular';
  bool _loadingCertifications = false;
  late Future<SuccessStoryPage> _future;

  @override
  void initState() {
    super.initState();
    _selectedCertificationId = widget.initialCertificationId;
    _selectedCertificationName = widget.initialCertificationName;
    _future = _fetch();
    _loadCertificationTags();
  }

  @override
  void dispose() {
    _certificationDebounce?.cancel();
    _certificationSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'success-story-write',
        tooltip: '후기 작성',
        onPressed: _openWriteStory,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.edit_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate:
                  _StoriesHeaderDelegate(onBack: Navigator.of(context).pop),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.x4),
                    _StorySearchPanel(
                      certificationSearchController:
                          _certificationSearchController,
                      selectedCertificationId: _selectedCertificationId,
                      selectedCertificationName: _selectedCertificationName,
                      certifications: _certifications,
                      loadingCertifications: _loadingCertifications,
                      sort: _sort,
                      onCertificationSearchChanged:
                          _onCertificationSearchChanged,
                      onCertificationSelected: _selectCertification,
                      onSortSelected: _selectSort,
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    FutureBuilder<SuccessStoryPage>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const _StoryListLoading();
                        }
                        if (snapshot.hasError) {
                          return const _StoryListError();
                        }

                        final items = snapshot.data?.items ?? const [];
                        return _StoryList(items: items, onOpen: _openStory);
                      },
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
  }

  Future<SuccessStoryPage> _fetch() {
    return _storyClient.fetchStories(
      query: _selectedCertificationName ?? '',
      certificationId: _selectedCertificationId,
      sort: _sort,
    );
  }

  Future<void> _loadCertificationTags() async {
    setState(() => _loadingCertifications = true);
    try {
      final items = await _certClient.search(
        query: _certificationSearchController.text,
        sort: 'popular',
        limit: _certificationSearchController.text.trim().isEmpty ? 8 : 20,
      );
      if (mounted) {
        setState(() => _certifications = items);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCertifications = false);
      }
    }
  }

  void _onCertificationSearchChanged(String value) {
    _certificationDebounce?.cancel();
    _certificationDebounce =
        Timer(const Duration(milliseconds: 260), _loadCertificationTags);
  }

  void _selectCertification(CertificationSearchResult? item) {
    setState(() {
      _selectedCertificationId = item?.id;
      _selectedCertificationName = item?.name;
      _future = _fetch();
    });
  }

  void _selectSort(String value) {
    setState(() {
      _sort = value;
      _future = _fetch();
    });
  }

  Future<void> _openStory(SuccessStoryItem item) async {
    var targetItem = item;
    if (!item.dummy) {
      try {
        targetItem = await _storyClient.recordView(item.id);
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

    if (!mounted) {
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
            certificationName: targetItem.certificationName,
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

  Future<void> _openWriteStory() async {
    final created = await Navigator.of(context).push<SuccessStoryItem>(
      MaterialPageRoute<SuccessStoryItem>(
        builder: (_) => SuccessStoryWriteScreen(
          initialCertificationId: _selectedCertificationId,
          initialCertificationName: _selectedCertificationName,
        ),
      ),
    );

    if (created == null || !mounted) {
      return;
    }

    setState(() => _future = _fetch());
    _openStory(created);
  }
}

class _StoriesHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StoriesHeaderDelegate({required this.onBack});

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
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface.withValues(alpha: 0.94),
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
  bool shouldRebuild(covariant _StoriesHeaderDelegate oldDelegate) =>
      oldDelegate.onBack != onBack;
}

class _StorySearchPanel extends StatelessWidget {
  const _StorySearchPanel({
    required this.certificationSearchController,
    required this.selectedCertificationId,
    required this.selectedCertificationName,
    required this.certifications,
    required this.loadingCertifications,
    required this.sort,
    required this.onCertificationSearchChanged,
    required this.onCertificationSelected,
    required this.onSortSelected,
  });

  final TextEditingController certificationSearchController;
  final String? selectedCertificationId;
  final String? selectedCertificationName;
  final List<CertificationSearchResult> certifications;
  final bool loadingCertifications;
  final String sort;
  final ValueChanged<String> onCertificationSearchChanged;
  final ValueChanged<CertificationSearchResult?> onCertificationSelected;
  final ValueChanged<String> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: certificationSearchController,
            onChanged: onCertificationSearchChanged,
            decoration: const InputDecoration(
              hintText: '자격증 태그 검색',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          if (loadingCertifications)
            const LinearProgressIndicator()
          else
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: certifications.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.x2),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ChoiceChip(
                      label: const Text('전체'),
                      selected: selectedCertificationId == null,
                      onSelected: (_) => onCertificationSelected(null),
                      showCheckmark: false,
                    );
                  }

                  final item = certifications[index - 1];
                  final selected = selectedCertificationId == item.id;
                  return ChoiceChip(
                    label: Text(item.name),
                    selected: selected,
                    onSelected: (_) => onCertificationSelected(item),
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle:
                        Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.x4),
          Wrap(
            spacing: AppSpacing.x2,
            children: [
              _SortChip(
                label: '인기순',
                value: 'popular',
                selected: sort == 'popular',
                onSelected: onSortSelected,
              ),
              _SortChip(
                label: '최신순',
                value: 'latest',
                selected: sort == 'latest',
                onSelected: onSortSelected,
              ),
              _SortChip(
                label: '댓글순',
                value: 'comments',
                selected: sort == 'comments',
                onSelected: onSortSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      showCheckmark: false,
    );
  }
}

class _StoryList extends StatelessWidget {
  const _StoryList({
    required this.items,
    required this.onOpen,
  });

  final List<SuccessStoryItem> items;
  final ValueChanged<SuccessStoryItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _StoryListEmpty();
    }

    return Column(
      children: [
        for (final item in items) ...[
          SizedBox(
            height: 310,
            child: SuccessStoryCard(
              title: item.title,
              subtitle: item.body.isEmpty ? item.certificationName : item.body,
              likes: item.likeCount,
              comments: item.commentCount,
              views: item.viewCount,
              studyTime: '${item.studyPeriodDays}일 집중',
              studyMethod:
                  item.studyMethod.isEmpty ? item.body : item.studyMethod,
              score: item.score.isEmpty ? '${item.examAttempt} 합격' : item.score,
              onTap: () => onOpen(item),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

class _StoryListLoading extends StatelessWidget {
  const _StoryListLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.x12),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StoryListError extends StatelessWidget {
  const _StoryListError();

  @override
  Widget build(BuildContext context) {
    return const _MessageBox(
      icon: Icons.error_outline_rounded,
      title: '합격 후기를 불러오지 못했어요',
      message: '잠시 후 다시 시도해주세요.',
    );
  }
}

class _StoryListEmpty extends StatelessWidget {
  const _StoryListEmpty();

  @override
  Widget build(BuildContext context) {
    return const _MessageBox(
      icon: Icons.inbox_outlined,
      title: '표시할 후기가 없어요',
      message: '다른 자격증 태그나 검색어를 선택해보세요.',
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.x3),
          Text(title, style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.x1),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

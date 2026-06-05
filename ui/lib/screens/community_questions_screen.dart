import 'dart:async';

import 'package:flutter/material.dart';

import '../models/certification_search_data.dart';
import '../models/community_qna_data.dart';
import '../models/home_data.dart';
import '../services/certification_search_api_client.dart';
import '../services/community_qna_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/community_question_card.dart';
import '../widgets/responsive_page.dart';
import 'community_question_detail_screen.dart';
import 'community_question_write_screen.dart';

class CommunityQuestionsScreen extends StatefulWidget {
  const CommunityQuestionsScreen({super.key});

  @override
  State<CommunityQuestionsScreen> createState() =>
      _CommunityQuestionsScreenState();
}

class _CommunityQuestionsScreenState extends State<CommunityQuestionsScreen> {
  final _qnaClient = const CommunityQnaApiClient();
  final _certClient = const CertificationSearchApiClient();
  final _tagSearchController = TextEditingController();
  Timer? _tagDebounce;
  CertificationSearchResult? _selectedCertification;
  List<CertificationSearchResult> _certifications = const [];
  String _sort = 'popular';
  late Future<CommunityQnaPage> _future;
  bool _loadingTags = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    _loadCertificationTags();
  }

  @override
  void dispose() {
    _tagDebounce?.cancel();
    _tagSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'community-question-write',
        tooltip: '질문하기',
        onPressed: _openWriteQuestion,
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
              delegate: _QuestionsHeaderDelegate(
                onBack: Navigator.of(context).pop,
              ),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.x4),
                    _SearchPanel(
                      tagSearchController: _tagSearchController,
                      selectedCertification: _selectedCertification,
                      certifications: _certifications,
                      loadingTags: _loadingTags,
                      sort: _sort,
                      onTagSearchChanged: _onTagSearchChanged,
                      onCertificationSelected: _selectCertification,
                      onSortSelected: _selectSort,
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    FutureBuilder<CommunityQnaPage>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const _QuestionListLoading();
                        }
                        if (snapshot.hasError) {
                          return const _QuestionListError();
                        }

                        final items = snapshot.data?.items ?? const [];
                        return _QuestionList(
                          items: items,
                          onOpen: _openQuestion,
                        );
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

  Future<CommunityQnaPage> _fetch() {
    return _qnaClient.fetchQuestions(
      certificationId: _selectedCertification?.id,
      sort: _sort,
    );
  }

  Future<void> _loadCertificationTags() async {
    setState(() => _loadingTags = true);
    try {
      final items = await _certClient.search(
        query: _tagSearchController.text,
        sort: 'popular',
        limit: _tagSearchController.text.trim().isEmpty ? 8 : 20,
      );
      if (mounted) {
        setState(() => _certifications = items);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingTags = false);
      }
    }
  }

  void _onTagSearchChanged(String value) {
    _tagDebounce?.cancel();
    _tagDebounce =
        Timer(const Duration(milliseconds: 260), _loadCertificationTags);
  }

  void _selectCertification(CertificationSearchResult? item) {
    setState(() {
      _selectedCertification = item;
      _future = _fetch();
    });
  }

  void _selectSort(String value) {
    setState(() {
      _sort = value;
      _future = _fetch();
    });
  }

  Future<void> _openQuestion(CommunityQnaItem item) async {
    var targetItem = item;
    if (!item.dummy) {
      try {
        targetItem = await _qnaClient.recordView(item.id);
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

    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityQuestionDetailScreen(
          post: HomeCommunityPost(
            id: targetItem.id,
            title: targetItem.title,
            body: targetItem.body,
            certificationName: targetItem.certificationName,
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

  Future<void> _openWriteQuestion() async {
    final created = await Navigator.of(context).push<CommunityQnaItem>(
      MaterialPageRoute<CommunityQnaItem>(
        builder: (_) => CommunityQuestionWriteScreen(
          initialCertification: _selectedCertification,
        ),
      ),
    );

    if (created == null || !mounted) {
      return;
    }

    setState(() => _future = _fetch());
    _openQuestion(created);
  }
}

class _QuestionsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _QuestionsHeaderDelegate({
    required this.onBack,
  });

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
            Expanded(
              child: Text(
                '인기 질문',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _QuestionsHeaderDelegate oldDelegate) =>
      oldDelegate.onBack != onBack;
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.tagSearchController,
    required this.selectedCertification,
    required this.certifications,
    required this.loadingTags,
    required this.sort,
    required this.onTagSearchChanged,
    required this.onCertificationSelected,
    required this.onSortSelected,
  });

  final TextEditingController tagSearchController;
  final CertificationSearchResult? selectedCertification;
  final List<CertificationSearchResult> certifications;
  final bool loadingTags;
  final String sort;
  final ValueChanged<String> onTagSearchChanged;
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
            controller: tagSearchController,
            onChanged: onTagSearchChanged,
            decoration: const InputDecoration(
              hintText: '자격증 태그 검색',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          if (loadingTags)
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
                      selected: selectedCertification == null,
                      onSelected: (_) => onCertificationSelected(null),
                      showCheckmark: false,
                    );
                  }

                  final item = certifications[index - 1];
                  final selected = selectedCertification?.id == item.id;
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
                label: '답변많은순',
                value: 'answers',
                selected: sort == 'answers',
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

class _QuestionList extends StatelessWidget {
  const _QuestionList({
    required this.items,
    required this.onOpen,
  });

  final List<CommunityQnaItem> items;
  final ValueChanged<CommunityQnaItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _QuestionListEmpty();
    }

    return Column(
      children: [
        for (final item in items) ...[
          SizedBox(
            height: 276,
            child: CommunityQuestionCard(
              author: item.authorName,
              question: item.title,
              certificationName: item.certificationName,
              questionPreview: item.body,
              answerAuthorName: item.acceptedAnswer?.authorName,
              answerPreview: item.acceptedAnswer?.body ?? '',
              comments: item.answerCount,
              likes: item.likeCount,
              views: item.viewCount,
              createdAgo: '오늘',
              onTap: () => onOpen(item),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

class _QuestionListLoading extends StatelessWidget {
  const _QuestionListLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.x12),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _QuestionListError extends StatelessWidget {
  const _QuestionListError();

  @override
  Widget build(BuildContext context) {
    return const _MessageBox(
      icon: Icons.error_outline_rounded,
      title: '질문을 불러오지 못했어요',
      message: '잠시 후 다시 시도해주세요.',
    );
  }
}

class _QuestionListEmpty extends StatelessWidget {
  const _QuestionListEmpty();

  @override
  Widget build(BuildContext context) {
    return const _MessageBox(
      icon: Icons.inbox_outlined,
      title: '표시할 질문이 없어요',
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

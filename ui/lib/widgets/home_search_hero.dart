import 'dart:async';

import 'package:flutter/material.dart';

import '../models/certification_search_data.dart';
import '../services/certification_search_api_client.dart';
import '../theme/app_theme.dart';

class HomeSearchHero extends StatefulWidget {
  const HomeSearchHero({
    required this.onCertificationSelected,
    super.key,
  });

  final ValueChanged<CertificationSearchResult> onCertificationSelected;

  @override
  State<HomeSearchHero> createState() => _HomeSearchHeroState();
}

class _HomeSearchHeroState extends State<HomeSearchHero> {
  final _controller = TextEditingController();
  final _client = const CertificationSearchApiClient();
  Timer? _debounce;
  List<CertificationSearchTag> _tags = const [];
  List<CertificationSearchResult> _results = const [];
  CertificationSearchTag? _selectedTag;
  String _sort = 'popular';
  String _qualificationType = 'all';
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.blueTint,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '찾고싶은 자격증이 있나요?',
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            '자격증명, 분야, 태그로 빠르게 찾아보세요.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          _SearchField(
            controller: _controller,
            searching: _searching,
            onChanged: _onQueryChanged,
            onFilterTap: _openFilterSheet,
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x4),
            _ResultPanel(
              results: _results,
              onSelected: widget.onCertificationSelected,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadTags({String qualificationType = 'all'}) async {
    try {
      final tags = await _client.fetchTags(
        limit: 18,
        qualificationType: qualificationType,
      );
      if (mounted) {
        setState(() {
          _tags = tags;
        });
      }
    } catch (_) {}
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), _search);
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty && _selectedTag == null) {
      if (mounted) {
        setState(() => _results = const []);
      }
      return;
    }

    setState(() => _searching = true);
    try {
      final results = await _client.search(
        query: query,
        tagId: _selectedTag?.id,
        sort: _sort,
        qualificationType: _qualificationType,
      );
      if (mounted) {
        setState(() => _results = results);
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<_SearchFilter>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _FilterSheet(
          tags: _tags,
          selectedTag: _selectedTag,
          sort: _sort,
          qualificationType: _qualificationType,
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedTag = selected.tag;
      _sort = selected.sort;
      _qualificationType = selected.qualificationType;
    });
    await _loadTags(qualificationType: selected.qualificationType);
    _search();
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.searching,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '자격증 이름을 입력하세요',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            tooltip: '검색 필터',
            onPressed: onFilterTap,
            icon: searching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.tune_rounded),
          ),
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.results,
    required this.onSelected,
  });

  final List<CertificationSearchResult> results;
  final ValueChanged<CertificationSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          for (var index = 0; index < results.length; index++) ...[
            _ResultTile(
              result: results[index],
              onTap: () => onSelected(results[index]),
            ),
            if (index != results.length - 1)
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.38),
              ),
          ],
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.onTap,
  });

  final CertificationSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tags = result.tags.take(2).map((tag) => tag.name).join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tags.isEmpty ? result.category : tags,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.tags,
    required this.selectedTag,
    required this.sort,
    required this.qualificationType,
  });

  final List<CertificationSearchTag> tags;
  final CertificationSearchTag? selectedTag;
  final String sort;
  final String qualificationType;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final _client = const CertificationSearchApiClient();
  CertificationSearchTag? _tag;
  late List<CertificationSearchTag> _tags;
  late String _sort;
  late String _qualificationType;
  bool _loadingTags = false;

  @override
  void initState() {
    super.initState();
    _tag = widget.selectedTag;
    _tags = widget.tags;
    _sort = widget.sort;
    _qualificationType = widget.qualificationType;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x4,
        AppSpacing.x5,
        AppSpacing.x6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text(
              '검색 필터',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text('정렬', style: textTheme.labelMedium),
            const SizedBox(height: AppSpacing.x2),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'popular', label: Text('인기순')),
                ButtonSegment(value: 'name', label: Text('이름순')),
              ],
              selected: {_sort},
              onSelectionChanged: (value) =>
                  setState(() => _sort = value.first),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text('자격 구분', style: textTheme.labelMedium),
            const SizedBox(height: AppSpacing.x2),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('전체')),
                ButtonSegment(
                  value: 'national_technical',
                  label: Text('국가기술'),
                ),
                ButtonSegment(value: 'professional', label: Text('전문자격')),
              ],
              selected: {_qualificationType},
              onSelectionChanged: (value) =>
                  _changeQualificationType(value.first),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text('태그', style: textTheme.labelMedium),
            const SizedBox(height: AppSpacing.x2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: _loadingTags
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.x5),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: AppSpacing.x2,
                        runSpacing: AppSpacing.x2,
                        children: [
                          ChoiceChip(
                            label: const Text('전체'),
                            selected: _tag == null,
                            onSelected: (_) => setState(() => _tag = null),
                          ),
                          for (final tag in _tags)
                            ChoiceChip(
                              label:
                                  Text('${tag.name} ${tag.certificationCount}'),
                              selected: _tag?.id == tag.id,
                              onSelected: (_) => setState(() => _tag = tag),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.x6),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _SearchFilter(
                  tag: _tag,
                  sort: _sort,
                  qualificationType: _qualificationType,
                ),
              ),
              child: const Text('필터 적용'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeQualificationType(String value) async {
    setState(() {
      _qualificationType = value;
      _tag = null;
      _loadingTags = true;
    });

    try {
      final tags = await _client.fetchTags(
        limit: 18,
        qualificationType: value,
      );
      if (mounted) {
        setState(() => _tags = tags);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingTags = false);
      }
    }
  }
}

class _SearchFilter {
  const _SearchFilter({
    required this.tag,
    required this.sort,
    required this.qualificationType,
  });

  final CertificationSearchTag? tag;
  final String sort;
  final String qualificationType;
}

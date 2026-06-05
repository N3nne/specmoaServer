import 'dart:async';

import 'package:flutter/material.dart';

import '../models/certification_search_data.dart';
import '../services/certification_search_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_page.dart';
import 'certification_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _client = const CertificationSearchApiClient();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<CertificationSearchTag> _tags = const [];
  List<CertificationSearchResult> _items = const [];
  String? _selectedTagId;
  bool _tagsExpanded = false;
  bool _loadingTags = true;
  bool _loadingItems = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTags();
    _loadItems();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), _loadItems);
  }

  Future<void> _loadTags() async {
    setState(() => _loadingTags = true);
    try {
      final tags = await _client.fetchTags(limit: 30);
      if (mounted) {
        setState(() => _tags = tags);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingTags = false);
      }
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    try {
      final items = await _client.search(
        query: _searchController.text,
        tagId: _selectedTagId,
        limit: 30,
      );
      if (mounted) {
        setState(() => _items = items);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingItems = false);
      }
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadTags(), _loadItems()]);
  }

  void _selectTag(String? tagId) {
    setState(() => _selectedTagId = _selectedTagId == tagId ? null : tagId);
    _loadItems();
  }

  void _openDetail(CertificationSearchResult item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CertificationDetailScreen(
          certificationId: item.id,
          certificationName: item.name,
          category: item.category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visibleTags =
        _tagsExpanded ? _tags : _tags.take(14).toList(growable: false);
    final hiddenTagCount = _tags.length - visibleTags.length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.x5),
                    Text('탐색', style: textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      '자격증을 검색하고 분야 태그로 빠르게 좁혀보세요.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '자격증명, 분야, 기관 검색',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: '검색어 지우기',
                                onPressed: () {
                                  _searchController.clear();
                                  _loadItems();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    if (_loadingTags)
                      const LinearProgressIndicator()
                    else if (_tags.isNotEmpty) ...[
                      Wrap(
                        spacing: AppSpacing.x2,
                        runSpacing: AppSpacing.x2,
                        children: [
                          _TagChip(
                            label: '전체',
                            count: null,
                            selected: _selectedTagId == null,
                            onTap: () => _selectTag(null),
                          ),
                          for (final tag in visibleTags)
                            _TagChip(
                              label: tag.name,
                              count: tag.certificationCount,
                              selected: tag.id == _selectedTagId,
                              onTap: () => _selectTag(tag.id),
                            ),
                        ],
                      ),
                      if (_tags.length > 14) ...[
                        const SizedBox(height: AppSpacing.x3),
                        _ShowMoreTagsButton(
                          expanded: _tagsExpanded,
                          hiddenCount: hiddenTagCount,
                          onTap: () {
                            setState(() => _tagsExpanded = !_tagsExpanded);
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.x5),
                    Row(
                      children: [
                        Expanded(
                          child: Text('자격증 목록', style: textTheme.titleMedium),
                        ),
                        Text(
                          '${_items.length}개',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    if (_loadingItems)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.x12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_items.isEmpty)
                      const _ExploreInfoPanel(
                        icon: Icons.search_off_rounded,
                        title: '검색 결과가 없습니다.',
                        message: '검색어를 줄이거나 다른 태그를 선택해보세요.',
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.x3,
                          mainAxisSpacing: AppSpacing.x3,
                          childAspectRatio: 0.84,
                        ),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _CertificationHubCard(
                            item: item,
                            onTap: () => _openDetail(item),
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
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x2,
          ),
          child: Text(
            count == null ? label : '$label $count',
            style: textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowMoreTagsButton extends StatelessWidget {
  const _ShowMoreTagsButton({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        expanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
      ),
      label: Text(expanded ? '접기' : '태그 더보기 $hiddenCount개'),
    );
  }
}

class _CertificationHubCard extends StatelessWidget {
  const _CertificationHubCard({
    required this.item,
    required this.onTap,
  });

  final CertificationSearchResult item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tags = item.tags.take(2).toList(growable: false);
    final visual = _CertificationVisualSpec.from(item);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                visual.accent.withValues(alpha: 0.16),
                visual.accent.withValues(alpha: 0.06),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.soft,
            border: Border.all(color: visual.accent.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                [
                  if (item.category.isNotEmpty) item.category,
                  if ((item.organization ?? '').isNotEmpty) item.organization!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Center(child: _CertificationCardVisual(spec: visual)),
              ),
              Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x2,
                children: [
                  for (final tag in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.x3,
                        vertical: AppSpacing.x1,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        tag.name,
                        style: textTheme.labelSmall?.copyWith(
                          color: visual.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (tags.isEmpty)
                    Text(
                      '태그 정보 확인 중',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (item.acquiredCount > 0) ...[
                const SizedBox(height: AppSpacing.x2),
                Text(
                  '취득자 ${_formatCount(item.acquiredCount)}명',
                  style: textTheme.labelSmall?.copyWith(
                    color: visual.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificationCardVisual extends StatelessWidget {
  const _CertificationCardVisual({required this.spec});

  final _CertificationVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: spec.accent.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              spec.backgroundIcon,
              size: 88,
              color: spec.accent.withValues(alpha: 0.1),
            ),
          ),
          Center(
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: spec.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(spec.icon, color: spec.accent, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificationVisualSpec {
  const _CertificationVisualSpec({
    required this.accent,
    required this.icon,
    required this.backgroundIcon,
  });

  final Color accent;
  final IconData icon;
  final IconData backgroundIcon;

  factory _CertificationVisualSpec.from(CertificationSearchResult item) {
    final text = [
      item.name,
      item.category,
      item.organization ?? '',
      ...item.tags.map((tag) => tag.name),
    ].join(' ');

    if (_containsAny(text, ['정보', '컴퓨터', '데이터', 'SQL', '전산', '네트워크'])) {
      return const _CertificationVisualSpec(
        accent: AppColors.primary,
        icon: Icons.code_rounded,
        backgroundIcon: Icons.memory_rounded,
      );
    }
    if (_containsAny(text, ['전기', '전자', '통신', '전파'])) {
      return const _CertificationVisualSpec(
        accent: Color(0xFF7C3AED),
        icon: Icons.bolt_rounded,
        backgroundIcon: Icons.electrical_services_rounded,
      );
    }
    if (_containsAny(text, ['건축', '토목', '건설', '도시', '측량'])) {
      return const _CertificationVisualSpec(
        accent: Color(0xFF0F766E),
        icon: Icons.apartment_rounded,
        backgroundIcon: Icons.foundation_rounded,
      );
    }
    if (_containsAny(text, ['조리', '식품', '제과', '제빵', '미용'])) {
      return const _CertificationVisualSpec(
        accent: Color(0xFFDB2777),
        icon: Icons.restaurant_menu_rounded,
        backgroundIcon: Icons.local_dining_rounded,
      );
    }
    if (_containsAny(text, ['안전', '보건', '위험', '소방'])) {
      return const _CertificationVisualSpec(
        accent: Color(0xFFDC2626),
        icon: Icons.health_and_safety_rounded,
        backgroundIcon: Icons.shield_rounded,
      );
    }
    if (_containsAny(text, ['기계', '자동차', '용접', '금속', '설비'])) {
      return const _CertificationVisualSpec(
        accent: Color(0xFFEA580C),
        icon: Icons.precision_manufacturing_rounded,
        backgroundIcon: Icons.settings_rounded,
      );
    }
    if (_containsAny(text, ['경영', '회계', '세무', '금융', '무역'])) {
      return const _CertificationVisualSpec(
        accent: AppColors.tertiary,
        icon: Icons.account_balance_rounded,
        backgroundIcon: Icons.bar_chart_rounded,
      );
    }
    return const _CertificationVisualSpec(
      accent: AppColors.secondary,
      icon: Icons.workspace_premium_rounded,
      backgroundIcon: Icons.school_rounded,
    );
  }
}

class _ExploreInfoPanel extends StatelessWidget {
  const _ExploreInfoPanel({
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
          Icon(icon, size: 34, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.x3),
          Text(title, textAlign: TextAlign.center, style: textTheme.titleSmall),
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

String _formatCount(int value) {
  if (value >= 10000) {
    final fixed = (value / 10000).toStringAsFixed(1);
    final compact =
        fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
    return '$compact만';
  }
  return '$value';
}

bool _containsAny(String value, List<String> keywords) {
  final lower = value.toLowerCase();
  return keywords.any((keyword) => lower.contains(keyword.toLowerCase()));
}

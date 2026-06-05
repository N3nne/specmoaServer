import 'dart:async';

import 'package:flutter/material.dart';

import '../models/certification_ranking_data.dart';
import '../models/certification_search_data.dart';
import '../services/certification_ranking_api_client.dart';
import '../services/certification_search_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_page.dart';
import 'certification_detail_screen.dart';

class PopularCertificationsScreen extends StatefulWidget {
  const PopularCertificationsScreen({super.key});

  @override
  State<PopularCertificationsScreen> createState() =>
      _PopularCertificationsScreenState();
}

class _PopularCertificationsScreenState
    extends State<PopularCertificationsScreen> {
  final _rankingClient = const CertificationRankingApiClient();
  final _searchClient = const CertificationSearchApiClient();
  final _fieldTagSearchController = TextEditingController();
  final _tabs = const [
    _RankingTab(label: '전체', metric: 'popular'),
    _RankingTab(label: '분야별', metric: 'field'),
    _RankingTab(label: '합격률', metric: 'pass_rate'),
  ];

  int _selectedTab = 0;
  String _qualificationType = 'all';
  CertificationSearchTag? _selectedFieldTag;
  List<CertificationSearchTag> _fieldTags = const [];
  bool _loadingFieldTags = false;
  Timer? _fieldTagSearchDebounce;
  late Future<List<CertificationRankingItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    _loadFieldTags();
  }

  @override
  void dispose() {
    _fieldTagSearchDebounce?.cancel();
    _fieldTagSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _tabs[_selectedTab];
    final showFieldTags = selected.metric == 'field';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate:
                  _RankingHeaderDelegate(onBack: Navigator.of(context).pop),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.x4),
                    Text(
                      _subtitleFor(selected.metric),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    _TabSelector(
                      tabs: _tabs,
                      selectedIndex: _selectedTab,
                      onSelected: (index) {
                        setState(() {
                          _selectedTab = index;
                          _selectedFieldTag = null;
                          _future = _fetch();
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    _QualificationFilter(
                      selected: _qualificationType,
                      enabled: selected.metric != 'age',
                      onSelected: (value) async {
                        setState(() {
                          _qualificationType = value;
                          _selectedFieldTag = null;
                          _future = _fetch();
                        });
                        await _loadFieldTags();
                      },
                    ),
                    if (showFieldTags) ...[
                      const SizedBox(height: AppSpacing.x4),
                      _FieldTagSelector(
                        loading: _loadingFieldTags,
                        controller: _fieldTagSearchController,
                        tags: _fieldTags,
                        selectedTag: _selectedFieldTag,
                        onQueryChanged: _onFieldTagQueryChanged,
                        onSelected: (tag) {
                          setState(() {
                            _selectedFieldTag =
                                _selectedFieldTag?.id == tag.id ? null : tag;
                            _future = _fetch();
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.x4),
                    FutureBuilder<List<CertificationRankingItem>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const _RankingLoading();
                        }
                        if (snapshot.hasError) {
                          return const _RankingError();
                        }

                        final items = snapshot.data ?? const [];
                        return _RankingList(
                          metric: selected.metric,
                          items: items,
                          onOpen: _openDetail,
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

  Future<List<CertificationRankingItem>> _fetch() {
    final metric = _tabs[_selectedTab].metric;
    return _rankingClient.fetchRankings(
      metric: metric,
      qualificationType: _qualificationType,
      tagId: metric == 'field' ? _selectedFieldTag?.id : null,
      limit: 30,
    );
  }

  Future<void> _loadFieldTags() async {
    setState(() => _loadingFieldTags = true);
    try {
      final tags = await _searchClient.fetchTags(
        limit: _fieldTagSearchController.text.trim().isEmpty ? 18 : 30,
        qualificationType: _qualificationType,
        query: _fieldTagSearchController.text,
      );
      if (mounted) {
        setState(() => _fieldTags = tags);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingFieldTags = false);
      }
    }
  }

  void _onFieldTagQueryChanged(String value) {
    _fieldTagSearchDebounce?.cancel();
    _fieldTagSearchDebounce = Timer(
      const Duration(milliseconds: 240),
      _loadFieldTags,
    );
  }

  void _openDetail(CertificationRankingItem item) {
    if (!item.opensDetail) {
      return;
    }

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

  String _subtitleFor(String metric) {
    return switch (metric) {
      'field' => '분야 태그를 선택해서 해당 분야의 인기 자격증을 볼 수 있어요.',
      'pass_rate' => '응시자 50명 이상 자격증 중 합격률이 높은 순서예요.',
      _ => '응시자 수 기준으로 가장 많이 찾는 자격증이에요.',
    };
  }
}

class _RankingTab {
  const _RankingTab({required this.label, required this.metric});

  final String label;
  final String metric;
}

class _RankingHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _RankingHeaderDelegate({required this.onBack});

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
              '인기 자격증',
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
  bool shouldRebuild(covariant _RankingHeaderDelegate oldDelegate) =>
      oldDelegate.onBack != onBack;
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_RankingTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x2),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;
          return ChoiceChip(
            label: Text(tabs[index].label),
            selected: selected,
            onSelected: (_) => onSelected(index),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: colorScheme.surface,
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      selected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
            side: BorderSide(
              color: selected ? AppColors.primary : colorScheme.outlineVariant,
            ),
          );
        },
      ),
    );
  }
}

class _QualificationFilter extends StatelessWidget {
  const _QualificationFilter({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      _FilterChipData(label: '전체', value: 'all'),
      _FilterChipData(label: '국가기술', value: 'national_technical'),
      _FilterChipData(label: '전문자격', value: 'professional'),
    ];

    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        for (final item in items)
          ChoiceChip(
            label: Text(item.label),
            selected: selected == item.value,
            onSelected: enabled ? (_) => onSelected(item.value) : null,
            showCheckmark: false,
          ),
      ],
    );
  }
}

class _FieldTagSelector extends StatelessWidget {
  const _FieldTagSelector({
    required this.loading,
    required this.controller,
    required this.tags,
    required this.selectedTag,
    required this.onQueryChanged,
    required this.onSelected,
  });

  final bool loading;
  final TextEditingController controller;
  final List<CertificationSearchTag> tags;
  final CertificationSearchTag? selectedTag;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<CertificationSearchTag> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '분야 태그',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: AppSpacing.x2),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: '분야 태그 검색',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x4,
                vertical: AppSpacing.x2,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x2),
        if (loading)
          const SizedBox(
            height: 3,
            child: LinearProgressIndicator(),
          ),
        if (loading) const SizedBox(height: AppSpacing.x2),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x2),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ChoiceChip(
                  label: const Text('전체 분야'),
                  selected: selectedTag == null,
                  onSelected: (_) {
                    if (selectedTag != null && tags.isNotEmpty) {
                      onSelected(selectedTag!);
                    }
                  },
                  showCheckmark: false,
                );
              }

              final tag = tags[index - 1];
              final selected = selectedTag?.id == tag.id;
              return ChoiceChip(
                label: Text('${tag.name} ${tag.certificationCount}'),
                selected: selected,
                onSelected: (_) => onSelected(tag),
                showCheckmark: false,
                selectedColor: AppColors.primary,
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChipData {
  const _FilterChipData({required this.label, required this.value});

  final String label;
  final String value;
}

class _RankingList extends StatelessWidget {
  const _RankingList({
    required this.metric,
    required this.items,
    required this.onOpen,
  });

  final String metric;
  final List<CertificationRankingItem> items;
  final ValueChanged<CertificationRankingItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _RankingEmpty();
    }

    return Column(
      children: [
        for (final item in items) ...[
          _RankingCard(
            metric: metric,
            item: item,
            onTap: () => onOpen(item),
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.metric,
    required this.item,
    required this.onTap,
  });

  final String metric;
  final CertificationRankingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryLabel = '응시 ${_formatCount(item.primaryCount)}';
    final passRate =
        item.passRate == null ? null : '${item.passRate!.toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.opensDetail ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    '${item.rank}',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x2),
                          _SmallBadge(item.metaLabel ?? item.category),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        item.organization?.isNotEmpty == true
                            ? item.organization!
                            : item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      Wrap(
                        spacing: AppSpacing.x2,
                        runSpacing: AppSpacing.x1,
                        children: [
                          _StatPill(
                            icon: Icons.groups_rounded,
                            label: primaryLabel,
                          ),
                          if (passRate != null)
                            _StatPill(
                              icon: Icons.check_circle_outline_rounded,
                              label: '합격률 $passRate',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (item.opensDetail)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.outline,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge(this.label);

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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _RankingLoading extends StatelessWidget {
  const _RankingLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.x12),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RankingError extends StatelessWidget {
  const _RankingError();

  @override
  Widget build(BuildContext context) {
    return const _MessageBox(
      icon: Icons.error_outline_rounded,
      title: '랭킹을 불러오지 못했어요',
      message: '잠시 후 다시 시도해주세요.',
    );
  }
}

class _RankingEmpty extends StatelessWidget {
  const _RankingEmpty();

  @override
  Widget build(BuildContext context) {
    return const _MessageBox(
      icon: Icons.inbox_outlined,
      title: '표시할 랭킹이 없어요',
      message: '다른 기준을 선택해보세요.',
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
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

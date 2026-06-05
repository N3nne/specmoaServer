import 'package:flutter/material.dart';

import '../models/user_certification_data.dart';
import '../services/user_certification_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo_icon.dart';
import '../widgets/responsive_page.dart';
import 'certification_detail_screen.dart';
import 'certification_register_screen.dart';

class CertificationsScreen extends StatefulWidget {
  const CertificationsScreen({
    this.userId,
    super.key,
  });

  final String? userId;

  @override
  State<CertificationsScreen> createState() => _CertificationsScreenState();
}

class _CertificationsScreenState extends State<CertificationsScreen> {
  final _client = const UserCertificationApiClient();
  SpecFilter _filter = SpecFilter.all;
  final Set<String> _deletingIds = {};
  late Future<UserCertificationPage> _future;

  @override
  void initState() {
    super.initState();
    _future = _client.fetchMine(userId: widget.userId);
  }

  @override
  void didUpdateWidget(covariant CertificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _future = _client.fetchMine(userId: widget.userId);
    }
  }

  Future<void> _refresh() async {
    final nextFuture = _client.fetchMine(userId: widget.userId);
    setState(() => _future = nextFuture);
    try {
      await nextFuture;
    } catch (_) {
      // FutureBuilder displays the error state; keep manual refresh taps quiet.
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<UserCertificationPage>(
              future: _future,
              builder: (context, snapshot) {
                final items = snapshot.data?.items ?? const [];
                final visibleItems = _filtered(items);

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: ResponsivePage(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.x5),
                            Row(
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
                                  tooltip: '새로고침',
                                  onPressed: _refresh,
                                  icon: const Icon(Icons.refresh_rounded),
                                ),
                                IconButton(
                                  tooltip: '검색',
                                  onPressed: () {},
                                  icon: const Icon(Icons.search_rounded),
                                ),
                                IconButton(
                                  tooltip: '정렬',
                                  onPressed: () {},
                                  icon: const Icon(Icons.tune_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.x5),
                            _SpecSummaryPanel(
                              items: items,
                              selected: _filter,
                              onChanged: (filter) {
                                setState(() => _filter = filter);
                              },
                            ),
                            const SizedBox(height: AppSpacing.x8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '자격증 리스트',
                                    style: textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  '${visibleItems.length}개 표시',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.x3),
                            if (snapshot.connectionState !=
                                ConnectionState.done)
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.x12,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (snapshot.hasError)
                              const _InfoText(
                                text: '자격증 정보를 불러오지 못했습니다.',
                                icon: Icons.error_outline_rounded,
                              )
                            else if (items.isEmpty)
                              const _InfoText(
                                text: '자격증을 등록해주세요!',
                                icon: Icons.inventory_2_outlined,
                              )
                            else if (visibleItems.isEmpty)
                              const _InfoText(
                                text: '선택한 상태의 자격증이 없습니다.',
                                icon: Icons.filter_alt_off_outlined,
                              )
                            else
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Column(
                                  key: ValueKey(_filter),
                                  children: [
                                    for (final item in visibleItems) ...[
                                      _SpecListCard(
                                        item: item,
                                        onTap: () => _openDetail(item),
                                        onDelete: () => _confirmDelete(item),
                                      ),
                                      if (item != visibleItems.last)
                                        const SizedBox(height: AppSpacing.x3),
                                    ],
                                  ],
                                ),
                              ),
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
          Positioned(
            right: AppSpacing.x5,
            bottom: 92,
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CertificationRegisterScreen(),
                  ),
                );
                if (mounted) {
                  _refresh();
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }

  List<UserCertificationItem> _filtered(List<UserCertificationItem> items) {
    return items.where((item) {
      return switch (_filter) {
        SpecFilter.all => true,
        SpecFilter.progress => !item.certified,
        SpecFilter.completed => item.certified,
      };
    }).toList();
  }

  void _openDetail(UserCertificationItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CertificationDetailScreen(
          certificationId: item.certification.id,
          certificationName: item.certification.name,
          category: item.certification.category,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(UserCertificationItem item) async {
    if (_deletingIds.contains(item.id)) {
      return;
    }

    setState(() => _deletingIds.add(item.id));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자격증 삭제'),
        content: Text('${item.certification.name}을(를) 목록에서 삭제할까요?'),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.x6,
          AppSpacing.x2,
          AppSpacing.x6,
          AppSpacing.x5,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: const Text('삭제'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      if (mounted) {
        setState(() => _deletingIds.remove(item.id));
      }
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _client.remove(
        userId: widget.userId ?? '',
        userCertificationId: item.id,
      );
      if (mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('선택하신 자격증이 목록에서 지워졌습니다.'),
          ),
        );
        final nextFuture = _client.fetchMine(userId: widget.userId);
        setState(() {
          _deletingIds.remove(item.id);
          _future = nextFuture;
        });
        try {
          await nextFuture;
        } catch (_) {
          // The list area will show its own error state; deletion already succeeded.
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _deletingIds.remove(item.id));
        messenger.showSnackBar(
          const SnackBar(content: Text('자격증 삭제에 실패했습니다.')),
        );
      }
    }
  }
}

enum SpecFilter { all, progress, completed }

class _SpecSummaryPanel extends StatelessWidget {
  const _SpecSummaryPanel({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<UserCertificationItem> items;
  final SpecFilter selected;
  final ValueChanged<SpecFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = items.length;
    final completed = items.where((item) => item.certified).length;
    final progress = total - completed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
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
            '나의 스펙 요약',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text.rich(
            TextSpan(
              text: '전체 자격증 ',
              children: [
                TextSpan(
                  text: '$total',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.secondaryContainer,
                  ),
                ),
                const TextSpan(text: '개'),
              ],
            ),
            style:
                textTheme.headlineSmall?.copyWith(color: AppColors.onPrimary),
          ),
          const SizedBox(height: AppSpacing.x5),
          Row(
            children: [
              Expanded(
                child: _FilterMetric(
                  label: '전체',
                  value: '$total',
                  active: selected == SpecFilter.all,
                  onTap: () => onChanged(SpecFilter.all),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: _FilterMetric(
                  label: '진행 중',
                  value: '$progress',
                  active: selected == SpecFilter.progress,
                  onTap: () => onChanged(SpecFilter.progress),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: _FilterMetric(
                  label: '완료',
                  value: '$completed',
                  active: selected == SpecFilter.completed,
                  onTap: () => onChanged(SpecFilter.completed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterMetric extends StatelessWidget {
  const _FilterMetric({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.white.withValues(alpha: active ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                value,
                style:
                    textTheme.titleLarge?.copyWith(color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecListCard extends StatelessWidget {
  const _SpecListCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final UserCertificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final completed = item.certified;
    final accent = completed ? AppColors.tertiary : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x5),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x3,
                      vertical: AppSpacing.x1,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      item.certification.category.isEmpty
                          ? '자격증'
                          : item.certification.category,
                      style: textTheme.labelSmall?.copyWith(color: accent),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '삭제',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x2,
                      vertical: AppSpacing.x1,
                    ),
                    decoration: BoxDecoration(
                      color: completed
                          ? AppColors.tertiary.withValues(alpha: 0.1)
                          : AppColors.errorContainer.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _statusLabel(item),
                      style: textTheme.labelMedium?.copyWith(
                        color: completed ? AppColors.tertiary : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x4),
              Text(item.certification.name, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle_rounded
                        : Icons.calendar_today_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Text(
                      _metaLabel(item),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(UserCertificationItem item) {
    if (item.certified) {
      return '취득 완료';
    }
    if (item.status == 'in_progress') {
      return '진행 중';
    }
    return '취득 예정';
  }

  String _metaLabel(UserCertificationItem item) {
    if (item.certified) {
      return item.certifiedOn == null ? '취득 완료' : '취득일 ${item.certifiedOn}';
    }
    if (item.targetExamDate != null) {
      return '목표 시험일 ${item.targetExamDate}';
    }
    if (item.notes?.trim().isNotEmpty ?? false) {
      return item.notes!.trim();
    }
    return item.certification.organization.isEmpty
        ? '등록된 자격증'
        : item.certification.organization;
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.48),
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            text,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.68),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

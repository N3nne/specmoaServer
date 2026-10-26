import 'package:flutter/material.dart';

import '../models/user_spec.dart';
import '../services/user_spec_api_client.dart';
import '../widgets/responsive_page.dart';
import 'specs/spec_register_screen.dart';
import 'specs/spec_type_selection_screen.dart';

class MySpecScreen extends StatefulWidget {
  const MySpecScreen({
    this.userId,
    this.displayName,
    this.client = const UserSpecApiClient(),
    super.key,
  });

  final String? userId;
  final String? displayName;
  final UserSpecApiClient client;

  @override
  State<MySpecScreen> createState() => _MySpecScreenState();
}

class _MySpecScreenState extends State<MySpecScreen> {
  UserSpecApiClient get _client => widget.client;
  late Future<List<UserSpec>> _future;

  @override
  void initState() {
    super.initState();
    _future = _client.fetchMine();
  }

  @override
  void didUpdateWidget(covariant MySpecScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.client != widget.client) {
      _future = _client.fetchMine();
    }
  }

  Future<void> _refresh() async {
    final future = _client.fetchMine();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _C.surface,
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<List<UserSpec>>(
          key: ValueKey(widget.userId),
          future: _future,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <UserSpec>[];
            return RefreshIndicator(
              color: _C.primary,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ResponsivePage(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _Hero(name: _name, items: items),
                          const SizedBox(height: 12),
                          _AddBanner(onTap: _openAddSheet),
                          const SizedBox(height: 28),
                          _SectionHeader(
                            index: '01',
                            title: '시험 · 성적 스펙',
                            count: items
                                .where((item) => item.type.isExamScore)
                                .length,
                            icon: Icons.verified_rounded,
                            trailing: '공식 연계 준비',
                            accent: _C.primary,
                          ),
                          const SizedBox(height: 16),
                          if (snapshot.connectionState != ConnectionState.done)
                            const _Loading()
                          else if (snapshot.hasError)
                            _Failure(onRetry: _refresh)
                          else if (!items.any((item) => item.type.isExamScore))
                            const _EmptyCertification()
                          else
                            ..._categories(items, true),
                          const SizedBox(height: 32),
                          _SectionHeader(
                            index: '02',
                            title: '활동 · 경험 스토리',
                            count: items
                                .where((item) => !item.type.isExamScore)
                                .length,
                            icon: Icons.psychology_rounded,
                            trailing: '직접 기록한 경험',
                            accent: _C.tertiary,
                          ),
                          const SizedBox(height: 16),
                          if (items.any((item) => !item.type.isExamScore))
                            ..._categories(items, false)
                          else
                            const _ExperienceEmpty(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String get _name {
    final name = widget.displayName?.trim() ?? '';
    return name.isEmpty ? '나' : name;
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  List<Widget> _categories(List<UserSpec> items, bool exam) {
    return [
      for (final type in SpecType.values.where((type) =>
          type.isExamScore == exam &&
          items.any((item) => item.type == type))) ...[
        _CategoryHeader(
            label:
                '${type.label} (${items.where((item) => item.type == type).length})',
            accent: exam ? _C.primary : _C.tertiary),
        const SizedBox(height: 8),
        for (final item in items.where((item) => item.type == type))
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CertificationCard(
                  item: item,
                  onTap: () => _openDetail(item),
                  onDelete: () => _delete(item))),
      ]
    ];
  }

  Future<void> _openDetail(UserSpec item) async {
    final saved = await Navigator.of(context).push<UserSpec>(MaterialPageRoute(
        builder: (_) => SpecRegisterScreen(type: item.type, initial: item)));
    if (saved != null && mounted) await _refresh();
  }

  Future<void> _delete(UserSpec item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('스펙 삭제'),
        content:
            Text('${item.displayTitle}을(를) 내 스펙에서 삭제할까요? 연결된 학습 기록도 삭제됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _C.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _client.remove(item.id);
      if (!mounted) return;
      _notice('선택하신 스펙이 내 스펙에서 삭제됐습니다.');
      await _refresh();
    } catch (_) {
      if (mounted) _notice('스펙 삭제에 실패했습니다.');
    }
  }

  Future<void> _openAddSheet() async {
    int? count;
    try {
      count = (await _future).length;
    } catch (_) {}
    if (!mounted) return;
    final saved = await Navigator.of(context).push<UserSpec>(MaterialPageRoute(
        builder: (_) => SpecTypeSelectionScreen(existingCount: count)));
    if (saved != null && mounted) await _refresh();
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.name, required this.items});
  final String name;
  final List<UserSpec> items;

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) => item.type.isExamScore).length;
    final preparing = items.length - completed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x4D2563EB),
              blurRadius: 32,
              spreadRadius: -8,
              offset: Offset(0, 12))
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
              right: -40,
              bottom: -40,
              child: Container(
                  width: 176,
                  height: 176,
                  decoration: const BoxDecoration(
                      color: Color(0x1AFFFFFF), shape: BoxShape.circle))),
          const Positioned(
              top: -12,
              right: -16,
              child: Opacity(
                  opacity: .1,
                  child: Icon(Icons.inventory_2_outlined,
                      size: 108, color: Colors.white))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                      child: Text('SPEC ARCHIVE · OVERVIEW',
                          style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w600,
                              color: Color(0xE6DBEAFE)))),
                  _HeroBadge(count: items.length),
                ],
              ),
              const SizedBox(height: 12),
              Text('$name님의 스펙 아카이브',
                  style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.2,
                      color: Colors.white)),
              const SizedBox(height: 4),
              const Text('정량적 공인 성적과 정성적 프로젝트 경험이 균형 있게 보관되어 있습니다.',
                  style: TextStyle(
                      fontSize: 12, height: 1.45, color: Color(0xE6DBEAFE))),
              const SizedBox(height: 20),
              _Balance(
                  total: items.length,
                  completed: completed,
                  preparing: preparing),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x33FFFFFF))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text('등록 $count건',
              style: const TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white))
        ]),
      );
}

class _Balance extends StatelessWidget {
  const _Balance(
      {required this.total, required this.completed, required this.preparing});
  final int total;
  final int completed;
  final int preparing;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x26FFFFFF))),
        child: Column(children: [
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const _BalanceLabel(dot: Color(0xFFBFDBFE), text: '시험 · 성적'),
                  const SizedBox(width: 5),
                  Text('$completed',
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ]),
                Text('총 $total건 등록',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1,
                        color: Color(0xFFBFDBFE))),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const _BalanceLabel(dot: Color(0xFFD8B4FE), text: '활동 · 경험'),
                  const SizedBox(width: 5),
                  Text('$preparing',
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ]),
              ]),
          const SizedBox(height: 10),
          Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                  color: const Color(0x33000000),
                  borderRadius: BorderRadius.circular(999)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Row(children: [
                    if (completed > 0)
                      Expanded(
                          flex: completed,
                          child: const ColoredBox(
                              color: Color(0xFFBFDBFE),
                              child: SizedBox.expand())),
                    if (preparing > 0)
                      Expanded(
                          flex: preparing,
                          child: const ColoredBox(
                              color: Color(0xFFD8B4FE),
                              child: SizedBox.expand())),
                  ]))),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0x1AFFFFFF)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
                child: Text('시험·성적 $completed건',
                    style: const TextStyle(
                        fontSize: 11, height: 1.2, color: Color(0xCCDBEAFE)))),
            Text('활동·경험 $preparing건',
                style: const TextStyle(
                    fontSize: 11, height: 1.2, color: Color(0xCCDBEAFE)))
          ]),
        ]),
      );
}

class _BalanceLabel extends StatelessWidget {
  const _BalanceLabel({required this.dot, required this.text});
  final Color dot;
  final String text;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w600,
                color: Colors.white))
      ]);
}

class _AddBanner extends StatelessWidget {
  const _AddBanner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: _C.lowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.container),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ]),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add_rounded,
                      size: 22, color: _C.primary)),
              const SizedBox(width: 14),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Text('새로운 스펙 추가하기',
                          style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: _C.onSurface)),
                      SizedBox(width: 6),
                      _OneClick()
                    ]),
                    SizedBox(height: 2),
                    Text('새로운 스펙 항목을 추가하고 포트폴리오를 완성하세요',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: _C.onSurfaceVariant)),
                  ])),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: _C.outlineVariant),
            ]),
          ),
        ),
      );
}

class _OneClick extends StatelessWidget {
  const _OneClick();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: _C.primary.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(4)),
      child: const Text('원클릭',
          style: TextStyle(
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w600,
              color: _C.primary)));
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.index,
      required this.title,
      required this.count,
      required this.icon,
      required this.trailing,
      required this.accent});
  final String index;
  final String title;
  final int count;
  final IconData icon;
  final String trailing;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 4),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xB3E5E9EB)))),
        child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(index,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: accent)),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(title,
                        style: const TextStyle(
                            fontFamily: 'SpecJakarta',
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: _C.onSurface))),
                const SizedBox(width: 6),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text('$count',
                        style: TextStyle(
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: accent)))
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 13, color: accent),
                const SizedBox(width: 4),
                Text(trailing,
                    style: const TextStyle(
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: FontWeight.w500,
                        color: _C.onSurfaceVariant)),
              ]),
            ]),
      );
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.accent});
  final String label;
  final Color accent;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 4,
            height: 12,
            decoration: BoxDecoration(
                color: accent, borderRadius: BorderRadius.circular(999))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                letterSpacing: .6,
                fontWeight: FontWeight.w700,
                color: _C.onSurfaceVariant))
      ]);
}

class _CertificationCard extends StatelessWidget {
  const _CertificationCard(
      {required this.item, required this.onTap, required this.onDelete});
  final UserSpec item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final complete = item.type.isExamScore;
    final accent = complete ? _C.secondary : _C.primary;
    return Material(
      color: _C.lowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.container),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Wrap(spacing: 6, runSpacing: 4, children: [
                _Tag(
                    label: item.type.label,
                    background: accent.withValues(alpha: .1),
                    foreground: accent),
                const _Tag(
                    label: '미검증',
                    background: _C.container,
                    foreground: _C.onSurfaceVariant,
                    pill: true),
              ])),
              const SizedBox(width: 8),
              _Tag(
                  label: item.data['ongoing'] == true ? '진행 중' : '등록 내역',
                  background: complete
                      ? _C.secondaryContainer.withValues(alpha: .4)
                      : _C.error.withValues(alpha: .1),
                  foreground: complete ? _C.secondary : _C.error),
              IconButton(
                  tooltip: '삭제',
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 28, height: 24),
                  icon: const Icon(Icons.more_horiz_rounded,
                      size: 20, color: _C.outline)),
            ]),
            const SizedBox(height: 10),
            Text(item.displayTitle,
                style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: _C.onSurface)),
            const SizedBox(height: 2),
            Text(_specSubtitle(item),
                style: const TextStyle(
                    fontSize: 12, height: 1.35, color: _C.onSurfaceVariant)),
            const SizedBox(height: 12),
            Container(height: 1, color: _C.low),
            const SizedBox(height: 10),
            Row(children: [
              Icon(
                  complete
                      ? Icons.check_circle_outline_rounded
                      : Icons.calendar_today_outlined,
                  size: 13,
                  color: complete ? _C.secondary : _C.outline),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(_footer(item),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: complete ? _C.onSurfaceVariant : _C.error,
                          fontWeight:
                              complete ? FontWeight.w400 : FontWeight.w500))),
              Text(
                  item.text('certificateNumber').isNotEmpty
                      ? 'No. ${item.text('certificateNumber')}'
                      : '수정하기',
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      height: 1.2,
                      color: _C.outline)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(
      {required this.label,
      required this.background,
      required this.foreground,
      this.pill = false});
  final String label;
  final Color background;
  final Color foreground;
  final bool pill;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(pill ? 999 : 4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w600,
              color: foreground)));
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2))));
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _EmptyFrame(
          child: Column(children: [
        const Icon(Icons.cloud_off_rounded, size: 22, color: _C.outline),
        const SizedBox(height: 6),
        const Text('내 스펙을 불러오지 못했습니다.',
            style: TextStyle(fontSize: 12, color: _C.onSurfaceVariant)),
        TextButton(onPressed: onRetry, child: const Text('다시 시도'))
      ]));
}

class _EmptyCertification extends StatelessWidget {
  const _EmptyCertification();
  @override
  Widget build(BuildContext context) => const _EmptyFrame(
          child: Column(children: [
        Icon(Icons.inventory_2_outlined, size: 22, color: _C.outline),
        SizedBox(height: 6),
        Text('등록된 시험 · 성적 스펙이 없습니다',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.onSurfaceVariant)),
        SizedBox(height: 2),
        Text('상단 스펙 추가를 통해 취득한 스펙을 등록해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: _C.outline))
      ]));
}

class _ExperienceEmpty extends StatelessWidget {
  const _ExperienceEmpty();
  @override
  Widget build(BuildContext context) => const _EmptyFrame(
          child: Column(children: [
        CircleAvatar(
            radius: 16,
            backgroundColor: _C.container,
            child: Icon(Icons.military_tech_outlined,
                size: 18, color: _C.outline)),
        SizedBox(height: 6),
        Text('등록된 활동 · 경험 스펙이 없습니다',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.onSurfaceVariant)),
        SizedBox(height: 2),
        Text('상단 스펙 추가를 통해 프로젝트와 활동 이력을 연결해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: _C.outline))
      ]));
}

class _EmptyFrame extends StatelessWidget {
  const _EmptyFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _C.lowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.container)),
      child: child);
}

String _specSubtitle(UserSpec item) {
  final keys = switch (item.type) {
    SpecType.certification => ['issuer', 'result', 'grade'],
    SpecType.languageScore => ['score', 'grade', 'issuer'],
    SpecType.educationRecord => ['major', 'degree', 'academicStatus'],
    SpecType.award => ['organizer', 'prize'],
    SpecType.project => ['projectType', 'role'],
    SpecType.workExperience => ['employmentType', 'departmentRole'],
    SpecType.externalActivity => ['organizer', 'activityType'],
    SpecType.training => ['institution', 'trainingType'],
  };
  final values =
      keys.map(item.text).where((value) => value.isNotEmpty).toList();
  return values.isEmpty ? '정보 미입력' : values.join(' · ');
}

String _footer(UserSpec item) {
  for (final key in [
    'acquiredOn',
    'testedOn',
    'awardedOn',
    'completedOn',
    'startedMonth'
  ]) {
    if (item.text(key).isNotEmpty) return item.text(key).replaceAll('-', '.');
  }
  return '날짜 미입력';
}

class _C {
  const _C._();
  static const surface = Color(0xFFF5F7F9);
  static const lowest = Color(0xFFFFFFFF);
  static const low = Color(0xFFEEF1F3);
  static const container = Color(0xFFE5E9EB);
  static const primary = Color(0xFF0057BD);
  static const secondary = Color(0xFF3A53B7);
  static const secondaryContainer = Color(0xFFC7CFFF);
  static const tertiary = Color(0xFF893C92);
  static const onSurface = Color(0xFF2C2F31);
  static const onSurfaceVariant = Color(0xFF595C5E);
  static const outline = Color(0xFF747779);
  static const outlineVariant = Color(0xFFABADAF);
  static const error = Color(0xFFB31B25);
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_session.dart';
import '../models/job_comparison.dart';
import '../models/job_data.dart';
import '../services/authenticated_client.dart';
import '../services/job_api_client.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen(
      {super.key,
      required this.jobId,
      required this.userId,
      this.client = const JobApiClient(),
      this.openLink});

  final String jobId;
  final String userId;
  final JobApiClient client;
  final Future<bool> Function(Uri)? openLink;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _scroll = ScrollController();
  final _anchors = List.generate(3, (_) => GlobalKey());
  JobDetail? _detail;
  JobComparison? _comparison;
  bool _loading = true;
  bool _comparisonLoading = true;
  bool _opening = false;
  String? _error;
  String? _comparisonError;
  int _revision = 0;
  int _comparisonRevision = 0;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant JobDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobId != widget.jobId ||
        oldWidget.userId != widget.userId ||
        oldWidget.client != widget.client) {
      _selected = 0;
      _opening = false;
      _load();
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _current(int revision, int generation) =>
      mounted &&
      revision == _revision &&
      generation == ApiCredentials.generation;

  Future<void> _load() async {
    final revision = ++_revision;
    final generation = ApiCredentials.generation;
    ++_comparisonRevision;
    setState(() {
      _loading = true;
      _error = null;
      _detail = null;
      _comparison = null;
      _comparisonLoading = true;
      _comparisonError = null;
    });
    try {
      final detail = await widget.client.fetchDetail(widget.jobId);
      if (!_current(revision, generation)) return;
      if (detail.job.id != widget.jobId) {
        throw const FormatException('Mismatched job ID');
      }
      setState(() {
        _detail = detail;
        _loading = false;
      });
      await _loadComparison();
    } catch (error) {
      if (!_current(revision, generation)) return;
      setState(() {
        _error = error is JobApiException && error.statusCode == 404
            ? error.message
            : '공고 상세 정보를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  Future<void> _loadComparison() async {
    if (_detail == null) return;
    final request = ++_comparisonRevision;
    final revision = _revision;
    final generation = ApiCredentials.generation;
    setState(() {
      _comparisonLoading = true;
      _comparisonError = null;
    });
    try {
      final result = await widget.client.fetchComparison(widget.jobId);
      if (!_current(revision, generation) || request != _comparisonRevision) {
        return;
      }
      if (result.job.job.id != widget.jobId) {
        throw const FormatException('Mismatched job ID');
      }
      setState(() {
        _detail = result.job;
        _comparison = result.comparison;
        _comparisonLoading = false;
      });
    } catch (_) {
      if (!_current(revision, generation) || request != _comparisonRevision) {
        return;
      }
      setState(() {
        _comparisonError = '조건 비교 결과를 불러오지 못했습니다.';
        _comparisonLoading = false;
      });
    }
  }

  double get _tabsHeight =>
      40 + MediaQuery.textScalerOf(context).scale(12) * 4 / 3;

  void _jumpTo(int index) {
    setState(() => _selected = index);
    final render = _anchors[index].currentContext?.findRenderObject();
    if (render == null || !_scroll.hasClients) return;
    final viewport = RenderAbstractViewport.of(render);
    // The viewport already accounts for the pinned segment header obstruction.
    final target = viewport.getOffsetToReveal(render, 0).offset;
    _scroll.animateTo(target.clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _share() async {
    final uri = _detail?.sourceUri;
    if (uri == null) return;
    final revision = _revision;
    final generation = ApiCredentials.generation;
    try {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (_current(revision, generation)) _notice('공고 링크가 클립보드에 복사되었습니다.');
    } catch (_) {
      if (_current(revision, generation)) _notice('링크를 복사하지 못했습니다.');
    }
  }

  Future<void> _apply() async {
    final detail = _detail;
    if (_opening || detail == null || !detail.canOpenApplication) return;
    final revision = _revision;
    final generation = ApiCredentials.generation;
    setState(() => _opening = true);
    try {
      final opened = await (widget.openLink?.call(detail.sourceUri!) ??
          launchUrl(detail.sourceUri!, mode: LaunchMode.externalApplication));
      if (_current(revision, generation) && !opened) {
        _notice('지원 페이지를 열지 못했습니다.');
      }
    } catch (_) {
      if (_current(revision, generation)) _notice('지원 페이지를 열지 못했습니다.');
    } finally {
      if (_current(revision, generation)) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _DetailColors(context);
    final session =
        context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
    if (session != null && session.user?.id != widget.userId) {
      return Scaffold(backgroundColor: colors.background);
    }
    return Scaffold(
      extendBody: true,
      backgroundColor: colors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        leadingWidth: 56,
        titleSpacing: 0,
        backgroundColor: colors.background.withValues(alpha: .8),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        shadowColor: const Color(0x0A000000),
        leading: IconButton(
            tooltip: '뒤로가기',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, size: 24, color: colors.primary)),
        title: Text('상세정보',
            style: _type(20, colors.text,
                weight: FontWeight.w700, headline: true)),
        flexibleSpace: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: const SizedBox.expand())),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!,
                            style: _type(13, colors.secondary),
                            textAlign: TextAlign.center),
                        IconButton(
                            tooltip: '다시 시도',
                            onPressed: _load,
                            icon: const Icon(Icons.refresh)),
                      ])))
              : _content(_detail!, colors),
      bottomNavigationBar:
          _detail == null ? null : _applicationBar(_detail!, colors),
    );
  }

  Widget _constrain(Widget child, {EdgeInsets padding = EdgeInsets.zero}) =>
      Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 672),
              child: Padding(padding: padding, child: child)));

  Widget _content(JobDetail detail, _DetailColors colors) => CustomScrollView(
        key: ValueKey('job-detail-${detail.job.id}'),
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(
              child: _constrain(
                  Column(children: [
                    _utility(detail, colors),
                    const SizedBox(height: 24),
                    _company(detail, colors),
                    const SizedBox(height: 24),
                    _ComparisonCard(
                        key: const ValueKey('job-comparison'),
                        detail: detail,
                        comparison: _comparison,
                        loading: _comparisonLoading,
                        error: _comparisonError,
                        onRetry: _loadComparison,
                        colors: colors),
                  ]),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24))),
          SliverPersistentHeader(
              pinned: true,
              delegate: _DetailSegments(
                  height: _tabsHeight,
                  selected: _selected,
                  onSelected: _jumpTo,
                  colors: colors)),
          SliverToBoxAdapter(
              child: _constrain(
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DetailSection(
                            key: _anchors[0],
                            title: '공고 상세',
                            icon: Icons.work_outline,
                            colors: colors,
                            child: Text(
                                detail.description?.trim().isNotEmpty == true
                                    ? detail.description!
                                    : '공고 본문이 제공되지 않았습니다.',
                                style: _type(12, colors.secondary,
                                    height: 1.625))),
                        const SizedBox(height: 24),
                        _DetailSection(
                            key: _anchors[1],
                            title: '지원 자격 (Qualifications)',
                            icon: Icons.assignment_turned_in_outlined,
                            colors: colors,
                            child: _requirements(detail, colors,
                                preferred: false)),
                        const SizedBox(height: 24),
                        _DetailSection(
                            title: '우대 사항 (Preferred)',
                            icon: Icons.workspace_premium_outlined,
                            colors: colors,
                            accent: colors.tertiary,
                            child:
                                _requirements(detail, colors, preferred: true)),
                        const SizedBox(height: 24),
                        _DetailSection(
                            key: _anchors[2],
                            title: '전형 절차 및 근무 조건',
                            icon: Icons.route_outlined,
                            colors: colors,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('전형 절차 정보가 제공되지 않았습니다.',
                                      style: _type(12, colors.secondary)),
                                  const SizedBox(height: 16),
                                  _condition(Icons.location_on_outlined, '근무지',
                                      detail.job.region, colors),
                                  _condition(
                                      Icons.calendar_today_outlined,
                                      '접수 마감',
                                      detail.job.closesAt == null
                                          ? '마감일 미정'
                                          : _date(detail.job.closesAt!),
                                      colors),
                                  _condition(Icons.badge_outlined, '고용 형태',
                                      detail.job.employmentLabel, colors),
                                  _condition(Icons.payments_outlined, '급여',
                                      detail.salaryText ?? '급여 정보 없음', colors),
                                  if (detail.opensAt != null)
                                    _condition(
                                        Icons.event_available_outlined,
                                        '접수 시작',
                                        _date(detail.opensAt!),
                                        colors),
                                  if (detail.postedAt != null)
                                    _condition(Icons.article_outlined, '게시일',
                                        _date(detail.postedAt!), colors),
                                ])),
                      ]),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 128))),
        ],
      );

  Widget _utility(JobDetail detail, _DetailColors colors) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(children: [
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  heightFactor: 1,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: colors.high,
                          borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: colors.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Flexible(
                            child: Text(
                                switch (detail.job.status) {
                                  'open' => '채용 중',
                                  'upcoming' => '접수 예정',
                                  _ => '마감된 공고',
                                },
                                style: _type(12, colors.secondary,
                                    weight: FontWeight.w600, height: 4 / 3))),
                      ])))),
          Tooltip(
              message: detail.sourceUri == null
                  ? '공유 가능한 원본 링크가 없습니다.'
                  : '채용공고 공유하기',
              child: SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                          backgroundColor: colors.card,
                          disabledBackgroundColor: colors.card,
                          disabledForegroundColor: colors.secondary),
                      onPressed: detail.sourceUri == null ? null : _share,
                      icon: Icon(Icons.share_outlined,
                          size: 19, color: colors.secondary)))),
        ]),
      );

  Widget _company(JobDetail detail, _DetailColors colors) => Container(
        key: const ValueKey('job-company'),
        padding: const EdgeInsets.all(20),
        decoration: _card(colors),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(detail.job.companyBadge,
                    style: _type(16, colors.onPrimary,
                        weight: FontWeight.w800, headline: true))),
            const SizedBox(width: 12),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(detail.job.companyName,
                        style: _type(14, colors.text,
                            weight: FontWeight.w700,
                            height: 20 / 14,
                            headline: true)))),
            const SizedBox(width: 12),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: colors.errorBackground,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(detail.job.deadlineLabel(DateTime.now()),
                    style: _type(12, colors.error,
                        weight: FontWeight.w700, height: 4 / 3))),
          ]),
          const SizedBox(height: 16),
          Text(detail.job.title,
              style: _type(20, colors.text,
                  weight: FontWeight.w800, height: 1.25, headline: true)),
          const SizedBox(height: 20),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final tag in {
              detail.job.region,
              detail.job.experienceLabel,
              detail.job.employmentLabel,
              ...detail.job.keywords
            })
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: colors.low,
                      borderRadius: BorderRadius.circular(99)),
                  child: Text('#$tag',
                      style: _type(12, colors.secondary,
                          weight: FontWeight.w500, height: 4 / 3))),
          ]),
          if (detail.notice.isNotEmpty || detail.synthetic) ...[
            const SizedBox(height: 16),
            Text(
                detail.notice.isNotEmpty
                    ? detail.notice
                    : '시연용 가상 공고입니다. 실제 지원 접수와 관계없습니다.',
                style: _type(11, colors.secondary, height: 1.625)),
          ],
        ]),
      );

  Widget _requirements(JobDetail detail, _DetailColors colors,
      {required bool preferred}) {
    final items = <String>[
      if (!preferred) ...[
        '학력: ${detail.educationLabel}',
        '경력: ${detail.experienceLabel}'
      ],
      for (final item in detail.requirements ?? <JobRequirement>[])
        if (item.required != preferred) item.label,
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (index, text) in items.indexed) ...[
        if (index > 0) const SizedBox(height: 8),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: preferred ? colors.preferredBackground : colors.low,
                borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                      preferred ? Icons.verified_user_outlined : Icons.check,
                      size: 16,
                      color: preferred ? colors.tertiary : colors.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(text,
                      style: _type(12, colors.secondary, height: 1.625))),
            ])),
      ],
      if (items.isEmpty || (!preferred && detail.requirements == null)) ...[
        if (items.isNotEmpty) const SizedBox(height: 12),
        Text(preferred ? '우대 사항 정보가 제공되지 않았습니다.' : '상세 지원 자격 정보가 제공되지 않았습니다.',
            style: _type(12, colors.secondary, height: 1.625)),
      ],
    ]);
  }

  Widget _condition(
          IconData icon, String label, String value, _DetailColors colors) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 16, color: colors.secondary)),
            const SizedBox(width: 8),
            Expanded(
                child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '$label: ',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: value),
                    ]),
                    style: _type(12, colors.secondary, height: 1.4))),
          ]));

  Widget _applicationBar(JobDetail detail, _DetailColors colors) {
    final label = detail.synthetic
        ? '지원 불가 · 시연용'
        : detail.job.status == 'closed'
            ? '마감된 공고'
            : detail.job.status == 'upcoming'
                ? '접수 예정'
                : !detail.canOpenApplication
                    ? '지원 링크 없음'
                    : '지원하기';
    return DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              colors.background.withValues(alpha: 0),
              colors.background.withValues(alpha: .95),
              colors.background
            ])),
        child: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: _constrain(ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: FilledButton(
                      key: const ValueKey('job-apply'),
                      style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          disabledBackgroundColor: Color.alphaBlend(
                              colors.primary.withValues(alpha: .45),
                              colors.background),
                          disabledForegroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      onPressed: detail.canOpenApplication && !_opening
                          ? _apply
                          : null,
                      child: _opening
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: colors.onPrimary))
                          : Text(label,
                              textAlign: TextAlign.center,
                              style: _type(18, colors.onPrimary,
                                  weight: FontWeight.w700,
                                  height: 28 / 18,
                                  headline: true)),
                    ))))));
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    super.key,
    required this.detail,
    required this.comparison,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.colors,
  });
  final JobDetail detail;
  final JobComparison? comparison;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final _DetailColors colors;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? colors.text : const Color(0xFFF0F2FF);
    final surfaceTint = dark ? foreground : Colors.white;
    final muted = dark ? colors.secondary : const Color(0xFFB4C1FF);
    final accent = dark ? colors.tertiary : const Color(0xFFF199F7);
    final result = comparison;
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [
                        Color.alphaBlend(
                            colors.primary.withValues(alpha: .2), colors.card),
                        colors.card,
                        Color.alphaBlend(
                            colors.tertiary.withValues(alpha: .12), colors.card)
                      ]
                    : const [
                        Color(0xFF0057BD),
                        Color(0xFF004CA6),
                        Color(0xFF2C47AB)
                      ]),
            boxShadow: [
              BoxShadow(
                  color: colors.primary.withValues(alpha: dark ? .06 : .25),
                  offset: const Offset(0, 10),
                  blurRadius: 15),
            ]),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
                child: Container(
                    key: const ValueKey('comparison-badge'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: surfaceTint.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(99)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                          width: 14,
                          height: 20,
                          child: Icon(Icons.fact_check_outlined,
                              size: 14, color: accent)),
                      const SizedBox(width: 6),
                      Flexible(
                          child: Text('내 스펙 조건 비교',
                              style: _type(12, foreground,
                                  weight: FontWeight.w600, height: 4 / 3))),
                    ]))),
            const SizedBox(width: 8),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: dark ? colors.low : const Color(0xFFC7CFFF),
                    borderRadius: BorderRadius.circular(99)),
                child: Text('등록 정보 기준',
                    style: _type(
                        11, dark ? colors.text : const Color(0xFF00278F),
                        weight: FontWeight.w700, height: 1.5, headline: true))),
          ]),
          const SizedBox(height: 16),
          if (loading && result == null)
            SizedBox(
                height: 120,
                child: Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                            semanticsLabel: '조건 비교 중'))))
          else if (result == null) ...[
            Text(error ?? '조건 비교 결과가 없습니다.',
                style: _type(12, foreground, height: 1.625)),
            const SizedBox(height: 16),
            _retryButton(),
          ] else ...[
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('조건별 확인 결과',
                        style: _type(12, foreground.withValues(alpha: .8),
                            height: 4 / 3)),
                    const SizedBox(height: 2),
                    Text('충족 ${result.confirmed}개',
                        key: const ValueKey('comparison-confirmed'),
                        style: _type(24, foreground,
                            weight: FontWeight.w800,
                            height: 4 / 3,
                            headline: true)),
                    const SizedBox(height: 2),
                    Wrap(
                        key: const ValueKey('comparison-unconfirmed'),
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text('기준 미달 ${result.notConfirmed}개',
                              style: _type(12, muted,
                                  weight: FontWeight.w500, height: 4 / 3)),
                          Text('확인 불가 ${result.unknown}개',
                              style: _type(12, muted,
                                  weight: FontWeight.w500, height: 4 / 3)),
                        ]),
                    if (result.notRequired > 0)
                      Text('제한 없음 ${result.notRequired}개',
                          style: _type(12, muted, height: 4 / 3)),
                  ])),
              const SizedBox(width: 12),
              Semantics(
                  label: '전체 비교 항목 ${result.checks.length}개',
                  excludeSemantics: true,
                  child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: foreground.withValues(alpha: .2),
                              width: 7)),
                      alignment: Alignment.center,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${result.checks.length}개',
                            style: _type(14, foreground,
                                weight: FontWeight.w800, headline: true)),
                        Text('비교 항목',
                            style: _type(9, foreground.withValues(alpha: .75))),
                      ]))),
            ]),
            const SizedBox(height: 16),
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: surfaceTint.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryLine('필수', result.required, foreground),
                      const SizedBox(height: 4),
                      _summaryLine('우대', result.preferred, foreground),
                      if (!result.detailedRequirementsAvailable) ...[
                        const SizedBox(height: 8),
                        Text('공고의 상세 조건이 제공되지 않았습니다.',
                            style: _type(12, foreground, height: 1.625)),
                      ],
                    ])),
            const SizedBox(height: 20),
            for (final (index, check) in result.checks.indexed) ...[
              if (index > 0) const SizedBox(height: 8),
              _ComparisonCheck(
                  key: ValueKey('comparison-check-$index'),
                  check: check,
                  label: switch (check.kind) {
                    'education' => '학력: ${detail.educationLabel}',
                    'experience' => '경력: ${detail.experienceLabel}',
                    'certification' => '자격증: ${check.condition}',
                    'language_score' => '어학: ${check.condition}',
                    _ => check.condition,
                  },
                  foreground: foreground,
                  background: surfaceTint.withValues(alpha: .1),
                  muted: muted,
                  accent: accent),
            ],
            const SizedBox(height: 16),
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Icon(Icons.info_outline,
                            size: 16, color: colors.tertiary),
                        const SizedBox(width: 6),
                        Text('비교 기준',
                            style: _type(12, colors.tertiary,
                                weight: FontWeight.w700, headline: true)),
                      ]),
                      const SizedBox(height: 6),
                      Text(result.notice,
                          style: _type(12, colors.secondary, height: 1.625)),
                      const SizedBox(height: 6),
                      Text(_comparisonTime(result.comparedAt),
                          style: _type(11, colors.secondary, height: 1.5)),
                      if (error != null) ...[
                        const SizedBox(height: 6),
                        Text(error!,
                            style: _type(12, colors.error, height: 1.625)),
                      ],
                      const SizedBox(height: 8),
                      _retryButton(),
                    ])),
          ],
        ]));
  }

  Widget _summaryLine(
          String label, JobMatchSummary summary, Color foreground) =>
      Wrap(spacing: 8, runSpacing: 2, children: [
        Text('$label · 충족 ${summary.confirmed}개',
            style: _type(12, foreground, height: 1.625)),
        Text('기준 미달 ${summary.notConfirmed}개',
            style: _type(12, foreground, height: 1.625)),
        Text('확인 불가 ${summary.unknown}개',
            style: _type(12, foreground, height: 1.625)),
      ]);

  Widget _retryButton() => TextButton.icon(
      key: const ValueKey('comparison-retry'),
      onPressed: loading ? null : onRetry,
      style: TextButton.styleFrom(
          backgroundColor: colors.low,
          foregroundColor: colors.primary,
          minimumSize: const Size(double.infinity, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      icon: loading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: colors.primary))
          : const Icon(Icons.refresh, size: 14),
      label: Text(loading ? '비교 중' : '다시 비교',
          style: _type(12, loading ? colors.secondary : colors.primary,
              weight: FontWeight.w700, height: 4 / 3)));
}

class _ComparisonCheck extends StatefulWidget {
  const _ComparisonCheck({
    super.key,
    required this.check,
    required this.label,
    required this.foreground,
    required this.background,
    required this.muted,
    required this.accent,
  });
  final JobMatchCheck check;
  final String label;
  final Color foreground, background, muted, accent;
  @override
  State<_ComparisonCheck> createState() => _ComparisonCheckState();
}

class _ComparisonCheckState extends State<_ComparisonCheck> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final check = widget.check;
    final color = switch (check.status) {
      JobMatchStatus.confirmed => widget.muted,
      JobMatchStatus.notConfirmed => widget.accent,
      _ => widget.foreground.withValues(alpha: .85),
    };
    final icon = switch (check.status) {
      JobMatchStatus.confirmed => Icons.check_circle,
      JobMatchStatus.notConfirmed => Icons.cancel_outlined,
      JobMatchStatus.unknown => Icons.help_outline,
      JobMatchStatus.notRequired => Icons.remove_circle_outline,
    };
    return Material(
        color: widget.background,
        borderRadius: BorderRadius.circular(8),
        child: Semantics(
            button: true,
            expanded: _expanded,
            hint: _expanded ? '판단 이유 접기' : '판단 이유 보기',
            child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                    width: 16,
                                    height: 24,
                                    child: Icon(icon, size: 16, color: color)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(widget.label,
                                        maxLines: _expanded ? null : 2,
                                        overflow: _expanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        style: _type(12, widget.foreground,
                                            height: 4 / 3))),
                                const SizedBox(width: 6),
                                Text(
                                    '${check.required ? '필수' : '우대'} · ${check.status.label}',
                                    style: _type(11, color,
                                        weight: FontWeight.w600, height: 1.5)),
                                const SizedBox(width: 4),
                                Icon(
                                    _expanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: color),
                              ]),
                          if (_expanded) ...[
                            const SizedBox(height: 8),
                            Text(check.reason,
                                style: _type(
                                    12, widget.foreground.withValues(alpha: .9),
                                    height: 1.625)),
                          ],
                        ])))));
  }
}

String _comparisonTime(DateTime value) {
  final date = value.toUtc().add(const Duration(hours: 9));
  return '비교 시각 ${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} (한국 시간)';
}

class _DetailSection extends StatelessWidget {
  const _DetailSection(
      {super.key,
      required this.title,
      required this.icon,
      required this.colors,
      required this.child,
      this.accent});
  final String title;
  final IconData icon;
  final _DetailColors colors;
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(colors),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: colors.low, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 19, color: accent ?? colors.primary)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  style: _type(16, colors.text,
                      weight: FontWeight.w700, height: 1.5, headline: true))),
        ]),
        const SizedBox(height: 12),
        child,
      ]));
}

class _DetailSegments extends SliverPersistentHeaderDelegate {
  _DetailSegments(
      {required this.height,
      required this.selected,
      required this.onSelected,
      required this.colors});
  final double height;
  final int selected;
  final ValueChanged<int> onSelected;
  final _DetailColors colors;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(
          color: colors.background,
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 672),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: colors.container,
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            for (final (index, label) in const [
                              '공고 상세',
                              '자격요건',
                              '기업 정보'
                            ].indexed) ...[
                              if (index > 0) const SizedBox(width: 4),
                              Expanded(
                                  child: Semantics(
                                      button: true,
                                      selected: selected == index,
                                      child: Material(
                                          color: selected == index
                                              ? colors.card
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () => onSelected(index),
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          vertical: 8),
                                                  child: Text(label,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: _type(
                                                          12,
                                                          selected == index
                                                              ? colors.primary
                                                              : colors
                                                                  .secondary,
                                                          weight: FontWeight.w600,
                                                          height: 4 / 3))))))),
                            ],
                          ]))))));
  @override
  bool shouldRebuild(covariant _DetailSegments oldDelegate) => true;
}

BoxDecoration _card(_DetailColors colors) => BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), offset: Offset(0, 1), blurRadius: 2),
        ]);

TextStyle _type(double size, Color color,
        {FontWeight weight = FontWeight.w400,
        double height = 1.4,
        bool headline = false}) =>
    TextStyle(
        fontFamily: headline ? 'SpecJakarta' : 'SpecInter',
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: 0,
        color: color);

String _date(DateTime value) {
  final date = value.toLocal();
  const week = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 (${week[date.weekday - 1]}) '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _DetailColors {
  _DetailColors(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    background = dark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7F9);
    primary = dark ? scheme.primary : const Color(0xFF0057BD);
    onPrimary = dark ? scheme.onPrimary : const Color(0xFFF0F2FF);
    text = dark ? scheme.onSurface : const Color(0xFF2C2F31);
    secondary = dark ? scheme.onSurfaceVariant : const Color(0xFF595C5E);
    low = dark ? scheme.surfaceContainerHigh : const Color(0xFFEEF1F3);
    high = dark ? scheme.surfaceContainerHighest : const Color(0xFFDFE3E6);
    container = dark ? scheme.surfaceContainerHighest : const Color(0xFFE5E9EB);
    card = dark ? theme.cardColor : Colors.white;
    tertiary = dark ? scheme.tertiary : const Color(0xFF893C92);
    preferredBackground = dark
        ? scheme.tertiaryContainer.withValues(alpha: .25)
        : const Color(0x33F199F7);
    error = dark ? scheme.error : const Color(0xFFB31B25);
    errorBackground = dark ? scheme.errorContainer : const Color(0x33FB5151);
  }
  late final Color background,
      primary,
      onPrimary,
      text,
      secondary,
      low,
      high,
      container,
      card,
      tertiary,
      preferredBackground,
      error,
      errorBackground;
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/job_data.dart';
import '../models/ai_demo_data.dart';
import '../services/authenticated_client.dart';
import '../services/job_api_client.dart';
import '../widgets/responsive_page.dart';
import '../widgets/job_ai_demo_section.dart';
import 'job_detail_screen.dart';
import 'profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen(
      {super.key, this.userId, this.client = const JobApiClient()});
  final String? userId;
  final JobApiClient client;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<JobOccupation> _occupations = const [];
  List<JobPosting> _items = const [];
  JobPage? _page;
  String? _occupation;
  String _sort = 'latest';
  String _lastText = '';
  bool _wasComposing = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;
  bool _moreError = false;
  int _revision = 0;
  int _accountRevision = 0;
  int _nextOffset = 0;
  AiDemoAvailability? _aiStatus;
  bool _aiSelected = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_searchChanged);
    _scroll.addListener(_scrolled);
    _refresh();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.client != widget.client) {
      _accountRevision++;
      _revision++;
      _debounce?.cancel();
      _search.removeListener(_searchChanged);
      _search.clear();
      _search.addListener(_searchChanged);
      _lastText = '';
      _wasComposing = false;
      _occupation = null;
      _sort = 'latest';
      _occupations = const [];
      _items = const [];
      _page = null;
      _aiStatus = null;
      _aiSelected = false;
      _refresh();
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _searchChanged() {
    final composing =
        _search.value.composing.isValid && !_search.value.composing.isCollapsed;
    if (_lastText == _search.text && _wasComposing == composing) return;
    _lastText = _search.text;
    _wasComposing = composing;
    _debounce?.cancel();
    // Reject stale responses even while a Korean syllable is still composing.
    _revision++;
    setState(() {
      _items = const [];
      _page = null;
      _loading = true;
      _loadingMore = false;
      _error = false;
      _moreError = false;
    });
    if (!composing) {
      _debounce = Timer(const Duration(milliseconds: 260), _loadJobs);
    }
  }

  void _scrolled() {
    if (_scroll.position.extentAfter < 280 && !_moreError) {
      _loadJobs(append: true);
    }
  }

  Future<void> _loadOccupations() async {
    final account = _accountRevision;
    if (widget.userId == null) return;
    try {
      final occupations =
          List<JobOccupation>.of(await widget.client.fetchOccupations());
      if (!mounted || account != _accountRevision) return;
      const first = ['frontend', 'backend', 'data'];
      int rank(JobOccupation item) {
        final index = first.indexOf(item.value);
        return index < 0 ? first.length : index;
      }

      occupations.sort((a, b) {
        final order = rank(a).compareTo(rank(b));
        return order == 0 ? a.value.compareTo(b.value) : order;
      });
      setState(() => _occupations = occupations);
    } catch (_) {
      // Optional facets failing must not block the unfiltered feed.
    }
  }

  Future<void> _loadJobs({bool append = false}) async {
    if (append &&
        (_loading ||
            _loadingMore ||
            _page == null ||
            _nextOffset >= _page!.total)) {
      return;
    }
    final revision = append ? _revision : ++_revision;
    final offset = append ? _nextOffset : 0;
    if (widget.userId == null) {
      setState(() {
        _items = const [];
        _page = null;
        _loading = false;
        _error = false;
        _loadingMore = false;
      });
      return;
    }
    setState(() {
      if (append) {
        _loadingMore = true;
        _moreError = false;
      } else {
        _loading = true;
        _loadingMore = false;
        _error = false;
        _moreError = false;
        _items = const [];
        _page = null;
      }
    });
    try {
      final page = await widget.client.fetchJobs(
        query: _search.text,
        occupation: _occupation,
        sort: _sort,
        offset: offset,
      );
      if (!mounted || revision != _revision) return;
      if (page.offset != offset ||
          (page.items.isEmpty && offset < page.total)) {
        throw const FormatException('Incomplete job page');
      }
      setState(() {
        final byId = {
          for (final item in [..._items, ...page.items]) item.id: item
        };
        _items = byId.values.toList();
        _nextOffset = offset + page.items.length;
        _page = page;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (append) {
          _moreError = true;
        } else {
          _error = true;
        }
      });
    }
  }

  Future<void> _refresh() async {
    _debounce?.cancel();
    await Future.wait([_loadJobs(), _loadOccupations(), _loadAiStatus()]);
  }

  Future<void> _loadAiStatus() async {
    final account = _accountRevision;
    final generation = ApiCredentials.generation;
    if (widget.userId == null) return;
    try {
      final status = await widget.client.fetchAiDemoStatus();
      if (!mounted ||
          account != _accountRevision ||
          generation != ApiCredentials.generation) {
        return;
      }
      setState(() {
        _aiStatus = status;
        if (!status.enabled) _aiSelected = false;
      });
    } catch (_) {
      // Older or disabled servers keep the existing job feed available.
    }
  }

  void _selectAi() {
    if (_aiSelected) return;
    final reload = _occupation != null;
    _debounce?.cancel();
    setState(() {
      _aiSelected = true;
      _occupation = null;
    });
    if (reload) _loadJobs();
  }

  void _selectOccupation(String? value) {
    if (_occupation == value && !_aiSelected) return;
    _debounce?.cancel();
    setState(() {
      _occupation = value;
      _aiSelected = false;
    });
    _loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ExploreColors.of(context);
    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsivePage(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _header(colors),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  key: const ValueKey('job-feed'),
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
                  children: [
                    SizedBox(height: 44, child: _searchField(colors)),
                    const SizedBox(height: 12),
                    _occupationChips(colors),
                    const SizedBox(height: 20),
                    if (_aiSelected &&
                        _aiStatus?.enabled == true &&
                        widget.userId != null) ...[
                      JobAiDemoSection(
                          key: ValueKey('ai-${widget.userId}'),
                          userId: widget.userId!,
                          client: widget.client,
                          availability: _aiStatus!),
                      const SizedBox(height: 20),
                    ],
                    _feedHeading(colors),
                    if (_page?.notice.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(_page!.notice,
                          style: _text(11, colors.secondary, height: 1.5)),
                    ],
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(child: CircularProgressIndicator()))
                    else if (_error)
                      _FeedMessage(
                          text: '채용공고를 불러오지 못했습니다.',
                          onRetry: _loadJobs,
                          colors: colors)
                    else if (_items.isEmpty)
                      _FeedMessage(
                          text: widget.userId == null
                              ? '로그인이 필요합니다.'
                              : '조건에 맞는 채용공고가 없습니다.',
                          colors: colors)
                    else ...[
                      for (final item in _items) ...[
                        _JobCard(
                            key: ValueKey(item.id),
                            job: item,
                            asOf: _page!.asOf,
                            onTap: () {
                              final userId = widget.userId;
                              if (userId == null) return;
                              Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                      builder: (_) => JobDetailScreen(
                                          jobId: item.id,
                                          userId: userId,
                                          client: widget.client)));
                            },
                            colors: colors),
                        const SizedBox(height: 12),
                      ],
                      if (_loadingMore)
                        const Center(child: CircularProgressIndicator())
                      else if (_moreError)
                        _FeedMessage(
                            text: '추가 공고를 불러오지 못했습니다.',
                            onRetry: () => _loadJobs(append: true),
                            colors: colors)
                      else if (_nextOffset < _page!.total)
                        Center(
                            child: IconButton(
                                tooltip: '공고 더 불러오기',
                                onPressed: () => _loadJobs(append: true),
                                icon: const Icon(Icons.expand_more))),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header(_ExploreColors colors) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: colors.background, boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 8),
        ]),
        child: Row(children: [
          Expanded(
              child: Text('스펙모아.zip',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(20, colors.primary,
                      weight: FontWeight.w800, headline: true))),
          IconButton(
              tooltip: '알림',
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const NotificationSettingsScreen())),
              icon: Icon(Icons.notifications_none,
                  size: 22, color: colors.secondary)),
          const SizedBox(width: 4),
          IconButton(
              tooltip: '설정',
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SettingsHubScreen())),
              icon: Icon(Icons.settings_outlined,
                  size: 22, color: colors.secondary)),
          const SizedBox(width: 8),
          CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary,
              child: Icon(Icons.person_outline,
                  size: 18, color: colors.onPrimary)),
        ]),
      );

  Widget _searchField(_ExploreColors colors) => Row(children: [
        Expanded(
            child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          decoration: BoxDecoration(
              color: colors.low, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Icon(Icons.search, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
              controller: _search,
              style: _text(14, colors.text),
              textInputAction: TextInputAction.search,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              onSubmitted: (_) {
                _debounce?.cancel();
                _loadJobs();
              },
              decoration: InputDecoration(
                hintText: '기업명, 직무, 요구 스펙 검색',
                hintStyle: _text(14, colors.secondary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            )),
            if (_search.text.isNotEmpty)
              IconButton(
                  tooltip: '검색어 지우기',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 24, height: 32),
                  onPressed: _search.clear,
                  icon: Icon(Icons.cancel, size: 18, color: colors.secondary)),
          ]),
        )),
      ]);

  Widget _occupationChips(_ExploreColors colors) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            _filterChip('전체', _occupation == null && !_aiSelected,
                () => _selectOccupation(null), colors),
            if (_aiStatus?.enabled == true)
              _filterChip('AI 추천 시연', _aiSelected, _selectAi, colors,
                  icon: Icons.auto_awesome),
            for (final item in _occupations)
              _filterChip(item.label, _occupation == item.value && !_aiSelected,
                  () => _selectOccupation(item.value), colors),
          ]),
        ),
      );

  Widget _filterChip(String label, bool selected, VoidCallback onTap,
          _ExploreColors colors, {IconData? icon}) =>
      Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Semantics(
              button: true,
              selected: selected,
              child: Material(
                  color: selected ? colors.primary : colors.low,
                  borderRadius: BorderRadius.circular(99),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: onTap,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (icon != null) ...[
                              Icon(icon,
                                  size: 14,
                                  color: selected
                                      ? colors.onPrimary
                                      : colors.primary),
                              const SizedBox(width: 4)
                            ],
                            Text(label,
                                style: _text(
                                    12,
                                    selected
                                        ? colors.onPrimary
                                        : colors.secondary,
                                    weight: FontWeight.w600,
                                    height: 4 / 3)),
                          ]))))));

  Widget _feedHeading(_ExploreColors colors) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(_page?.synthetic == true ? '시연용 채용공고' : '채용공고',
                      style: _text(14, colors.text,
                          weight: FontWeight.w700, headline: true)),
                ),
                const SizedBox(width: 6),
                if (_page != null)
                  Text('${_page!.total}건',
                      style:
                          _text(12, colors.primary, weight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: '공고 정렬',
            initialValue: _sort,
            color: colors.card,
            surfaceTintColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            constraints: const BoxConstraints.tightFor(width: 128),
            menuPadding: const EdgeInsets.all(4),
            position: PopupMenuPosition.under,
            offset: const Offset(0, 4),
            onSelected: (value) {
              if (value == _sort) return;
              _debounce?.cancel();
              setState(() => _sort = value);
              _loadJobs();
            },
            itemBuilder: (_) => [
              _sortOption('latest', '최신순', colors),
              _sortOption('deadline', '마감임박순', colors),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: colors.low, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_sort == 'latest' ? '최신순' : '마감임박순',
                    style:
                        _text(12, colors.secondary, weight: FontWeight.w600)),
                const SizedBox(width: 2),
                Icon(Icons.expand_more, size: 16, color: colors.secondary),
              ]),
            ),
          ),
        ]),
      );

  PopupMenuItem<String> _sortOption(
          String value, String label, _ExploreColors colors) =>
      PopupMenuItem<String>(
        value: value,
        height: 28,
        padding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:
                _sort == value ? colors.primary.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: _text(
                  12, _sort == value ? colors.primary : colors.secondary,
                  weight: _sort == value ? FontWeight.w600 : FontWeight.w400,
                  height: 4 / 3)),
        ),
      );
}

class _JobCard extends StatelessWidget {
  const _JobCard(
      {super.key,
      required this.job,
      required this.asOf,
      required this.colors,
      required this.onTap});
  final JobPosting job;
  final DateTime asOf;
  final _ExploreColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 2,
                        offset: Offset(0, 1))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: colors.low,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(job.companyBadge,
                                  style: _text(14, colors.primary,
                                      weight: FontWeight.w800))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Wrap(
                                    spacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(job.companyName,
                                          style: _text(12, colors.secondary,
                                              weight: FontWeight.w500)),
                                      Text('·',
                                          style: _text(11, colors.secondary)),
                                      Text(job.deadlineLabel(asOf),
                                          style: _text(
                                              11,
                                              job.closesAt == null
                                                  ? colors.primary
                                                  : colors.deadline,
                                              weight: FontWeight.w700)),
                                    ]),
                                const SizedBox(height: 2),
                                Text(job.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _text(14, colors.text,
                                        weight: FontWeight.w700, height: 1.45)),
                                const SizedBox(height: 2),
                                Text(
                                    '${job.region} · ${job.experienceLabel} · ${job.employmentLabel}',
                                    style: _text(11, colors.secondary,
                                        height: 1.5)),
                              ])),
                        ]),
                    if (job.keywords.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(spacing: 4, runSpacing: 4, children: [
                        for (final keyword in job.keywords)
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: colors.low,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(keyword,
                                  style: _text(11, colors.text,
                                      weight: FontWeight.w500, height: 1.45))),
                      ]),
                    ],
                  ]),
            )),
      );
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.text, required this.colors, this.onRetry});
  final String text;
  final _ExploreColors colors;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          Text(text,
              textAlign: TextAlign.center, style: _text(13, colors.secondary)),
          if (onRetry != null)
            IconButton(
                tooltip: '다시 시도',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh)),
        ]),
      );
}

TextStyle _text(double size, Color color,
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

class _ExploreColors {
  _ExploreColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    background = dark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7F9);
    primary = dark ? theme.colorScheme.primary : const Color(0xFF0057BD);
    onPrimary = dark ? theme.colorScheme.onPrimary : const Color(0xFFF0F2FF);
    text = dark ? theme.colorScheme.onSurface : const Color(0xFF2C2F31);
    secondary =
        dark ? theme.colorScheme.onSurfaceVariant : const Color(0xFF595C5E);
    low =
        dark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFFEEF1F3);
    card = dark ? theme.cardColor : Colors.white;
    deadline = dark ? theme.colorScheme.error : const Color(0xFFB31B25);
  }
  late final Color background,
      primary,
      onPrimary,
      text,
      secondary,
      low,
      card,
      deadline;
}

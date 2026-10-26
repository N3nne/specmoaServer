import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ai_demo_data.dart';
import '../screens/job_detail_screen.dart';
import '../services/authenticated_client.dart';
import '../services/job_api_client.dart';

class JobAiDemoSection extends StatefulWidget {
  const JobAiDemoSection(
      {super.key,
      required this.userId,
      required this.client,
      required this.availability});
  final String userId;
  final JobApiClient client;
  final AiDemoAvailability availability;

  @override
  State<JobAiDemoSection> createState() => _JobAiDemoSectionState();
}

class _JobAiDemoSectionState extends State<JobAiDemoSection> {
  AiDemoResult? _result;
  String? _error, _opening;
  bool _loading = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant JobAiDemoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.client != widget.client) {
      _revision++;
      _result = null;
      _loading = false;
      _opening = null;
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    final revision = ++_revision;
    final generation = ApiCredentials.generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.client.generateAiDemo();
      if (!mounted ||
          revision != _revision ||
          generation != ApiCredentials.generation) {
        return;
      }
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted ||
          revision != _revision ||
          generation != ApiCredentials.generation) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error is AiDemoApiException
            ? error.message
            : error is TimeoutException
                ? 'AI 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.'
                : 'AI 응답을 확인하지 못했습니다. 다시 시도해주세요.';
      });
    }
  }

  Future<void> _open(AiDemoRecommendation recommendation) async {
    if (_opening != null) return;
    final userId = widget.userId;
    final revision = _revision;
    final generation = ApiCredentials.generation;
    setState(() => _opening = recommendation.externalId);
    try {
      final job =
          await widget.client.fetchDemoDetail(recommendation.externalId);
      if (!mounted ||
          userId != widget.userId ||
          revision != _revision ||
          generation != ApiCredentials.generation) {
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => JobDetailScreen(
              jobId: job.job.id, userId: userId, client: widget.client)));
    } catch (_) {
      if (mounted &&
          userId == widget.userId &&
          generation == ApiCredentials.generation) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('해당 가상 공고를 찾지 못했습니다. 공고 목록을 새로고침해주세요.')));
      }
    } finally {
      if (mounted &&
          userId == widget.userId &&
          generation == ApiCredentials.generation) {
        setState(() => _opening = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final primary = dark ? theme.colorScheme.primary : const Color(0xFF0057BD);
    final text = dark ? theme.colorScheme.onSurface : const Color(0xFF2C2F31);
    final secondary =
        dark ? theme.colorScheme.onSurfaceVariant : const Color(0xFF595C5E);
    final card = dark ? theme.cardColor : Colors.white;
    final low =
        dark ? theme.colorScheme.surfaceContainerHigh : const Color(0xFFEEF1F3);
    final result = _result;
    final generated = result?.generatedAt.add(const Duration(hours: 9));
    final time = generated == null
        ? '생성 전'
        : '${generated.hour.toString().padLeft(2, '0')}:${generated.minute.toString().padLeft(2, '0')} 생성';
    final profile = result?.profileLabel ?? widget.availability.profileLabel;
    final summary =
        result?.profileSummary ?? widget.availability.profileSummary;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        key: const ValueKey('ai-demo-summary'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer
                      ]
                    : const [Color(0xFF0057BD), Color(0xFF004CA6)]),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x180057BD), offset: Offset(0, 4), blurRadius: 6)
            ]),
        child: Builder(builder: (context) {
          final foreground = dark
              ? theme.colorScheme.onPrimaryContainer
              : const Color(0xFFF0F2FF);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: foreground.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(99)),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        size: 12, color: foreground),
                                    const SizedBox(width: 6),
                                    Flexible(
                                        child: Text(
                                            _loading
                                                ? 'AI 추천 생성 중'
                                                : '가상 스펙 AI 시연',
                                            style: _style(11, foreground,
                                                weight: FontWeight.w500,
                                                height: 1.5))),
                                  ]))),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(time,
                            style: _style(11, foreground.withValues(alpha: .8),
                                height: 1.5)),
                        IconButton(
                            tooltip: 'AI 추천 새로고침',
                            onPressed: _loading ? null : _load,
                            constraints: const BoxConstraints.tightFor(
                                width: 28, height: 24),
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.refresh,
                                size: 18,
                                color: foreground.withValues(
                                    alpha: _loading ? .45 : 1))),
                      ]),
                    ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(profile,
                            style: _style(12, foreground.withValues(alpha: .8),
                                height: 4 / 3)),
                        const SizedBox(height: 2),
                        Text(summary,
                            style: _style(14, foreground,
                                weight: FontWeight.w600, height: 1.5)),
                      ])),
                  const SizedBox(width: 12),
                  Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: foreground.withValues(alpha: .1),
                          border: Border.all(
                              color: foreground.withValues(alpha: .3),
                              width: 3.5)),
                      child: Center(
                          child: _loading && result == null
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: foreground))
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      Text(
                                          result == null
                                              ? '대기'
                                              : '${result.items.length}건',
                                          style: _style(12, foreground,
                                              weight: FontWeight.w800,
                                              headline: true,
                                              height: 1.2)),
                                      Text('추천',
                                          style: _style(8,
                                              foreground.withValues(alpha: .75),
                                              height: 1.25)),
                                    ]))),
                ]),
                const SizedBox(height: 12),
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: foreground.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                              _error == null
                                  ? Icons.auto_awesome
                                  : Icons.info_outline,
                              size: 18,
                              color: foreground),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  _error ??
                                      '가상 스펙·가상 공고 전용입니다. 실제 내 스펙은 전송하지 않습니다. AI 설명은 틀릴 수 있습니다.',
                                  style:
                                      _style(11, foreground, height: 1.625))),
                        ])),
              ]);
        }),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Icon(Icons.stars_outlined, size: 20, color: primary),
        const SizedBox(width: 6),
        Expanded(
            child: Text('AI 추천 공고 · 시연',
                style:
                    _style(16, text, weight: FontWeight.w700, headline: true))),
        Text(result?.cached == true ? '저장된 결과' : '가상 프로필 기준',
            style: _style(11, primary, weight: FontWeight.w500)),
      ]),
      const SizedBox(height: 12),
      if (result == null)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text('아직 생성된 추천이 없습니다.', style: _style(13, secondary))))
      else if (result.items.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('근거를 확인할 수 있는 추천 공고가 없습니다.',
                textAlign: TextAlign.center, style: _style(13, secondary)))
      else
        LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
                  key: const ValueKey('ai-demo-carousel'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 4),
                  child: IntrinsicHeight(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        for (final item in result.items)
                          Padding(
                              padding: EdgeInsets.only(
                                  right: item == result.items.last ? 0 : 12),
                              child: SizedBox(
                                  width: math.min(290, constraints.maxWidth),
                                  child: _RecommendationCard(
                                      item: item,
                                      primary: primary,
                                      text: text,
                                      secondary: secondary,
                                      card: card,
                                      low: low,
                                      opening: _opening == item.externalId,
                                      onOpen: _opening != null || _loading
                                          ? null
                                          : () => _open(item)))),
                      ])),
                )),
    ]);
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard(
      {required this.item,
      required this.primary,
      required this.text,
      required this.secondary,
      required this.card,
      required this.low,
      required this.opening,
      required this.onOpen});
  final AiDemoRecommendation item;
  final Color primary, text, secondary, card, low;
  final bool opening;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('ai-recommendation-${item.rank}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2)
            ]),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: low, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.business_outlined, color: primary, size: 22)),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.companyName,
                      style: _style(12, secondary,
                          weight: FontWeight.w500, height: 1.5)),
                  Text('가상 공고',
                      style: _style(10, primary,
                          weight: FontWeight.w700, height: 1.5)),
                ])),
          ]),
          const SizedBox(height: 10),
          Text(item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _style(14, text, weight: FontWeight.w700, height: 1.375)),
          const SizedBox(height: 10),
          Text(item.metadata, style: _style(11, secondary, height: 1.5)),
          const SizedBox(height: 10),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.auto_awesome, size: 16, color: primary),
                const SizedBox(width: 4),
                Expanded(
                    child: Text('AI 추천 ${item.rank}순위',
                        style: _style(12, primary, weight: FontWeight.w700))),
                Text('가상 스펙',
                    style: _style(10, primary, weight: FontWeight.w500)),
              ])),
          const SizedBox(height: 10),
          for (final reason in item.reasons) ...[
            Text(reason.explanation, style: _style(12, text, height: 1.5)),
            const SizedBox(height: 4),
            Tooltip(
                message: '${reason.specQuote}\n${reason.jobQuote}',
                child: Text(
                    '근거: ${_inlineQuote(reason.specQuote)} → ${_inlineQuote(reason.jobQuote)}',
                    style: _style(10, secondary, height: 1.5))),
            const SizedBox(height: 8),
          ],
          if (item.cautions.isNotEmpty) ...[
            Text(item.cautions.join('\n'),
                style: _style(11, secondary, height: 1.5)),
            const SizedBox(height: 8),
          ],
          const Spacer(),
          const SizedBox(height: 6),
          DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: item.rank == 1 ? primary : low,
                  gradient: item.rank == 1 &&
                          Theme.of(context).brightness == Brightness.light
                      ? LinearGradient(
                          colors: [primary, const Color(0xFF5391FF)])
                      : null),
              child: FilledButton(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: item.rank == 1
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onPrimary
                              : const Color(0xFFF0F2FF)
                          : text,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: _style(12, text, weight: FontWeight.w700)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('공고 상세'),
                        const SizedBox(width: 4),
                        if (opening)
                          const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          const Icon(Icons.arrow_forward, size: 14),
                      ]))),
        ]),
      );
}

String _inlineQuote(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

TextStyle _style(double size, Color color,
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

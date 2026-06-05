import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/study_session_data.dart';
import '../models/user_certification_data.dart';
import '../services/study_session_api_client.dart';
import '../services/user_certification_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_page.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({
    this.userId,
    super.key,
  });

  final String? userId;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const _maxSeconds = 60 * 60;

  final _certificationClient = const UserCertificationApiClient();
  final _sessionClient = const StudySessionApiClient();
  late Future<_TimerPageData> _future;

  Timer? _ticker;
  DateTime? _startedAt;
  String? _selectedCertificationId;
  int _elapsedSeconds = 0;
  bool _running = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant TimerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _resetTimer();
      _future = _load();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<_TimerPageData> _load() async {
    final results = await Future.wait([
      _certificationClient.fetchMine(userId: widget.userId),
      _sessionClient.fetchSummary(userId: widget.userId),
    ]);
    final certifications = (results[0] as UserCertificationPage)
        .items
        .where((item) => !item.certified)
        .toList();
    final summary = results[1] as StudySessionSummary;

    if (certifications.isNotEmpty &&
        (_selectedCertificationId == null ||
            !certifications.any(
              (item) => item.certification.id == _selectedCertificationId,
            ))) {
      _selectedCertificationId = certifications.first.certification.id;
    }

    return _TimerPageData(certifications: certifications, summary: summary);
  }

  Future<void> _refresh() async {
    final nextFuture = _load();
    setState(() => _future = nextFuture);
    try {
      await nextFuture;
    } catch (_) {
      // FutureBuilder shows the error state.
    }
  }

  void _toggleTimer() {
    if (_selectedCertificationId == null || _saving) {
      return;
    }

    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }

    _startedAt ??= DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (_elapsedSeconds >= _maxSeconds) {
        _finishAndSave();
        return;
      }
      setState(() => _elapsedSeconds += 1);
      if (_elapsedSeconds >= _maxSeconds) {
        _finishAndSave();
      }
    });
    setState(() => _running = true);
  }

  Future<void> _finishAndSave() async {
    if (_elapsedSeconds <= 0 || _selectedCertificationId == null || _saving) {
      _resetTimer();
      return;
    }

    _ticker?.cancel();
    final startedAt = _startedAt ?? DateTime.now();
    final endedAt = DateTime.now();
    final durationSeconds = _elapsedSeconds.clamp(0, _maxSeconds);

    setState(() {
      _running = false;
      _saving = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _sessionClient.create(
        userId: widget.userId ?? '',
        certificationId: _selectedCertificationId!,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSeconds: durationSeconds,
      );
      if (!mounted) {
        return;
      }
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
              content: Text('학습 기록 ${_formatDuration(durationSeconds)} 저장 완료')),
        );
      _resetTimer();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('학습 기록 저장에 실패했습니다.')),
      );
      return;
    }

    try {
      await _refresh();
    } catch (_) {
      // The session was saved; a later manual refresh can reload the summary.
    }
  }

  void _resetTimer() {
    _ticker?.cancel();
    setState(() {
      _startedAt = null;
      _elapsedSeconds = 0;
      _running = false;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_TimerPageData>(
          future: _future,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            final data = snapshot.data;
            final certifications = data?.certifications ?? const [];
            final selected = _selectedCertification(certifications);
            final recentRecords = data?.summary.recent ?? const [];

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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('오늘의 학습 타이머',
                                      style: textTheme.headlineSmall),
                                  const SizedBox(height: AppSpacing.x1),
                                  Text(
                                    '준비중인 자격증을 선택하고 학습 시간을 기록하세요.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: '새로고침',
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x6),
                        if (snapshot.hasError)
                          const _TimerInfoPanel(
                            icon: Icons.error_outline_rounded,
                            title: '타이머 정보를 불러오지 못했습니다.',
                            message: '서버 연결 상태를 확인한 뒤 다시 시도해주세요.',
                          )
                        else if (loading)
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.x12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (certifications.isEmpty)
                          const _TimerInfoPanel(
                            icon: Icons.inventory_2_outlined,
                            title: '준비중인 자격증이 없습니다.',
                            message: '자격증 탭에서 준비 자격증을 등록하면 타이머를 사용할 수 있습니다.',
                          )
                        else ...[
                          _CertificationSelector(
                            certifications: certifications,
                            selectedId: _selectedCertificationId,
                            enabled: !_running && !_saving,
                            onSelected: (id) {
                              setState(() => _selectedCertificationId = id);
                            },
                          ),
                          const SizedBox(height: AppSpacing.x6),
                          _TimerMainCard(
                            title: selected?.certification.name ?? '자격증',
                            elapsedSeconds: _elapsedSeconds,
                            maxSeconds: _maxSeconds,
                            running: _running,
                            saving: _saving,
                            onToggle: _toggleTimer,
                            onStop: _finishAndSave,
                            onReset: _resetTimer,
                          ),
                          const SizedBox(height: AppSpacing.x6),
                          Row(
                            children: [
                              Expanded(
                                child: _TimerStatCard(
                                  label: '오늘의 학습',
                                  value: _formatDuration(
                                      data?.summary.todaySeconds ?? 0),
                                  caption: '오늘 저장된 학습 기록 합계',
                                  icon: Icons.trending_up_rounded,
                                  accent: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.x4),
                              Expanded(
                                child: _TimerStatCard(
                                  label: '전체 학습 시간',
                                  value: _formatDuration(
                                      data?.summary.totalSeconds ?? 0),
                                  caption: '내 계정의 누적 학습 시간',
                                  icon: Icons.military_tech_rounded,
                                  accent: AppColors.tertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x8),
                          Row(
                            children: [
                              Expanded(
                                child: Text('최근 학습 기록',
                                    style: textTheme.titleMedium),
                              ),
                              TextButton(
                                  onPressed: _refresh, child: const Text('갱신')),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x2),
                          if (recentRecords.isEmpty)
                            const _TimerInfoPanel(
                              icon: Icons.history_rounded,
                              title: '아직 저장된 학습 기록이 없습니다.',
                              message: '타이머를 종료하면 최근 학습 기록에 표시됩니다.',
                            )
                          else
                            Column(
                              children: [
                                for (final record in recentRecords) ...[
                                  _StudyRecordTile(record: record),
                                  const SizedBox(height: AppSpacing.x3),
                                ],
                              ],
                            ),
                        ],
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
    );
  }

  UserCertificationItem? _selectedCertification(
    List<UserCertificationItem> certifications,
  ) {
    for (final item in certifications) {
      if (item.certification.id == _selectedCertificationId) {
        return item;
      }
    }
    return certifications.isEmpty ? null : certifications.first;
  }
}

class _TimerPageData {
  const _TimerPageData({
    required this.certifications,
    required this.summary,
  });

  final List<UserCertificationItem> certifications;
  final StudySessionSummary summary;
}

class _CertificationSelector extends StatelessWidget {
  const _CertificationSelector({
    required this.certifications,
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
  });

  final List<UserCertificationItem> certifications;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: certifications.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x2),
        itemBuilder: (context, index) {
          final item = certifications[index];
          final active = item.certification.id == selectedId;
          return _CertChoiceChip(
            label: item.certification.name,
            active: active,
            enabled: enabled,
            onTap: () => onSelected(item.certification.id),
          );
        },
      ),
    );
  }
}

class _CertChoiceChip extends StatelessWidget {
  const _CertChoiceChip({
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: active ? AppColors.primary : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x5,
            vertical: AppSpacing.x2,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerMainCard extends StatelessWidget {
  const _TimerMainCard({
    required this.title,
    required this.elapsedSeconds,
    required this.maxSeconds,
    required this.running,
    required this.saving,
    required this.onToggle,
    required this.onStop,
    required this.onReset,
  });

  final String title;
  final int elapsedSeconds;
  final int maxSeconds;
  final bool running;
  final bool saving;
  final VoidCallback onToggle;
  final VoidCallback onStop;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = maxSeconds == 0 ? 0.0 : elapsedSeconds / maxSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x6,
        AppSpacing.x8,
        AppSpacing.x6,
        AppSpacing.x6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x8),
          SizedBox(
            width: 256,
            height: 256,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(256),
                  painter:
                      _TimerRingPainter(progress: progress.clamp(0.0, 1.0)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatClock(elapsedSeconds),
                      style: textTheme.displayLarge?.copyWith(fontSize: 46),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      saving
                          ? '저장 중'
                          : running
                              ? '집중 중'
                              : elapsedSeconds == 0
                                  ? '대기 중'
                                  : '일시 정지',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      '최대 60분',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundControlButton(
                icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                primary: true,
                onTap: saving ? null : onToggle,
              ),
              const SizedBox(width: AppSpacing.x5),
              _RoundControlButton(
                icon: Icons.stop_rounded,
                onTap: saving || elapsedSeconds == 0 ? null : onStop,
              ),
              const SizedBox(width: AppSpacing.x5),
              _RoundControlButton(
                icon: Icons.restart_alt_rounded,
                onTap: saving || elapsedSeconds == 0 ? null : onReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final track = Paint()
      ..color = AppColors.surfaceLow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final arc = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: primary
          ? AppColors.primary.withValues(alpha: enabled ? 1 : 0.42)
          : colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(
            icon,
            size: 30,
            color: primary
                ? AppColors.onPrimary
                : colorScheme.onSurfaceVariant
                    .withValues(alpha: enabled ? 1 : 0.4),
          ),
        ),
      ),
    );
  }
}

class _TimerStatCard extends StatelessWidget {
  const _TimerStatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(value, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyRecordTile extends StatelessWidget {
  const _StudyRecordTile({required this.record});

  final StudySessionRecord record;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.history_edu_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.certification?.name ?? '자격증 학습',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(record.startedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Text(_formatClock(record.durationSeconds),
              style: textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _TimerInfoPanel extends StatelessWidget {
  const _TimerInfoPanel({
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

String _formatClock(int seconds) {
  final safeSeconds = seconds.clamp(0, 99 * 60 * 60);
  final hours = safeSeconds ~/ 3600;
  final minutes = (safeSeconds % 3600) ~/ 60;
  final secs = safeSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${secs.toString().padLeft(2, '0')}';
}

String _formatDuration(int seconds) {
  final safeSeconds = seconds.clamp(0, 1 << 31);
  final hours = safeSeconds ~/ 3600;
  final minutes = (safeSeconds % 3600) ~/ 60;
  if (hours <= 0) {
    return '$minutes분';
  }
  return '$hours시간 $minutes분';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final meridiem = local.hour < 12 ? '오전' : '오후';
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')} $meridiem '
      '${hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

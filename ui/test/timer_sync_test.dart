import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:specmoa_zip_ui/models/study_session_data.dart';
import 'package:specmoa_zip_ui/models/user_spec.dart';
import 'package:specmoa_zip_ui/screens/timer_screen.dart';
import 'package:specmoa_zip_ui/services/study_session_api_client.dart';
import 'package:specmoa_zip_ui/services/user_spec_api_client.dart';

const _project = UserSpec(
    id: 'project-a', type: SpecType.project, title: '프로젝트 A', data: {});
const _summary =
    StudySessionSummary(todaySeconds: 0, totalSeconds: 0, recent: []);

class _Specs extends UserSpecApiClient {
  Future<List<UserSpec>> Function() load = () async => [_project];
  @override
  Future<List<UserSpec>> fetchMine() => load();
}

class _Sessions extends StudySessionApiClient {
  Future<void> Function()? save;
  final saved = <({String userId, String? specId, int seconds})>[];
  @override
  Future<StudySessionSummary> fetchSummary({String? userId}) async => _summary;
  @override
  Future<void> create({
    required String userId,
    String? certificationId,
    String? specId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
  }) async {
    saved.add((userId: userId, specId: specId, seconds: durationSeconds));
    await save?.call();
  }
}

Widget _app(_Specs specs, _Sessions sessions, {String userId = 'user-a'}) =>
    MaterialApp(
        home: Scaffold(
            body: TimerScreen(
                userId: userId, specClient: specs, sessionClient: sessions)));

void main() {
  Future<void> start(WidgetTester tester, _Specs specs, _Sessions sessions,
      {bool linked = true}) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(specs, sessions));
    await tester.pumpAndSettle();
    if (linked) {
      await tester.tap(find.text('프로젝트 A').first);
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:00:02'), findsOneWidget);
  }

  testWidgets('refresh keeps the running timer available while loading',
      (tester) async {
    final specs = _Specs();
    await start(tester, specs, _Sessions());
    final pending = Completer<List<UserSpec>>();
    specs.load = () => pending.future;
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.text('00:00:02'), findsOneWidget);
    pending.complete([_project]);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an older refresh cannot clear a more recent selection',
      (tester) async {
    final specs = _Specs();
    await start(tester, specs, _Sessions());
    final stale = Completer<List<UserSpec>>();
    specs.load = () => stale.future;
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pump();
    specs.load = () async => [_project];
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pumpAndSettle();
    stale.complete([]);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:00:03'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('deleting the selected spec clears its running timer',
      (tester) async {
    final specs = _Specs();
    await start(tester, specs, _Sessions());
    specs.load = () async => [];
    UserSpecApiClient.changes.value++;
    await tester.pumpAndSettle();
    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.text('프로젝트 A'), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a failed refresh leaves the active timer usable',
      (tester) async {
    final specs = _Specs();
    await start(tester, specs, _Sessions());
    specs.load = () async => throw Exception('offline');
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.text('타이머 정보를 갱신하지 못했습니다. 다시 시도해주세요.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(find.text('일시 정지'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('spec changes do not reset free study', (tester) async {
    final specs = _Specs();
    await start(tester, specs, _Sessions(), linked: false);
    specs.load = () async => [];
    UserSpecApiClient.changes.value++;
    await tester.pumpAndSettle();
    expect(find.text('00:00:02'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed save keeps elapsed time and spec for retry',
      (tester) async {
    final specs = _Specs();
    final sessions = _Sessions()..save = () async => throw Exception('offline');
    await start(tester, specs, sessions);
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pumpAndSettle();
    expect(find.text('학습 기록 저장에 실패했습니다.'), findsOneWidget);
    expect(find.text('00:00:02'), findsOneWidget);
    sessions.save = null;
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pumpAndSettle();
    expect(sessions.saved, [
      (userId: 'user-a', specId: 'project-a', seconds: 2),
      (userId: 'user-a', specId: 'project-a', seconds: 2),
    ]);
    expect(find.text('00:00:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a previous user save cannot reset the new user timer',
      (tester) async {
    final specs = _Specs();
    final pending = Completer<void>();
    final sessions = _Sessions()..save = () => pending.future;
    await start(tester, specs, sessions, linked: false);
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();
    await tester.pumpWidget(_app(specs, sessions, userId: 'user-b'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(seconds: 2));
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('00:00:02'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.textContaining('저장 완료'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

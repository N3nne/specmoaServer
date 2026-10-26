import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:specmoa_zip_ui/models/ai_demo_data.dart';
import 'package:specmoa_zip_ui/models/job_comparison.dart';
import 'package:specmoa_zip_ui/models/job_data.dart';
import 'package:specmoa_zip_ui/screens/explore_screen.dart';
import 'package:specmoa_zip_ui/services/authenticated_client.dart';
import 'package:specmoa_zip_ui/services/job_api_client.dart';

import 'fixtures/ai_demo_fixture.dart';
import 'fixtures/job_comparison_fixture.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

class _Client extends JobApiClient {
  int generations = 0, statuses = 0;
  bool enabled = true;
  Future<AiDemoResult> Function()? generate;
  Future<AiDemoAvailability> Function()? status;
  final opened = <String>[];

  @override
  Future<AiDemoAvailability> fetchAiDemoStatus() async {
    statuses++;
    return status == null
        ? AiDemoAvailability.fromJson(aiStatusFixture(enabled: enabled))
        : status!();
  }

  @override
  Future<AiDemoResult> generateAiDemo() async {
    generations++;
    return generate == null
        ? AiDemoResult.fromJson(aiResultFixture())
        : generate!();
  }

  @override
  Future<List<JobOccupation>> fetchOccupations() async =>
      const [JobOccupation('backend', 3)];

  @override
  Future<JobPage> fetchJobs(
          {String query = '',
          String? occupation,
          String sort = 'latest',
          int offset = 0,
          int limit = 20}) async =>
      JobPage(
          items: [JobPosting.fromJson(aiResolvedJobFixture())],
          total: 1,
          offset: 0,
          synthetic: true,
          notice: '시연용 가상 공고입니다.',
          asOf: DateTime.utc(2026, 10, 26));

  @override
  Future<JobDetail> fetchDemoDetail(String externalId) async {
    opened.add(externalId);
    return JobDetail.fromJson(aiResolvedJobFixture());
  }

  @override
  Future<JobDetail> fetchDetail(String id) async =>
      JobDetail.fromJson(aiResolvedJobFixture());

  @override
  Future<JobComparisonResult> fetchComparison(String id) async =>
      JobComparisonResult(
          job: await fetchDetail(id),
          comparison: JobComparison.fromJson(comparisonFixture()));
}

Widget _app(_Client client,
        {String? userId = 'a', bool dark = false, double scale = 1}) =>
    MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: Scaffold(
            body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: ExploreScreen(userId: userId, client: client))));

Future<void> _show(WidgetTester tester, _Client client,
    {double width = 390, bool dark = false, double scale = 1}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(client, dark: dark, scale: scale));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    ApiCredentials.accessToken = null;
  });

  test(
      'AI POST sends only a fixed fictional profile with existing authentication',
      () async {
    ApiCredentials.accessToken = 'mock-access-token';
    final client = JobApiClient(
        client: AuthenticatedClient(inner: MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/ai/demo/recommendations');
      expect(request.url.query, isEmpty);
      expect(request.headers['Authorization'], 'Bearer mock-access-token');
      expect(request.headers.containsKey('x-user-id'), isFalse);
      expect(jsonDecode(request.body), {'profile': 'backend'});
      return _json(aiResultFixture());
    })));
    final result = await client.generateAiDemo();
    expect(result.items.length, 3);
    expect(result.items.first.reasons.single.specQuote, 'TypeScript');
    expect(result.items.first.comparison.method, 'rules-v2');
  });

  test('AI status and demo job resolution validate synthetic identity',
      () async {
    final client = JobApiClient(
        client: MockClient((request) async => _json(
            request.url.path == '/ai/demo/status'
                ? aiStatusFixture()
                : aiResolvedJobFixture())));
    expect((await client.fetchAiDemoStatus()).enabled, isTrue);
    expect((await client.fetchDemoDetail('specmoa-demo-v1-001')).job.id,
        aiResolvedJobFixture()['id']);
    for (final mutation in [
      {'source': 'provider'},
      {'synthetic': false},
      {'externalId': 'wrong'}
    ]) {
      final bad = JobApiClient(
          client: MockClient(
              (_) async => _json({...aiResolvedJobFixture(), ...mutation})));
      await expectLater(
          bad.fetchDemoDetail('specmoa-demo-v1-001'), throwsFormatException);
    }
  });

  test('AI errors are sanitized; malformed results are not empty successes',
      () async {
    for (final status in [401, 429, 502, 503]) {
      final client = JobApiClient(
          client: MockClient(
              (_) async => http.Response('private-provider-error', status)));
      await expectLater(
          client.generateAiDemo(),
          throwsA(isA<AiDemoApiException>()
              .having((e) => e.statusCode, 'status', status)
              .having((e) => e.message.contains('private-provider-error'),
                  'redacted', false)));
    }
    final bad = JobApiClient(client: MockClient((_) async => _json([])));
    await expectLater(bad.generateAiDemo(), throwsFormatException);
  });

  test(
      'AI model rejects mismatched profile, provenance, timestamps, evidence, counts and ranks',
      () {
    final mutations = <void Function(Map<String, dynamic>)>[
      (j) => j['method'] = 'unknown',
      (j) => j['synthetic'] = false,
      (j) => j['profileId'] = 'real-user',
      (j) => j['generatedAt'] = '2026-10-26T12:00:00',
      (j) => j['candidateCount'] = 0,
      (j) => j['items'][0]['rank'] = 2,
      (j) => j['items'][1]['jobExternalId'] = j['items'][0]['jobExternalId'],
      (j) => j['items'][0]['reasons'] = [],
      (j) => j['items'][0]['reasons'][0]['specId'] = 'real-user-spec',
      (j) => j['items'][0]['comparison']['required']['confirmed'] = 1,
    ];
    for (final mutate in mutations) {
      final fixture = aiResultFixture();
      mutate(fixture);
      expect(() => AiDemoResult.fromJson(fixture), throwsFormatException);
    }
    expect(AiDemoResult.fromJson(aiResultFixture(count: 0)).items, isEmpty);
  });

  testWidgets(
      'AI never generates automatically; tapping the source chip loads actual API output',
      (tester) async {
    final client = _Client();
    await _show(tester, client);
    expect(client.generations, 0);
    await tester.tap(find.text('AI 추천 시연'));
    await tester.pumpAndSettle();
    expect(client.generations, 1);
    expect(find.text('가상 백엔드 프로필'), findsOneWidget);
    expect(find.text('3건'), findsOneWidget);
    expect(find.text('12:30 생성'), findsOneWidget);
    expect(find.textContaining('실제 내 스펙은 전송하지 않습니다'), findsOneWidget);
    expect(find.textContaining('96%'), findsNothing);
    expect(find.text('AI 추천 1순위'), findsOneWidget);
    final summary =
        tester.getRect(find.byKey(const ValueKey('ai-demo-summary')));
    expect(summary.left, 16);
    expect(summary.width, 358);
    expect(
        tester.getSize(find.byKey(const ValueKey('ai-recommendation-1'))).width,
        290);
    final before =
        tester.getTopLeft(find.byKey(const ValueKey('ai-recommendation-2'))).dx;
    await tester.drag(
        find.byKey(const ValueKey('ai-demo-carousel')), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('ai-recommendation-2'))).dx,
        lessThan(before));
  });

  testWidgets(
      'AI loading prevents duplicate generation and leaves job feed available',
      (tester) async {
    final pending = Completer<AiDemoResult>();
    final client = _Client()..generate = () => pending.future;
    await _show(tester, client);
    await tester.tap(find.text('AI 추천 시연'));
    await tester.pump();
    await tester.tap(find.text('AI 추천 시연'));
    await tester.pump();
    expect(client.generations, 1);
    expect(find.text('AI 추천 생성 중'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'AI 추천 새로고침'))
            .onPressed,
        isNull);
    expect(find.text('시연용 채용공고'), findsOneWidget);
    pending.complete(AiDemoResult.fromJson(aiResultFixture()));
    await tester.pumpAndSettle();
    expect(find.text('3건'), findsOneWidget);
  });

  testWidgets(
      '503 is visible and retry retains the last successful cards and timestamp',
      (tester) async {
    final client = _Client();
    await _show(tester, client);
    await tester.tap(find.text('AI 추천 시연'));
    await tester.pumpAndSettle();
    client.generate = () async =>
        throw const AiDemoApiException(503, 'AI 서버가 현재 요청을 처리할 수 없습니다.');
    await tester.tap(find.byTooltip('AI 추천 새로고침'));
    await tester.pumpAndSettle();
    expect(find.text('AI 서버가 현재 요청을 처리할 수 없습니다.'), findsOneWidget);
    expect(find.text('12:30 생성'), findsOneWidget);
    expect(find.text('3건'), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-recommendation-1')), findsOneWidget);
    expect(client.generations, 2);
  });

  testWidgets(
      'initial AI failure has no fake recommendations; normal feed remains',
      (tester) async {
    final client = _Client()
      ..generate =
          () async => throw const AiDemoApiException(429, 'AI 호출 한도에 도달했습니다.');
    await _show(tester, client);
    await tester.tap(find.text('AI 추천 시연'));
    await tester.pumpAndSettle();
    expect(find.text('AI 호출 한도에 도달했습니다.'), findsOneWidget);
    expect(find.text('아직 생성된 추천이 없습니다.'), findsOneWidget);
    expect(find.text('시연용 채용공고'), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-recommendation-1')), findsNothing);
  });

  testWidgets(
      'AI resolves fixture identity before opening the existing job detail',
      (tester) async {
    final client = _Client();
    await _show(tester, client);
    await tester.tap(find.text('AI 추천 시연'));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, '공고 상세').first;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(client.opened, ['specmoa-demo-v1-001']);
    expect(find.text('내 스펙 조건 비교'), findsOneWidget);
  });

  testWidgets(
      'account switch discards pending AI output and clears selected AI view',
      (tester) async {
    final pending = Completer<AiDemoResult>();
    final client = _Client()..generate = () => pending.future;
    await _show(tester, client);
    await tester.tap(find.text('AI 추천 시연'));
    await tester.pump();
    await tester.pumpWidget(_app(client, userId: 'b'));
    await tester.pump();
    pending.complete(AiDemoResult.fromJson(aiResultFixture()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-demo-summary')), findsNothing);
    expect(find.text('3건'), findsNothing);
  });

  testWidgets('disabled and unavailable AI does not alter job browsing',
      (tester) async {
    final client = _Client()..enabled = false;
    await _show(tester, client);
    expect(find.text('AI 추천 시연'), findsNothing);
    expect(client.generations, 0);
    client.status = () async => throw Exception('offline');
    await tester.pumpWidget(_app(client, userId: 'b'));
    await tester.pumpAndSettle();
    expect(find.text('AI 추천 시연'), findsNothing);
    expect(find.text('시연용 채용공고'), findsOneWidget);
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('AI carousel fits $width with dark mode and larger text',
        (tester) async {
      final client = _Client();
      await _show(tester, client, width: width, dark: true, scale: 1.5);
      await tester.tap(find.text('AI 추천 시연'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final first = find.byKey(const ValueKey('ai-recommendation-1'));
      await tester.ensureVisible(first);
      await tester.pumpAndSettle();
      await tester.dragFrom(tester.getTopLeft(first) + const Offset(100, 60),
          const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

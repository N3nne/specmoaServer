import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:specmoa_zip_ui/models/job_data.dart';
import 'package:specmoa_zip_ui/models/job_comparison.dart';
import 'package:specmoa_zip_ui/models/ai_demo_data.dart';
import 'package:specmoa_zip_ui/screens/explore_screen.dart';
import 'package:specmoa_zip_ui/services/job_api_client.dart';

import 'fixtures/job_comparison_fixture.dart';

final _now = DateTime.utc(2026, 10, 22, 3);

JobPosting _job(String id, {String? title, DateTime? closesAt}) => JobPosting(
      id: id,
      companyName: '스펙모아 가상기업 01',
      title: title ?? '[가상 공고] 백엔드 개발 $id',
      occupation: 'backend',
      region: '서울',
      employmentType: 'full_time',
      experienceLevel: 'entry',
      keywords: const ['NestJS', 'PostgreSQL'],
      closesAt: closesAt,
      status: 'open',
    );

JobPage _page(List<JobPosting> items, {int? total, int offset = 0}) => JobPage(
      items: items,
      total: total ?? items.length,
      offset: offset,
      synthetic: true,
      notice: '시연용 가상 공고입니다. 실제 지원 접수와 관계없습니다.',
      asOf: _now,
    );

class _Jobs extends JobApiClient {
  @override
  Future<AiDemoAvailability> fetchAiDemoStatus() async =>
      const AiDemoAvailability(
          enabled: false, profileLabel: '가상 백엔드 프로필', profileSummary: '가상 스펙');
  final requests =
      <({String query, String? occupation, String sort, int offset})>[];
  Future<JobPage> Function(
      String query, String? occupation, String sort, int offset)? load;
  Future<List<JobOccupation>> Function()? facets;

  @override
  Future<JobPage> fetchJobs(
      {String query = '',
      String? occupation,
      String sort = 'latest',
      int offset = 0,
      int limit = 20}) async {
    requests.add(
        (query: query, occupation: occupation, sort: sort, offset: offset));
    return load == null
        ? _page([_job('1')])
        : load!(query, occupation, sort, offset);
  }

  @override
  Future<JobDetail> fetchDetail(String id) async => JobDetail(
      job: _job(id), synthetic: true, notice: '시연용 가상 공고', canApply: false);

  @override
  Future<JobComparisonResult> fetchComparison(String id) async =>
      JobComparisonResult(
          job: await fetchDetail(id),
          comparison: JobComparison.fromJson(comparisonFixture()));

  @override
  Future<List<JobOccupation>> fetchOccupations() async => facets == null
      ? const [JobOccupation('backend', 3), JobOccupation('frontend', 2)]
      : facets!();
}

Widget _app(_Jobs client,
        {String? userId = 'a', bool dark = false, double scale = 1}) =>
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
          body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: ExploreScreen(userId: userId, client: client),
      )),
    );

Future<void> _show(WidgetTester tester, _Jobs client,
    {double width = 390, bool dark = false, double scale = 1}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(client, dark: dark, scale: scale));
  await tester.pumpAndSettle();
}

void main() {
  test('API encodes literal search and preserves nullable dates and provenance',
      () async {
    final client = JobApiClient(client: MockClient((request) async {
      expect(request.url.path, '/jobs');
      expect(request.url.queryParameters, {
        'q': '한글 %_ &',
        'occupation': 'backend',
        'sort': 'deadline',
        'status': 'open',
        'limit': '20',
        'offset': '20',
      });
      return http.Response.bytes(
          utf8.encode(jsonEncode({
            'items': [
              {
                'id': '1',
                'companyName': '가상기업',
                'title': '한글 공고',
                'occupation': 'backend',
                'region': '서울',
                'employmentType': 'full_time',
                'experienceLevel': null,
                'keywords': [],
                'closesAt': null,
                'status': 'open',
              }
            ],
            'total': 21,
            'offset': 20,
            'synthetic': true,
            'notice': '가상 데이터',
            'asOf': _now.toIso8601String(),
          })),
          200);
    }));
    final result = await client.fetchJobs(
        query: ' 한글 %_ & ',
        occupation: 'backend',
        sort: 'deadline',
        offset: 20);
    expect(result.synthetic, isTrue);
    expect(result.notice, '가상 데이터');
    expect(result.items.single.closesAt, isNull);
    expect(result.items.single.experienceLevel, isNull);
    expect(result.items.single.deadlineLabel(_now), '마감일 미정');
    expect(result.items.single.experienceLabel, '경력 정보 없음');
  });

  test('HTTP errors and malformed JSON are not treated as empty results',
      () async {
    final error =
        JobApiClient(client: MockClient((_) async => http.Response('no', 503)));
    await expectLater(error.fetchJobs(), throwsException);
    final invalid =
        JobApiClient(client: MockClient((_) async => http.Response('[]', 200)));
    await expectLater(invalid.fetchJobs(), throwsFormatException);
  });

  test('deadline uses calendar days rather than rounded hours', () {
    expect(
        _job('1', closesAt: _now.add(const Duration(hours: 1)))
            .deadlineLabel(_now),
        '오늘 마감');
    expect(
        _job('1', closesAt: _now.add(const Duration(days: 5)))
            .deadlineLabel(_now),
        'D-5');
  });

  testWidgets('shows backend content, synthetic notice and no AI claims',
      (tester) async {
    await _show(tester, _Jobs());
    expect(find.text('시연용 채용공고'), findsOneWidget);
    expect(find.text('1건'), findsOneWidget);
    expect(find.text('[가상 공고] 백엔드 개발 1'), findsOneWidget);
    expect(find.text('마감일 미정'), findsOneWidget);
    expect(find.text('서울 · 신입 · 정규직'), findsOneWidget);
    expect(find.text('NestJS'), findsOneWidget);
    expect(find.textContaining('실제 지원'), findsOneWidget);
    expect(find.textContaining('AI'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    await tester.tap(find.text('[가상 공고] 백엔드 개발 1'));
    await tester.pumpAndSettle();
    expect(find.text('상세정보'), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.text('시연용 채용공고'), findsOneWidget);
  });

  testWidgets('source dimensions and compact header are retained',
      (tester) async {
    await _show(tester, _Jobs(), width: 320);
    final card = tester.getRect(find.byKey(const ValueKey('1')));
    expect(card.left, 16);
    expect(card.width, 288);
    expect(tester.getSize(find.text('시연용 채용공고')).height, lessThan(30));
    expect(tester.widget<Text>(find.text('[가상 공고] 백엔드 개발 1')).maxLines, 1);
    expect(find.byTooltip('상세 필터 준비 중'), findsNothing);
    expect(find.byIcon(Icons.tune), findsNothing);
    expect(tester.getSize(find.byType(TextField)).width, 232);
  });

  testWidgets('cards have no bookmark and use the released space for content',
      (tester) async {
    await _show(tester, _Jobs());
    expect(find.byTooltip('공고 저장 준비 중'), findsNothing);
    expect(find.byIcon(Icons.bookmark_border), findsNothing);
    final card = tester.getRect(find.byKey(const ValueKey('1')));
    expect(
        tester
            .renderObject<RenderBox>(find.text('[가상 공고] 백엔드 개발 1'))
            .constraints
            .maxWidth,
        card.width - 88);
    await tester.tapAt(Offset(card.right - 20, card.top + 24));
    await tester.pumpAndSettle();
    expect(find.text('상세정보'), findsOneWidget);
    expect(find.byTooltip('공고 저장 준비 중'), findsNothing);
    expect(find.byIcon(Icons.bookmark_border), findsNothing);
  });

  testWidgets('dark selected chip uses contrasting on-primary text',
      (tester) async {
    await _show(tester, _Jobs(), dark: true);
    expect(tester.widget<Text>(find.text('전체')).style!.color,
        ThemeData(brightness: Brightness.dark).colorScheme.onPrimary);
  });

  testWidgets('Korean composition waits for commit and debounces search',
      (tester) async {
    final client = _Jobs();
    await _show(tester, client);
    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '백',
        composing: TextRange(start: 0, end: 1),
        selection: TextSelection.collapsed(offset: 1)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(client.requests.length, 1);
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '백엔드', selection: TextSelection.collapsed(offset: 3)));
    await tester.pump(const Duration(milliseconds: 259));
    expect(client.requests.length, 1);
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pumpAndSettle();
    expect(client.requests.last.query, '백엔드');
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pump(const Duration(milliseconds: 261));
    await tester.pumpAndSettle();
    expect(client.requests.last.query, '');
  });

  testWidgets('stale search cannot overwrite a newer query', (tester) async {
    final client = _Jobs();
    await _show(tester, client);
    final stale = Completer<JobPage>();
    client.load = (q, o, s, n) =>
        q == 'old' ? stale.future : Future.value(_page([_job(q)]));
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 261));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 261));
    await tester.pumpAndSettle();
    stale.complete(_page([_job('old')]));
    await tester.pumpAndSettle();
    expect(find.text('[가상 공고] 백엔드 개발 new'), findsOneWidget);
    expect(find.text('[가상 공고] 백엔드 개발 old'), findsNothing);
  });

  testWidgets('occupation and sort use API parameters', (tester) async {
    final client = _Jobs();
    await _show(tester, client);
    await tester.tap(find.text('백엔드/서버'));
    await tester.pumpAndSettle();
    expect(client.requests.last.occupation, 'backend');
    await tester.tap(find.byTooltip('공고 정렬'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마감임박순').last);
    await tester.pumpAndSettle();
    expect(client.requests.last.sort, 'deadline');
    expect(client.requests.last.occupation, 'backend');
  });

  testWidgets('pagination uses response offset and avoids duplicate cards',
      (tester) async {
    final client = _Jobs()
      ..load = (q, o, s, n) async => n == 0
          ? _page([_job('1')], total: 3)
          : _page([_job('1'), _job('2')], total: 3, offset: 1);
    await _show(tester, client);
    await tester.tap(find.byTooltip('공고 더 불러오기'));
    await tester.pumpAndSettle();
    expect(client.requests.last.offset, 1);
    expect(find.text('[가상 공고] 백엔드 개발 1'), findsOneWidget);
    expect(find.text('[가상 공고] 백엔드 개발 2'), findsOneWidget);
    expect(find.byTooltip('공고 더 불러오기'), findsNothing);
  });

  testWidgets('account switch drops pending feed and facet responses',
      (tester) async {
    final client = _Jobs();
    final stale = Completer<JobPage>();
    final staleFacets = Completer<List<JobOccupation>>();
    client.load = (q, o, s, n) => stale.future;
    client.facets = () => staleFacets.future;
    await tester.pumpWidget(_app(client));
    await tester.pump();
    client.load = (q, o, s, n) async => _page([_job('user-b')]);
    client.facets = () async => [const JobOccupation('mobile', 1)];
    await tester.pumpWidget(_app(client, userId: 'b'));
    await tester.pumpAndSettle();
    stale.complete(_page([_job('user-a')]));
    staleFacets.complete([const JobOccupation('backend', 10)]);
    await tester.pumpAndSettle();
    expect(find.text('[가상 공고] 백엔드 개발 user-a'), findsNothing);
    expect(find.text('[가상 공고] 백엔드 개발 user-b'), findsOneWidget);
    expect(find.text('백엔드/서버'), findsNothing);
    expect(find.text('모바일 앱'), findsOneWidget);
  });

  testWidgets('new search cancels pagination without mixing old cards',
      (tester) async {
    final client = _Jobs();
    final stale = Completer<JobPage>();
    client.load = (q, o, s, n) async {
      if (q.isNotEmpty) return _page([_job(q)]);
      return n == 0 ? _page([_job('old')], total: 2) : stale.future;
    };
    await _show(tester, client);
    await tester.tap(find.byTooltip('공고 더 불러오기'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 261));
    await tester.pumpAndSettle();
    stale.complete(_page([_job('old-next')], total: 2, offset: 1));
    await tester.pumpAndSettle();
    expect(find.text('[가상 공고] 백엔드 개발 new'), findsOneWidget);
    expect(find.text('[가상 공고] 백엔드 개발 old-next'), findsNothing);
  });

  testWidgets('failed pagination preserves cards and retries the same offset',
      (tester) async {
    final client = _Jobs();
    client.load = (q, o, s, n) async {
      if (n != 0) throw Exception('offline');
      return _page([_job('1')], total: 2);
    };
    await _show(tester, client);
    await tester.tap(find.byTooltip('공고 더 불러오기'));
    await tester.pumpAndSettle();
    expect(find.text('[가상 공고] 백엔드 개발 1'), findsOneWidget);
    expect(find.text('추가 공고를 불러오지 못했습니다.'), findsOneWidget);
    client.load = (q, o, s, n) async => _page([_job('2')], total: 2, offset: n);
    await tester.tap(find.byTooltip('다시 시도'));
    await tester.pumpAndSettle();
    expect(client.requests.map((r) => r.offset), [0, 1, 1]);
    expect(find.text('[가상 공고] 백엔드 개발 2'), findsOneWidget);
  });

  testWidgets('signed out screen performs no protected requests',
      (tester) async {
    final client = _Jobs();
    await tester.pumpWidget(_app(client, userId: null));
    await tester.pumpAndSettle();
    expect(client.requests, isEmpty);
    expect(find.text('로그인이 필요합니다.'), findsOneWidget);
  });

  testWidgets('retry, empty results and optional facet failure are handled',
      (tester) async {
    final client = _Jobs();
    client.load = (q, o, s, n) async => throw Exception('offline');
    client.facets = () async => throw Exception('offline');
    await _show(tester, client);
    expect(find.text('채용공고를 불러오지 못했습니다.'), findsOneWidget);
    client.load = (q, o, s, n) async => _page([]);
    await tester.tap(find.byTooltip('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('조건에 맞는 채용공고가 없습니다.'), findsOneWidget);
    expect(find.text('0건'), findsOneWidget);
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('no overflow at $width, dark mode and enlarged text',
        (tester) async {
      final client = _Jobs()
        ..load = (q, o, s, n) async => _page([
              _job('1', title: '[가상 공고] 아주긴문자열로표시하는백엔드개발직무공고제목과설명'),
            ]);
      await _show(tester, client, width: width, dark: true, scale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('시연용 채용공고'), findsOneWidget);
    });
  }
}

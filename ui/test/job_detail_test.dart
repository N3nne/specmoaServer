import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:specmoa_zip_ui/auth/auth_session.dart';
import 'package:specmoa_zip_ui/auth/auth_token_store.dart';
import 'package:specmoa_zip_ui/models/auth_user.dart';
import 'package:specmoa_zip_ui/models/job_comparison.dart';
import 'package:specmoa_zip_ui/models/job_data.dart';
import 'package:specmoa_zip_ui/screens/job_detail_screen.dart';
import 'package:specmoa_zip_ui/services/authenticated_client.dart';
import 'package:specmoa_zip_ui/services/job_api_client.dart';

import 'fixtures/job_comparison_fixture.dart';

Map<String, dynamic> _json(String id,
        {bool synthetic = true, String? sourceUrl}) =>
    {
      'id': id,
      'companyName': '스펙모아 가상기업 01',
      'title': '[가상 공고] 백엔드 개발 $id',
      'occupation': 'backend',
      'region': '서울',
      'employmentType': 'full_time',
      'experienceLevel': 'experienced',
      'minExperienceMonths': 24,
      'educationLevel': 'bachelor',
      'keywords': ['NestJS', 'PostgreSQL'],
      'closesAt': '2026-10-30T14:59:00Z',
      'status': 'open',
      'synthetic': synthetic,
      'notice': synthetic ? '시연용 가상 공고입니다. 실제 지원 접수와 관계없습니다.' : '',
      'canApply': true,
      'sourceUrl': sourceUrl,
      'description': '담당 업무\nAPI와 데이터베이스를 개발합니다.\n\n필수 및 우대 조건\n필수: NestJS',
      'salaryText': '연 3,600~4,600만원',
      'requirements': [
        {'kind': 'skill', 'name': 'NestJS', 'required': true},
        {'kind': 'certification', 'name': '정보처리기사', 'required': false},
        {
          'kind': 'language_score',
          'name': 'TOEIC',
          'minimumScore': 700,
          'required': false
        },
      ],
      'opensAt': '2026-10-20T00:00:00Z',
      'postedAt': '2026-10-19T00:00:00Z',
    };

class _Client extends JobApiClient {
  final requests = <String>[];
  final comparisonRequests = <String>[];
  final _details = <String, JobDetail>{};
  Future<JobDetail> Function(String)? load;
  Future<JobComparisonResult> Function(String)? compare;
  @override
  Future<JobDetail> fetchDetail(String id) async {
    requests.add(id);
    final detail =
        load == null ? JobDetail.fromJson(_json(id)) : await load!(id);
    _details[id] = detail;
    return detail;
  }

  @override
  Future<JobComparisonResult> fetchComparison(String id) async {
    comparisonRequests.add(id);
    return compare == null
        ? JobComparisonResult(
            job: _details[id]!,
            comparison: JobComparison.fromJson(comparisonFixture()))
        : compare!(id);
  }
}

Widget _app(_Client client,
        {String id = 'a',
        String userId = 'user-a',
        bool dark = false,
        double scale = 1,
        Future<bool> Function(Uri)? openLink}) =>
    MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: JobDetailScreen(
                jobId: id,
                userId: userId,
                client: client,
                openLink: openLink)));

Future<void> _show(WidgetTester tester, _Client client,
    {double width = 390,
    bool dark = false,
    double scale = 1,
    Future<bool> Function(Uri)? openLink}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester
      .pumpWidget(_app(client, dark: dark, scale: scale, openLink: openLink));
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 250,
      scrollable: find.byType(Scrollable).first, maxScrolls: 30);
  await tester.pumpAndSettle();
}

void main() {
  test('detail API uses the requested ID and preserves missing fields',
      () async {
    final data = _json('abc')
      ..['requirements'] = null
      ..['description'] = null
      ..['sourceUrl'] = null
      ..['closesAt'] = null;
    final client = JobApiClient(client: MockClient((request) async {
      expect(request.url.path, '/jobs/abc');
      return http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
    }));
    final detail = await client.fetchDetail('abc');
    expect(detail.job.id, 'abc');
    expect(detail.description, isNull);
    expect(detail.requirements, isNull);
    expect(detail.sourceUri, isNull);
    expect(detail.canOpenApplication, isFalse);
  });

  test('mismatched identity and 404 are not successful details', () async {
    final wrong = JobApiClient(
        client: MockClient((_) async =>
            http.Response.bytes(utf8.encode(jsonEncode(_json('b'))), 200)));
    await expectLater(wrong.fetchDetail('a'), throwsFormatException);
    final missing =
        JobApiClient(client: MockClient((_) async => http.Response('{}', 404)));
    await expectLater(
        missing.fetchDetail('a'),
        throwsA(
            isA<JobApiException>().having((e) => e.statusCode, 'status', 404)));
  });

  test('demo, closed and unsafe links can never be applied', () {
    for (final url in [
      'https://example.com/job',
      'javascript:alert(1)',
      'file:///tmp/job',
      'http://example.com',
      'https://user:password@example.com',
      '/job'
    ]) {
      final demo = JobDetail.fromJson(_json('a', sourceUrl: url));
      expect(demo.canOpenApplication, isFalse);
      expect(demo.sourceUri, isNull);
    }
    for (final url in [
      'javascript:alert(1)',
      'file:///tmp/job',
      'http://example.com',
      'https://user:pass@example.com'
    ]) {
      expect(
          JobDetail.fromJson(_json('a', synthetic: false, sourceUrl: url))
              .sourceUri,
          isNull);
    }
    final closed =
        _json('a', synthetic: false, sourceUrl: 'https://example.com/job')
          ..['status'] = 'closed';
    expect(JobDetail.fromJson(closed).canOpenApplication, isFalse);
    expect(
        JobDetail.fromJson(_json('a',
                synthetic: false, sourceUrl: 'https://example.com/job'))
            .canOpenApplication,
        isTrue);
  });

  testWidgets('source geometry, real content and demo restrictions',
      (tester) async {
    final client = _Client();
    await _show(tester, client);
    expect(client.requests, ['a']);
    expect(find.text('상세정보'), findsOneWidget);
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsOneWidget);
    expect(find.textContaining('AI'), findsNothing);
    expect(find.textContaining('네이버클라우드'), findsNothing);
    expect(find.textContaining('조회 3,842'), findsNothing);
    final company = tester.getRect(find.byKey(const ValueKey('job-company')));
    expect(company.left, 20);
    expect(company.width, 350);
    expect(company.top, 140);
    expect(find.byTooltip('공고 저장 준비 중'), findsNothing);
    expect(find.byIcon(Icons.bookmark_border), findsNothing);
    expect(tester.getRect(find.byTooltip('공유 가능한 원본 링크가 없습니다.')).right, 366);
    final button = tester.getRect(find.byKey(const ValueKey('job-apply')));
    expect(button.size, const Size(342, 64));
    expect(button.bottom, 820);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('job-apply')))
            .onPressed,
        isNull);
    final buttonColor = tester
        .widget<FilledButton>(find.byKey(const ValueKey('job-apply')))
        .style!
        .backgroundColor!
        .resolve({WidgetState.disabled});
    expect(buttonColor!.a, 1,
        reason:
            'The overlaid CTA must not reveal body text through its surface.');
    expect(find.text('지원 불가 · 시연용'), findsOneWidget);
    await _scrollTo(tester, find.textContaining('API와 데이터베이스'));
    expect(find.textContaining('API와 데이터베이스'), findsOneWidget);
    expect(find.text('학력: 학사 이상'), findsWidgets);
    expect(find.text('경력: 2년 이상'), findsWidgets);
    expect(find.text('TOEIC 700점 이상'), findsOneWidget);
  });

  testWidgets('segments scroll to visible anchors beneath the fixed controls',
      (tester) async {
    await _show(tester, _Client());
    await _scrollTo(tester, find.text('자격요건'));
    await tester.tap(find.text('자격요건'));
    await tester.pumpAndSettle();
    final position = tester.getTopLeft(find.text('지원 자격 (Qualifications)'));
    expect(position.dy, greaterThanOrEqualTo(140));
    expect(position.dy, lessThan(180));
    await tester.tap(find.text('기업 정보'));
    await tester.pumpAndSettle();
    final conditions = tester.getRect(find.text('전형 절차 및 근무 조건'));
    expect(conditions.top, greaterThanOrEqualTo(120));
    expect(conditions.bottom, lessThan(730));
    expect(tester.takeException(), isNull);
  });

  testWidgets('notch and gesture safe areas preserve the source spacing',
      (tester) async {
    final client = _Client();
    await _show(tester, client);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                padding: EdgeInsets.only(top: 24, bottom: 16)),
            child: JobDetailScreen(
                jobId: 'a', userId: 'user-a', client: client))));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('job-company'))).top, 164);
    expect(tester.getRect(find.byKey(const ValueKey('job-apply'))).bottom, 804);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'account changes immediately hide an already loaded protected detail',
      (tester) async {
    final session = AuthSession(store: _Tokens());
    await session.signIn(const AuthUser(
        id: 'user-a', email: 'qa@example.com', displayName: '검증'));
    await tester
        .pumpWidget(AuthScope(session: session, child: _app(_Client())));
    await tester.pumpAndSettle();
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsOneWidget);
    await session.signIn(const AuthUser(
        id: 'user-b', email: 'qa-b@example.com', displayName: '검증B'));
    await tester.pump();
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });

  testWidgets(
      'null data stays unknown and never becomes source mock information',
      (tester) async {
    final client = _Client()
      ..load = (id) async => JobDetail.fromJson(_json(id)
        ..['description'] = null
        ..['requirements'] = null
        ..['educationLevel'] = null
        ..['salaryText'] = null
        ..['closesAt'] = null);
    await _show(tester, client);
    await _scrollTo(tester, find.text('공고 본문이 제공되지 않았습니다.'));
    expect(find.text('공고 본문이 제공되지 않았습니다.'), findsOneWidget);
    expect(find.text('상세 지원 자격 정보가 제공되지 않았습니다.'), findsOneWidget);
    expect(find.text('우대 사항 정보가 제공되지 않았습니다.'), findsOneWidget);
    expect(find.textContaining('서류전형'), findsNothing);
    expect(find.textContaining('판교 테크원'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error can retry; no CTA is enabled while failed or loading',
      (tester) async {
    final client = _Client()
      ..load =
          (id) async => throw const JobApiException(404, '채용공고를 찾을 수 없습니다.');
    await _show(tester, client);
    expect(find.text('채용공고를 찾을 수 없습니다.'), findsOneWidget);
    expect(find.byKey(const ValueKey('job-apply')), findsNothing);
    client.load = (id) async => JobDetail.fromJson(_json(id));
    await tester.tap(find.byTooltip('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsOneWidget);
  });

  testWidgets(
      'late detail from another job or user cannot replace the current one',
      (tester) async {
    final pending = Completer<JobDetail>();
    final client = _Client()
      ..load = (id) => id == 'a'
          ? pending.future
          : Future.value(JobDetail.fromJson(_json(id)));
    await tester.pumpWidget(_app(client));
    await tester.pump();
    await tester.pumpWidget(_app(client, id: 'b', userId: 'user-b'));
    await tester.pumpAndSettle();
    pending.complete(JobDetail.fromJson(_json('a')));
    await tester.pumpAndSettle();
    expect(find.text('[가상 공고] 백엔드 개발 b'), findsOneWidget);
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsNothing);
  });

  testWidgets('authentication generation invalidates a pending detail',
      (tester) async {
    final pending = Completer<JobDetail>();
    final client = _Client()..load = (id) => pending.future;
    final generation = ApiCredentials.generation;
    addTearDown(() => ApiCredentials.generation = generation);
    await tester.pumpWidget(_app(client));
    await tester.pump();
    ApiCredentials.generation++;
    pending.complete(JobDetail.fromJson(_json('a')));
    await tester.pump();
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'real link opens only on user action, never reports a completed application',
      (tester) async {
    final client = _Client()
      ..load = (id) async => JobDetail.fromJson(
          _json(id, synthetic: false, sourceUrl: 'https://example.com/job/a'));
    final opened = <Uri>[];
    await _show(tester, client, openLink: (uri) async {
      opened.add(uri);
      return true;
    });
    expect(opened, isEmpty);
    await tester.tap(find.byKey(const ValueKey('job-apply')));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://example.com/job/a')]);
    expect(find.textContaining('지원 완료'), findsNothing);
  });

  testWidgets('launch failure restores the button for retry', (tester) async {
    final client = _Client()
      ..load = (id) async => JobDetail.fromJson(
          _json(id, synthetic: false, sourceUrl: 'https://example.com/job/a'));
    await _show(tester, client, openLink: (_) async => false);
    await tester.tap(find.byKey(const ValueKey('job-apply')));
    await tester.pump();
    expect(find.text('지원 페이지를 열지 못했습니다.'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('job-apply')))
            .onPressed,
        isNotNull);
  });

  testWidgets('sharing copies the actual public URL without auth credentials',
      (tester) async {
    final client = _Client()
      ..load = (id) async => JobDetail.fromJson(
          _json(id, synthetic: false, sourceUrl: 'https://example.com/job/a'));
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await _show(tester, client);
    await tester.tap(find.byTooltip('채용공고 공유하기'));
    await tester.pump();
    expect(copied, 'https://example.com/job/a');
    expect(find.text('공고 링크가 클립보드에 복사되었습니다.'), findsOneWidget);
  });

  testWidgets(
      'comparison reuses the source card and shows counts, not a probability',
      (tester) async {
    final client = _Client()
      ..compare = (id) async => JobComparisonResult(
          job: JobDetail.fromJson(_json(id)),
          comparison: JobComparison.fromJson(comparisonFixture(checks: [
            comparisonCheckFixture(
                kind: 'education', condition: 'any', status: 'not_required'),
            comparisonCheckFixture(
                kind: 'experience', condition: 'experienced'),
            comparisonCheckFixture(
                status: 'confirmed',
                reason: '명칭과 입력한 유효기간을 확인했습니다.',
                evidence: ['my-cert']),
            comparisonCheckFixture(
                kind: 'language_score',
                condition: 'TOEIC 700점 이상',
                required: false,
                status: 'not_confirmed',
                reason: '등록한 점수 650점이 기준보다 낮습니다.',
                evidence: ['my-score']),
          ])));
    await _show(tester, client);
    expect(client.comparisonRequests, ['a']);
    expect(find.text('내 스펙 조건 비교'), findsOneWidget);
    expect(find.text('충족 1개'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('comparison-unconfirmed')),
            matching: find.text('기준 미달 1개')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('comparison-unconfirmed')),
            matching: find.text('확인 불가 1개')),
        findsOneWidget);
    expect(find.text('제한 없음 1개'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('AI'), findsNothing);
    final card = tester.getRect(find.byKey(const ValueKey('job-comparison')));
    final company = tester.getRect(find.byKey(const ValueKey('job-company')));
    expect(card.left, 20);
    expect(card.width, 350);
    expect(card.top - company.bottom, 24);
    expect(
        tester.getSize(find.byKey(const ValueKey('comparison-badge'))).height,
        28);
    expect(
        tester.getSize(find.byKey(const ValueKey('comparison-check-0'))).height,
        40);
    final check = find.byKey(const ValueKey('comparison-check-3'));
    await _scrollTo(tester, check);
    expect(find.text('등록한 점수 650점이 기준보다 낮습니다.'), findsNothing);
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.text('등록한 점수 650점이 기준보다 낮습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pending comparison does not block the posting or application link',
      (tester) async {
    final pending = Completer<JobComparisonResult>();
    final client = _Client();
    client.load = (id) async => JobDetail.fromJson(
        _json(id, synthetic: false, sourceUrl: 'https://example.com/job/a'));
    client.compare = (_) => pending.future;
    await tester.pumpWidget(_app(client));
    await tester.pump();
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('job-apply')))
            .onPressed,
        isNotNull);
    expect(find.byKey(const ValueKey('comparison-confirmed')), findsNothing);
    pending.completeError(const JobApiException(503, 'unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('조건 비교 결과를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'comparison can retry independently and reflects newly saved specs',
      (tester) async {
    final client = _Client()
      ..compare = (_) async => throw const JobApiException(503, 'unavailable');
    await _show(tester, client);
    expect(find.text('조건 비교 결과를 불러오지 못했습니다.'), findsOneWidget);
    client.compare = (id) async => JobComparisonResult(
        job: JobDetail.fromJson(_json(id)),
        comparison: JobComparison.fromJson(comparisonFixture(checks: [
          comparisonCheckFixture(
              status: 'confirmed', evidence: ['updated-spec']),
        ])));
    final retry = find.byKey(const ValueKey('comparison-retry'));
    await _scrollTo(tester, retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(client.requests, ['a']);
    expect(client.comparisonRequests, ['a', 'a']);
    expect(find.text('충족 1개'), findsOneWidget);
    expect(find.text('조건 비교 결과를 불러오지 못했습니다.'), findsNothing);
  });

  testWidgets('unavailable detailed requirements stay explicitly unknown',
      (tester) async {
    final client = _Client()
      ..compare = (id) async => JobComparisonResult(
          job: JobDetail.fromJson(_json(id)..['requirements'] = null),
          comparison: JobComparison.fromJson(
              comparisonFixture(detailedRequirementsAvailable: false)));
    await _show(tester, client);
    expect(find.text('충족 0개'), findsOneWidget);
    expect(find.text('공고의 상세 조건이 제공되지 않았습니다.'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('comparison-unconfirmed')),
            matching: find.text('기준 미달 0개')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('comparison-unconfirmed')),
            matching: find.text('확인 불가 2개')),
        findsOneWidget);
  });

  testWidgets(
      'refresh keeps the last comparison visible and preserves its layout on a slow request',
      (tester) async {
    final client = _Client();
    await _show(tester, client);
    final retry = find.byKey(const ValueKey('comparison-retry'));
    await _scrollTo(tester, retry);
    final height =
        tester.getSize(find.byKey(const ValueKey('job-comparison'))).height;
    final pending = Completer<JobComparisonResult>();
    client.compare = (_) => pending.future;
    await tester.tap(retry);
    await tester.pump();
    expect(find.text('충족 0개'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('job-comparison'))).height,
        height);
    expect(tester.widget<TextButton>(retry).onPressed, isNull);
    pending.completeError(const JobApiException(503, 'unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('충족 0개'), findsOneWidget);
    expect(find.text('조건 비교 결과를 불러오지 못했습니다.'), findsOneWidget);
    expect(tester.widget<TextButton>(retry).onPressed, isNotNull);
  });

  testWidgets(
      'late comparison from a previous job or user cannot replace current data',
      (tester) async {
    final pending = Completer<JobComparisonResult>();
    final client = _Client()
      ..compare = (id) => id == 'a'
          ? pending.future
          : Future.value(JobComparisonResult(
              job: JobDetail.fromJson(_json(id)),
              comparison: JobComparison.fromJson(comparisonFixture())));
    await tester.pumpWidget(_app(client));
    await tester.pump();
    await tester.pumpWidget(_app(client, id: 'b', userId: 'user-b'));
    await tester.pumpAndSettle();
    pending.complete(JobComparisonResult(
        job: JobDetail.fromJson(_json('a')),
        comparison: JobComparison.fromJson(comparisonFixture(checks: [
          comparisonCheckFixture(
              status: 'confirmed',
              reason: '이전 사용자 비공개 근거',
              evidence: ['private-a']),
        ]))));
    await tester.pumpAndSettle();
    expect(find.text('[가상 공고] 백엔드 개발 b'), findsOneWidget);
    expect(find.text('충족 0개'), findsOneWidget);
    expect(find.text('이전 사용자 비공개 근거'), findsNothing);
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsNothing);
  });

  testWidgets('authentication generation invalidates a pending comparison',
      (tester) async {
    final pending = Completer<JobComparisonResult>();
    final client = _Client()..compare = (_) => pending.future;
    final generation = ApiCredentials.generation;
    addTearDown(() => ApiCredentials.generation = generation);
    await tester.pumpWidget(_app(client));
    await tester.pump();
    ApiCredentials.generation++;
    pending.complete(JobComparisonResult(
        job: JobDetail.fromJson(_json('a')),
        comparison: JobComparison.fromJson(comparisonFixture())));
    await tester.pump();
    expect(find.byKey(const ValueKey('comparison-confirmed')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'mismatched comparison identity never displays counts or another posting',
      (tester) async {
    final client = _Client()
      ..compare = (_) async => JobComparisonResult(
          job: JobDetail.fromJson(_json('other')),
          comparison: JobComparison.fromJson(comparisonFixture()));
    await _show(tester, client);
    expect(find.text('조건 비교 결과를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('[가상 공고] 백엔드 개발 a'), findsOneWidget);
    expect(find.text('[가상 공고] 백엔드 개발 other'), findsNothing);
    expect(find.byKey(const ValueKey('comparison-confirmed')), findsNothing);
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('detail fits $width with dark mode and larger text',
        (tester) async {
      final client = _Client()
        ..load = (id) async => JobDetail.fromJson(_json(id)
          ..['companyName'] = '스펙모아 긴 이름의 가상기업 주식회사'
          ..['title'] = '아주 긴 채용공고 제목으로 모든 화면에서 글자 겹침 없이 표시되어야 합니다'
          ..['closesAt'] = null);
      await _show(tester, client, width: width, dark: true, scale: 1.3);
      expect(tester.takeException(), isNull);
      final check = find.byKey(const ValueKey('comparison-check-0'));
      await _scrollTo(tester, check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

class _Tokens implements AuthTokenStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String? refreshToken) async {}
}

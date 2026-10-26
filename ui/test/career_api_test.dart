import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:specmoa_zip_ui/models/career_data.dart';
import 'package:specmoa_zip_ui/models/user_spec.dart';
import 'package:specmoa_zip_ui/services/authenticated_client.dart';
import 'package:specmoa_zip_ui/services/career_api_client.dart';

import 'fixtures/career_fixture.dart';

http.Response _json(Object? value, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(value)), status);

Matcher get _apiError => isA<CareerApiException>();

void main() {
  setUp(() {
    ApiCredentials.accessToken = null;
    ApiCredentials.onRefresh = null;
    ApiCredentials.onUnauthorized = null;
  });
  tearDown(() {
    ApiCredentials.accessToken = null;
    ApiCredentials.onRefresh = null;
    ApiCredentials.onUnauthorized = null;
  });

  test('catalog uses server labels, exact supported codes and immutable lists',
      () {
    final result = CareerOccupationCatalog.fromJson(careerCatalogFixture());
    expect(result.items.map((option) => option.code), DesiredOccupation.values);
    expect(result.items.first.label, '직무 backend');
    expect(() => result.items.clear(), throwsUnsupportedError);
    for (final data in [
      careerCatalogFixture()..['version'] = 'future',
      careerCatalogFixture()..['items'] = [],
      careerCatalogFixture()
        ..['items'] = [
          {'code': 'unknown', 'label': '미지원'}
        ]
    ]) {
      expect(
          () => CareerOccupationCatalog.fromJson(data), throwsFormatException);
    }
    final duplicate = careerCatalogFixture();
    (duplicate['items'] as List)[1] = (duplicate['items'] as List).first;
    expect(() => CareerOccupationCatalog.fromJson(duplicate),
        throwsFormatException);
  });

  test(
      'preferences preserve unset, saved order, explicit clear and needs-review',
      () {
    expect(CareerPreferences.fromJson(careerPreferencesFixture()).status,
        CareerPreferenceStatus.unset);
    final result = CareerPreferences.fromJson(
        careerPreferencesFixture(codes: ['mobile', 'backend']));
    expect(result.desiredOccupations,
        [DesiredOccupation.mobile, DesiredOccupation.backend]);
    expect(result.updatedAt, DateTime.utc(2026, 10, 26));
    expect(() => result.desiredOccupations.clear(), throwsUnsupportedError);
    expect(
        CareerPreferences.fromJson(
                careerPreferencesFixture(updatedAt: careerTime))
            .status,
        CareerPreferenceStatus.unset);
    final review = CareerPreferences.fromJson(
        careerPreferencesFixture(status: 'needs_review'));
    expect(review.status, CareerPreferenceStatus.needsReview);
    expect(review.desiredOccupations, isEmpty);
  });

  test(
      'invalid preference versions, statuses, codes and timestamps fail closed',
      () {
    for (final data in [
      careerPreferencesFixture()..['version'] = 'future',
      careerPreferencesFixture()..['status'] = 'unknown',
      careerPreferencesFixture(codes: ['unknown']),
      careerPreferencesFixture(codes: ['backend', 'backend']),
      careerPreferencesFixture(codes: ['backend'])..['updatedAt'] = null,
      careerPreferencesFixture(codes: ['backend'])..['status'] = 'unset',
      careerPreferencesFixture(status: 'set'),
      careerPreferencesFixture(status: 'needs_review', updatedAt: careerTime),
      careerPreferencesFixture()..['desiredOccupations'] = 'backend',
      careerPreferencesFixture()..['updatedAt'] = '2026-02-30T00:00:00.000Z',
      careerPreferencesFixture()..['updatedAt'] = '2026-10-26',
    ]) {
      expect(() => CareerPreferences.fromJson(data), throwsFormatException);
    }
  });

  test(
      'context preserves provenance, STAR, zero/false and deeply immutable facts',
      () {
    final raw = careerContextFixture();
    final result = CareerAnalysisContext.fromJson(raw);
    expect(result.generatedAt.isUtc, isTrue);
    expect(result.totalSpecs, 1);
    expect(result.byType.length, 8);
    expect(result.specs.single.specId, 'spec-project');
    expect(result.specs.single.type, SpecType.project);
    expect(result.specs.single.verification, 'unverified');
    expect(result.specs.single.facts[1].path, 'data.action');
    expect(result.specs.single.facts[1].value, 'API와 테스트 구현');
    expect(result.specs.single.facts.last.value, false);
    expect(result.externalAiTransmissionAllowed, isFalse);
    expect(result.userProvidedTextMayContainPersonalData, isTrue);
    expect(() => result.specs.clear(), throwsUnsupportedError);
    expect(() => result.byType.clear(), throwsUnsupportedError);
    expect(() => result.excludedFields.clear(), throwsUnsupportedError);
    expect(() => result.specs.single.facts.clear(), throwsUnsupportedError);
    expect(() => (result.specs.single.facts[2].value as List).clear(),
        throwsUnsupportedError);
    final sourceFacts = ((raw['specs'] as List).single as Map)['facts'] as List;
    ((sourceFacts[2] as Map)['value'] as List).add('사후 변경');
    expect(result.specs.single.facts[2].value, ['NestJS', 'PostgreSQL']);
    final language = CareerSpecAnalysis.fromJson(careerSpecFixture(
        type: 'language_score',
        facts: [
          careerFactFixture('exam', 'TOEIC'),
          careerFactFixture('score', 0)
        ]));
    expect(language.facts.last.value, 0);
  });

  test(
      'all eight types and empty, partial and unsupported records are retained',
      () {
    final specs = SpecType.values
        .map((type) => careerSpecFixture(
                id: type.apiValue,
                type: type.apiValue,
                status: 'empty',
                facts: [],
                missingFields: [
                  type == SpecType.languageScore
                      ? 'exam'
                      : type == SpecType.educationRecord
                          ? 'degree'
                          : type == SpecType.workExperience
                              ? 'company'
                              : 'name'
                ],
                missingContext: [
                  [
                    type == SpecType.languageScore
                        ? 'exam'
                        : type == SpecType.educationRecord
                            ? 'degree'
                            : type == SpecType.workExperience
                                ? 'company'
                                : 'name'
                  ]
                ]))
        .toList();
    final empty =
        CareerAnalysisContext.fromJson(careerContextFixture(records: specs));
    expect(empty.specs.map((spec) => spec.type), SpecType.values);
    expect(empty.byType.every((group) => group.empty == 1), isTrue);
    final partial = CareerSpecAnalysis.fromJson(
        careerSpecFixture(status: 'partial', facts: [], missingFields: [
      'name'
    ], missingContext: [
      ['name']
    ], issues: [
      {'field': null, 'code': 'invalid_record'}
    ]));
    expect(partial.status, CareerSpecStatus.partial);
    expect(() => partial.missingContext.single.clear(), throwsUnsupportedError);
    final unknown = careerSpecFixture(
        id: 'future-id',
        type: 'future',
        status: 'unsupported',
        facts: [],
        issues: [
          {'field': null, 'code': 'unsupported_type'}
        ]);
    final result = CareerAnalysisContext.fromJson(
        careerContextFixture(records: [unknown]));
    expect(result.unsupportedSpecs, 1);
    expect(result.specs.single.type, isNull);
    expect(result.specs.single.rawType, 'future');
  });

  test(
      'malformed facts, private fields, duplicate source paths and fake verification are rejected',
      () {
    for (final spec in [
      careerSpecFixture()..['verification'] = 'verified',
      careerSpecFixture()..['updatedAt'] = 'bad',
      careerSpecFixture()..['status'] = 'recommended',
      careerSpecFixture()..['type'] = 'unknown',
      careerSpecFixture(
          facts: [careerFactFixture('certificateNumber', 'SECRET')]),
      careerSpecFixture(facts: [careerFactFixture('name', 10)]),
      careerSpecFixture(facts: [careerFactFixture('ongoing', 'true')]),
      careerSpecFixture(facts: [
        careerFactFixture('skills', [1])
      ]),
      careerSpecFixture(facts: [
        careerFactFixture('skills', ['NestJS', 'NestJS'])
      ]),
      careerSpecFixture(
          facts: [careerFactFixture('name', '명칭')..['path'] = 'other.name']),
      careerSpecFixture(facts: [
        careerFactFixture('name', '명칭'),
        careerFactFixture('name', '중복')
      ]),
      careerSpecFixture(missingFields: ['name']),
      careerSpecFixture(missingFields: ['certificateNumber']),
      careerSpecFixture(issues: [
        {'field': 'name', 'code': 'unknown'}
      ]),
      careerSpecFixture(status: 'empty'),
      careerSpecFixture(missingContext: [
        ['name']
      ]),
    ]) {
      expect(() => CareerSpecAnalysis.fromJson(spec), throwsFormatException);
    }
  });

  test(
      'context counts, complete type groups, identity uniqueness and data policy must agree',
      () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (data) => data['version'] = 'future',
      (data) => data['generatedAt'] = '2026-10-26',
      (data) => (data['summary'] as Map)['totalSpecs'] = 2,
      (data) => (data['summary'] as Map)['totalSpecs'] = -1,
      (data) => (data['summary'] as Map)['totalSpecs'] = 1.5,
      (data) => (data['summary'] as Map)['unsupportedSpecs'] = 1,
      (data) => ((data['summary'] as Map)['byType'] as List).removeLast(),
      (data) => (((data['summary'] as Map)['byType'] as List).first
          as Map)['empty'] = 3,
      (data) =>
          (data['privacy'] as Map)['externalAiTransmissionAllowed'] = true,
      (data) => (data['privacy']
          as Map)['userProvidedTextMayContainPersonalData'] = false,
      (data) => (data['privacy'] as Map)['mode'] = 'external',
      (data) => (data['privacy'] as Map)['excludedFields'] = [],
    ]) {
      final data = careerContextFixture();
      mutate(data);
      expect(() => CareerAnalysisContext.fromJson(data), throwsFormatException);
    }
    expect(
        () => CareerAnalysisContext.fromJson(careerContextFixture(
            records: [careerSpecFixture(), careerSpecFixture()])),
        throwsFormatException);
  });

  test(
      'API uses only career routes, existing bearer auth, no user ID and no AI endpoint',
      () async {
    ApiCredentials.accessToken = 'mock-token';
    final requests = <http.Request>[];
    final transport = AuthenticatedClient(inner: MockClient((request) async {
      requests.add(request);
      expect(request.headers['Authorization'], 'Bearer mock-token');
      expect(request.headers.containsKey('x-user-id'), isFalse);
      expect(request.url.queryParameters, isEmpty);
      return _json(switch (request.url.path) {
        '/career/occupations' => careerCatalogFixture(),
        '/career/preferences' when request.method == 'PATCH' =>
          careerPreferencesFixture(
              codes: ((jsonDecode(request.body) as Map)['desiredOccupations']
                      as List)
                  .cast<String>()),
        '/career/preferences' => careerPreferencesFixture(),
        '/career/analysis-context' => careerContextFixture(),
        _ => throw StateError('Unexpected endpoint'),
      });
    }));
    addTearDown(transport.close);
    final client = CareerApiClient(client: transport);
    await client.fetchOccupations();
    await client.fetchPreferences();
    await client.fetchAnalysisContext();
    final saved = await client.updatePreferences([DesiredOccupation.backend]);
    expect(saved.desiredOccupations, [DesiredOccupation.backend]);
    expect(jsonDecode(requests.last.body), {
      'desiredOccupations': ['backend']
    });
    expect((await client.updatePreferences([])).status,
        CareerPreferenceStatus.unset);
    expect(jsonDecode(requests.last.body), {'desiredOccupations': []});
    expect(
        () => client.updatePreferences(
            [DesiredOccupation.backend, DesiredOccupation.backend]),
        throwsArgumentError);
    expect(requests.length, 5);
  });

  test(
      'saving must echo the exact selection rather than silently accepting another result',
      () async {
    for (final response in [
      careerPreferencesFixture(codes: ['data']),
      careerPreferencesFixture(),
      careerPreferencesFixture(status: 'needs_review')
    ]) {
      final client =
          CareerApiClient(client: MockClient((_) async => _json(response)));
      await expectLater(client.updatePreferences([DesiredOccupation.backend]),
          throwsA(_apiError));
    }
  });

  test(
      'every context request is fresh; changing or deleting specs is not hidden by a cache',
      () async {
    var calls = 0;
    final client = CareerApiClient(
        client: MockClient((_) async => _json(careerContextFixture(
            records: calls++ == 0 ? [careerSpecFixture()] : []))));
    expect((await client.fetchAnalysisContext()).totalSpecs, 1);
    expect((await client.fetchAnalysisContext()).totalSpecs, 0);
    expect(calls, 2);
  });

  test('expired access token refreshes once and retries the same PATCH body',
      () async {
    ApiCredentials.accessToken = 'old-token';
    var refreshes = 0, requests = 0;
    ApiCredentials.onRefresh = () async {
      refreshes++;
      ApiCredentials.accessToken = 'new-token';
      return true;
    };
    final transport = AuthenticatedClient(inner: MockClient((request) async {
      requests++;
      expect(request.method, 'PATCH');
      expect(jsonDecode(request.body), {
        'desiredOccupations': ['data']
      });
      if (requests == 1) return _json({'message': 'expired'}, 401);
      expect(request.headers['Authorization'], 'Bearer new-token');
      return _json(careerPreferencesFixture(codes: ['data']));
    }));
    addTearDown(transport.close);
    expect(
        (await CareerApiClient(client: transport)
                .updatePreferences([DesiredOccupation.data]))
            .desiredOccupations,
        [DesiredOccupation.data]);
    expect(refreshes, 1);
    expect(requests, 2);
  });

  test('an old account response cannot become the next account context',
      () async {
    ApiCredentials.accessToken = 'user-a-token';
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final transport = AuthenticatedClient(inner: MockClient((request) {
      started.complete();
      return pending.future;
    }));
    addTearDown(transport.close);
    final future = CareerApiClient(client: transport).fetchAnalysisContext();
    final check = expectLater(future, throwsA(_apiError));
    await started.future;
    ApiCredentials.generation++;
    ApiCredentials.accessToken = 'user-b-token';
    pending.complete(_json(careerContextFixture()));
    await check;
  });

  test(
      'errors are actionable and never expose raw upstream text or become empty data',
      () async {
    for (final status in [400, 401, 404, 429, 500, 502, 503]) {
      final client = CareerApiClient(
          client: MockClient(
              (_) async => http.Response('SECRET-UPSTREAM', status)));
      try {
        await client.fetchPreferences();
        fail('Must reject HTTP errors');
      } on CareerApiException catch (error) {
        expect(error.statusCode, status);
        expect(error.message, isNot(contains('SECRET')));
        expect(error.toString(), error.message);
      }
    }
    for (final body in [
      '[]',
      'not-json SECRET',
      jsonEncode({'version': 'future'})
    ]) {
      final client = CareerApiClient(
          client: MockClient((_) async => http.Response(body, 200)));
      await expectLater(client.fetchAnalysisContext(), throwsA(_apiError));
    }
    final timeout = CareerApiClient(
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) => Completer<http.Response>().future));
    await expectLater(timeout.fetchPreferences(), throwsA(_apiError));
    final offline = CareerApiClient(
        client: MockClient(
            (_) async => throw http.ClientException('SECRET-NETWORK')));
    await expectLater(offline.fetchPreferences(), throwsA(_apiError));
  });
}

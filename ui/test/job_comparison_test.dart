import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:specmoa_zip_ui/models/job_comparison.dart';
import 'package:specmoa_zip_ui/services/job_api_client.dart';

import 'fixtures/job_comparison_fixture.dart';

Map<String, dynamic> _response({String id = 'job-a'}) => {
      'job': {
        'id': id,
        'companyName': '가상기업',
        'title': '시연용 공고',
        'occupation': 'backend',
        'region': '서울',
        'employmentType': 'full_time',
        'experienceLevel': 'entry',
        'keywords': <String>[],
        'closesAt': null,
        'status': 'open',
        'synthetic': true,
        'notice': '시연용 공고입니다.',
        'canApply': false,
      },
      'comparison': comparisonFixture(),
    };

void main() {
  test('comparison API encodes the exact job ID and never accepts a user query',
      () async {
    const id = 'job / 한글?';
    final client = JobApiClient(client: MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.pathSegments, ['jobs', id, 'match']);
      expect(request.url.queryParameters, isEmpty);
      return http.Response.bytes(
          utf8.encode(jsonEncode(_response(id: id))), 200);
    }));
    final result = await client.fetchComparison(id);
    expect(result.job.job.id, id);
    expect(result.job.synthetic, isTrue);
    expect(result.comparison.method, 'rules-v2');
    expect(result.comparison.unknown, 2);
    expect(result.comparison.confirmed, 0);
    expect(result.comparison.comparedAt, DateTime.utc(2026, 10, 25));
    expect(result.comparison.checks.first.reason, '등록된 학력 정보가 없습니다.');
  });

  test(
      'comparison preserves every status, requiredness, reasons and non-positive evidence',
      () {
    final checks = [
      comparisonCheckFixture(status: 'confirmed', evidence: ['confirmed-id']),
      comparisonCheckFixture(
          status: 'not_confirmed',
          reasonCode: 'below_minimum',
          evidence: ['low-id']),
      comparisonCheckFixture(
          status: 'unknown', required: false, evidence: ['incomplete-id']),
      comparisonCheckFixture(status: 'not_required', required: false),
    ];
    final result = JobComparison.fromJson(comparisonFixture(checks: checks));
    expect(result.checks.map((c) => c.status), JobMatchStatus.values);
    expect(result.required.total, 2);
    expect(result.preferred.total, 2);
    expect(result.notConfirmed, 1);
    expect(result.notRequired, 1);
    expect(result.checks[1].evidenceSpecIds, ['low-id']);
    expect(result.checks[2].evidenceSpecIds, ['incomplete-id']);
    expect(() => result.checks.clear(), throwsUnsupportedError);
    expect(() => result.checks.first.evidenceSpecIds.clear(),
        throwsUnsupportedError);
  });

  test('missing detailed conditions are not converted into a failed condition',
      () {
    final result = JobComparison.fromJson(
        comparisonFixture(detailedRequirementsAvailable: false));
    expect(result.detailedRequirementsAvailable, isFalse);
    expect(result.confirmed, 0);
    expect(result.notConfirmed, 0);
    expect(result.unknown, 2);
  });

  test('unknown status is rejected rather than guessed as success or failure',
      () {
    final data = comparisonCheckFixture()..['status'] = 'eligible';
    expect(() => JobMatchCheck.fromJson(data), throwsFormatException);
  });

  test('malformed checks cannot become anonymous or unsupported evidence', () {
    for (final invalid in [
      comparisonCheckFixture()..remove('reason'),
      comparisonCheckFixture()..['reason'] = ' ',
      comparisonCheckFixture()..['required'] = 'true',
      comparisonCheckFixture()..['evidenceSpecIds'] = [123],
      comparisonCheckFixture()..['evidenceSpecIds'] = [''],
    ]) {
      expect(() => JobMatchCheck.fromJson(invalid), throwsFormatException);
    }
  });

  test('negative, fractional or missing status totals are rejected', () {
    for (final count in [-1, 0.5, null, '1']) {
      final data = comparisonFixture();
      data['required'] = Map<String, dynamic>.from(data['required'] as Map)
        ..['unknown'] = count;
      expect(() => JobComparison.fromJson(data), throwsFormatException);
    }
  });

  test(
      'summary totals must describe both the actual checks and their requiredness',
      () {
    final wrongCount = comparisonFixture();
    (wrongCount['required'] as Map)['confirmed'] = 1;
    expect(() => JobComparison.fromJson(wrongCount), throwsFormatException);
    final wrongGroup = comparisonFixture();
    (wrongGroup['checks'] as List).first['required'] = false;
    expect(() => JobComparison.fromJson(wrongGroup), throwsFormatException);
  });

  test(
      'old protocol, invalid time and missing metadata are not treated as empty results',
      () {
    for (final invalid in [
      comparisonFixture()..['method'] = 'rules-v1',
      comparisonFixture()..['comparedAt'] = 'not-a-date',
      comparisonFixture()..['comparedAt'] = '2026-10-25',
      comparisonFixture()..remove('detailedRequirementsAvailable'),
      comparisonFixture()..remove('notice'),
    ]) {
      expect(() => JobComparison.fromJson(invalid), throwsFormatException);
    }
  });

  test(
      'API rejects an identity mismatch, missing comparison and non-object JSON',
      () async {
    for (final body in [
      _response(id: 'another-job'),
      _response()..remove('comparison'),
      <dynamic>[],
    ]) {
      final client = JobApiClient(
          client: MockClient((_) async =>
              http.Response.bytes(utf8.encode(jsonEncode(body)), 200)));
      await expectLater(client.fetchComparison('job-a'), throwsFormatException);
    }
  });

  test(
      'authentication and HTTP errors remain errors, not zero matched conditions',
      () async {
    for (final status in [401, 404, 503]) {
      final client = JobApiClient(
          client: MockClient((_) async => http.Response('{}', status)));
      await expectLater(
          client.fetchComparison('job-a'),
          throwsA(isA<JobApiException>()
              .having((e) => e.statusCode, 'status', status)));
    }
  });
}

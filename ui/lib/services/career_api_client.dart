import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/career_data.dart';
import 'authenticated_client.dart';

class CareerApiClient {
  const CareerApiClient(
      {http.Client? client, Duration timeout = AppConfig.receiveTimeout})
      : _client = client,
        _timeout = timeout;

  final http.Client? _client;
  final Duration _timeout;

  Future<CareerOccupationCatalog> fetchOccupations() =>
      _request('GET', '/career/occupations', CareerOccupationCatalog.fromJson);

  Future<CareerPreferences> fetchPreferences() =>
      _request('GET', '/career/preferences', CareerPreferences.fromJson);

  Future<CareerAnalysisContext> fetchAnalysisContext() => _request(
      'GET', '/career/analysis-context', CareerAnalysisContext.fromJson);

  Future<CareerPreferences> updatePreferences(
      List<DesiredOccupation> desiredOccupations) {
    if (desiredOccupations.toSet().length != desiredOccupations.length) {
      throw ArgumentError('Desired occupations must be unique');
    }
    final expected = List<DesiredOccupation>.of(desiredOccupations);
    return _request('PATCH', '/career/preferences', CareerPreferences.fromJson,
            {'desiredOccupations': expected.map((code) => code.name).toList()})
        .then((saved) {
      if (saved.status == CareerPreferenceStatus.needsReview ||
          saved.desiredOccupations.length != expected.length ||
          expected.asMap().entries.any(
              (entry) => saved.desiredOccupations[entry.key] != entry.value)) {
        throw const CareerApiException(200, '직무 저장 결과를 확인할 수 없습니다. 다시 조회해주세요.');
      }
      return saved;
    });
  }

  Future<T> _request<T>(
      String method, String path, T Function(Map<String, dynamic>) parse,
      [Map<String, dynamic>? body]) async {
    final client = _client ?? AuthenticatedClient();
    try {
      final request =
          http.Request(method, Uri.parse('${AppConfig.apiBaseUrl}$path'));
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await (() async =>
              http.Response.fromStream(await client.send(request)))()
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw CareerApiException(
            response.statusCode,
            switch (response.statusCode) {
              400 => '선택한 직무 정보를 확인해주세요.',
              401 => '로그인이 만료되었습니다. 다시 로그인해주세요.',
              404 => '서버가 아직 이 기능을 지원하지 않습니다.',
              429 => '요청이 많습니다. 잠시 후 다시 시도해주세요.',
              _ => '스펙 분석 정보를 처리하지 못했습니다. 잠시 후 다시 시도해주세요.',
            });
      }
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map<String, dynamic>) throw const FormatException();
        return parse(decoded);
      } on FormatException {
        throw const CareerApiException(
            200, '서버 응답 형식이 맞지 않습니다. 앱과 서버 버전을 확인해주세요.');
      }
    } on TimeoutException {
      throw const CareerApiException(null, '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.');
    } on http.ClientException {
      throw const CareerApiException(
          null, '연결이 변경되었거나 서버에 연결할 수 없습니다. 다시 시도해주세요.');
    } finally {
      if (_client == null) client.close();
    }
  }
}

class CareerApiException implements Exception {
  const CareerApiException(this.statusCode, this.message);
  final int? statusCode;
  final String message;
  @override
  String toString() => message;
}

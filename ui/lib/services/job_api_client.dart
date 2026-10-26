import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/job_comparison.dart';
import '../models/job_data.dart';
import '../models/ai_demo_data.dart';
import 'authenticated_client.dart';

class JobApiClient {
  const JobApiClient({http.Client? client}) : _client = client;
  final http.Client? _client;

  Future<AiDemoAvailability> fetchAiDemoStatus() async =>
      AiDemoAvailability.fromJson(await _get('/ai/demo/status', const {}));

  Future<AiDemoResult> generateAiDemo() async {
    final client = _client ?? AuthenticatedClient();
    try {
      final response = await client
          .post(Uri.parse('${AppConfig.apiBaseUrl}/ai/demo/recommendations'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'profile': 'backend'}))
          .timeout(AppConfig.receiveTimeout);
      if (response.statusCode != 200) {
        throw AiDemoApiException(
            response.statusCode,
            switch (response.statusCode) {
              401 => '로그인이 만료되었습니다. 다시 로그인해주세요.',
              429 => 'AI 호출 한도에 도달했습니다. 나중에 다시 시도해주세요.',
              503 => 'AI 서버가 현재 요청을 처리할 수 없습니다. 잠시 후 다시 시도해주세요.',
              _ => 'AI 추천을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
            });
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid AI response');
      }
      return AiDemoResult.fromJson(decoded);
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<JobDetail> fetchDemoDetail(String externalId) async {
    final data =
        await _get('/jobs/demo/${Uri.encodeComponent(externalId)}', const {});
    if (data['externalId'] != externalId ||
        data['source'] != 'demo' ||
        data['synthetic'] != true) {
      throw const FormatException('Mismatched demo job');
    }
    return JobDetail.fromJson(data);
  }

  Future<JobDetail> fetchDetail(String id) async {
    final detail = JobDetail.fromJson(
        await _get('/jobs/${Uri.encodeComponent(id)}', const {}));
    if (detail.job.id != id) throw const FormatException('Mismatched job ID');
    return detail;
  }

  Future<JobComparisonResult> fetchComparison(String id) async {
    final result = JobComparisonResult.fromJson(
        await _get('/jobs/${Uri.encodeComponent(id)}/match', const {}));
    if (result.job.job.id != id) {
      throw const FormatException('Mismatched job ID');
    }
    return result;
  }

  Future<JobPage> fetchJobs({
    String query = '',
    String? occupation,
    String sort = 'latest',
    int offset = 0,
    int limit = 20,
  }) async =>
      JobPage.fromJson(await _get('/jobs', {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (occupation != null) 'occupation': occupation,
        'sort': sort,
        'status': 'open',
        'limit': '$limit',
        'offset': '$offset',
      }));

  Future<List<JobOccupation>> fetchOccupations() async {
    final data = await _get('/jobs/facets', {'status': 'open'});
    return (data['occupations'] as List)
        .map((item) => JobOccupation(
            item['value'] as String, (item['count'] as num).toInt()))
        .toList();
  }

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String> query) async {
    final client = _client ?? AuthenticatedClient();
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$path')
          .replace(queryParameters: query);
      final response = await client.get(uri).timeout(AppConfig.receiveTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw JobApiException(
            response.statusCode,
            response.statusCode == 404
                ? '채용공고를 찾을 수 없습니다.'
                : '채용공고를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } finally {
      if (_client == null) client.close();
    }
  }
}

class JobApiException implements Exception {
  const JobApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

class AiDemoApiException implements Exception {
  const AiDemoApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
}

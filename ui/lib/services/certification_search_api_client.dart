import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/certification_search_data.dart';

class CertificationSearchApiClient {
  const CertificationSearchApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<CertificationSearchTag>> fetchTags({
    int limit = 12,
    String qualificationType = 'all',
    String query = '',
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      if (qualificationType != 'all') 'qualificationType': qualificationType,
      if (query.trim().isNotEmpty) 'q': query.trim(),
    };
    final json = await _get(
      Uri.parse('${AppConfig.apiBaseUrl}/certifications/tags')
          .replace(queryParameters: params),
    );

    return json.map(CertificationSearchTag.fromJson).toList();
  }

  Future<List<CertificationSearchResult>> search({
    String query = '',
    String? tagId,
    String sort = 'popular',
    String qualificationType = 'all',
    int limit = 8,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'sort': sort,
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (tagId != null && tagId.isNotEmpty) 'tagId': tagId,
      if (qualificationType != 'all') 'qualificationType': qualificationType,
    };
    final json = await _get(
      Uri.parse('${AppConfig.apiBaseUrl}/certifications/search')
          .replace(queryParameters: params),
    );

    return json.map(CertificationSearchResult.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _get(Uri uri) async {
    final client = _client ?? http.Client();

    try {
      final response = await client.get(uri).timeout(AppConfig.receiveTimeout);
      final decoded = response.bodyBytes.isEmpty
          ? const []
          : jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Search API failed with ${response.statusCode}');
      }

      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

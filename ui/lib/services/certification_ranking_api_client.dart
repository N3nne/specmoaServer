import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/certification_ranking_data.dart';

class CertificationRankingApiClient {
  const CertificationRankingApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<CertificationRankingItem>> fetchRankings({
    required String metric,
    String qualificationType = 'all',
    String? tagId,
    int limit = 30,
  }) async {
    final params = <String, String>{
      'metric': metric,
      'limit': '$limit',
      if (qualificationType != 'all') 'qualificationType': qualificationType,
      if (tagId != null && tagId.isNotEmpty) 'tagId': tagId,
    };
    final client = _client ?? http.Client();

    try {
      final response = await client
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/certifications/rankings')
                .replace(queryParameters: params),
          )
          .timeout(AppConfig.receiveTimeout);
      final decoded = response.bodyBytes.isEmpty
          ? const []
          : jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Ranking API failed with ${response.statusCode}');
      }

      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => CertificationRankingItem.fromJson(
                item.cast<String, dynamic>(),
              ))
          .toList();
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

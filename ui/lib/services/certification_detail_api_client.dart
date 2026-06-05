import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/certification_detail_data.dart';

class CertificationDetailApiClient {
  const CertificationDetailApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<CertificationDetailData> fetchDetailPage(String certificationId) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .get(
            Uri.parse(
              '${AppConfig.apiBaseUrl}/certifications/$certificationId/detail-page',
            ),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Detail API failed with ${response.statusCode}');
      }

      return CertificationDetailData.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

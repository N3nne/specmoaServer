import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/success_story_list_data.dart';

class SuccessStoryApiClient {
  const SuccessStoryApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<SuccessStoryPage> fetchStories({
    String query = '',
    String? certificationId,
    String sort = 'popular',
    int limit = 30,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'sort': sort,
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (certificationId != null && certificationId.isNotEmpty)
        'certificationId': certificationId,
    };
    final client = _client ?? http.Client();

    try {
      final response = await client
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/community/success-stories')
                .replace(queryParameters: params),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Success story API failed with ${response.statusCode}');
      }

      return SuccessStoryPage.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<SuccessStoryItem> createStory({
    required String userId,
    required String certificationId,
    required String title,
    required String subtitle,
    required String body,
    required int studyPeriodDays,
    required String studyMethod,
    required String score,
    required String examAttempt,
  }) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/community/success-stories'),
            headers: {
              'content-type': 'application/json',
              if (userId.isNotEmpty) 'x-user-id': userId,
            },
            body: jsonEncode({
              'certificationId': certificationId,
              'title': title,
              'subtitle': subtitle,
              'body': body,
              'studyPeriodDays': studyPeriodDays,
              'studyMethod': studyMethod,
              'score': score,
              'examAttempt': examAttempt,
            }),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final message = decoded is Map
            ? decoded['message']?.toString()
            : 'Success story create failed with ${response.statusCode}';
        throw Exception(message);
      }

      return SuccessStoryItem.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<SuccessStoryItem> recordView(String id) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(
            Uri.parse(
                '${AppConfig.apiBaseUrl}/community/success-stories/$id/view'),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Success story view API failed with ${response.statusCode}',
        );
      }

      return SuccessStoryItem.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

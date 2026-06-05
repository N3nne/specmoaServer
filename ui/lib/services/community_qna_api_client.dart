import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/community_qna_data.dart';

class CommunityQnaApiClient {
  const CommunityQnaApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<CommunityQnaPage> fetchQuestions({
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
            Uri.parse('${AppConfig.apiBaseUrl}/community/qna')
                .replace(queryParameters: params),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('QnA API failed with ${response.statusCode}');
      }

      return CommunityQnaPage.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<CommunityQnaItem> createQuestion({
    required String userId,
    required String certificationId,
    required String title,
    required String body,
    required List<String> tags,
    required bool isAnonymous,
  }) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/community/qna'),
            headers: {
              'Content-Type': 'application/json',
              if (userId.isNotEmpty) 'x-user-id': userId,
            },
            body: jsonEncode({
              'certificationId': certificationId,
              'title': title,
              'body': body,
              'tags': tags,
              'isAnonymous': isAnonymous,
            }),
          )
          .timeout(AppConfig.receiveTimeout);

      final decoded = response.bodyBytes.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded['message'];
        if (message is List && message.isNotEmpty) {
          throw Exception(message.first);
        }
        throw Exception(message as String? ?? '질문을 등록하지 못했습니다.');
      }

      return CommunityQnaItem.fromJson(decoded);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<CommunityQnaItem> recordView(String id) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(Uri.parse('${AppConfig.apiBaseUrl}/community/qna/$id/view'))
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('QnA view API failed with ${response.statusCode}');
      }

      return CommunityQnaItem.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<CommunityQnaAnswerPage> fetchAnswers(String postId) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .get(Uri.parse(
              '${AppConfig.apiBaseUrl}/community/qna/$postId/answers'))
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('QnA answers API failed with ${response.statusCode}');
      }

      return CommunityQnaAnswerPage.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<CommunityQnaAnswer> createAnswer({
    required String postId,
    required String userId,
    required String body,
  }) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/community/qna/$postId/answers'),
            headers: {
              'Content-Type': 'application/json',
              if (userId.isNotEmpty) 'x-user-id': userId,
            },
            body: jsonEncode({'body': body}),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('QnA answer create failed with ${response.statusCode}');
      }

      return CommunityQnaAnswer.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<CommunityQnaAnswer> acceptAnswer({
    required String postId,
    required String answerId,
    required String userId,
  }) async {
    final client = _client ?? http.Client();

    try {
      final response = await client.post(
        Uri.parse(
          '${AppConfig.apiBaseUrl}/community/qna/$postId/answers/$answerId/accept',
        ),
        headers: {
          if (userId.isNotEmpty) 'x-user-id': userId,
        },
      ).timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('QnA answer accept failed with ${response.statusCode}');
      }

      return CommunityQnaAnswer.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

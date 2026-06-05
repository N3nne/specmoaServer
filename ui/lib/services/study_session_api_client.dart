import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/study_session_data.dart';

class StudySessionApiClient {
  const StudySessionApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<StudySessionSummary> fetchSummary({String? userId}) async {
    final client = _client ?? http.Client();

    try {
      final response = await client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/study-sessions/summary'),
        headers: {
          if (userId != null && userId.isNotEmpty) 'x-user-id': userId,
        },
      ).timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Study session summary API failed with ${response.statusCode}',
        );
      }

      return StudySessionSummary.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<void> create({
    required String userId,
    required String certificationId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
  }) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/study-sessions'),
            headers: {
              'Content-Type': 'application/json',
              if (userId.isNotEmpty) 'x-user-id': userId,
            },
            body: jsonEncode({
              'certificationId': certificationId,
              'startedAt': startedAt.toIso8601String(),
              'endedAt': endedAt.toIso8601String(),
              'durationSeconds': durationSeconds,
            }),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = response.bodyBytes.isEmpty
            ? null
            : jsonDecode(utf8.decode(response.bodyBytes));
        final message = decoded is Map ? decoded['message']?.toString() : null;
        throw Exception(
          message ??
              'Study session create API failed with ${response.statusCode}',
        );
      }
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

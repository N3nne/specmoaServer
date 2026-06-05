import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/user_certification_data.dart';

class UserCertificationApiClient {
  const UserCertificationApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<UserCertificationPage> fetchMine({String? userId}) async {
    final client = _client ?? http.Client();

    try {
      final response = await client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/certifications/user'),
        headers: {
          if (userId != null && userId.isNotEmpty) 'x-user-id': userId,
        },
      ).timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'User certifications API failed with ${response.statusCode}',
        );
      }

      return UserCertificationPage.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<void> register({
    required String userId,
    required String certificationId,
    required String status,
    String? targetExamDate,
    String? certifiedOn,
    String? certificateNumber,
    String? preparationCategory,
    String? notes,
  }) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/certifications/user'),
            headers: {
              'Content-Type': 'application/json',
              if (userId.isNotEmpty) 'x-user-id': userId,
            },
            body: jsonEncode({
              'certificationId': certificationId,
              'status': status,
              if (targetExamDate != null) 'targetExamDate': targetExamDate,
              if (certifiedOn != null) 'certifiedOn': certifiedOn,
              if (certificateNumber != null)
                'certificateNumber': certificateNumber,
              if (preparationCategory != null)
                'preparationCategory': preparationCategory,
              if (notes != null) 'notes': notes,
            }),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'User certification register API failed with ${response.statusCode}',
        );
      }
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<void> remove({
    required String userId,
    required String userCertificationId,
  }) async {
    final client = _client ?? http.Client();

    try {
      final response = await client.post(
        Uri.parse(
          '${AppConfig.apiBaseUrl}/certifications/user/$userCertificationId/delete',
        ),
        headers: {
          if (userId.isNotEmpty) 'x-user-id': userId,
        },
      ).timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = response.bodyBytes.isEmpty
            ? null
            : jsonDecode(utf8.decode(response.bodyBytes));
        final message = decoded is Map ? decoded['message']?.toString() : null;
        throw Exception(
          message ??
              'User certification delete API failed with ${response.statusCode}',
        );
      }
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

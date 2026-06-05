import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/auth_user.dart';

class AuthApiClient {
  const AuthApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    return _sendAuthRequest(
      path: '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<AuthUser> register({
    required String email,
    required String displayName,
    required String password,
  }) async {
    return _sendAuthRequest(
      path: '/auth/register',
      body: {
        'email': email,
        'displayName': displayName,
        'password': password,
      },
    );
  }

  Future<String> requestPasswordReset({required String email}) async {
    final json = await _postJson(
      path: '/auth/password-reset',
      body: {'email': email},
    );

    return json['message'] as String? ?? '비밀번호 재설정 요청을 접수했습니다.';
  }

  Future<AuthUser> _sendAuthRequest({
    required String path,
    required Map<String, Object?> body,
  }) async {
    final json = await _postJson(path: path, body: body);
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? {};
    return AuthUser.fromJson(user);
  }

  Future<Map<String, dynamic>> _postJson({
    required String path,
    required Map<String, Object?> body,
  }) async {
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
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
        throw Exception(message as String? ?? '요청을 처리하지 못했습니다.');
      }

      return decoded;
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/auth_user.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class AuthApiClient {
  const AuthApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<AuthUser> refresh(String refreshToken) => _sendAuthRequest(
        path: '/auth/refresh',
        body: {'refreshToken': refreshToken},
      );

  Future<void> logout(String refreshToken) async {
    await _postJson(
      path: '/auth/logout',
      body: {'refreshToken': refreshToken},
    );
  }

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
    final token = json['accessToken'] as String?;
    final refreshToken = json['refreshToken'] as String?;
    if (token == null ||
        token.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        user['id'] is! String ||
        (user['id'] as String).isEmpty) {
      throw Exception('서버 인증 기능을 업데이트한 뒤 다시 로그인해주세요.');
    }
    return AuthUser(
      id: user['id'] as String? ?? '',
      email: user['email'] as String? ?? '',
      displayName: user['displayName'] as String? ?? '',
      accessToken: token,
      refreshToken: refreshToken,
    );
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
          throw AuthApiException(response.statusCode, message.first.toString());
        }
        throw AuthApiException(
            response.statusCode, message as String? ?? '요청을 처리하지 못했습니다.');
      }

      return decoded;
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}

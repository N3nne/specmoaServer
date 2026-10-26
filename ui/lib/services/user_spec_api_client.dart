import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_spec.dart';
import 'authenticated_client.dart';

class UserSpecApiClient {
  static final changes = ValueNotifier<int>(0);
  const UserSpecApiClient({http.Client? client}) : _client = client;
  final http.Client? _client;

  Future<List<UserSpec>> fetchMine() async {
    final items = <UserSpec>[];
    while (true) {
      final result =
          await _request('GET', '/specs?limit=100&offset=${items.length}');
      final page = (result['items'] as List)
          .map((item) =>
              UserSpec.fromJson((item as Map).cast<String, dynamic>()))
          .toList();
      items.addAll(page);
      if (items.length >= (result['total'] as num).toInt()) break;
      if (page.isEmpty) throw Exception('스펙 목록 응답이 불완전합니다. 다시 시도해주세요.');
    }
    return items;
  }

  Future<UserSpec> save(
      {required SpecType type,
      required Map<String, dynamic> data,
      String? id}) async {
    final result = await _request(
        id == null ? 'POST' : 'PATCH',
        id == null ? '/specs' : '/specs/$id',
        {if (id == null) 'type': type.apiValue, 'data': data});
    final saved = UserSpec.fromJson(result);
    changes.value++;
    return saved;
  }

  Future<void> remove(String id) async {
    await _request('DELETE', '/specs/$id');
    changes.value++;
  }

  Future<Map<String, dynamic>> _request(String method, String path,
      [Map<String, dynamic>? body]) async {
    final client = _client ?? AuthenticatedClient();
    try {
      final request =
          http.Request(method, Uri.parse('${AppConfig.apiBaseUrl}$path'));
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await http.Response.fromStream(
          await client.send(request).timeout(AppConfig.receiveTimeout));
      Map<String, dynamic> decoded;
      try {
        final value = jsonDecode(utf8.decode(response.bodyBytes));
        if (value is! Map<String, dynamic>) throw const FormatException();
        decoded = value;
      } on FormatException {
        throw Exception('서버 응답을 처리하지 못했습니다. 잠시 후 다시 시도해주세요.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded['message'];
        throw Exception(message is List
            ? message.join('\n')
            : message ?? '스펙 요청을 처리하지 못했습니다.');
      }
      return decoded;
    } finally {
      if (_client == null) client.close();
    }
  }
}

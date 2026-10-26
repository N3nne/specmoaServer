import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiCredentials {
  ApiCredentials._();
  static String? accessToken;
  static void Function()? onUnauthorized;
  static Future<bool> Function()? onRefresh;
  static int generation = 0;
}

class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient({http.Client? inner}) : _inner = inner ?? http.Client();
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final api = Uri.parse(AppConfig.apiBaseUrl);
    final isApi = request.url.origin == api.origin;
    if (!isApi) return _inner.send(request);
    final generation = ApiCredentials.generation;
    _authorize(request);
    final retry = request is http.Request ? _copy(request) : null;
    final sentToken = request.headers['Authorization'];
    final response = await _inner.send(request);
    if (generation != ApiCredentials.generation) {
      await response.stream.drain<void>();
      throw http.ClientException('로그인 사용자가 변경되어 이전 요청을 취소했습니다.', request.url);
    }
    if (response.statusCode != 401 || sentToken == null) {
      return _guardResponse(response, generation);
    }
    final body = await response.stream.toBytes();
    if (generation != ApiCredentials.generation) {
      throw http.ClientException('로그인 사용자가 변경되어 이전 요청을 취소했습니다.', request.url);
    }
    final refresh = ApiCredentials.onRefresh;
    final changed = sentToken != 'Bearer ${ApiCredentials.accessToken}';
    final refreshed = changed || (refresh != null && await refresh());
    if (!refreshed) {
      if (generation == ApiCredentials.generation) {
        ApiCredentials.onUnauthorized?.call();
      }
      return http.StreamedResponse(Stream.value(body), response.statusCode,
          headers: response.headers,
          request: request,
          reasonPhrase: response.reasonPhrase);
    }
    if (generation != ApiCredentials.generation) {
      throw http.ClientException('로그인 사용자가 변경되어 이전 요청을 취소했습니다.', request.url);
    }
    if (retry == null) {
      throw http.ClientException('로그인이 갱신되었습니다. 요청을 다시 시도해주세요.', request.url);
    }
    _authorize(retry);
    final retried = await _inner.send(retry);
    if (generation != ApiCredentials.generation) {
      await retried.stream.drain<void>();
      throw http.ClientException('로그인 사용자가 변경되어 이전 요청을 취소했습니다.', request.url);
    }
    if (retried.statusCode == 401) ApiCredentials.onUnauthorized?.call();
    return _guardResponse(retried, generation);
  }

  http.StreamedResponse _guardResponse(
      http.StreamedResponse response, int generation) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return response;
    }
    return http.StreamedResponse(response.stream.map((chunk) {
      if (generation != ApiCredentials.generation) {
        throw http.ClientException('로그인 사용자가 변경되어 이전 응답을 취소했습니다.');
      }
      return chunk;
    }), response.statusCode,
        headers: response.headers,
        request: response.request,
        contentLength: response.contentLength,
        reasonPhrase: response.reasonPhrase,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection);
  }

  void _authorize(http.BaseRequest request) {
    request.headers.remove('x-user-id');
    request.headers.remove('Authorization');
    final token = ApiCredentials.accessToken;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
  }

  http.Request _copy(http.Request request) =>
      http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;

  @override
  void close() => _inner.close();
}

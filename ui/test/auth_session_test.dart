import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:specmoa_zip_ui/auth/auth_session.dart';
import 'package:specmoa_zip_ui/auth/auth_token_store.dart';
import 'package:specmoa_zip_ui/config/app_config.dart';
import 'package:specmoa_zip_ui/models/auth_user.dart';
import 'package:specmoa_zip_ui/services/auth_api_client.dart';
import 'package:specmoa_zip_ui/services/authenticated_client.dart';
import 'package:specmoa_zip_ui/screens/auth_gate.dart';

const first = AuthUser(
    id: 'user-a',
    email: 'a@example.com',
    displayName: 'A',
    accessToken: 'access-a',
    refreshToken: 'refresh-a');
const second = AuthUser(
    id: 'user-b',
    email: 'b@example.com',
    displayName: 'B',
    accessToken: 'access-b',
    refreshToken: 'refresh-b');
final endpoint = Uri.parse('${AppConfig.apiBaseUrl}/specs');

http.Response renewed({String id = 'user-a', String token = 'renewed'}) =>
    http.Response(
        jsonEncode({
          'accessToken': 'access-$token',
          'refreshToken': 'refresh-$token',
          'user': {'id': id, 'email': '$id@example.com', 'displayName': id},
        }),
        201);

class MemoryTokens implements AuthTokenStore {
  MemoryTokens([this.token]);
  String? token;
  bool failWrite = false;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String? refreshToken) async {
    if (failWrite && refreshToken != null) {
      throw StateError('Storage unavailable');
    }
    token = refreshToken;
  }
}

void main() {
  tearDown(() {
    ApiCredentials.accessToken = null;
    ApiCredentials.onRefresh = null;
    ApiCredentials.onUnauthorized = null;
    ++ApiCredentials.generation;
  });

  test(
      'restart restores identity from the server and persists only the rotated refresh token',
      () async {
    final store = MemoryTokens('saved-refresh');
    final session = AuthSession(
        store: store,
        api: AuthApiClient(client: MockClient((request) async {
          expect(request.url.path, '/auth/refresh');
          expect(jsonDecode(request.body), {'refreshToken': 'saved-refresh'});
          expect(request.headers.containsKey('Authorization'), isFalse);
          return renewed();
        })));
    final restoring = session.restore();
    expect(session.isRestoring, isTrue);
    expect(session.isSignedIn, isFalse);
    await restoring;
    expect(session.user?.id, 'user-a');
    expect(ApiCredentials.accessToken, 'access-renewed');
    expect(store.token, 'refresh-renewed');
    expect(session.isRestoring, isFalse);
    session.dispose();
  });

  test('empty storage does not call the API', () async {
    final session = AuthSession(
        store: MemoryTokens(),
        api: AuthApiClient(client: MockClient((_) async {
          fail('No saved token should mean no request');
        })));
    await session.restore();
    expect(session.isSignedIn, isFalse);
    expect(session.isRestoring, isFalse);
    session.dispose();
  });

  for (final status in [400, 401]) {
    test('invalid or expired saved token ($status) is cleared', () async {
      final store = MemoryTokens('invalid-refresh');
      final session = AuthSession(
          store: store,
          api: AuthApiClient(
              client: MockClient((_) async => http.Response('{}', status))));
      await session.restore();
      expect(store.token, isNull);
      expect(session.isSignedIn, isFalse);
      session.dispose();
    });
  }

  test(
      'temporary restoration failure preserves saved login but opens no protected data',
      () async {
    final store = MemoryTokens('still-valid');
    final session = AuthSession(
        store: store,
        api: AuthApiClient(
            client: MockClient((_) async => http.Response('{}', 503))));
    await session.restore();
    expect(store.token, 'still-valid');
    expect(session.isSignedIn, isFalse);
    expect(ApiCredentials.accessToken, isNull);
    session.dispose();
  });

  test('login fails closed if secure token storage cannot be written',
      () async {
    final store = MemoryTokens()..failWrite = true;
    final revoked = <String>[];
    final session = AuthSession(
        store: store,
        api: AuthApiClient(client: MockClient((request) async {
          revoked
              .add((jsonDecode(request.body) as Map)['refreshToken'] as String);
          return http.Response('{}', 201);
        })));
    await expectLater(session.signIn(first), throwsException);
    expect(session.isSignedIn, isFalse);
    expect(ApiCredentials.accessToken, isNull);
    expect(store.token, isNull);
    expect(revoked, ['refresh-a']);
    session.dispose();
  });

  test('restore revokes a rotated token that cannot be persisted', () async {
    final store = MemoryTokens('saved-refresh')..failWrite = true;
    final revoked = <String>[];
    final session = AuthSession(
        store: store,
        api: AuthApiClient(client: MockClient((request) async {
          if (request.url.path == '/auth/refresh') return renewed();
          revoked
              .add((jsonDecode(request.body) as Map)['refreshToken'] as String);
          return http.Response('{}', 201);
        })));
    await session.restore();
    expect(session.isSignedIn, isFalse);
    expect(store.token, isNull);
    expect(revoked, ['refresh-renewed']);
    session.dispose();
  });

  test(
      'concurrent expired requests perform one refresh and retry with the new token',
      () async {
    var refreshes = 0;
    final session = AuthSession(
        store: MemoryTokens(),
        api: AuthApiClient(client: MockClient((_) async {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return renewed();
        })));
    await session.signIn(first);
    var attempts = 0;
    final client = AuthenticatedClient(inner: MockClient((request) async {
      attempts++;
      return http.Response('{}',
          request.headers['Authorization'] == 'Bearer access-a' ? 401 : 200);
    }));
    final responses =
        await Future.wait(List.generate(8, (_) => client.get(endpoint)));
    expect(responses.every((response) => response.statusCode == 200), isTrue);
    expect(refreshes, 1);
    expect(attempts, 16);
    expect(session.isSignedIn, isTrue);
    client.close();
    session.dispose();
  });

  test('POST retry preserves the exact body and is limited to one retry',
      () async {
    var requests = 0;
    final session = AuthSession(
        store: MemoryTokens(),
        api: AuthApiClient(client: MockClient((_) async => renewed())));
    await session.signIn(first);
    final client = AuthenticatedClient(inner: MockClient((request) async {
      requests++;
      expect(request.method, 'POST');
      expect(request.body, '{"type":"project","data":{"name":"sample"}}');
      expect(request.headers['content-type'], 'application/json');
      return http.Response('{}', requests == 1 ? 401 : 201);
    }));
    final response = await client.post(endpoint,
        headers: {'content-type': 'application/json'},
        body: '{"type":"project","data":{"name":"sample"}}');
    expect(response.statusCode, 201);
    expect(requests, 2);
    client.close();
    session.dispose();
  });

  test(
      'a transient refresh error retains identity and saved credentials for retry',
      () async {
    final store = MemoryTokens();
    final session = AuthSession(
        store: store,
        api: AuthApiClient(
            client: MockClient((_) async => http.Response('{}', 503))));
    await session.signIn(first);
    final client = AuthenticatedClient(
        inner: MockClient((_) async => http.Response('{}', 401)));
    await expectLater(client.get(endpoint), throwsA(isA<AuthApiException>()));
    expect(session.user?.id, 'user-a');
    expect(store.token, 'refresh-a');
    client.close();
    session.dispose();
  });

  test(
      'rejected refresh clears local login without retrying the protected request',
      () async {
    final store = MemoryTokens();
    final session = AuthSession(
        store: store,
        api: AuthApiClient(
            client: MockClient((request) async => http.Response(
                '{}', request.url.path == '/auth/refresh' ? 401 : 201))));
    await session.signIn(first);
    var attempts = 0;
    final client = AuthenticatedClient(inner: MockClient((_) async {
      attempts++;
      return http.Response('{}', 401);
    }));
    expect((await client.get(endpoint)).statusCode, 401);
    expect(attempts, 1);
    expect(session.isSignedIn, isFalse);
    expect(store.token, isNull);
    client.close();
    session.dispose();
  });

  test('a second 401 does not create a refresh loop', () async {
    var refreshes = 0, attempts = 0;
    final session = AuthSession(
        store: MemoryTokens(),
        api: AuthApiClient(client: MockClient((request) async {
          if (request.url.path == '/auth/refresh') {
            refreshes++;
            return renewed();
          }
          return http.Response('{}', 201);
        })));
    await session.signIn(first);
    final client = AuthenticatedClient(inner: MockClient((_) async {
      attempts++;
      return http.Response('{}', 401);
    }));
    expect((await client.get(endpoint)).statusCode, 401);
    await Future<void>.delayed(Duration.zero);
    expect(attempts, 2);
    expect(refreshes, 1);
    expect(session.isSignedIn, isFalse);
    client.close();
    session.dispose();
  });

  test('logout while refresh is in flight cannot restore the old login',
      () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final revoked = <String>[];
    final store = MemoryTokens();
    final session = AuthSession(
        store: store,
        api: AuthApiClient(client: MockClient((request) async {
          if (request.url.path == '/auth/refresh') {
            started.complete();
            return pending.future;
          }
          revoked
              .add((jsonDecode(request.body) as Map)['refreshToken'] as String);
          return http.Response('{}', 201);
        })));
    await session.signIn(first);
    final refresh = session.refresh();
    await started.future;
    await session.signOut();
    pending.complete(renewed());
    expect(await refresh, isFalse);
    expect(session.isSignedIn, isFalse);
    expect(store.token, isNull);
    expect(ApiCredentials.accessToken, isNull);
    expect(revoked, containsAll(['refresh-a', 'refresh-renewed']));
    session.dispose();
  });

  test('an old account refresh cannot replace the new account', () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final store = MemoryTokens();
    final session = AuthSession(
        store: store,
        api: AuthApiClient(client: MockClient((request) async {
          if (request.url.path == '/auth/refresh') {
            started.complete();
            return pending.future;
          }
          return http.Response('{}', 201);
        })));
    await session.signIn(first);
    final refresh = session.refresh();
    await started.future;
    await session.signIn(second);
    pending.complete(renewed());
    expect(await refresh, isFalse);
    expect(session.user?.id, 'user-b');
    expect(store.token, 'refresh-b');
    expect(ApiCredentials.accessToken, 'access-b');
    session.dispose();
  });

  test('late successful responses from the previous account are rejected',
      () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final session = AuthSession(
        store: MemoryTokens(),
        api: AuthApiClient(
            client: MockClient((_) async => http.Response('{}', 201))));
    await session.signIn(first);
    final client = AuthenticatedClient(inner: MockClient((_) async {
      started.complete();
      return pending.future;
    }));
    final request = client.get(endpoint);
    final rejected = expectLater(request, throwsA(isA<http.ClientException>()));
    await started.future;
    await session.signIn(second);
    pending.complete(http.Response('{"private":"user-a"}', 200));
    await rejected;
    expect(session.user?.id, 'user-b');
    client.close();
    session.dispose();
  });

  test('foreign origins never receive the app token or trigger logout',
      () async {
    ApiCredentials.accessToken = 'private';
    var unauthorized = false;
    ApiCredentials.onUnauthorized = () => unauthorized = true;
    final client = AuthenticatedClient(inner: MockClient((request) async {
      expect(request.headers.containsKey('Authorization'), isFalse);
      return http.Response('{}', 401);
    }));
    await client.get(Uri.parse('https://example.invalid/resource'));
    expect(unauthorized, isFalse);
    client.close();
  });

  test('a stale explicit authorization header is removed after logout',
      () async {
    final client = AuthenticatedClient(inner: MockClient((request) async {
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.headers.containsKey('x-user-id'), isFalse);
      return http.Response('{}', 401);
    }));
    await client.get(endpoint,
        headers: {'Authorization': 'Bearer previous', 'x-user-id': 'previous'});
    client.close();
  });

  testWidgets(
      'fast account switching closes old protected routes even before the next frame',
      (tester) async {
    final session = AuthSession(
        store: MemoryTokens(),
        api: AuthApiClient(
            client: MockClient((_) async => http.Response('{}', 201))));
    await session.signIn(first);
    await tester.pumpWidget(AuthScope(
        session: session,
        child: MaterialApp(
          home: AuthGate(
              session: session,
              signedInBuilder: (_) =>
                  Scaffold(body: Text('현재 ${session.user?.id}'))),
        )));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('A의 보호된 상세 화면'))));
    await tester.pumpAndSettle();
    expect(find.text('A의 보호된 상세 화면'), findsOneWidget);
    await session.signIn(second);
    await tester.pumpAndSettle();
    expect(find.text('A의 보호된 상세 화면'), findsNothing);
    expect(find.text('현재 user-b'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
}

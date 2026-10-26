import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:specmoa_zip_ui/models/user_spec.dart';
import 'package:specmoa_zip_ui/screens/specs/spec_form_schema.dart';
import 'package:specmoa_zip_ui/screens/specs/spec_register_screen.dart';
import 'package:specmoa_zip_ui/services/authenticated_client.dart';
import 'package:specmoa_zip_ui/services/user_spec_api_client.dart';
import 'package:specmoa_zip_ui/config/app_config.dart';
import 'package:specmoa_zip_ui/auth/auth_session.dart';
import 'package:specmoa_zip_ui/auth/auth_token_store.dart';
import 'package:specmoa_zip_ui/models/auth_user.dart';
import 'package:specmoa_zip_ui/screens/auth_gate.dart';
import 'package:specmoa_zip_ui/services/certification_search_api_client.dart';

Widget app(Widget child) => MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: child,
    );

void main() {
  testWidgets('editing a query immediately hides previous suggestions',
      (tester) async {
    final search = CertificationSearchApiClient(
        client: MockClient((_) async => http.Response(
            jsonEncode([
              {'id': 'catalog-id', 'name': '공식 검색 결과', 'organization': '시험 기관'}
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'})));
    await tester.pumpWidget(app(SpecRegisterScreen(
        type: SpecType.certification, searchClient: search)));
    final name = find.byKey(const ValueKey('spec-field-name'));
    await tester.enterText(name, '정보');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    await tester.enterText(name, '산업');
    await tester.pump();
    expect(find.byType(ListTile), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('searching an unchanged official name preserves its catalog link',
      (tester) async {
    Map<String, dynamic>? payload;
    final client = UserSpecApiClient(client: MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
          jsonEncode({
            'id': 'existing',
            'type': 'certification',
            'data': payload!['data']
          }),
          200);
    }));
    await tester.pumpWidget(app(SpecRegisterScreen(
        type: SpecType.certification,
        client: client,
        initial: const UserSpec(
            id: 'existing',
            type: SpecType.certification,
            data: {'name': '정보처리기사', 'certificationId': 'catalog-id'}))));
    await tester.tap(find.text('공식 명칭 검색'));
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect((payload!['data'] as Map)['certificationId'], 'catalog-id');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sign out closes previously opened protected routes',
      (tester) async {
    final session = AuthSession(store: _MemoryTokens());
    await tester.pumpWidget(
        AuthScope(session: session, child: app(AuthGate(session: session))));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('보호된 화면'))));
    await tester.pumpAndSettle();
    await session.signIn(const AuthUser(
        id: 'test',
        email: 'test@example.com',
        displayName: '테스트',
        accessToken: 'test-token'));
    await session.signOut();
    await tester.pumpAndSettle();
    expect(find.text('보호된 화면'), findsNothing);
    expect(find.text('로그인'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
  for (final type in SpecType.values) {
    testWidgets('${type.apiValue}: empty fields can register without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? payload;
      UserSpec? result;
      final client = UserSpecApiClient(client: MockClient((request) async {
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
            jsonEncode({
              'id': 'test-id',
              'type': type.apiValue,
              'title': null,
              'data': {}
            }),
            201);
      }));
      await tester.pumpWidget(app(Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () async {
                    result = await Navigator.push<UserSpec>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SpecRegisterScreen(
                                type: type, client: client)));
                  },
                  child: const Text('열기'))))));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final section in specForms[type]!.sections) {
        for (final field in section.fields) {
          final finder = find.byKey(ValueKey('spec-field-${field.key}'));
          if (finder.evaluate().isNotEmpty) {
            final controller = tester.widget<TextFormField>(finder).controller;
            expect(controller!.text, '',
                reason: '${field.key} must not contain demo values');
          }
        }
      }
      await tester.tap(find.text('등록하기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(result?.type, type);
      expect(payload?['type'], type.apiValue);
      final values = payload!['data'] as Map;
      expect(
          values.values.every(
              (value) => value == null || value is List && value.isEmpty),
          isTrue);
    });
  }

  testWidgets('existing values can be cleared and PATCH preserves the spec ID',
      (tester) async {
    Map<String, dynamic>? payload;
    String? method;
    final client = UserSpecApiClient(client: MockClient((request) async {
      method = request.method;
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
          jsonEncode({
            'id': 'existing',
            'type': 'certification',
            'title': null,
            'data': {}
          }),
          200);
    }));
    await tester.pumpWidget(app(SpecRegisterScreen(
        type: SpecType.certification,
        initial: const UserSpec(
            id: 'existing',
            type: SpecType.certification,
            data: {'certificateNumber': '0001'}),
        client: client)));
    await tester.ensureVisible(
        find.byKey(const ValueKey('spec-field-certificateNumber')));
    await tester.enterText(
        find.byKey(const ValueKey('spec-field-certificateNumber')), '');
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(method, 'PATCH');
    expect((payload!['data'] as Map)['certificateNumber'], isNull);
    expect(payload!.containsKey('type'), isFalse);
  });

  test(
      'authenticated requests replace spoofable identity headers with bearer tokens',
      () async {
    ApiCredentials.accessToken = 'test-access-token';
    final client = AuthenticatedClient(inner: MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-access-token');
      expect(request.headers.containsKey('x-user-id'), isFalse);
      return http.Response('{}', 200);
    }));
    await client.get(Uri.parse('${AppConfig.apiBaseUrl}/specs'),
        headers: {'x-user-id': 'someone-else'});
    client.close();
    ApiCredentials.accessToken = null;
  });
}

class _MemoryTokens implements AuthTokenStore {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String? refreshToken) async => token = refreshToken;
}

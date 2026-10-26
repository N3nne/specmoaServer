import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:specmoa_zip_ui/auth/auth_session.dart';
import 'package:specmoa_zip_ui/auth/auth_token_store.dart';
import 'package:specmoa_zip_ui/models/user_spec.dart';
import 'package:specmoa_zip_ui/screens/my_spec_screen.dart';
import 'package:specmoa_zip_ui/screens/root_shell.dart';
import 'package:specmoa_zip_ui/services/user_spec_api_client.dart';
import 'package:specmoa_zip_ui/settings/app_settings.dart';
import 'package:specmoa_zip_ui/theme/app_theme.dart';
import 'package:specmoa_zip_ui/widgets/main_tab_header.dart';

class _Specs extends UserSpecApiClient {
  @override
  Future<List<UserSpec>> fetchMine() async => [
        for (var i = 0; i < 12; i++)
          UserSpec(
            id: 'spec-$i',
            type: i < 6 ? SpecType.certification : SpecType.project,
            title: '테스트 스펙 $i',
            data: const {'name': '테스트', 'issuer': '시험 기관'},
          ),
      ];
}

class _Tokens implements AuthTokenStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String? refreshToken) async {}
}

void main() {
  for (final width in [320.0, 360.0, 390.0, 520.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('shared header fits width $width and text scale $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Offset? notificationPosition;
        Offset? settingsPosition;
        var tapped = 0;
        for (final section in ['My Spec', '타이머', '탐색', '마이']) {
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: MainTabHeader(
                  section: section,
                  onNotifications: () => tapped++,
                  onSettings: () => tapped++,
                ),
              ),
            ),
          ));
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(MainTabHeader)).height, 56);
          final notifications = tester.getCenter(find.byTooltip('알림'));
          final settings = tester.getCenter(find.byTooltip('설정'));
          notificationPosition ??= notifications;
          settingsPosition ??= settings;
          expect(notifications, notificationPosition);
          expect(settings, settingsPosition);
          expect(tester.widget<Icon>(find.byIcon(Icons.settings_outlined)).size,
              20);
          await tester.tap(find.byTooltip('알림'));
          await tester.tap(find.byTooltip('설정'));
        }
        expect(tapped, 8);
      });
    }
  }

  testWidgets('root reserves bottom navigation and shares one fixed header',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final session = AuthSession(store: _Tokens());
    final settings = AppSettingsController();
    await tester.pumpWidget(AppSettingsScope(
      controller: settings,
      child: AuthScope(
        session: session,
        child: MaterialApp(theme: AppTheme.light(), home: const RootShell()),
      ),
    ));
    await tester.pumpAndSettle();
    final nav = find.byType(NavigationBar);
    final content = find.byType(IndexedStack);
    expect(tester.widget<Scaffold>(find.byType(Scaffold).first).extendBody,
        isFalse);
    expect(tester.getBottomLeft(content).dy,
        lessThanOrEqualTo(tester.getTopLeft(nav).dy));
    final position = tester.getTopLeft(find.byType(MainTabHeader));
    for (final label in ['타이머', '탐색', '마이', '내 스펙']) {
      await tester.tap(find.descendant(of: nav, matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(find.byType(MainTabHeader), findsOneWidget);
      expect(tester.getTopLeft(find.byType(MainTabHeader)), position);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
    settings.dispose();
  });

  testWidgets('last spec scrolls fully above navigation with system inset',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            MainTabHeader(
                section: 'My Spec', onNotifications: () {}, onSettings: () {}),
            Expanded(child: MySpecScreen(client: _Specs())),
          ]),
        ),
        bottomNavigationBar: NavigationBar(
          height: 72,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.folder), label: '내 스펙'),
            NavigationDestination(icon: Icon(Icons.timer), label: '타이머'),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final lastCard = find.ancestor(
        of: find.text('테스트 스펙 11'), matching: find.byType(InkWell));
    expect(lastCard, findsOneWidget);
    expect(tester.getBottomLeft(lastCard).dy,
        lessThan(tester.getTopLeft(find.byType(NavigationBar)).dy));
    final headerPosition = tester.getTopLeft(find.byType(MainTabHeader));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(MainTabHeader)), headerPosition);
    expect(tester.takeException(), isNull);
  });
}

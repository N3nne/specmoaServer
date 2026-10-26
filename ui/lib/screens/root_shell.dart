import 'dart:ui';

import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../widgets/main_tab_header.dart';
import 'explore_screen.dart';
import 'my_spec_screen.dart';
import 'profile_screen.dart';
import 'timer_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context);
    final userId = session.user?.id;
    final screens = [
      MySpecScreen(
        userId: userId,
        displayName: session.user?.displayName,
      ),
      TimerScreen(userId: userId),
      ExploreScreen(userId: userId),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            MainTabHeader(
              section: const ['My Spec', '타이머', '탐색', '마이'][_selectedIndex],
              onNotifications: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ),
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsHubScreen(),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            height: 72,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.folder_zip_outlined),
                selectedIcon: Icon(Icons.folder_zip_rounded),
                label: '내 스펙',
              ),
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer_rounded),
                label: '타이머',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: '탐색',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: '마이',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

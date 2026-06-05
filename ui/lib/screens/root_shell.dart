import 'dart:ui';

import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import 'certifications_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
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
      HomeScreen(userId: userId),
      CertificationsScreen(userId: userId),
      TimerScreen(userId: userId),
      const ExploreScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
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
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: '자격증',
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

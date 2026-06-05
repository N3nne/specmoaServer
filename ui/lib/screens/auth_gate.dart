import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import 'login_screen.dart';
import 'root_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.session,
    super.key,
  });

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (!session.isSignedIn) {
          return const LoginScreen();
        }

        return const RootShell();
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import 'login_screen.dart';
import 'root_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.session,
    this.signedInBuilder,
    super.key,
  });

  final AuthSession session;
  final WidgetBuilder? signedInBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _previousUserId;

  @override
  void initState() {
    super.initState();
    _previousUserId = widget.session.user?.id;
    widget.session.addListener(_sessionChanged);
  }

  @override
  void didUpdateWidget(covariant AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_sessionChanged);
      widget.session.addListener(_sessionChanged);
      _sessionChanged();
    }
  }

  void _sessionChanged() {
    final userId = widget.session.user?.id;
    if (_previousUserId != null && _previousUserId != userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
    _previousUserId = userId;
  }

  @override
  void dispose() {
    widget.session.removeListener(_sessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        if (widget.session.isRestoring) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!widget.session.isSignedIn) {
          return const LoginScreen();
        }

        return KeyedSubtree(
          key: ValueKey(widget.session.user?.id),
          child: widget.signedInBuilder?.call(context) ?? const RootShell(),
        );
      },
    );
  }
}

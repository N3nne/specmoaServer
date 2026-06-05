import 'package:flutter/widgets.dart';

import '../models/auth_user.dart';

class AuthSession extends ChangeNotifier {
  AuthUser? _user;

  AuthUser? get user => _user;

  bool get isSignedIn => _user != null;

  void signIn(AuthUser user) {
    _user = user;
    notifyListeners();
  }

  void signOut() {
    _user = null;
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthSession> {
  const AuthScope({
    required AuthSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);

  static AuthSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}

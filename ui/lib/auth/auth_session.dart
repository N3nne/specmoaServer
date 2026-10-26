import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/auth_user.dart';
import '../services/authenticated_client.dart';
import '../services/auth_api_client.dart';
import 'auth_token_store.dart';

class AuthSession extends ChangeNotifier {
  AuthSession({AuthApiClient? api, AuthTokenStore? store})
      : _api = api ?? const AuthApiClient(),
        _store = store ?? const SecureAuthTokenStore();

  final AuthApiClient _api;
  final AuthTokenStore _store;
  AuthUser? _user;
  int _revision = 0;
  bool _restoring = false;
  bool _disposed = false;
  Future<bool>? _refreshing;
  Future<void> _storageWork = Future.value();

  AuthUser? get user => _user;

  bool get isSignedIn => _user != null;
  bool get isRestoring => _restoring;

  Future<void> restore() async {
    final revision = ++_revision;
    _restoring = true;
    _notify();
    AuthUser? renewed;
    try {
      final token = await _store.read();
      if (token == null || !_isCurrent(revision)) return;
      final user = await _api.refresh(token);
      renewed = user;
      if (!_isCurrent(revision)) {
        await _revoke(user.refreshToken);
        return;
      }
      await _saveToken(user.refreshToken);
      if (_isCurrent(revision)) {
        _install(user);
      } else {
        await _revoke(user.refreshToken);
      }
    } on AuthApiException catch (error) {
      if (_isCurrent(revision) &&
          (error.statusCode == 400 || error.statusCode == 401)) {
        await _clearSavedToken();
      }
    } catch (_) {
      // A network failure must not erase an otherwise valid saved login.
      if (renewed != null) {
        await _revoke(renewed.refreshToken);
        if (_isCurrent(revision)) await _clearSavedToken();
      }
    } finally {
      if (_isCurrent(revision)) {
        _restoring = false;
        _notify();
      }
    }
  }

  Future<void> signIn(AuthUser user) async {
    final revision = ++_revision;
    _restoring = false;
    final previous = _user;
    _clearLocal();
    _notify();
    unawaited(_revoke(previous?.refreshToken));
    try {
      await _saveToken(user.refreshToken);
    } catch (_) {
      await _revoke(user.refreshToken);
      if (_isCurrent(revision)) await _clearSavedToken();
      throw Exception('로그인 정보를 안전하게 저장하지 못했습니다. 다시 시도해주세요.');
    }
    if (!_isCurrent(revision)) {
      await _revoke(user.refreshToken);
      return;
    }
    _install(user);
    _notify();
  }

  void _install(AuthUser user) {
    ApiCredentials.accessToken = user.accessToken;
    ApiCredentials.onRefresh = refresh;
    ApiCredentials.onUnauthorized = () => unawaited(signOut());
    _user = user;
  }

  Future<void> signOut() async {
    final previous = _user;
    ++_revision;
    _restoring = false;
    _clearLocal();
    _notify();
    await _clearSavedToken();
    await _revoke(previous?.refreshToken);
  }

  Future<bool> refresh() {
    final pending = _refreshing;
    if (pending != null) return pending;
    final revision = _revision;
    late Future<bool> operation;
    operation = _refresh(revision).whenComplete(() {
      if (identical(_refreshing, operation)) _refreshing = null;
    });
    _refreshing = operation;
    return operation;
  }

  Future<bool> _refresh(int revision) async {
    final token = _user?.refreshToken;
    if (token == null) return false;
    AuthUser next;
    try {
      next = await _api.refresh(token);
    } on AuthApiException catch (error) {
      if (_isCurrent(revision) &&
          (error.statusCode == 400 || error.statusCode == 401)) {
        await signOut();
        return false;
      }
      rethrow;
    }
    if (!_isCurrent(revision)) {
      await _revoke(next.refreshToken);
      return false;
    }
    try {
      await _saveToken(next.refreshToken);
    } catch (_) {
      await _revoke(next.refreshToken);
      if (_isCurrent(revision)) await signOut();
      return false;
    }
    if (!_isCurrent(revision)) {
      await _revoke(next.refreshToken);
      return false;
    }
    _install(next);
    return true;
  }

  void _clearLocal() {
    ++ApiCredentials.generation;
    ApiCredentials.accessToken = null;
    ApiCredentials.onUnauthorized = null;
    ApiCredentials.onRefresh = null;
    _user = null;
    _refreshing = null;
  }

  Future<void> _saveToken(String? token) {
    // Serialize writes so a late refresh cannot restore credentials after logout.
    final work =
        _storageWork.catchError((Object _) {}).then((_) => _store.write(token));
    _storageWork = work;
    return work;
  }

  Future<void> _revoke(String? token) async {
    if (token == null) return;
    try {
      await _api.logout(token);
    } catch (_) {
      debugPrint('서버에 연결하지 못해 원격 로그아웃을 확인하지 못했습니다.');
    }
  }

  Future<void> _clearSavedToken() async {
    try {
      await _saveToken(null);
    } catch (_) {
      debugPrint('로그인 정보 삭제에 실패했습니다.');
    }
  }

  bool _isCurrent(int revision) => !_disposed && revision == _revision;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    _clearLocal();
    super.dispose();
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

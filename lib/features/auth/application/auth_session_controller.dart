import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session_invalidator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/models/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

enum AuthSessionStatus { unknown, unauthenticated, authenticated }

final class AuthSessionController extends ChangeNotifier {
  AuthSessionController({
    required this.authRepository,
    required this.tokenStorage,
    required this.sessionInvalidator,
  }) {
    sessionInvalidator.addListener(_handleSessionInvalidated);
  }

  final AuthRepository authRepository;
  final TokenStorage tokenStorage;
  final AuthSessionInvalidator sessionInvalidator;

  AuthSessionStatus _status = AuthSessionStatus.unknown;
  AuthUser? _currentUser;
  Object? _restoreError;
  Object? _authenticationError;
  bool _isAuthenticating = false;
  bool _isLoggingOut = false;
  int _operationId = 0;
  bool _isDisposed = false;

  AuthSessionStatus get status => _status;
  AuthUser? get currentUser => _currentUser;
  Object? get restoreError => _restoreError;
  Object? get authenticationError => _authenticationError;
  bool get isAuthenticating => _isAuthenticating;
  bool get isLoggingOut => _isLoggingOut;

  Future<void> restore() async {
    final operationId = ++_operationId;

    try {
      final token = await tokenStorage.readAccessToken();
      if (!_isCurrent(operationId)) return;

      if (token == null || token.trim().isEmpty) {
        _setUnauthenticated();
        return;
      }

      final user = await authRepository.getCurrentUser();
      if (!_isCurrent(operationId)) return;

      _setAuthenticated(user);
    } on ApiException catch (error) {
      if (!_isCurrent(operationId)) return;

      if (error.statusCode == 401) {
        await _clearInvalidSession(operationId);
        return;
      }

      _setUnauthenticated(restoreError: error);
    } on Object catch (error) {
      if (!_isCurrent(operationId)) return;
      _setUnauthenticated(restoreError: error);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nickname,
  }) {
    return _authenticate(
      () => authRepository.register(
        email: email,
        password: password,
        nickname: nickname,
      ),
    );
  }

  Future<void> login({required String email, required String password}) {
    return _authenticate(
      () => authRepository.login(email: email, password: password),
    );
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;

    final operationId = ++_operationId;
    Object? logoutError;
    _isLoggingOut = true;
    _notify();

    try {
      await authRepository.logout();
    } on Object catch (error) {
      logoutError = error;
      rethrow;
    } finally {
      if (_isCurrent(operationId)) {
        _setUnauthenticated(restoreError: logoutError);
      }
    }
  }

  Future<void> _authenticate(Future<AuthUser> Function() action) async {
    final operationId = ++_operationId;
    _restoreError = null;
    _authenticationError = null;
    _isAuthenticating = true;
    _notify();

    try {
      final user = await action();
      if (!_isCurrent(operationId)) return;

      _setAuthenticated(user);
    } on Object catch (error) {
      if (_isCurrent(operationId)) {
        _authenticationError = error;
        _isAuthenticating = false;
        _notify();
      }
      rethrow;
    }
  }

  void clearAuthenticationError() {
    if (_authenticationError == null) return;
    _authenticationError = null;
    _notify();
  }

  Future<void> _clearInvalidSession(int operationId) async {
    Object? cleanupError;
    try {
      await authRepository.logout();
    } on Object catch (error) {
      cleanupError = error;
    }

    if (_isCurrent(operationId)) {
      _setUnauthenticated(restoreError: cleanupError);
    }
  }

  void _setAuthenticated(AuthUser user) {
    _currentUser = user;
    _restoreError = null;
    _authenticationError = null;
    _isAuthenticating = false;
    _isLoggingOut = false;
    _status = AuthSessionStatus.authenticated;
    _notify();
  }

  void _setUnauthenticated({Object? restoreError}) {
    _currentUser = null;
    _restoreError = restoreError;
    _authenticationError = null;
    _isAuthenticating = false;
    _isLoggingOut = false;
    _status = AuthSessionStatus.unauthenticated;
    _notify();
  }

  bool _isCurrent(int operationId) =>
      !_isDisposed && operationId == _operationId;

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  void _handleSessionInvalidated() {
    if (_isDisposed) return;
    _operationId++;
    _setUnauthenticated(restoreError: sessionInvalidator.cleanupError);
  }

  @override
  void dispose() {
    _isDisposed = true;
    sessionInvalidator.removeListener(_handleSessionInvalidated);
    super.dispose();
  }
}

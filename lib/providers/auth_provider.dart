import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:timesheet/config/oidc_config.dart';
import 'package:timesheet/models/auth_info.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/session.dart';
import 'package:timesheet/repositories/auth_repository.dart';
import 'package:timesheet/services/session_manager.dart';
import 'package:timesheet/ui/platform/macos/dialog.dart' as mac_dialog;
import 'package:timesheet/ui/platform/macos/snackbar.dart';
import 'package:timesheet/ui/platform/windows/dialog.dart' as win_dialog;
import 'package:timesheet/ui/platform/windows/infobar.dart';

enum TokenRefreshResult { success, failed, interactionRequired }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionManager _sessionManager;

  bool _isLoading = false;
  bool _refreshInProgress = false;
  bool _autoRefreshTriggered = false;
  Timer? _sessionMonitorTimer;
  bool _dialogShown = false;
  Future<TokenRefreshResult>? _ongoingRefresh;

  AuthProvider({
    required AuthRepository authRepository,
    required SessionManager sessionManager,
  }) : _authRepository = authRepository,
       _sessionManager = sessionManager {
    _sessionManager.addListener(_onSessionChanged);
    _startSessionMonitoring();
  }

  bool get isLoading => _isLoading;
  bool get isRefreshing => _refreshInProgress;
  bool get isAuthenticated => _sessionManager.isValid;
  String? get accessToken => _sessionManager.accessToken;
  DateTime? get tokenExpiresAt => _sessionManager.expiresAt;
  String? get userName => _sessionManager.userName;
  String? get userEmail => _sessionManager.email;

  Future<void> login() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authRepository.authenticate();

      switch (result) {
        case OK():
          _applyAuthInfo(result.value);
        case Error():
          _showError(result.message);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TokenRefreshResult> refreshToken({bool showErrors = true}) {
    if (_sessionManager.isEmpty) {
      return Future.value(TokenRefreshResult.failed);
    }
    if (_ongoingRefresh != null) {
      return _ongoingRefresh!;
    }

    final refresh = _doRefreshToken(showErrors);
    _ongoingRefresh = refresh;
    return refresh.whenComplete(() {
      if (identical(_ongoingRefresh, refresh)) {
        _ongoingRefresh = null;
      }
    });
  }

  Future<bool> refreshTokenForHttp() async {
    final result = await refreshToken(showErrors: false);
    if (result == TokenRefreshResult.interactionRequired) {
      _showReLoginDialog();
    }
    return result == TokenRefreshResult.success;
  }

  Future<TokenRefreshResult> _doRefreshToken(bool showErrors) async {
    _refreshInProgress = true;
    notifyListeners();

    try {
      for (
        var attempt = 0;
        attempt < OidcConfig.tokenRefreshRetryCount;
        attempt++
      ) {
        if (attempt > 0) {
          await Future.delayed(OidcConfig.tokenRefreshRetryInterval);
        }

        final result = await _authRepository.refreshSession();
        switch (result) {
          case OK():
            _applyAuthInfo(result.value);
            return TokenRefreshResult.success;
          case Error(:final message):
            if (message == OidcConfig.interactionRequiredError) {
              if (showErrors) {
                _showReLoginDialog();
              }
              return TokenRefreshResult.interactionRequired;
            }
            if (attempt == OidcConfig.tokenRefreshRetryCount - 1) {
              if (showErrors) {
                _showError(message);
              }
              return TokenRefreshResult.failed;
            }
        }
      }

      return TokenRefreshResult.failed;
    } finally {
      _refreshInProgress = false;
      notifyListeners();
    }
  }

  Future<void> extendSession() async {
    _dialogShown = false;
    await refreshToken(showErrors: true);
  }

  void logout() {
    _sessionManager.clearSession();
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionManager.removeListener(_onSessionChanged);
    _stopSessionMonitoring();
    super.dispose();
  }

  void _applyAuthInfo(AuthInfo authInfo) {
    _autoRefreshTriggered = false;
    _sessionManager.updateSession(
      Session(
        accessToken: authInfo.accessToken,
        expiresAt: authInfo.expiresAt,
        userName: authInfo.name,
        email: authInfo.email,
      ),
    );
  }

  void _onSessionChanged() {
    final session = _sessionManager.value;

    if (session.isValid) {
      _dialogShown = false;
      _startSessionMonitoring();
    } else {
      _stopSessionMonitoring();
      _dialogShown = false;
      _autoRefreshTriggered = false;
    }

    notifyListeners();
  }

  void _startSessionMonitoring() {
    _stopSessionMonitoring();

    final session = _sessionManager.value;
    if (!session.isValid || session.expiresAt == null) {
      return;
    }

    _sessionMonitorTimer = Timer.periodic(
      OidcConfig.expirationCheckInterval,
      (_) => _checkTokenRefresh(),
    );

    _checkTokenRefresh();
  }

  void _stopSessionMonitoring() {
    _sessionMonitorTimer?.cancel();
    _sessionMonitorTimer = null;
  }

  void _checkTokenRefresh() {
    final session = _sessionManager.value;

    if (!session.isValid || session.expiresAt == null || _refreshInProgress) {
      return;
    }

    final needsRefresh = session.expiresWithin(OidcConfig.tokenRefreshLeeway);
    if (!needsRefresh) {
      _autoRefreshTriggered = false;
      return;
    }

    if (_autoRefreshTriggered) {
      return;
    }

    _autoRefreshTriggered = true;
    unawaited(_performAutoRefresh());
  }

  Future<void> _performAutoRefresh() async {
    final result = await refreshToken(showErrors: false);
    if (result != TokenRefreshResult.success) {
      _autoRefreshTriggered = false;
    }
    if (result == TokenRefreshResult.interactionRequired) {
      _showReLoginDialog();
    }
  }

  void _showReLoginDialog() {
    if (_dialogShown) {
      return;
    }

    _dialogShown = true;

    const title = 'Session Expired';
    const message = 'Your session has expired. Please log in again.';
    const confirmText = 'Log In';
    const cancelText = 'Log Out';

    void onResult(bool confirmed) {
      _dialogShown = false;
      if (confirmed) {
        login();
      } else {
        logout();
      }
    }

    if (Platform.isWindows) {
      win_dialog.DialogManager.warningConfirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onResult: onResult,
      );
    } else {
      mac_dialog.DialogManager.warningConfirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onResult: onResult,
      );
    }
  }

  void _showError(String message) {
    if (Platform.isWindows) {
      InfoBarManager.error(message);
    } else {
      SnackBarManager.error(message);
    }
  }
}

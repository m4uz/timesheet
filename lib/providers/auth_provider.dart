import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/session.dart';
import 'package:timesheet/repositories/auth_repository.dart';
import 'package:timesheet/services/session_manager.dart';
import 'package:timesheet/ui/macos/dialog.dart' as mac_dialog;
import 'package:timesheet/ui/macos/snackbar.dart';
import 'package:timesheet/ui/windows/dialog.dart' as win_dialog;
import 'package:timesheet/ui/windows/infobar.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionManager _sessionManager;

  bool _isLoading = false;
  Timer? _expirationTimer;
  bool _dialogShown = false;

  AuthProvider({
    required AuthRepository authRepository,
    required SessionManager sessionManager,
  }) : _authRepository = authRepository,
       _sessionManager = sessionManager {
    _sessionManager.addListener(_onSessionChanged);
    _startExpirationMonitoring();
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _sessionManager.isValid;
  String? get accessToken => _sessionManager.accessToken;
  DateTime? get tokenExpiresAt => _sessionManager.expiresAt;
  String? get userName => _sessionManager.userName;
  String? get userEmail => _sessionManager.email;

  Future<void> login() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authRepository.authenticate();

    switch (result) {
      case OK():
        _sessionManager.updateSession(
          Session(
            accessToken: result.value.accessToken,
            expiresAt: result.value.expiresAt,
            userName: result.value.name,
            email: result.value.email,
          ),
        );
        _isLoading = false;
        notifyListeners();
      case Error():
        _isLoading = false;
        notifyListeners();
        if (Platform.isWindows) {
          InfoBarManager.error(result.message);
        } else {
          SnackBarManager.error(result.message);
        }
    }
  }

  Future<void> extendSession() async {
    _dialogShown = false;
    return await login();
  }

  void logout() {
    _sessionManager.clearSession();
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionManager.removeListener(_onSessionChanged);
    _stopExpirationMonitoring();
    super.dispose();
  }

  void _onSessionChanged() {
    final session = _sessionManager.value;

    if (session.isValid) {
      _dialogShown = false;
      _startExpirationMonitoring();
    } else {
      _stopExpirationMonitoring();
      _dialogShown = false;
    }

    notifyListeners();
  }

  void _startExpirationMonitoring() {
    _stopExpirationMonitoring();

    final session = _sessionManager.value;
    if (!session.isValid || session.expiresAt == null) {
      return;
    }

    _expirationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkExpiration();
    });

    _checkExpiration();
  }

  void _stopExpirationMonitoring() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
  }

  void _checkExpiration() {
    final session = _sessionManager.value;

    if (!session.isValid) {
      _dialogShown = false;
      return;
    }

    const warningThreshold = Duration(minutes: 5);
    final expiresWithin = session.expiresWithin(warningThreshold);

    if (expiresWithin && !_dialogShown) {
      _dialogShown = true;
      _showExpirationDialog(session.expiresAt);
    } else if (!expiresWithin) {
      _dialogShown = false;
    }
  }

  void _showExpirationDialog(DateTime? expiresAt) {
    final timeRemaining = expiresAt?.difference(DateTime.now());
    final minutes = timeRemaining != null
        ? (timeRemaining.inSeconds / 60).ceil()
        : 0;

    const title = 'Session Expiring';
    final message =
        'Your session will expire in $minutes minute${minutes != 1 ? 's' : ''}. '
        'Would you like to extend your session?';
    const confirmText = 'Extend Session';
    const cancelText = 'Log Out';

    void onResult(bool confirmed) {
      if (confirmed) {
        extendSession();
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
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:timesheet/services/oidc_browser_auth_session.dart';
import 'package:timesheet/services/oidc_webview_session.dart';

enum OidcAuthPresentation { hidden, silent, interactive }

class OidcAuthCoordinator extends ChangeNotifier {
  final OidcWebViewSession session;
  final OidcBrowserAuthSession browserSession;

  OidcAuthPresentation _presentation = OidcAuthPresentation.hidden;
  bool _disposed = false;

  OidcAuthCoordinator({
    OidcWebViewSession? session,
    OidcBrowserAuthSession? browserSession,
  }) : session = session ?? OidcWebViewSession(),
       browserSession = browserSession ?? OidcBrowserAuthSession();

  OidcAuthPresentation get presentation => _presentation;
  bool get visible => _presentation != OidcAuthPresentation.hidden;
  bool get interactive => _presentation == OidcAuthPresentation.interactive;

  /// Linux embeds WebKitGTK via platform views, which currently breaks the
  /// Flutter GL surface on Wayland. Use the system browser instead.
  bool get usesSystemBrowser => !kIsWeb && Platform.isLinux;

  Future<Map<String, String>> authorize(
    Uri authorizationUri, {
    required bool interactive,
  }) async {
    if (usesSystemBrowser) {
      return _authorizeWithBrowser(
        authorizationUri,
        interactive: interactive,
      );
    }

    return _authorizeWithWebView(
      authorizationUri,
      interactive: interactive,
    );
  }

  Future<Map<String, String>> _authorizeWithWebView(
    Uri authorizationUri, {
    required bool interactive,
  }) async {
    await session.ensureInitialized();

    if (session.isAuthorizing) {
      throw StateError('Authorization already in progress.');
    }

    _setPresentation(
      interactive
          ? OidcAuthPresentation.interactive
          : OidcAuthPresentation.silent,
    );

    await SchedulerBinding.instance.endOfFrame;

    try {
      return await session.loadAuthorizationUri(authorizationUri);
    } finally {
      _setPresentation(OidcAuthPresentation.hidden);
    }
  }

  Future<Map<String, String>> _authorizeWithBrowser(
    Uri authorizationUri, {
    required bool interactive,
  }) async {
    if (browserSession.isAuthorizing) {
      throw StateError('Authorization already in progress.');
    }

    _setPresentation(
      interactive
          ? OidcAuthPresentation.interactive
          : OidcAuthPresentation.silent,
    );

    try {
      return await browserSession.authorize(authorizationUri);
    } finally {
      _setPresentation(OidcAuthPresentation.hidden);
    }
  }

  void cancel() {
    if (usesSystemBrowser) {
      browserSession.cancelAuthorization();
    } else {
      session.cancelAuthorization();
    }
    _setPresentation(OidcAuthPresentation.hidden);
  }

  @override
  void dispose() {
    _disposed = true;
    session.dispose();
    browserSession.dispose();
    super.dispose();
  }

  void _setPresentation(OidcAuthPresentation presentation) {
    if (_presentation != presentation) {
      _presentation = presentation;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }
}

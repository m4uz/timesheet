import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:timesheet/services/oidc_webview_session.dart';

enum OidcAuthPresentation { hidden, silent, interactive }

class OidcAuthCoordinator extends ChangeNotifier {
  final OidcWebViewSession session;

  OidcAuthPresentation _presentation = OidcAuthPresentation.hidden;
  bool _disposed = false;

  OidcAuthCoordinator({OidcWebViewSession? session})
    : session = session ?? OidcWebViewSession();

  OidcAuthPresentation get presentation => _presentation;
  bool get visible => _presentation != OidcAuthPresentation.hidden;
  bool get interactive => _presentation == OidcAuthPresentation.interactive;

  Future<Map<String, String>> authorize(
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

  void cancel() {
    session.cancelAuthorization();
    _setPresentation(OidcAuthPresentation.hidden);
  }

  @override
  void dispose() {
    _disposed = true;
    session.dispose();
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

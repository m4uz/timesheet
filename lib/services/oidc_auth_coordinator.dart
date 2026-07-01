import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:timesheet/services/oidc_webview_session.dart';

class OidcAuthCoordinator extends ChangeNotifier {
  final OidcWebViewSession session;

  bool _visible = false;
  bool _interactive = false;

  OidcAuthCoordinator({OidcWebViewSession? session})
    : session = session ?? OidcWebViewSession();

  bool get visible => _visible;
  bool get interactive => _interactive;

  Future<Map<String, String>> authorize(
    Uri authorizationUri, {
    required bool interactive,
  }) async {
    await session.ensureInitialized();

    if (session.isAuthorizing) {
      throw StateError('Authorization already in progress.');
    }

    _interactive = interactive;
    _visible = true;
    notifyListeners();

    await SchedulerBinding.instance.endOfFrame;

    try {
      return await session.loadAuthorizationUri(authorizationUri);
    } finally {
      _visible = false;
      notifyListeners();
    }
  }

  void cancel() {
    session.cancelAuthorization();
    if (_visible) {
      _visible = false;
      notifyListeners();
    }
  }
}

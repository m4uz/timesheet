import 'dart:async';

import 'package:logging/logging.dart';
import 'package:timesheet/config/oidc_config.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class OidcWebViewSession {
  final _log = Logger('OidcWebViewSession');
  WebViewController? _controller;
  Completer<Map<String, String>>? _pendingAuthorization;
  Future<void>? _initialization;

  bool get isInitialized => _controller != null;

  WebViewController get controller {
    final controller = _controller;
    if (controller == null) {
      throw StateError('OidcWebViewSession is not initialized.');
    }
    return controller;
  }

  Future<void> ensureInitialized() {
    return _initialization ??= _initialize();
  }

  bool get isAuthorizing =>
      _pendingAuthorization != null && !_pendingAuthorization!.isCompleted;

  Future<Map<String, String>> loadAuthorizationUri(Uri authorizationUri) async {
    await ensureInitialized();

    if (isAuthorizing) {
      return Future.error(StateError('Authorization already in progress.'));
    }

    final completer = Completer<Map<String, String>>();
    _pendingAuthorization = completer;

    _log.fine('Loading authorization URI.');
    unawaited(controller.loadRequest(authorizationUri));

    return completer.future
        .timeout(
          OidcConfig.authorizationTimeout,
          onTimeout: () {
            throw TimeoutException('Authorization timed out.');
          },
        )
        .whenComplete(() {
          _pendingAuthorization = null;
        });
  }

  void cancelAuthorization() {
    final pending = _pendingAuthorization;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(Exception('Authorization cancelled.'));
    }
    _pendingAuthorization = null;
  }

  Future<void> _initialize() async {
    final controller = _createController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(onNavigationRequest: _onNavigationRequest),
    );
    _controller = controller;
  }

  static WebViewController _createController() {
    final params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
          )
        : const PlatformWebViewControllerCreationParams();

    return WebViewController.fromPlatformCreationParams(params);
  }

  FutureOr<NavigationDecision> _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.parse(request.url);
    if (!_isRedirect(uri)) {
      return NavigationDecision.navigate;
    }

    _log.fine('Authorization redirect intercepted.');

    final pending = _pendingAuthorization;
    if (pending != null && !pending.isCompleted) {
      pending.complete(Map<String, String>.from(uri.queryParameters));
    }

    return NavigationDecision.prevent;
  }

  bool _isRedirect(Uri uri) {
    final redirect = OidcConfig.redirectUri;
    return uri.scheme == redirect.scheme &&
        uri.host == redirect.host &&
        uri.port == redirect.port &&
        uri.path == redirect.path;
  }
}

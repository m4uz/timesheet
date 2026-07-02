import 'dart:async';

import 'package:logging/logging.dart';
import 'package:timesheet/config/oidc_config.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class OidcWebViewSession {
  final _log = Logger('OidcWebViewSession');
  WebViewController? _controller;
  Completer<Map<String, String>>? _pendingAuthorization;
  Future<void>? _configuration;
  bool _configured = false;
  static final Uri _aboutBlank = Uri.parse('about:blank');

  bool get hasController => _controller != null;
  bool get isInitialized => _configured;

  WebViewController get controller {
    final controller = _controller;
    if (controller == null) {
      throw StateError('OidcWebViewSession controller is not created.');
    }
    return controller;
  }

  void ensureControllerCreated() {
    _controller ??= _createController();
  }

  Future<void> ensureInitialized() {
    return _configuration ??= _configure();
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

  Future<void> _configure() async {
    if (_configured) {
      return;
    }

    ensureControllerCreated();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: _onNavigationRequest,
        onUrlChange: _onUrlChange,
      ),
    );
    _configured = true;
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
    if (!_tryCompleteAuthorization(uri)) {
      return NavigationDecision.navigate;
    }

    return NavigationDecision.prevent;
  }

  void _onUrlChange(UrlChange change) {
    final url = change.url;
    if (url == null) {
      return;
    }

    final uri = Uri.parse(url);
    if (_tryCompleteAuthorization(uri)) {
      // WebView2 can still try to load the loopback URL and show a refused page.
      // Navigating to about:blank immediately keeps the UX clean.
      unawaited(controller.loadRequest(_aboutBlank));
    }
  }

  bool _tryCompleteAuthorization(Uri uri) {
    if (!_isRedirect(uri)) {
      return false;
    }

    _log.fine('Authorization redirect intercepted.');

    final pending = _pendingAuthorization;
    if (pending != null && !pending.isCompleted) {
      pending.complete(Map<String, String>.from(uri.queryParameters));
    }

    return true;
  }

  bool _isRedirect(Uri uri) {
    final redirect = OidcConfig.redirectUri;
    return uri.scheme == redirect.scheme &&
        uri.host == redirect.host &&
        uri.port == redirect.port &&
        uri.path == redirect.path;
  }
}

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/services/oidc_auth_coordinator.dart';
import 'package:webview_all/webview_all.dart';

typedef OidcInteractiveAuthBuilder =
    Widget Function(
      BuildContext context,
      OidcAuthCoordinator coordinator,
      Widget webView,
    );

typedef OidcWebViewBuilder =
    Widget Function(BuildContext context, OidcAuthCoordinator coordinator);

class OidcAuthHostCore extends StatefulWidget {
  final Widget? child;
  final OidcInteractiveAuthBuilder buildInteractiveAuth;
  final OidcWebViewBuilder? buildWebView;

  const OidcAuthHostCore({
    required this.buildInteractiveAuth,
    super.key,
    this.child,
    this.buildWebView,
  });

  @override
  State<OidcAuthHostCore> createState() => _OidcAuthHostCoreState();
}

class _OidcAuthHostCoreState extends State<OidcAuthHostCore> {
  var _mountWebView = false;
  var _sessionReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSession());
  }

  Future<void> _initializeSession() async {
    final session = context.read<OidcAuthCoordinator>().session;
    session.ensureControllerCreated();
    if (!mounted) {
      return;
    }

    setState(() => _mountWebView = true);
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    await session.ensureInitialized();
    if (!mounted) {
      return;
    }

    setState(() => _sessionReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<OidcAuthCoordinator>();
    final child = widget.child;
    final interactive =
        _sessionReady &&
        coordinator.presentation == OidcAuthPresentation.interactive;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        if (child != null) child,
        if (_mountWebView)
          _MountedOidcWebView(
            coordinator: coordinator,
            interactive: interactive,
            buildInteractiveAuth: widget.buildInteractiveAuth,
            buildWebView: widget.buildWebView,
          ),
      ],
    );
  }
}

class _MountedOidcWebView extends StatelessWidget {
  static const _offscreenOffset = -10000.0;
  static const _offscreenSize = 1.0;

  final OidcAuthCoordinator coordinator;
  final bool interactive;
  final OidcInteractiveAuthBuilder buildInteractiveAuth;
  final OidcWebViewBuilder? buildWebView;

  const _MountedOidcWebView({
    required this.coordinator,
    required this.interactive,
    required this.buildInteractiveAuth,
    this.buildWebView,
  });

  @override
  Widget build(BuildContext context) {
    final webView =
        buildWebView?.call(context, coordinator) ??
        WebViewWidget(controller: coordinator.session.controller);

    if (interactive) {
      return buildInteractiveAuth(context, coordinator, webView);
    }

    return Positioned(
      left: _offscreenOffset,
      top: _offscreenOffset,
      width: _offscreenSize,
      height: _offscreenSize,
      child: webView,
    );
  }
}

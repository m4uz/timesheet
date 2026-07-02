import 'package:flutter/material.dart' as material show Colors;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/services/oidc_auth_coordinator.dart';
import 'package:webview_all/webview_all.dart';

class WinOidcAuthHost extends StatefulWidget {
  final Widget? child;

  const WinOidcAuthHost({super.key, this.child});

  @override
  State<WinOidcAuthHost> createState() => _WinOidcAuthHostState();
}

class _WinOidcAuthHostState extends State<WinOidcAuthHost> {
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
        _sessionReady && coordinator.visible && coordinator.interactive;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        if (child != null) child,
        if (_mountWebView)
          _MountedWebView(coordinator: coordinator, interactive: interactive),
      ],
    );
  }
}

class _MountedWebView extends StatelessWidget {
  final OidcAuthCoordinator coordinator;
  final bool interactive;

  const _MountedWebView({required this.coordinator, required this.interactive});

  @override
  Widget build(BuildContext context) {
    final webView = WebViewWidget(controller: coordinator.session.controller);

    if (interactive) {
      return ColoredBox(
        color: material.Colors.black54,
        child: Center(
          child: Container(
            width: 560,
            height: 760,
            decoration: BoxDecoration(
              color: FluentTheme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: FluentTheme.of(
                  context,
                ).resources.dividerStrokeColorDefault,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(
                        'Login',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const Spacer(),
                      Button(
                        onPressed: coordinator.cancel,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(child: webView),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: -10000,
      top: -10000,
      width: 1,
      height: 1,
      child: webView,
    );
  }
}

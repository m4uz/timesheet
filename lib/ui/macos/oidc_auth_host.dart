import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/services/oidc_auth_coordinator.dart';
import 'package:webview_all/webview_all.dart';

class OidcAuthHost extends StatelessWidget {
  final Widget child;

  const OidcAuthHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<OidcAuthCoordinator>();

    return Stack(
      children: [
        child,
        if (coordinator.visible && coordinator.interactive)
          _InteractiveAuthOverlay(coordinator: coordinator),
        if (coordinator.visible && !coordinator.interactive)
          _SilentAuthWebView(coordinator: coordinator),
      ],
    );
  }
}

class _InteractiveAuthOverlay extends StatelessWidget {
  final OidcAuthCoordinator coordinator;

  const _InteractiveAuthOverlay({required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 500,
          height: 700,
          decoration: BoxDecoration(
            color: MacosTheme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: MacosTheme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text(
                      'Login',
                      style: MacosTheme.of(context).typography.title3,
                    ),
                    const Spacer(),
                    PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: coordinator.cancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WebViewWidget(
                  controller: coordinator.session.controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SilentAuthWebView extends StatelessWidget {
  final OidcAuthCoordinator coordinator;

  const _SilentAuthWebView({required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -10000,
      top: -10000,
      width: 1,
      height: 1,
      child: WebViewWidget(controller: coordinator.session.controller),
    );
  }
}

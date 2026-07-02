import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/oidc/oidc_auth_host_core.dart';

class MacosOidcAuthHost extends StatelessWidget {
  final Widget? child;

  const MacosOidcAuthHost({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return OidcAuthHostCore(
      child: child,
      buildInteractiveAuth: (context, coordinator, webView) {
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
                  Expanded(child: webView),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

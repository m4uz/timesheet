import 'package:flutter/material.dart' as material show Colors;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:timesheet/ui/oidc/oidc_auth_host_core.dart';

class WindowsOidcAuthHost extends StatelessWidget {
  final Widget? child;

  const WindowsOidcAuthHost({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return OidcAuthHostCore(
      child: child,
      buildInteractiveAuth: (context, coordinator, webView) {
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
      },
    );
  }
}

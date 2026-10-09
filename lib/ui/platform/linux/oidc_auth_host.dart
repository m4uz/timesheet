import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/services/oidc_auth_coordinator.dart';
import 'package:yaru/yaru.dart';

/// Linux auth host: system-browser OIDC (no embedded WebView).
///
/// Shows a lightweight waiting overlay while the browser completes login.
class LinuxOidcAuthHost extends StatelessWidget {
  final Widget? child;

  const LinuxOidcAuthHost({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<OidcAuthCoordinator>();
    final waiting =
        coordinator.presentation == OidcAuthPresentation.interactive ||
        coordinator.presentation == OidcAuthPresentation.silent;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        ?child,
        if (waiting)
          ColoredBox(
            color: Colors.black54,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(kYaruContainerRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          coordinator.interactive
                              ? 'Complete login in your browser'
                              : 'Refreshing session…',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (coordinator.interactive)
                          Text(
                            'A browser window was opened for authentication. '
                            'Return here after signing in.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 20),
                        const YaruCircularProgressIndicator(),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: coordinator.cancel,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

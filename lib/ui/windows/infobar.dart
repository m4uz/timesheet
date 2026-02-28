import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

const Duration _kDismissDuration = Duration(seconds: 10);

class InfoBarManager {
  InfoBarManager._();
  static final InfoBarManager _instance = InfoBarManager._();
  static InfoBarManager get instance => _instance;

  GlobalKey<NavigatorState>? _navigatorKey;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _instance._navigatorKey = navigatorKey;
  }

  OverlayState? get _overlay => _navigatorKey?.currentState?.overlay;

  static void info(String message) {
    _instance._show(message: message, severity: InfoBarSeverity.info);
  }

  static void success(String message) {
    _instance._show(message: message, severity: InfoBarSeverity.success);
  }

  static void warning(String message) {
    _instance._show(message: message, severity: InfoBarSeverity.warning);
  }

  static void error(String message) {
    _instance._show(message: message, severity: InfoBarSeverity.error);
  }

  void _show({required String message, required InfoBarSeverity severity}) {
    final overlay = _overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: InfoBar(
            severity: severity,
            style: InfoBarThemeData(
              icon: (severity) {
                switch (severity) {
                  case InfoBarSeverity.info:
                    return WindowsIcons.info;
                  case InfoBarSeverity.success:
                    return WindowsIcons.check_mark;
                  case InfoBarSeverity.warning:
                    return WindowsIcons.warning;
                  case InfoBarSeverity.error:
                    return WindowsIcons.error;
                }
              },
            ),
            title: Text(switch (severity) {
              InfoBarSeverity.info => 'Info',
              InfoBarSeverity.success => 'Success',
              InfoBarSeverity.warning => 'Warning',
              InfoBarSeverity.error => 'Error',
            }),
            content: Text(message),
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: () {
                entry.remove();
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future<void>.delayed(_kDismissDuration, () {
      if (entry.mounted) entry.remove();
    });
  }
}

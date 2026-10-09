import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

const Duration _kDismissDuration = Duration(seconds: 10);

class SnackBarManager {
  SnackBarManager._();
  static final SnackBarManager _instance = SnackBarManager._();

  GlobalKey<NavigatorState>? _navigatorKey;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _instance._navigatorKey = navigatorKey;
  }

  OverlayState? get _overlay => _navigatorKey?.currentState?.overlay;

  static void info(String message) {
    _instance._show(message: message, type: YaruInfoType.information);
  }

  static void success(String message) {
    _instance._show(message: message, type: YaruInfoType.success);
  }

  static void warning(String message) {
    _instance._show(message: message, type: YaruInfoType.warning);
  }

  static void error(String message) {
    _instance._show(message: message, type: YaruInfoType.danger);
  }

  void _show({required String message, required YaruInfoType type}) {
    final overlay = _overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: YaruInfoBox(
              yaruInfoType: type,
              title: Text(switch (type) {
                YaruInfoType.information => 'Info',
                YaruInfoType.success => 'Success',
                YaruInfoType.important => 'Important',
                YaruInfoType.warning => 'Warning',
                YaruInfoType.danger => 'Error',
              }),
              subtitle: Text(message),
              trailing: YaruIconButton(
                icon: const Icon(YaruIcons.window_close),
                onPressed: () {
                  if (entry.mounted) entry.remove();
                },
              ),
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

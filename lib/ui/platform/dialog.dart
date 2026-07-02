import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:timesheet/ui/platform/macos/dialog.dart' as mac_dialog;
import 'package:timesheet/ui/platform/windows/dialog.dart' as win_dialog;

class PlatformDialog {
  PlatformDialog._();

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    mac_dialog.DialogManager.initialize(navigatorKey);
    win_dialog.DialogManager.initialize(navigatorKey);
  }

  static void warningConfirmation({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required void Function(bool confirmed) onResult,
  }) {
    if (Platform.isWindows) {
      win_dialog.DialogManager.warningConfirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onResult: onResult,
      );
    } else {
      mac_dialog.DialogManager.warningConfirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onResult: onResult,
      );
    }
  }
}

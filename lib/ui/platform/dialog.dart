import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:timesheet/ui/platform/macos/dialog_manager.dart' as macos;
import 'package:timesheet/ui/platform/windows/dialog_manager.dart' as windows;

class Dialog {
  Dialog._();

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    macos.DialogManager.initialize(navigatorKey);
    windows.DialogManager.initialize(navigatorKey);
  }

  static void warningConfirmation({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required void Function(bool confirmed) onResult,
  }) {
    if (Platform.isWindows) {
      windows.DialogManager.warningConfirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onResult: onResult,
      );
    } else {
      macos.DialogManager.warningConfirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onResult: onResult,
      );
    }
  }
}

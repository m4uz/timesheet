import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:timesheet/ui/platform/macos/dialog_manager.dart' as mac_dialog_manager;
import 'package:timesheet/ui/platform/windows/dialog_manager.dart' as win_dialog_manager;

class Dialog {
  Dialog._();

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    mac_dialog_manager.DialogManager.initialize(navigatorKey);
    win_dialog_manager.DialogManager.initialize(navigatorKey);
  }

  static void warningConfirmation({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required void Function(bool confirmed) onResult,
  }) {
    if (Platform.isWindows) {
      win_dialog_manager.DialogManager.warningConfirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onResult: onResult,
      );
    } else {
      mac_dialog_manager.DialogManager.warningConfirmation(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onResult: onResult,
      );
    }
  }
}

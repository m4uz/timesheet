import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:timesheet/ui/platform/macos/snackbar_manager.dart';
import 'package:timesheet/ui/platform/windows/infobar_manager.dart';

class Snackbar {
  Snackbar._();

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    SnackBarManager.initialize(navigatorKey);
    InfoBarManager.initialize(navigatorKey);
  }

  static void info(String message) {
    if (Platform.isWindows) {
      InfoBarManager.info(message);
    } else {
      SnackBarManager.info(message);
    }
  }

  static void success(String message) {
    if (Platform.isWindows) {
      InfoBarManager.success(message);
    } else {
      SnackBarManager.success(message);
    }
  }

  static void warning(String message) {
    if (Platform.isWindows) {
      InfoBarManager.warning(message);
    } else {
      SnackBarManager.warning(message);
    }
  }

  static void error(String message) {
    if (Platform.isWindows) {
      InfoBarManager.error(message);
    } else {
      SnackBarManager.error(message);
    }
  }
}

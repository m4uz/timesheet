import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:timesheet/ui/platform/macos/snackbar_manager.dart' as mac_snackbar_manager;
import 'package:timesheet/ui/platform/windows/infobar_manager.dart' as win_infobar_manager;

class Snackbar {
  Snackbar._();

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    mac_snackbar_manager.SnackBarManager.initialize(navigatorKey);
    win_infobar_manager.InfoBarManager.initialize(navigatorKey);
  }

  static void info(String message) {
    if (Platform.isWindows) {
      win_infobar_manager.InfoBarManager.info(message);
    } else {
      mac_snackbar_manager.SnackBarManager.info(message);
    }
  }

  static void success(String message) {
    if (Platform.isWindows) {
      win_infobar_manager.InfoBarManager.success(message);
    } else {
      mac_snackbar_manager.SnackBarManager.success(message);
    }
  }

  static void warning(String message) {
    if (Platform.isWindows) {
      win_infobar_manager.InfoBarManager.warning(message);
    } else {
      mac_snackbar_manager.SnackBarManager.warning(message);
    }
  }

  static void error(String message) {
    if (Platform.isWindows) {
      win_infobar_manager.InfoBarManager.error(message);
    } else {
      mac_snackbar_manager.SnackBarManager.error(message);
    }
  }
}

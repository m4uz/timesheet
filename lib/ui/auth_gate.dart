import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/ui/macos/macos_timesheet.dart';
import 'package:timesheet/ui/macos/views/login_view.dart';
import 'package:timesheet/ui/windows/views/login_view.dart';
import 'package:timesheet/ui/windows/windows_timesheet.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Platform.isWindows ? const WinLoginView() : const LoginView();
    }

    return Platform.isWindows ? const WindowsTimesheet() : const MacosTimesheet();
  }
}

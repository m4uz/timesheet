import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: Text(
          'Login',
          style: MacosTheme.of(context).typography.title2,
        ),
        titleWidth: 150.0,
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Center(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.isLoading) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Authenticating...',
                          style: MacosTheme.of(context).typography.body,
                        ),
                      ],
                    );
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', width: 250, height: 250),
                      const SizedBox(height: 32),
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () => _handleLogin(context, authProvider),
                        child: const Text('Login with OIDC'),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleLogin(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    await authProvider.login();
    // If authentication fails, AuthProvider takes care of displaying snackbar error.
    if (authProvider.isAuthenticated && context.mounted) {
      // Navigation will be handled by the main app based on auth state
      // The app will automatically show the main content when authenticated
    }
  }
}

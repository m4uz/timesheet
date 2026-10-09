import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:yaru/yaru.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const YaruWindowTitleBar(
        border: BorderSide.none,
        title: Text('Login'),
      ),
      body: Center(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const YaruCircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Authenticating...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 250, height: 250),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => _handleLogin(context, authProvider),
                  child: const Text('Login with OIDC'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLogin(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    await authProvider.login();
  }
}

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';

class WinLoginView extends StatelessWidget {
  const WinLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Login')),
      content: Center(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // --------------------------------------------------
            // Loading state
            // --------------------------------------------------
            if (authProvider.isLoading) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ProgressRing(),
                  const SizedBox(height: 16),
                  Text(
                    'Authenticating...',
                    style: FluentTheme.of(context).typography.body,
                  ),
                ],
              );
            }
            // --------------------------------------------------
            // Login content
            // --------------------------------------------------
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 250, height: 250),
                const SizedBox(height: 32),
                Button(
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
    if (authProvider.isAuthenticated && context.mounted) {
      // App will show main content when authenticated
    }
  }
}

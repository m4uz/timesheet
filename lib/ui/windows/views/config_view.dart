import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/app_config_model.dart';
import 'package:timesheet/providers/config_provider.dart';
import 'package:timesheet/ui/windows/infobar.dart';
import 'package:url_launcher/url_launcher.dart';

const _logLevels = [
  'OFF',
  'SEVERE',
  'WARNING',
  'INFO',
  'CONFIG',
  'FINE',
  'FINER',
  'FINEST',
  'ALL',
];

class ConfigView extends StatefulWidget {
  const ConfigView({super.key});

  @override
  State<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
  late TextEditingController _logFileController;
  late TextEditingController _timetrackerDbController;
  late TextEditingController _oidcIssuerUrlController;
  late TextEditingController _oidcClientIdController;
  late TextEditingController _wtmBaseUrlController;
  late TextEditingController _proxyHostController;
  late TextEditingController _proxyPortController;

  String _logLevel = 'INFO';
  String? _loadedConfigKey;
  static const double _labelWidth = 160.0;

  @override
  void initState() {
    super.initState();
    _logFileController = TextEditingController();
    _timetrackerDbController = TextEditingController();
    _oidcIssuerUrlController = TextEditingController();
    _oidcClientIdController = TextEditingController();
    _wtmBaseUrlController = TextEditingController();
    _proxyHostController = TextEditingController();
    _proxyPortController = TextEditingController();
  }

  @override
  void dispose() {
    _logFileController.dispose();
    _timetrackerDbController.dispose();
    _oidcIssuerUrlController.dispose();
    _oidcClientIdController.dispose();
    _wtmBaseUrlController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    super.dispose();
  }

  void _loadFromConfig(AppConfigModel config) {
    _logFileController.text = config.logFile;
    _logLevel = config.logLevel;
    _timetrackerDbController.text = config.timetrackerDB;
    _oidcIssuerUrlController.text = config.oidcIssuerUrl;
    _oidcClientIdController.text = config.oidcClientId;
    _wtmBaseUrlController.text = config.wtmBaseUrl;
    _proxyHostController.text = config.proxyHost;
    _proxyPortController.text = config.proxyPort.toString();
  }

  String _configKey(AppConfigModel config) {
    return [
      config.logFile,
      config.logLevel,
      config.timetrackerDB,
      config.oidcIssuerUrl,
      config.oidcClientId,
      config.wtmBaseUrl,
      config.proxyHost,
      config.proxyPort.toString(),
    ].join('|');
  }

  AppConfigModel _buildConfigFromForm(AppConfigModel current) {
    final proxyPort = int.tryParse(_proxyPortController.text.trim()) ?? 0;
    return current.copyWith(
      logFile: _logFileController.text.trim(),
      logLevel: _logLevel.trim(),
      timetrackerDB: _timetrackerDbController.text.trim(),
      oidcIssuerUrl: _oidcIssuerUrlController.text.trim(),
      oidcClientId: _oidcClientIdController.text.trim(),
      wtmBaseUrl: _wtmBaseUrlController.text.trim(),
      proxyHost: _proxyHostController.text.trim(),
      proxyPort: proxyPort,
    );
  }

  Future<void> _openAppSupportDir(String? path) async {
    if (path == null || path.isEmpty) return;
    final uri = Uri.file(path);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _validatePort(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0 || parsed > 65535) return 'Invalid port';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, provider, _) {
        final successMsg = provider.successMsg;
        final errorMsg = provider.errorMsg;
        if (successMsg != null || errorMsg != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (successMsg != null) {
              InfoBarManager.success(successMsg);
              provider.clearSuccessMsg();
            }
            if (errorMsg != null) {
              InfoBarManager.error(errorMsg);
              provider.clearErrorMsg();
            }
          });
        }

        final config = provider.config;
        if (config != null && _loadedConfigKey != _configKey(config)) {
          _loadFromConfig(config);
          _loadedConfigKey = _configKey(config);
        }

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Config'),
            commandBar: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --------------------------------------------------
                // Reload config
                // --------------------------------------------------
                Tooltip(
                  message: 'Reload config',
                  child: IconButton(
                    icon: const Icon(FluentIcons.refresh),
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.loadConfig(),
                  ),
                ),
                const SizedBox(width: 8),
                // --------------------------------------------------
                // Save config
                // --------------------------------------------------
                Tooltip(
                  message: 'Save config',
                  child: FilledButton(
                    onPressed: provider.isLoading || config == null
                        ? null
                        : () {
                            final portError = _validatePort(
                              _proxyPortController.text,
                            );
                            if (portError != null) {
                              InfoBarManager.error(portError);
                              return;
                            }
                            final updated = _buildConfigFromForm(config);
                            provider.saveConfig(updated);
                          },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
          content: provider.isLoading
              ? const Center(child: ProgressRing())
              : config == null
              // --------------------------------------------------
              // Empty state
              // --------------------------------------------------
              ? Center(
                  child: Text(
                    'No config loaded.',
                    style: FluentTheme.of(context).typography.body,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --------------------------------------------------
                      // App directories
                      // --------------------------------------------------
                      _buildSectionTitle(context, 'App directories'),
                      _buildRow(
                        context: context,
                        label: 'Application Support',
                        value: SelectableText(
                          provider.appSupportPath ?? '-',
                          style: FluentTheme.of(context).typography.body,
                        ),
                        action: IconButton(
                          icon: const Icon(FluentIcons.folder),
                          onPressed:
                              provider.appSupportPath == null ||
                                  provider.appSupportPath!.isEmpty
                              ? null
                              : () =>
                                    _openAppSupportDir(provider.appSupportPath),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      // --------------------------------------------------
                      // Logging
                      // --------------------------------------------------
                      _buildSectionTitle(context, 'Logging'),
                      _buildRow(
                        context: context,
                        label: 'Log file',
                        value: TextBox(controller: _logFileController),
                      ),
                      _buildRow(
                        context: context,
                        label: 'Log level',
                        value: ComboBox<String>(
                          value: _logLevel,
                          items: _logLevels
                              .map(
                                (item) => ComboBoxItem<String>(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _logLevel = value);
                            }
                          },
                          isExpanded: true,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      // --------------------------------------------------
                      // Storage
                      // --------------------------------------------------
                      _buildSectionTitle(context, 'Storage'),
                      _buildRow(
                        context: context,
                        label: 'Timetracker DB',
                        value: TextBox(controller: _timetrackerDbController),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      // --------------------------------------------------
                      // Authentication
                      // --------------------------------------------------
                      _buildSectionTitle(context, 'Authentication'),
                      _buildRow(
                        context: context,
                        label: 'OIDC URL',
                        value: TextBox(controller: _oidcIssuerUrlController),
                      ),
                      _buildRow(
                        context: context,
                        label: 'Client ID',
                        value: TextBox(controller: _oidcClientIdController),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      // --------------------------------------------------
                      // WTM
                      // --------------------------------------------------
                      _buildSectionTitle(context, 'WTM'),
                      _buildRow(
                        context: context,
                        label: 'URL',
                        value: TextBox(controller: _wtmBaseUrlController),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      // --------------------------------------------------
                      // Proxy
                      // --------------------------------------------------
                      _buildSectionTitle(context, 'Proxy'),
                      _buildRow(
                        context: context,
                        label: 'Host',
                        value: TextBox(controller: _proxyHostController),
                      ),
                      _buildRow(
                        context: context,
                        label: 'Port',
                        value: TextBox(
                          controller: _proxyPortController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: FluentTheme.of(context).typography.subtitle),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String label,
    required Widget value,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(label, style: FluentTheme.of(context).typography.body),
          ),
          const SizedBox(width: 12),
          Expanded(child: value),
          const SizedBox(width: 12),
          if (action != null) action,
        ],
      ),
    );
  }
}

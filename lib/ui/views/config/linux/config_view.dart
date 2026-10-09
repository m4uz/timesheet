import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/app_config_model.dart';
import 'package:timesheet/providers/config_provider.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:timesheet/ui/platform/linux/toolbar_icon_button.dart';
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yaru/yaru.dart';

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
  late TextEditingController _oidcIssuerUrlController;
  late TextEditingController _oidcClientIdController;
  late TextEditingController _wtmBaseUrlController;
  late TextEditingController _proxyHostController;
  late TextEditingController _proxyPortController;

  String _logLevel = 'INFO';
  String? _loadedConfigKey;
  static const double _labelWidth = LinuxLayout.formLabelWidth;

  @override
  void initState() {
    super.initState();
    _logFileController = TextEditingController();
    _oidcIssuerUrlController = TextEditingController();
    _oidcClientIdController = TextEditingController();
    _wtmBaseUrlController = TextEditingController();
    _proxyHostController = TextEditingController();
    _proxyPortController = TextEditingController();
  }

  @override
  void dispose() {
    _logFileController.dispose();
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
              Snackbar.success(successMsg);
              provider.clearSuccessMsg();
            }
            if (errorMsg != null) {
              Snackbar.error(errorMsg);
              provider.clearErrorMsg();
            }
          });
        }

        final config = provider.config;
        if (config != null && _loadedConfigKey != _configKey(config)) {
          _loadFromConfig(config);
          _loadedConfigKey = _configKey(config);
        }

        return Scaffold(
          appBar: YaruWindowTitleBar(
            border: BorderSide.none,
            title: const Text('Config'),
            actions: [
              ToolbarIconButton(
                message: 'Reload config',
                icon: YaruIcons.refresh,
                onPressed: provider.isLoading
                    ? null
                    : () => provider.loadConfig(),
              ),
              const SizedBox(width: LinuxLayout.space8),
              ToolbarIconButton(
                message: 'Save config',
                icon: YaruIcons.network_transmit,
                onPressed: provider.isLoading || config == null
                    ? null
                    : () {
                        final portError = _validatePort(
                          _proxyPortController.text,
                        );
                        if (portError != null) {
                          Snackbar.error(portError);
                          return;
                        }
                        final updated = _buildConfigFromForm(config);
                        provider.saveConfig(updated);
                      },
              ),
              const SizedBox(width: LinuxLayout.space8),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: YaruCircularProgressIndicator())
              : config == null
              ? Center(
                  child: Text(
                    'No config loaded.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : SingleChildScrollView(
                  padding: LinuxLayout.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'App directories'),
                      _buildRow(
                        context: context,
                        label: 'Application Support',
                        value: SelectableText(
                          provider.appSupportPath ?? '-',
                          style: LinuxLayout.rowFieldStyle(
                            Theme.of(context),
                          ),
                        ),
                        action: IconButton(
                          icon: Icon(
                            YaruIcons.folder,
                            size: LinuxLayout.rowIconSize,
                          ),
                          onPressed:
                              provider.appSupportPath == null ||
                                  provider.appSupportPath!.isEmpty
                              ? null
                              : () =>
                                    _openAppSupportDir(provider.appSupportPath),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: LinuxLayout.space16),
                      _buildSectionTitle(context, 'Logging'),
                      _buildRow(
                        context: context,
                        label: 'Log file',
                        value: TextField(controller: _logFileController),
                      ),
                      _buildRow(
                        context: context,
                        label: 'Log level',
                        value: DropdownButtonFormField<String>(
                          initialValue: _logLevel,
                          items: _logLevels
                              .map(
                                (item) => DropdownMenuItem<String>(
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
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: LinuxLayout.space16),
                      _buildSectionTitle(context, 'Authentication'),
                      _buildRow(
                        context: context,
                        label: 'OIDC URL',
                        value: TextField(controller: _oidcIssuerUrlController),
                      ),
                      _buildRow(
                        context: context,
                        label: 'Client ID',
                        value: TextField(controller: _oidcClientIdController),
                      ),
                      const Divider(),
                      const SizedBox(height: LinuxLayout.space16),
                      _buildSectionTitle(context, 'WTM'),
                      _buildRow(
                        context: context,
                        label: 'URL',
                        value: TextField(controller: _wtmBaseUrlController),
                      ),
                      const Divider(),
                      const SizedBox(height: LinuxLayout.space16),
                      _buildSectionTitle(context, 'Proxy'),
                      _buildRow(
                        context: context,
                        label: 'Host',
                        value: TextField(controller: _proxyHostController),
                      ),
                      _buildRow(
                        context: context,
                        label: 'Port',
                        value: TextField(
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
      padding: const EdgeInsets.only(bottom: LinuxLayout.space8),
      child: Text(
        title,
        style: LinuxLayout.sectionTitleStyle(Theme.of(context)),
      ),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String label,
    required Widget value,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: LinuxLayout.space10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(label, style: LinuxLayout.rowFieldStyle(theme)),
          ),
          const SizedBox(width: LinuxLayout.space12),
          Expanded(child: value),
          const SizedBox(width: LinuxLayout.space12),
          ?action,
        ],
      ),
    );
  }
}

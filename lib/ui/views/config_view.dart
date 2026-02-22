import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/app_config_model.dart';
import 'package:timesheet/providers/config_provider.dart';
import 'package:timesheet/ui/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (path == null || path.isEmpty) {
      return;
    }
    final uri = Uri.file(path);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, provider, _) {
        if (provider.successMsg != null) {
          SnackBarManager.success(provider.successMsg!);
          provider.clearSuccessMsg();
        }
        if (provider.errorMsg != null) {
          SnackBarManager.error(provider.errorMsg!);
          provider.clearErrorMsg();
        }

        final config = provider.config;
        if (config != null && _loadedConfigKey != _configKey(config)) {
          _loadFromConfig(config);
          _loadedConfigKey = _configKey(config);
        }

        return MacosScaffold(
          toolBar: ToolBar(
            title: Text(
              'Config',
              style: MacosTheme.of(context).typography.title2,
            ),
            titleWidth: 100.0,
            leading: MacosTooltip(
              message: 'Toggle Sidebar',
              child: MacosIconButton(
                icon: MacosIcon(
                  CupertinoIcons.sidebar_left,
                  color: CupertinoColors.inactiveGray,
                ),
                boxConstraints: const BoxConstraints(
                  minHeight: 20,
                  minWidth: 20,
                  maxWidth: 32,
                  maxHeight: 32,
                ),
                onPressed: () => MacosWindowScope.of(context).toggleSidebar(),
              ),
            ),
            actions: [
              ToolBarIconButton(
                label: 'Refresh',
                showLabel: false,
                icon: const MacosIcon(CupertinoIcons.refresh_circled),
                tooltipMessage: 'Reload config',
                onPressed: provider.isLoading
                    ? null
                    : () {
                        provider.loadConfig();
                      },
              ),
              ToolBarIconButton(
                label: 'Save',
                showLabel: false,
                icon: const MacosIcon(CupertinoIcons.cloud_upload),
                tooltipMessage: 'Save config',
                onPressed: provider.isLoading || config == null
                    ? null
                    : () {
                        final portError = _validatePort(
                          _proxyPortController.text,
                        );
                        if (portError != null) {
                          SnackBarManager.error(portError);
                          return;
                        }
                        final updated = _buildConfigFromForm(config);
                        provider.saveConfig(updated);
                      },
              ),
            ],
          ),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                if (provider.isLoading) {
                  return Center(child: ProgressCircle());
                }

                if (config == null) {
                  return Center(
                    child: Text(
                      'No config loaded.',
                      style: MacosTheme.of(context).typography.body,
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'App directories'),
                      _buildRow(
                        context: context,
                        label: 'Application Support',
                        value: SelectableText(
                          provider.appSupportPath ?? '-',
                          style: MacosTheme.of(context).typography.title3,
                        ),
                        action: MacosIconButton(
                          icon: MacosIcon(
                            CupertinoIcons.folder,
                            color: MacosTheme.of(context).primaryColor,
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
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'Logging'),
                      _buildRow(
                        context: context,
                        label: 'Log file',
                        value: _buildTextField(controller: _logFileController),
                      ),
                      _buildRow(
                        context: context,
                        label: 'Log level',
                        value: _buildDropdownField(
                          context: context,
                          value: _logLevel,
                          values: const [
                            'OFF',
                            'SEVERE',
                            'WARNING',
                            'INFO',
                            'CONFIG',
                            'FINE',
                            'FINER',
                            'FINEST',
                            'ALL',
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _logLevel = value);
                            }
                          },
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'Storage'),
                      _buildRow(
                        context: context,
                        label: 'Timetracker DB',
                        value: _buildTextField(
                          controller: _timetrackerDbController,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'Authentication'),
                      _buildRow(
                        context: context,
                        label: 'OIDC URL',
                        value: _buildTextField(
                          controller: _oidcIssuerUrlController,
                        ),
                      ),
                      _buildRow(
                        context: context,
                        label: 'Client ID',
                        value: _buildTextField(
                          controller: _oidcClientIdController,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'WTM'),
                      _buildRow(
                        context: context,
                        label: 'URL',
                        value: _buildTextField(
                          controller: _wtmBaseUrlController,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildSectionTitle(context, 'Proxy'),
                      _buildRow(
                        context: context,
                        label: 'Host',
                        value: _buildTextField(
                          controller: _proxyHostController,
                        ),
                      ),
                      _buildRow(
                        context: context,
                        label: 'Port',
                        value: _buildTextField(
                          controller: _proxyPortController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String? _validatePort(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0 || parsed > 65535) {
      return 'Invalid port';
    }
    return null;
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: MacosTheme.of(
          context,
        ).typography.title2.copyWith(fontWeight: FontWeight.bold),
      ),
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
            child: Text(label, style: MacosTheme.of(context).typography.title3),
          ),
          const SizedBox(width: 12),
          Expanded(child: value),
          const SizedBox(width: 12),
          SizedBox(child: action ?? const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return MacosTextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) {},
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String value,
    required List<String> values,
    required void Function(String?) onChanged,
  }) {
    return MacosPopupButton<String>(
      value: value,
      items: values
          .map(
            (item) =>
                MacosPopupMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

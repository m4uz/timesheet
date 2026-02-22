import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timesheet/models/app_config_model.dart';

class ConfigRepository {
  static const _assetPath = 'assets/config.json';
  static const _fileName = 'config.json';

  Future<AppConfigModel> loadConfig() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final configFile = await _ensureConfigFileExists(appSupportDir);
    final contents = await configFile.readAsString();
    final jsonData = jsonDecode(contents) as Map<String, dynamic>;
    return AppConfigModel.fromJson(jsonData);
  }

  Future<File> saveConfig(AppConfigModel config) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final configFile = File(p.join(appSupportDir.path, _fileName));
    final jsonContent = const JsonEncoder.withIndent(
      '  ',
    ).convert(config.toJson());
    return configFile.writeAsString(jsonContent);
  }

  Future<String> getAppSupportPath() async {
    final appSupportDir = await getApplicationSupportDirectory();
    return appSupportDir.path;
  }

  Future<File> _ensureConfigFileExists(Directory appSupportDir) async {
    final configFile = File(p.join(appSupportDir.path, _fileName));

    if (!await configFile.exists()) {
      final defaultConfig = await rootBundle.loadString(_assetPath);
      await configFile.writeAsString(defaultConfig);
    }

    return configFile;
  }
}

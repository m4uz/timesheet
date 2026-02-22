import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppConfig {
  static const _assetPath = 'assets/config.json';
  static const _fileName = 'config.json';

  static late Map<String, dynamic> _config;
  static late Directory _appSupportDir;

  static Future<void> init() async {
    _appSupportDir = await getApplicationSupportDirectory();
    final configFile = await _ensureConfigFileExists();
    final contents = await configFile.readAsString();
    _config = jsonDecode(contents) as Map<String, dynamic>;
  }

  static String get logFile =>
      p.join(_appSupportDir.path, _config['logFile'] as String);
  static Level get logLevel {
    final levelName = (_config['logLevel'] as String?)?.toUpperCase();
    return Level.LEVELS.firstWhere((level) => level.name == levelName);
  }

  static String get timetrackerDB =>
      p.join(_appSupportDir.path, _config['timetrackerDB'] as String);
  static Uri get oidcIssuerUrl => Uri.parse(_config['oidcIssuerUrl'] as String);
  static String get oidcClientId => _config['oidcClientId'] as String;
  static Uri get wtmBaseUrl => Uri.parse(_config['wtmBaseUrl'] as String);
  static String? get proxyHost => _config['proxyHost'] as String?;
  static int? get proxyPort => _config['proxyPort'] as int?;

  static Future<File> _ensureConfigFileExists() async {
    final configFile = File(p.join(_appSupportDir.path, _fileName));

    if (!await configFile.exists()) {
      final defaultConfig = await rootBundle.loadString(_assetPath);
      await configFile.writeAsString(defaultConfig);
    }

    return configFile;
  }
}

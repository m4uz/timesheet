import 'package:flutter/material.dart';
import 'package:timesheet/models/app_config_model.dart';
import 'package:timesheet/repositories/config_repository.dart';

class ConfigProvider extends ChangeNotifier {
  final ConfigRepository _repository;

  AppConfigModel? _config;
  bool _isLoading = false;
  String? _successMsg;
  String? _errorMsg;
  String? _appSupportPath;

  ConfigProvider({required ConfigRepository repository})
    : _repository = repository {
    loadConfig();
  }

  AppConfigModel? get config => _config;
  bool get isLoading => _isLoading;
  String? get successMsg => _successMsg;
  String? get errorMsg => _errorMsg;
  String? get appSupportPath => _appSupportPath;

  Future<void> loadConfig() async {
    _isLoading = true;
    _errorMsg = null;
    _successMsg = null;
    notifyListeners();

    try {
      _config = await _repository.loadConfig();
      _appSupportPath = await _repository.getAppSupportPath();
    } catch (e) {
      _errorMsg = 'Failed to load config.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveConfig(AppConfigModel config) async {
    _isLoading = true;
    _errorMsg = null;
    _successMsg = null;
    notifyListeners();

    try {
      await _repository.saveConfig(config);
      _config = config;
      _successMsg = 'Configuration saved. Restart required.';
    } catch (e) {
      _errorMsg = 'Failed to save config.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearSuccessMsg() {
    _successMsg = null;
  }

  void clearErrorMsg() {
    _errorMsg = null;
  }
}

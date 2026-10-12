import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _appLockEnabled = false;
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = const Color(0xFF6366F1);
  int _authTimeoutSeconds = 60;

  // Integrations Settings
  bool _offlineVaultAccess = true;
  bool _cloudSyncBackup = true;
  bool _enableHomeScreenWidget = false;
  bool _showHiddenMaskedCodes = true;

  // Privacy & Permissions
  bool _cameraAccess = true;
  bool _biometricPrompts = true;
  bool _pushNotifications = true;

  // Privacy Screen specific
  bool _shareUsageStats = true;
  bool _shareEmailAddress = true;
  bool _enableCrashReporting = true;
  bool _shakeToSendFeedback = false;

  // Personalization Page specific
  String _defaultHomepage = 'mfa'; // 'mfa' or 'authenticator'
  String _language = 'English'; // User selected language

  // Integrations - Wear OS Status
  bool _wearOsSynced = false;

  bool get appLockEnabled => _appLockEnabled;
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  int get authTimeoutSeconds => _authTimeoutSeconds;

  bool get offlineVaultAccess => _offlineVaultAccess;
  bool get cloudSyncBackup => _cloudSyncBackup;
  bool get enableHomeScreenWidget => _enableHomeScreenWidget;
  bool get showHiddenMaskedCodes => _showHiddenMaskedCodes;

  bool get cameraAccess => _cameraAccess;
  bool get biometricPrompts => _biometricPrompts;
  bool get pushNotifications => _pushNotifications;

  bool get shareUsageStats => _shareUsageStats;
  bool get shareEmailAddress => _shareEmailAddress;
  bool get enableCrashReporting => _enableCrashReporting;
  bool get shakeToSendFeedback => _shakeToSendFeedback;

  String get defaultHomepage => _defaultHomepage;
  String get language => _language;
  bool get wearOsSynced => _wearOsSynced;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() {
    _appLockEnabled = LocalStorageService.getAppLock();
    final themeIndex = LocalStorageService.getThemeMode();
    _themeMode = ThemeMode.values[themeIndex];
    
    final timeoutStr = LocalStorageService.getString('auth_timeout');
    if (timeoutStr != null) _authTimeoutSeconds = int.parse(timeoutStr);
    
    final accentVal = LocalStorageService.getString('app_accent_color');
    if (accentVal != null) {
      _accentColor = Color(int.parse(accentVal));
    }

    _offlineVaultAccess = _prefsGetBool('offline_vault_access', true);
    _cloudSyncBackup = _prefsGetBool('cloud_sync_backup', true);
    _enableHomeScreenWidget = _prefsGetBool('enable_home_screen_widget', false);
    _showHiddenMaskedCodes = _prefsGetBool('show_hidden_masked_codes', true);
    _cameraAccess = _prefsGetBool('camera_access', true);
    _biometricPrompts = _prefsGetBool('biometric_prompts', true);
    _pushNotifications = _prefsGetBool('push_notifications', true);

    _shareUsageStats = _prefsGetBool('share_usage_stats', true);
    _shareEmailAddress = _prefsGetBool('share_email_address', true);
    _enableCrashReporting = _prefsGetBool('enable_crash_reporting', true);
    _shakeToSendFeedback = _prefsGetBool('shake_to_send_feedback', false);

    _defaultHomepage = LocalStorageService.getString('default_homepage') ?? 'mfa';
    _language = LocalStorageService.getString('app_language') ?? 'English';
    _wearOsSynced = _prefsGetBool('wear_os_synced', false);
    
    notifyListeners();
  }

  bool _prefsGetBool(String key, bool defaultValue) {
    final val = LocalStorageService.getString(key);
    if (val == null) return defaultValue;
    return val == 'true';
  }

  void _prefsSetBool(String key, bool value) {
    LocalStorageService.setString(key, value.toString());
  }

  void toggleAppLock(bool value) {
    _appLockEnabled = value;
    LocalStorageService.setAppLock(value);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    LocalStorageService.setThemeMode(mode.index);
    notifyListeners();
  }

  void setAuthTimeout(int seconds) {
    _authTimeoutSeconds = seconds;
    LocalStorageService.setString('auth_timeout', seconds.toString());
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    LocalStorageService.setString('app_accent_color', color.toARGB32().toString());
    notifyListeners();
  }

  void setOfflineVaultAccess(bool value) {
    _offlineVaultAccess = value;
    _prefsSetBool('offline_vault_access', value);
    notifyListeners();
  }

  void setCloudSyncBackup(bool value) {
    _cloudSyncBackup = value;
    _prefsSetBool('cloud_sync_backup', value);
    notifyListeners();
  }

  void setEnableHomeScreenWidget(bool value) {
    _enableHomeScreenWidget = value;
    _prefsSetBool('enable_home_screen_widget', value);
    notifyListeners();
  }

  void setShowHiddenMaskedCodes(bool value) {
    _showHiddenMaskedCodes = value;
    _prefsSetBool('show_hidden_masked_codes', value);
    notifyListeners();
  }

  void setCameraAccess(bool value) {
    _cameraAccess = value;
    _prefsSetBool('camera_access', value);
    notifyListeners();
  }

  void setBiometricPrompts(bool value) {
    _biometricPrompts = value;
    _prefsSetBool('biometric_prompts', value);
    notifyListeners();
  }

  void setPushNotifications(bool value) {
    _pushNotifications = value;
    _prefsSetBool('push_notifications', value);
    notifyListeners();
  }

  void setShareUsageStats(bool value) {
    _shareUsageStats = value;
    _prefsSetBool('share_usage_stats', value);
    notifyListeners();
  }

  void setShareEmailAddress(bool value) {
    _shareEmailAddress = value;
    _prefsSetBool('share_email_address', value);
    notifyListeners();
  }

  void setEnableCrashReporting(bool value) {
    _enableCrashReporting = value;
    _prefsSetBool('enable_crash_reporting', value);
    notifyListeners();
  }

  void setShakeToSendFeedback(bool value) {
    _shakeToSendFeedback = value;
    _prefsSetBool('shake_to_send_feedback', value);
    notifyListeners();
  }

  void setDefaultHomepage(String value) {
    _defaultHomepage = value;
    LocalStorageService.setString('default_homepage', value);
    notifyListeners();
  }

  void setLanguage(String value) {
    _language = value;
    LocalStorageService.setString('app_language', value);
    notifyListeners();
  }

  void setWearOsSynced(bool value) {
    _wearOsSynced = value;
    _prefsSetBool('wear_os_synced', value);
    notifyListeners();
  }
}

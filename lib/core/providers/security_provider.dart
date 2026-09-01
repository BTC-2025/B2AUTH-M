import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class SecurityProvider with ChangeNotifier {
  bool _authenticatorEnabled = false;
  bool _smsEnabled = false;
  bool _twoStepEnabled = false;
  
  bool _passwordlessEnabled = true;
  bool _pushNotificationEnabled = true;
  bool _fingerprintEnabled = false;
  String _passphrase = '';
  
  bool get authenticatorEnabled => _authenticatorEnabled;
  bool get smsEnabled => _smsEnabled;
  bool get twoStepEnabled => _twoStepEnabled;

  bool get is2FAEnabled => _authenticatorEnabled || _twoStepEnabled;
  bool get isSMSEnabled => _smsEnabled;
  bool get isBiometricsEnabled => _fingerprintEnabled;
  
  bool get passwordlessEnabled => _passwordlessEnabled;
  bool get pushNotificationEnabled => _pushNotificationEnabled;
  bool get fingerprintEnabled => _fingerprintEnabled;
  String get passphrase => _passphrase;

  int get score {
    int s = 50;
    if (_authenticatorEnabled || _twoStepEnabled) s += 25;
    if (_smsEnabled) s += 15;
    if (_fingerprintEnabled) s += 10;
    return s.clamp(0, 100);
  }

  SecurityProvider() {
    _loadSecurityStatus();
  }

  void _loadSecurityStatus() {
    _authenticatorEnabled = LocalStorageService.getString('security_auth_enabled') == 'true';
    _smsEnabled = LocalStorageService.getString('security_sms_enabled') == 'true';
    _twoStepEnabled = LocalStorageService.getString('security_2fa_enabled') == 'true';
    
    _passwordlessEnabled = LocalStorageService.getString('security_passwordless_enabled') != 'false';
    _pushNotificationEnabled = LocalStorageService.getString('security_push_enabled') != 'false';
    _fingerprintEnabled = LocalStorageService.getString('security_fingerprint_enabled') == 'true';
    _passphrase = LocalStorageService.getString('security_passphrase') ?? '';
    notifyListeners();
  }

  void enableAuthenticator() {
    _authenticatorEnabled = true;
    _twoStepEnabled = true;
    LocalStorageService.setString('security_auth_enabled', 'true');
    LocalStorageService.setString('security_2fa_enabled', 'true');
    notifyListeners();
  }

  void enable2FA() {
    enableAuthenticator();
  }

  void toggle2FA(bool value) {
    _authenticatorEnabled = value;
    _twoStepEnabled = value;
    LocalStorageService.setString('security_auth_enabled', value.toString());
    LocalStorageService.setString('security_2fa_enabled', value.toString());
    notifyListeners();
  }

  void enableSMS() {
    _smsEnabled = true;
    LocalStorageService.setString('security_sms_enabled', 'true');
    notifyListeners();
  }

  void toggleSMS(bool value) {
    _smsEnabled = value;
    LocalStorageService.setString('security_sms_enabled', value.toString());
    notifyListeners();
  }

  void toggleTwoStep(bool value) {
    _twoStepEnabled = value;
    LocalStorageService.setString('security_2fa_enabled', value.toString());
    notifyListeners();
  }

  void toggleBiometrics(bool value) {
    _fingerprintEnabled = value;
    LocalStorageService.setString('security_fingerprint_enabled', value.toString());
    notifyListeners();
  }

  void togglePasswordless(bool value) {
    _passwordlessEnabled = value;
    LocalStorageService.setString('security_passwordless_enabled', value.toString());
    notifyListeners();
  }

  void togglePushNotification(bool value) {
    _pushNotificationEnabled = value;
    LocalStorageService.setString('security_push_enabled', value.toString());
    notifyListeners();
  }

  void toggleFingerprint(bool value) {
    _fingerprintEnabled = value;
    LocalStorageService.setString('security_fingerprint_enabled', value.toString());
    notifyListeners();
  }

  void setPassphrase(String val) {
    _passphrase = val;
    LocalStorageService.setString('security_passphrase', val);
    notifyListeners();
  }
}

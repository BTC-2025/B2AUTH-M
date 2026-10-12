import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;
  static final Map<String, dynamic> _inMemoryStore = {};

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences init error fallback: $e');
    }
  }

  // --- Account Storage ---
  static const String _keyAccounts = 'user_accounts';
  static const String _keySelectedAccountId = 'selected_account_id';

  static Future<void> saveAccounts(List<UserAccount> accounts) async {
    final List<String> accountJsonList = accounts.map((a) => a.toJson()).toList();
    _inMemoryStore[_keyAccounts] = accountJsonList;
    if (_prefs != null) {
      try {
        await _prefs!.setStringList(_keyAccounts, accountJsonList);
      } catch (e) {
        debugPrint('saveAccounts error: $e');
      }
    }
  }

  static List<UserAccount> getAccounts() {
    List<String>? accountJsonList;
    if (_prefs != null) {
      try {
        accountJsonList = _prefs!.getStringList(_keyAccounts);
      } catch (_) {}
    }
    accountJsonList ??= (_inMemoryStore[_keyAccounts] as List<String>?);
    if (accountJsonList == null) return [];
    return accountJsonList.map((json) => UserAccount.fromJson(json)).toList();
  }

  static Future<void> setSelectedAccountId(String id) async {
    _inMemoryStore[_keySelectedAccountId] = id;
    if (_prefs != null) {
      try {
        await _prefs!.setString(_keySelectedAccountId, id);
      } catch (_) {}
    }
  }

  static String? getSelectedAccountId() {
    if (_prefs != null) {
      try {
        final val = _prefs!.getString(_keySelectedAccountId);
        if (val != null) return val;
      } catch (_) {}
    }
    return _inMemoryStore[_keySelectedAccountId] as String?;
  }

  static Future<void> setAccountToken(String accountId, String token) async {
    final key = 'account_token_$accountId';
    _inMemoryStore[key] = token;
    if (_prefs != null) {
      try {
        await _prefs!.setString(key, token);
      } catch (_) {}
    }
  }

  static String? getAccountToken(String accountId) {
    final key = 'account_token_$accountId';
    if (_prefs != null) {
      try {
        final val = _prefs!.getString(key);
        if (val != null && val.isNotEmpty) return val;
      } catch (_) {}
    }
    final inMem = _inMemoryStore[key] as String?;
    if (inMem != null && inMem.isNotEmpty) return inMem;
    return null;
  }

  // --- Settings Storage ---
  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyThemeMode = 'app_theme_mode'; 
  
  static Future<void> setAppLock(bool enabled) async {
    _inMemoryStore[_keyAppLockEnabled] = enabled;
    if (_prefs != null) {
      try { await _prefs!.setBool(_keyAppLockEnabled, enabled); } catch (_) {}
    }
  }

  static bool getAppLock() {
    if (_prefs != null) {
      try { return _prefs!.getBool(_keyAppLockEnabled) ?? false; } catch (_) {}
    }
    return (_inMemoryStore[_keyAppLockEnabled] as bool?) ?? false;
  }

  static Future<void> setThemeMode(int mode) async {
    _inMemoryStore[_keyThemeMode] = mode;
    if (_prefs != null) {
      try { await _prefs!.setInt(_keyThemeMode, mode); } catch (_) {}
    }
  }

  static int getThemeMode() {
    if (_prefs != null) {
      try { return _prefs!.getInt(_keyThemeMode) ?? 0; } catch (_) {}
    }
    return (_inMemoryStore[_keyThemeMode] as int?) ?? 0;
  }

  // --- Generic Persistence ---
  static Future<void> setBool(String key, bool value) async {
    _inMemoryStore[key] = value;
    if (_prefs != null) {
      try { await _prefs!.setBool(key, value); } catch (_) {}
    }
  }

  static bool getBool(String key) {
    if (_prefs != null) {
      try { return _prefs!.getBool(key) ?? false; } catch (_) {}
    }
    return (_inMemoryStore[key] as bool?) ?? false;
  }

  static Future<void> setString(String key, String value) async {
    _inMemoryStore[key] = value;
    if (_prefs != null) {
      try { await _prefs!.setString(key, value); } catch (_) {}
    }
  }

  static String? getString(String key) {
    if (_prefs != null) {
      try { return _prefs!.getString(key); } catch (_) {}
    }
    return _inMemoryStore[key] as String?;
  }

  static Future<void> remove(String key) async {
    _inMemoryStore.remove(key);
    if (_prefs != null) {
      try { await _prefs!.remove(key); } catch (_) {}
    }
  }

  static Future<void> clearAllData() async {
    _inMemoryStore.clear();
    if (_prefs != null) {
      try { await _prefs!.clear(); } catch (_) {}
    }
  }
}

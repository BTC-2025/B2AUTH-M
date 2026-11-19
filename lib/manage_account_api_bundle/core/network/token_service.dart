import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:b2auth/core/services/local_storage_service.dart';

/// Secure token and session persistence service.
/// Uses resilient local persistent storage on desktop/web platforms (.bnx_local_store.json)
/// without hardcoded values, reflecting active authenticated user credentials.
class TokenService {
  static const _kAccess = 'bnx_access_token';
  static const _kRefresh = 'bnx_refresh_token';
  static const _kEmail = 'bnx_user_email';
  static const _kName = 'bnx_user_name';
  static const _kGlobalAvatar = 'bnx_user_avatar_global';
  static const _kSavedAccountsRegistry = 'bnx_saved_accounts_registry';
  static const _kExplicitlyLoggedOut = 'bnx_user_explicitly_logged_out';

  static String? _cachedAccessToken;
  static String? get cachedAccessToken {
    _ensureFallbackLoaded();
    return _cachedAccessToken;
  }
  static set cachedAccessToken(String? val) {
    _cachedAccessToken = val;
  }
  static final Map<String, String> _memoryFallback = {};
  static bool _fallbackLoaded = false;

  static String _kSettingsKey(String email) =>
      'bnx_user_settings_${email.trim().toLowerCase()}';

  static String _kAvatarKey(String email) =>
      'bnx_user_avatar_${email.trim().toLowerCase()}';

  static String _kBizOnboardedKey(String email) =>
      'bnx_biz_onboarded_${email.trim().toLowerCase()}';

  static File? _resolveFallbackFile() {
    try {
      if (kIsWeb) return null;
      Directory? baseDir;
      if (Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          baseDir = Directory('$home/Library/Application Support/com.bnxmail.app');
        }
      } else if (Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          baseDir = Directory('$home/.config/com.bnxmail.app');
        }
      } else if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          baseDir = Directory('$appData/com.bnxmail.app');
        }
      }
      baseDir ??= Directory('${Directory.systemTemp.path}/com.bnxmail.app');
      if (!baseDir.existsSync()) {
        baseDir.createSync(recursive: true);
      }
      return File('${baseDir.path}/.bnx_local_store.json');
    } catch (_) {
      return null;
    }
  }

  static void _ensureFallbackLoaded() {
    if (_fallbackLoaded) return;
    _fallbackLoaded = true;
    try {
      final file = _resolveFallbackFile();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              if (k != null && v != null) {
                _memoryFallback[k.toString()] = v.toString();
              }
            });
          }
        }
        _memoryFallback.remove(_kGlobalAvatar);
      }
      if (_memoryFallback.containsKey(_kAccess)) {
        final candidate = _memoryFallback[_kAccess];
        if (!isTokenExpired(candidate)) {
          cachedAccessToken = candidate;
        }
      }
    } catch (e) {
      debugPrint('[TOKEN SERVICE] Fallback storage read error: $e');
    }
  }

  static void _persistFallback() {
    try {
      final file = _resolveFallbackFile();
      if (file != null) {
        file.writeAsStringSync(jsonEncode(_memoryFallback));
      }
    } catch (e) {
      debugPrint('[TOKEN SERVICE] Fallback storage persist error: $e');
    }
  }

  static Future<void> _safeWrite({required String key, required String value}) async {
    _ensureFallbackLoaded();
    _memoryFallback[key] = value;
    _persistFallback();
  }

  static Future<String?> _safeRead({required String key}) async {
    _ensureFallbackLoaded();
    return _memoryFallback[key];
  }

  static Future<void> _safeDelete({required String key}) async {
    _ensureFallbackLoaded();
    _memoryFallback.remove(key);
    _persistFallback();
  }

  static Future<void> _safeDeleteAll() async {
    _ensureFallbackLoaded();
    final preserved = <String, String>{};
    _memoryFallback.forEach((k, v) {
      if (k.startsWith('bnx_biz_onboarded_') ||
          k.startsWith('bnx_user_settings_') ||
          k.startsWith('bnx_user_avatar_') ||
          k == _kExplicitlyLoggedOut ||
          k == _kSavedAccountsRegistry) {
        preserved[k] = v;
      }
    });
    _memoryFallback.clear();
    _memoryFallback.addAll(preserved);
    _persistFallback();
  }

  // ── Tokens ─────────────────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    cachedAccessToken = accessToken;
    await _safeWrite(key: _kAccess, value: accessToken);
    await _safeWrite(key: _kRefresh, value: refreshToken);
  }

  static bool isTokenExpired(String? token) {
    if (token == null || token.isEmpty || token.startsWith('offline_')) return true;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return false;
      var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decodedBytes = base64Decode(normalized);
      final payload = jsonDecode(utf8.decode(decodedBytes));
      if (payload is Map && payload.containsKey('exp')) {
        final exp = int.tryParse(payload['exp'].toString());
        if (exp != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          return now >= exp;
        }
      }
    } catch (_) {}
    return false;
  }

  static Future<String?> getAccessToken([String? forEmail]) async {
    String? cleanEmail = forEmail?.trim().toLowerCase();
    if (cleanEmail == null || cleanEmail.isEmpty) {
      try {
        final activeEmail = LocalStorageService.getString('active_email');
        if (activeEmail != null && activeEmail.isNotEmpty) {
          cleanEmail = activeEmail.trim().toLowerCase();
        }
      } catch (_) {}
    }

    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      // 1. Look for account-specific token in LocalStorageService
      try {
        final tokByEmail = LocalStorageService.getString('token_$cleanEmail');
        if (tokByEmail != null && !isTokenExpired(tokByEmail)) {
          cachedAccessToken = tokByEmail;
          return tokByEmail;
        }

        final localAccs = LocalStorageService.getAccounts();
        for (final a in localAccs) {
          if (a.email.trim().toLowerCase() == cleanEmail &&
              a.token != null &&
              !isTokenExpired(a.token)) {
            cachedAccessToken = a.token;
            return a.token;
          }
        }
      } catch (_) {}

      // 2. Look in registry
      final registry = await getSavedAccountsFromRegistry();
      for (final reg in registry) {
        if ((reg['email']?.toString() ?? '').toLowerCase() == cleanEmail) {
          final regTok = reg['accessToken']?.toString();
          if (regTok != null && !isTokenExpired(regTok)) {
            cachedAccessToken = regTok;
            try {
              await LocalStorageService.setString('token_$cleanEmail', regTok);
              await LocalStorageService.setString('access_token', regTok);
            } catch (_) {}
            return regTok;
          }
        }
      }

      // 3. Look in cached settings
      final settings = await getUserSettings(cleanEmail);
      final sTok = settings?['accessToken']?.toString() ?? settings?['token']?.toString();
      if (sTok != null && !isTokenExpired(sTok)) {
        cachedAccessToken = sTok;
        return sTok;
      }

      // 4. Look in memory fallback accounts
      _ensureFallbackLoaded();
      for (final entry in _memoryFallback.entries) {
        if (entry.key.contains(cleanEmail) || entry.key == _kSavedAccountsRegistry) {
          try {
            if (entry.key == _kSavedAccountsRegistry) {
              final regList = jsonDecode(entry.value);
              if (regList is List) {
                for (final item in regList) {
                  final itemEmail = (item['email']?.toString() ?? '').toLowerCase();
                  final itemToken = item['accessToken']?.toString();
                  if (itemEmail == cleanEmail && itemToken != null && !isTokenExpired(itemToken)) {
                    cachedAccessToken = itemToken;
                    try {
                      await LocalStorageService.setString('token_$cleanEmail', itemToken);
                      await LocalStorageService.setString('access_token', itemToken);
                    } catch (_) {}
                    return itemToken;
                  }
                }
              }
            }
          } catch (_) {}
        }
      }

      // If a specific email was requested, do not bleed another account's token
      if (forEmail != null && forEmail.trim().isNotEmpty) {
        return null;
      }
    }

    // Default active session resolution (Priority: LocalStorageService -> cached -> fallback)
    try {
      final activeTok = LocalStorageService.getString('access_token') ??
          LocalStorageService.getString('auth_token');
      if (activeTok != null && !isTokenExpired(activeTok)) {
        cachedAccessToken = activeTok;
        return activeTok;
      }
      final selectedId = LocalStorageService.getSelectedAccountId();
      if (selectedId != null && selectedId.isNotEmpty) {
        final accTok = LocalStorageService.getAccountToken(selectedId);
        if (accTok != null && !isTokenExpired(accTok)) {
          cachedAccessToken = accTok;
          return accTok;
        }
      }
      final activeEmail = LocalStorageService.getString('active_email');
      if (activeEmail != null && activeEmail.isNotEmpty) {
        final tok = LocalStorageService.getString('token_${activeEmail.toLowerCase()}');
        if (tok != null && !isTokenExpired(tok)) {
          cachedAccessToken = tok;
          return tok;
        }
      }
      final accounts = LocalStorageService.getAccounts();
      for (final a in accounts) {
        if (a.token != null && !isTokenExpired(a.token)) {
          cachedAccessToken = a.token;
          return a.token;
        }
      }
    } catch (_) {}

    if (cachedAccessToken != null && !isTokenExpired(cachedAccessToken)) {
      return cachedAccessToken;
    }

    _ensureFallbackLoaded();
    final fallbackTok = await _safeRead(key: _kAccess);
    if (fallbackTok != null && !isTokenExpired(fallbackTok)) {
      cachedAccessToken = fallbackTok;
      return fallbackTok;
    }

    // Fallback: check any valid token in _memoryFallback
    for (final v in _memoryFallback.values) {
      if (!isTokenExpired(v)) {
        cachedAccessToken = v;
        return v;
      }
    }

    return null;
  }

  static Future<String?> getRefreshToken() async =>
      _safeRead(key: _kRefresh);

  static Future<void> clearTokens() async {
    cachedAccessToken = null;
    await _safeDelete(key: _kAccess);
    await _safeDelete(key: _kRefresh);
  }

  static Future<void> clearAll() async {
    cachedAccessToken = null;
    await _safeDeleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> isExplicitlyLoggedOut() async {
    _ensureFallbackLoaded();
    final val = await _safeRead(key: _kExplicitlyLoggedOut);
    return val == 'true';
  }

  static Future<void> setExplicitlyLoggedOut(bool value) async {
    _ensureFallbackLoaded();
    if (value) {
      await _safeWrite(key: _kExplicitlyLoggedOut, value: 'true');
    } else {
      await _safeDelete(key: _kExplicitlyLoggedOut);
    }
  }

  // ── User Info & Active Session ─────────────────────────────────────────────

  static Future<String?> getUserEmail() async {
    try {
      final activeEmail = LocalStorageService.getString('active_email');
      if (activeEmail != null && activeEmail.isNotEmpty) return activeEmail;

      final selectedId = LocalStorageService.getSelectedAccountId();
      final accounts = LocalStorageService.getAccounts();
      if (selectedId != null && accounts.isNotEmpty) {
        final acc = accounts.firstWhere(
          (a) => a.id == selectedId,
          orElse: () => accounts.firstWhere((a) => a.isPrimary, orElse: () => accounts.first),
        );
        if (acc.email.isNotEmpty) return acc.email;
      } else if (accounts.isNotEmpty) {
        return accounts.first.email;
      }
    } catch (_) {}

    final email = await _safeRead(key: _kEmail);
    if (email != null && email.isNotEmpty) return email;

    final registry = await getSavedAccountsFromRegistry();
    if (registry.isNotEmpty) {
      final regEmail = registry.first['email']?.toString();
      if (regEmail != null && regEmail.isNotEmpty) return regEmail;
    }

    return null;
  }

  static Future<String?> getUserName() async {
    try {
      final selectedId = LocalStorageService.getSelectedAccountId();
      final accounts = LocalStorageService.getAccounts();
      if (selectedId != null && accounts.isNotEmpty) {
        final acc = accounts.firstWhere((a) => a.id == selectedId, orElse: () => accounts.first);
        if (acc.displayName.isNotEmpty) return acc.displayName;
        if (acc.name.isNotEmpty) return acc.name;
      }
    } catch (_) {}
    final name = await _safeRead(key: _kName);
    if (name != null && name.isNotEmpty) return name;
    final email = await getUserEmail();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return null;
  }

  static Future<void> saveUserInfo({String? email, String? name}) async {
    if (email != null && email.isNotEmpty) {
      final cleanEmail = email.trim().toLowerCase();
      await _safeWrite(key: _kEmail, value: cleanEmail);
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        await saveAccountToRegistry({
          'id': cleanEmail,
          'email': cleanEmail,
          'name': name ?? cleanEmail.split('@').first,
          'accessToken': token,
          'isPrimary': true,
        });
      }
    }
    if (name != null && name.isNotEmpty) {
      await _safeWrite(key: _kName, value: name);
    }
  }

  // ── User Avatar ────────────────────────────────────────────────────────────

  static Future<String?> getUserAvatar(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isNotEmpty) {
      final val = await _safeRead(key: _kAvatarKey(cleanEmail));
      if (val != null && val.isNotEmpty) return val;
      return null;
    }
    return null;
  }

  static Future<void> saveUserAvatar(String email, String avatar) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isNotEmpty) {
      if (avatar.isNotEmpty) {
        await _safeWrite(key: _kAvatarKey(cleanEmail), value: avatar);
      } else {
        await _safeDelete(key: _kAvatarKey(cleanEmail));
      }
    }
    await _safeDelete(key: _kGlobalAvatar);
  }

  // ── User Settings ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserSettings(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;
    final str = await _safeRead(key: _kSettingsKey(cleanEmail));
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  static Future<void> saveUserSettings(String email, Map<String, dynamic> data) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isNotEmpty) {
      final existing = await getUserSettings(cleanEmail) ?? {};
      final merged = {...existing, ...data};
      await _safeWrite(key: _kSettingsKey(cleanEmail), value: jsonEncode(merged));
    }
  }

  // ── Multi-Account Registry ─────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSavedAccountsFromRegistry() async {
    final raw = await _safeRead(key: _kSavedAccountsRegistry);
    List<Map<String, dynamic>> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          list = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }
    try {
      final localAccounts = LocalStorageService.getAccounts();
      final selectedId = LocalStorageService.getSelectedAccountId();
      final activeEmail = (LocalStorageService.getString('active_email') ?? '').trim().toLowerCase();
      for (final a in localAccounts) {
        final email = a.email.trim().toLowerCase();
        if (email.isEmpty) continue;
        final tok = a.token ??
            LocalStorageService.getAccountToken(a.id) ??
            LocalStorageService.getString('token_${a.id}') ??
            LocalStorageService.getString('token_$email');
        final isSelected = (a.id == selectedId || (activeEmail.isNotEmpty && email == activeEmail));
        final existingIdx = list.indexWhere((r) => (r['email']?.toString() ?? '').toLowerCase() == email);
        final entry = {
          'id': a.id,
          'email': email,
          'name': a.displayName.isNotEmpty ? a.displayName : (a.name.isNotEmpty ? a.name : email.split('@').first),
          'accessToken': (tok != null && tok.isNotEmpty) ? tok : '',
          'isPrimary': a.isPrimary || isSelected,
          'avatarUrl': a.avatarUrl ?? a.effectiveAvatarUrl,
        };
        if (existingIdx != -1) {
          if (tok != null && tok.isNotEmpty) {
            list[existingIdx]['accessToken'] = tok;
          }
          if (isSelected) {
            list[existingIdx]['isPrimary'] = true;
          }
        } else {
          list.add(entry);
        }
      }
    } catch (_) {}
    return list;
  }

  static Future<void> saveAccountToRegistry(Map<String, dynamic> account) async {
    final email = (account['email']?.toString() ?? '').trim().toLowerCase();
    if (email.isEmpty) return;
    final existing = await getSavedAccountsFromRegistry();
    final targetExisting = existing.firstWhere(
      (a) => (a['email']?.toString() ?? '').toLowerCase() == email,
      orElse: () => {},
    );
    final updated = existing.where((a) => (a['email']?.toString() ?? '').toLowerCase() != email).toList();
    String? token = account['accessToken']?.toString() ?? targetExisting['accessToken']?.toString();
    String? refresh = account['refreshToken']?.toString() ?? targetExisting['refreshToken']?.toString();

    if (token == null || token.isEmpty) {
      final currentToken = await getAccessToken(email);
      if (currentToken != null && currentToken.isNotEmpty) {
        token = currentToken;
      }
    }

    updated.add({
      ...targetExisting,
      ...account,
      if (token != null && token.isNotEmpty) 'accessToken': token,
      if (refresh != null && refresh.isNotEmpty) 'refreshToken': refresh,
      'email': email,
      'id': email,
    });
    await _safeWrite(key: _kSavedAccountsRegistry, value: jsonEncode(updated));
  }

  static Future<void> removeAccountFromRegistry(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final existing = await getSavedAccountsFromRegistry();
    final updated = existing.where((a) => (a['email']?.toString() ?? '').toLowerCase() != cleanEmail).toList();
    await _safeWrite(key: _kSavedAccountsRegistry, value: jsonEncode(updated));
  }

  static Future<void> switchActiveAccountSession(String id) async {
    final clean = id.trim().toLowerCase();
    cachedAccessToken = null;

    String targetEmail = clean;
    String targetName = clean.split('@').first;
    String targetId = clean;
    String accessToken = '';
    String refreshToken = '';

    // 1. Check LocalStorageService accounts first
    try {
      final localAccs = LocalStorageService.getAccounts();
      for (final a in localAccs) {
        if (a.id.toLowerCase() == clean || a.email.toLowerCase() == clean || a.username.toLowerCase() == clean) {
          targetEmail = a.email.toLowerCase();
          targetName = a.displayName.isNotEmpty ? a.displayName : a.name;
          targetId = a.id;
          accessToken = a.token ??
              LocalStorageService.getAccountToken(a.id) ??
              LocalStorageService.getString('token_${a.email.toLowerCase()}') ??
              '';
          break;
        }
      }
    } catch (_) {}

    // 2. Check saved registry
    final accounts = await getSavedAccountsFromRegistry();
    final target = accounts.firstWhere(
      (a) => (a['email']?.toString() ?? '').toLowerCase() == clean ||
             (a['id']?.toString() ?? '').toLowerCase() == clean,
      orElse: () => {},
    );
    if (target.isNotEmpty) {
      targetEmail = target['email']?.toString() ?? targetEmail;
      targetName = target['name']?.toString() ?? targetName;
      targetId = target['id']?.toString() ?? targetId;
      if (accessToken.isEmpty) {
        accessToken = target['accessToken']?.toString() ?? '';
      }
      if (refreshToken.isEmpty) {
        refreshToken = target['refreshToken']?.toString() ?? '';
      }
    }

    // 3. Fallback to settings cache
    if (accessToken.isEmpty) {
      final s = await getUserSettings(targetEmail);
      if (s != null) {
        accessToken = s['accessToken']?.toString() ?? s['token']?.toString() ?? '';
        refreshToken = s['refreshToken']?.toString() ?? '';
      }
    }

    if (accessToken.isNotEmpty) {
      await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      cachedAccessToken = accessToken;
      try {
        await LocalStorageService.setString('access_token', accessToken);
        await LocalStorageService.setString('active_email', targetEmail);
        await LocalStorageService.setSelectedAccountId(targetId);
        await LocalStorageService.setAccountToken(targetId, accessToken);
        await LocalStorageService.setString('token_$targetEmail', accessToken);
      } catch (_) {}
    }

    await _safeWrite(key: _kEmail, value: targetEmail);
    await _safeWrite(key: _kName, value: targetName);

    final updated = accounts.map((acc) {
      final accEmail = (acc['email']?.toString() ?? '').toLowerCase();
      final accId = (acc['id']?.toString() ?? '').toLowerCase();
      final isMatch = accEmail == targetEmail || accId == targetId;
      return {...acc, 'isPrimary': isMatch};
    }).toList();
    await _safeWrite(key: _kSavedAccountsRegistry, value: jsonEncode(updated));
  }

  // ── Business Onboarding ────────────────────────────────────────────────────

  static Future<void> setBusinessOnboardingCompleted(
    String email, {
    bool completed = true,
  }) async {
    final clean = email.trim().toLowerCase();
    if (clean.isNotEmpty) {
      await _safeWrite(key: _kBizOnboardedKey(clean), value: completed ? 'true' : 'false');
    }
  }

  static Future<bool> isBusinessOnboardingCompleted(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return false;
    final val = await _safeRead(key: _kBizOnboardedKey(clean));
    return val == 'true';
  }
}

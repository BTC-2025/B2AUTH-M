import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/storage_account_model.dart';

/// Secure token & multi-account session persistence manager for the Storage suite.
/// Works out-of-the-box across macOS, Windows, Linux, Android, iOS, and Web.
/// Automatically resolves active BNX sessions and per-account tokens from local stores.
class TokenService {
  static const _kAccess = 'bnx_access_token';
  static const _kRefresh = 'bnx_refresh_token';
  static const _kEmail = 'bnx_user_email';
  static const _kName = 'bnx_user_name';
  static const _kAvatar = 'bnx_user_avatar';
  static const _kSavedAccountsRegistry = 'bnx_saved_accounts_registry';

  static String? cachedAccessToken;
  static String? cachedEmail;

  // ── Resilient Fallback Storage ───────────────────────────────────────────
  static final Map<String, String> _memoryFallback = {};
  static bool _fallbackLoaded = false;
  static DateTime? _lastFileLoadTime;

  static Directory? _getBaseDir() {
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
      return baseDir;
    } catch (_) {
      return null;
    }
  }

  static File? _resolveFallbackFile() {
    final baseDir = _getBaseDir();
    if (baseDir == null) return null;
    return File('${baseDir.path}/.bnx_storage_store.json');
  }

  static File? _resolveMainAppStoreFile() {
    final baseDir = _getBaseDir();
    if (baseDir == null) return null;
    return File('${baseDir.path}/.bnx_local_store.json');
  }

  static void _ensureFallbackLoaded({bool forceReload = false}) {
    final now = DateTime.now();
    if (_fallbackLoaded && !forceReload) {
      if (_lastFileLoadTime != null &&
          now.difference(_lastFileLoadTime!).inSeconds < 2) {
        return;
      }
    }
    _fallbackLoaded = true;
    _lastFileLoadTime = now;
    try {
      // 1. Read main app store (.bnx_local_store.json) for shared active credentials
      final mainFile = _resolveMainAppStoreFile();
      if (mainFile != null && mainFile.existsSync()) {
        final content = mainFile.readAsStringSync();
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
        _memoryFallback.remove(_kAvatar);
      }

      // 2. Overlay storage-specific store (.bnx_storage_store.json)
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
        _memoryFallback.remove(_kAvatar);
      }
    } catch (_) {}
  }

  static void _persistFallback() {
    try {
      final file = _resolveFallbackFile();
      if (file != null) {
        file.writeAsStringSync(jsonEncode(_memoryFallback), flush: true);
      }
    } catch (_) {}
  }

  static Future<void> _writeKey(String key, String value) async {
    _ensureFallbackLoaded();
    _memoryFallback[key] = value;
    _persistFallback();
  }

  static Future<String?> _readKey(String key) async {
    _ensureFallbackLoaded(forceReload: true);
    return _memoryFallback[key];
  }

  static Future<void> _deleteKey(String key) async {
    _ensureFallbackLoaded();
    _memoryFallback.remove(key);
    _persistFallback();
  }

  // ── Token Expiration Validation ──────────────────────────────────────────

  static String? getEmailFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decodedBytes = base64Decode(normalized);
      final payload = jsonDecode(utf8.decode(decodedBytes));
      if (payload is Map) {
        return (payload['sub'] ?? payload['email'] ?? payload['username'])?.toString();
      }
    } catch (_) {}
    return null;
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

  // ── Public Accessors with Multi-Account Awareness ────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? email,
  }) async {
    cachedAccessToken = accessToken;
    await _writeKey(_kAccess, accessToken);
    if (refreshToken != null) {
      await _writeKey(_kRefresh, refreshToken);
    }
    if (email != null && email.isNotEmpty) {
      final clean = email.trim().toLowerCase();
      cachedEmail = clean;
      await _writeKey(_kEmail, clean);
      await _writeKey('active_email', clean);
      await _writeKey('token_$clean', accessToken);
    }
  }

  /// Resolves the valid access token for [forEmail] or active account.
  static Future<String?> getAccessToken([String? forEmail]) async {
    _ensureFallbackLoaded(forceReload: true);

    String? cleanEmail = forEmail?.trim().toLowerCase();
    if (cleanEmail == null || cleanEmail.isEmpty) {
      final active = _memoryFallback['active_email'] ?? _memoryFallback[_kEmail];
      if (active != null && active.trim().isNotEmpty) {
        cleanEmail = active.trim().toLowerCase();
      }
    }

    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      // 1. Check direct account token key
      final directKey = 'token_$cleanEmail';
      if (_memoryFallback.containsKey(directKey)) {
        final tok = _memoryFallback[directKey];
        if (!isTokenExpired(tok)) {
          return tok;
        }
      }

      // 2. Search bnx_saved_accounts_registry
      if (_memoryFallback.containsKey(_kSavedAccountsRegistry)) {
        try {
          final regRaw = _memoryFallback[_kSavedAccountsRegistry];
          if (regRaw != null && regRaw.isNotEmpty) {
            final regList = jsonDecode(regRaw);
            if (regList is List) {
              for (final item in regList) {
                if (item is Map) {
                  final itemEmail = (item['email']?.toString() ?? '').trim().toLowerCase();
                  final itemTok = item['accessToken']?.toString();
                  if (itemEmail == cleanEmail && itemTok != null && !isTokenExpired(itemTok)) {
                    return itemTok;
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      // 3. Search user settings key
      final settingsKey = 'bnx_user_settings_$cleanEmail';
      if (_memoryFallback.containsKey(settingsKey)) {
        try {
          final setRaw = _memoryFallback[settingsKey];
          if (setRaw != null && setRaw.isNotEmpty) {
            final setData = jsonDecode(setRaw);
            if (setData is Map) {
              final tok = setData['accessToken']?.toString() ?? setData['token']?.toString();
              if (tok != null && !isTokenExpired(tok)) {
                return tok;
              }
            }
          }
        } catch (_) {}
      }

      // If a specific email was requested and not found above, don't bleed another account's token
      if (forEmail != null && forEmail.trim().isNotEmpty) {
        // 1. Check if the active email in LocalStorageService or memory matches cleanEmail
        final activeEmail = (await getUserEmail())?.trim().toLowerCase();
        if (activeEmail != null && activeEmail.isNotEmpty && activeEmail == cleanEmail) {
          final candidate = _memoryFallback['access_token'] ??
              _memoryFallback[_kAccess] ??
              cachedAccessToken;
          if (candidate != null && !isTokenExpired(candidate)) {
            cachedAccessToken = candidate;
            return candidate;
          }
        }

        // 2. Check if default/cached token subject matches cleanEmail
        final generalToken = _memoryFallback['access_token'] ??
            _memoryFallback[_kAccess] ??
            cachedAccessToken;
        if (generalToken != null && !isTokenExpired(generalToken)) {
          final tokSub = getEmailFromToken(generalToken)?.trim().toLowerCase();
          if (tokSub != null && (tokSub == cleanEmail || tokSub.split('@').first == cleanEmail.split('@').first)) {
            cachedAccessToken = generalToken;
            return generalToken;
          }
        }

        return null;
      }
    }

    // Default fallback: active token key
    if (_memoryFallback.containsKey('access_token')) {
      final tok = _memoryFallback['access_token'];
      if (!isTokenExpired(tok)) return tok;
    }
    if (_memoryFallback.containsKey(_kAccess)) {
      final tok = _memoryFallback[_kAccess];
      if (!isTokenExpired(tok)) return tok;
    }

    if (cachedAccessToken != null && !isTokenExpired(cachedAccessToken)) {
      return cachedAccessToken;
    }
    return null;
  }

  static Future<String?> getRefreshToken() async => _readKey(_kRefresh);

  static Future<void> saveUserEmail(String email) async {
    final clean = email.trim().toLowerCase();
    cachedEmail = clean;
    await _writeKey(_kEmail, clean);
    await _writeKey('active_email', clean);
  }

  static Future<String?> getUserEmail([String? forEmail]) async {
    if (forEmail != null && forEmail.trim().isNotEmpty) {
      return forEmail.trim().toLowerCase();
    }
    final email = await _readKey('active_email') ?? await _readKey(_kEmail);
    if (email != null && email.trim().isNotEmpty) return email.trim().toLowerCase();
    return cachedEmail;
  }

  static String? get activeEmailSynchronous {
    _ensureFallbackLoaded();
    final active = _memoryFallback['active_email'] ?? _memoryFallback[_kEmail];
    if (active != null && active.trim().isNotEmpty) return active.trim().toLowerCase();
    return cachedEmail;
  }

  static String? getUserNameSynchronous([String? forEmail]) {
    _ensureFallbackLoaded();
    final cleanEmail = forEmail?.trim().toLowerCase();
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      final settingsKey = 'bnx_user_settings_$cleanEmail';
      if (_memoryFallback.containsKey(settingsKey)) {
        try {
          final setData = jsonDecode(_memoryFallback[settingsKey]!);
          if (setData is Map) {
            final name = setData['name']?.toString() ??
                setData['fullName']?.toString() ??
                setData['displayName']?.toString();
            if (name != null && name.isNotEmpty) return name;
          }
        } catch (_) {}
      }
    }
    final name = _memoryFallback[_kName];
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  static Future<void> saveUserName(String name) async => _writeKey(_kName, name);

  static Future<String?> getUserName([String? forEmail]) async {
    _ensureFallbackLoaded();
    final cleanEmail = forEmail?.trim().toLowerCase();
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      final settingsKey = 'bnx_user_settings_$cleanEmail';
      if (_memoryFallback.containsKey(settingsKey)) {
        try {
          final setData = jsonDecode(_memoryFallback[settingsKey]!);
          if (setData is Map) {
            final name = setData['name']?.toString() ??
                setData['fullName']?.toString() ??
                setData['displayName']?.toString();
            if (name != null && name.isNotEmpty) return name;
          }
        } catch (_) {}
      }
    }
    final name = await _readKey(_kName);
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  static Future<void> saveUserAvatar(String avatarUrl, [String? forEmail]) async {
    final cleanEmail = forEmail?.trim().toLowerCase();
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      if (avatarUrl.isNotEmpty) {
        await _writeKey('bnx_user_avatar_$cleanEmail', avatarUrl);
      } else {
        await _deleteKey('bnx_user_avatar_$cleanEmail');
      }
    }
    await _deleteKey(_kAvatar);
  }

  static Future<String?> getUserAvatar([String? forEmail]) async {
    _ensureFallbackLoaded();
    final cleanEmail = forEmail?.trim().toLowerCase();
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      final key = 'bnx_user_avatar_$cleanEmail';
      if (_memoryFallback.containsKey(key)) {
        final val = _memoryFallback[key];
        return (val != null && val.isNotEmpty) ? val : null;
      }
      return null;
    }
    return null;
  }

  /// Lists all logged in accounts stored in the local registry
  static Future<List<StorageAccountModel>> getSavedAccounts() async {
    _ensureFallbackLoaded(forceReload: true);
    final List<StorageAccountModel> accounts = [];
    final seenEmails = <String>{};

    if (_memoryFallback.containsKey(_kSavedAccountsRegistry)) {
      try {
        final regRaw = _memoryFallback[_kSavedAccountsRegistry];
        if (regRaw != null && regRaw.isNotEmpty) {
          final regList = jsonDecode(regRaw);
          if (regList is List) {
            for (final item in regList) {
              if (item is Map) {
                final email = (item['email']?.toString() ?? '').trim();
                if (email.isNotEmpty && !seenEmails.contains(email.toLowerCase())) {
                  seenEmails.add(email.toLowerCase());
                  final name = item['name']?.toString() ?? email.split('@').first;
                  final avatar = item['avatarUrl']?.toString();
                  accounts.add(StorageAccountModel(
                    id: email,
                    name: name,
                    email: email,
                    avatarUrl: (avatar != null && avatar.isNotEmpty) ? avatar : null,
                  ));
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    if (accounts.isEmpty) {
      final activeEmail = await getUserEmail();
      if (activeEmail != null && activeEmail.isNotEmpty) {
        accounts.add(StorageAccountModel(
          id: activeEmail,
          name: await getUserName(activeEmail) ?? activeEmail.split('@').first,
          email: activeEmail,
          avatarUrl: await getUserAvatar(activeEmail),
        ));
      }
    }

    return accounts;
  }

  /// Switches active session to [email] and persists it
  static Future<void> switchActiveAccount(String email) async {
    final clean = email.trim().toLowerCase();
    cachedEmail = clean;
    await _writeKey('active_email', clean);
    await _writeKey(_kEmail, clean);

    final tok = await getAccessToken(clean);
    if (tok != null && tok.isNotEmpty) {
      cachedAccessToken = tok;
      await _writeKey('access_token', tok);
      await _writeKey(_kAccess, tok);
    }
  }

  static Future<void> clearAll() async {
    cachedAccessToken = null;
    cachedEmail = null;
    await _deleteKey(_kAccess);
    await _deleteKey(_kRefresh);
    await _deleteKey(_kEmail);
    await _deleteKey(_kName);
    await _deleteKey(_kAvatar);
  }
}

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/storage_quota.dart';

class StorageDebug {
  static final List<String> logs = [];
  static void log(String s) {
    logs.add(s);
    print(s);
  }
}

/// Repository for handling real-time storage quota APIs with per-account routing.
class StorageRepository {
  static final Map<String, Future<StorageQuota>> _inFlightByEmail = {};

  /// Resets in-flight request guard (used on account switch).
  static void resetInFlight([String? accountEmail]) {
    if (accountEmail != null) {
      _inFlightByEmail.remove(accountEmail.trim().toLowerCase());
    } else {
      _inFlightByEmail.clear();
    }
  }

  /// Fetches real-time mailbox quota from GET /api/mail/storage-quota for [accountEmail]
  /// Deduplicates concurrent requests per account so only one HTTP request is active at a time.
  static Future<StorageQuota> fetchStorageQuota([String? accountEmail]) async {
    final key = (accountEmail ?? '').trim().toLowerCase();
    if (_inFlightByEmail.containsKey(key)) {
      StorageDebug.log('[STORAGE] Duplicate request prevented for $key');
      return _inFlightByEmail[key]!;
    }
    final future = _performFetch(accountEmail);
    _inFlightByEmail[key] = future;
    try {
      return await future;
    } finally {
      _inFlightByEmail.remove(key);
    }
  }

  static Future<StorageQuota> _performFetch([String? accountEmail]) async {
    StorageDebug.log('[STORAGE] Fetching storage quota for ${accountEmail ?? "active account"}...');
    try {
      final res = await ApiClient.get(
        '/api/mail/storage-quota',
        accountEmail: accountEmail,
      );
      final bool success = res['success'] == true;
      final dynamic data = res['data'];

      if (!success || data is! Map<String, dynamic>) {
        // Some backends return the data directly at top level
        if (res.containsKey('storageLimit') || res.containsKey('storageUsed')) {
          final quota = StorageQuota.fromJson(res);
          StorageDebug.log('[STORAGE] Quota loaded directly: ${quota.storageUsed}/${quota.storageLimit}');
          return quota;
        }
        throw ApiException(
          statusCode: 200,
          message: res['message']?.toString() ?? 'Invalid storage quota response',
        );
      }

      final quota = StorageQuota.fromJson(data);
      StorageDebug.log('[STORAGE] Quota loaded for ${quota.email}');
      StorageDebug.log('[STORAGE] Used: ${quota.storageUsed} bytes');
      StorageDebug.log('[STORAGE] Limit: ${quota.storageLimit} bytes');
      StorageDebug.log('[STORAGE] Percentage: ${quota.storagePercentage}%');
      return quota;
    } catch (e) {
      StorageDebug.log('[STORAGE ERROR] Failed to fetch storage quota: $e');
      rethrow;
    }
  }

  /// Backward compatibility alias
  static Future<StorageQuota> getStorageQuota([String? accountEmail]) => fetchStorageQuota(accountEmail);
}

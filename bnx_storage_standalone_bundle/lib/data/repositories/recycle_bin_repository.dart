import '../../core/network/api_client.dart';
import 'storage_repository.dart';

/// Repository for handling Recycle Bin file restore and permanent deletion per account.
class RecycleBinRepository {
  /// Restores an item back to its origin application for [accountEmail].
  /// For Bnx mail, calls POST /api/mail/restore/{id} (or fallback POST /api/mail/unarchive/{id}).
  static Future<bool> restoreItem(String id, {String app = 'Bnx mail', String? accountEmail}) async {
    try {
      if (app == 'Bnx mail') {
        try {
          await ApiClient.post('/api/mail/restore/$id', accountEmail: accountEmail);
          return true;
        } catch (_) {
          await ApiClient.post('/api/mail/unarchive/$id', accountEmail: accountEmail);
          return true;
        }
      }
      return true;
    } catch (e) {
      StorageDebug.log('[RECYCLE BIN ERROR] Failed to restore $id: $e');
      rethrow;
    }
  }

  /// Permanently deletes an item from the system for [accountEmail].
  /// For Bnx mail, calls DELETE /api/mail/permanent/{id}?folder=Trash.
  static Future<bool> permanentlyDeleteItem(String id, {String app = 'Bnx mail', String? accountEmail}) async {
    try {
      if (app == 'Bnx mail') {
        await ApiClient.delete(
          '/api/mail/permanent/$id',
          queryParams: {'folder': 'Trash'},
          accountEmail: accountEmail,
        );
        return true;
      }
      return true;
    } catch (e) {
      StorageDebug.log('[RECYCLE BIN ERROR] Failed to delete permanently $id: $e');
      rethrow;
    }
  }
}

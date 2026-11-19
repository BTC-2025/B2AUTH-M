import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/token_service.dart';
import '../../models/storage_account_model.dart';

class StorageAccountNotifier extends StateNotifier<StorageAccountModel> {
  bool _manuallySet = false;

  StorageAccountNotifier() : super(_initialAccount()) {
    _loadFromTokenService();
  }

  static StorageAccountModel _initialAccount() {
    final email = TokenService.activeEmailSynchronous ?? '';
    final name = TokenService.getUserNameSynchronous(email) ??
        (email.isNotEmpty ? email.split('@').first : 'User');
    return StorageAccountModel(
      id: email,
      email: email,
      name: name,
    );
  }

  Future<void> _loadFromTokenService() async {
    try {
      final email = await TokenService.getUserEmail();
      if (_manuallySet) return;
      if (email != null && email.isNotEmpty) {
        final name = await TokenService.getUserName(email);
        final avatar = await TokenService.getUserAvatar(email);
        if (_manuallySet) return;
        state = state.copyWith(
          id: email,
          email: email,
          name: (name != null && name.isNotEmpty) ? name : email.split('@').first,
          avatarUrl: avatar,
        );
      }
    } catch (_) {}
  }

  void updateAccount({required String email, String? name, String? avatarUrl}) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;
    _manuallySet = true;
    state = state.copyWith(
      id: cleanEmail,
      email: cleanEmail,
      name: name ?? cleanEmail.split('@').first,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> switchAccount(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return;
    _manuallySet = true;
    await TokenService.switchActiveAccount(clean);
    final name = await TokenService.getUserName(clean);
    final avatar = await TokenService.getUserAvatar(clean);
    updateAccount(
      email: clean,
      name: (name != null && name.isNotEmpty) ? name : clean.split('@').first,
      avatarUrl: avatar,
    );
  }
}

final activeAccountProvider =
    StateNotifierProvider<StorageAccountNotifier, StorageAccountModel>((ref) {
  return StorageAccountNotifier();
});

/// Lists all saved user accounts for account switcher menu
final savedAccountsProvider = FutureProvider<List<StorageAccountModel>>((ref) async {
  return TokenService.getSavedAccounts();
});

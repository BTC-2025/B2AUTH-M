import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vault_file.dart';
import '../repositories/vault_repository.dart';
import 'storage_account_provider.dart';

class VaultFilesNotifier extends StateNotifier<AsyncValue<List<VaultFile>>> {
  final Ref _ref;
  String? _currentEmail;

  VaultFilesNotifier(this._ref) : super(const AsyncValue.loading()) {
    final initial = _ref.read(activeAccountProvider).email;
    _currentEmail = initial.isNotEmpty ? initial : null;
    loadFiles(_currentEmail);
  }

  Future<void> loadFiles([String? accountEmail]) async {
    final targetEmail = (accountEmail != null && accountEmail.trim().isNotEmpty)
        ? accountEmail.trim().toLowerCase()
        : (_currentEmail ?? _ref.read(activeAccountProvider).email.trim().toLowerCase());

    if (targetEmail.isNotEmpty) {
      _currentEmail = targetEmail;
    }

    try {
      final files = await VaultRepository.listVaultFiles(targetEmail.isNotEmpty ? targetEmail : null);
      if (mounted) {
        state = AsyncValue.data(files);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await loadFiles(_currentEmail);
  }

  Future<void> onAccountSwitched(String newEmail) async {
    final clean = newEmail.trim().toLowerCase();
    _currentEmail = clean;
    state = const AsyncValue.loading();
    await loadFiles(clean);
  }

  Future<void> deleteFile(int id) async {
    final prev = state.valueOrNull ?? [];
    try {
      await VaultRepository.deleteVaultFile(id, _currentEmail);
      if (mounted) {
        state = AsyncValue.data(prev.where((f) => f.id != id).toList());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadFile(String path) async {
    try {
      final newFile = await VaultRepository.uploadVaultFile(path, _currentEmail);
      final current = state.valueOrNull ?? [];
      if (mounted) {
        state = AsyncValue.data([newFile, ...current]);
      }
    } catch (e) {
      rethrow;
    }
  }
}

final vaultFilesProvider =
    StateNotifierProvider<VaultFilesNotifier, AsyncValue<List<VaultFile>>>((ref) {
  final notifier = VaultFilesNotifier(ref);

  ref.listen<String>(
    activeAccountProvider.select((a) => a.email),
    (previous, next) {
      if (previous != next && next.isNotEmpty) {
        notifier.onAccountSwitched(next);
      }
    },
  );

  return notifier;
});

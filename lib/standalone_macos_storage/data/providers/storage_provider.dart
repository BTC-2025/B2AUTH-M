import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/storage_quota.dart';
import '../repositories/storage_repository.dart';
import 'storage_account_provider.dart';

class StorageQuotaNotifier extends StateNotifier<AsyncValue<StorageQuota>> {
  static StorageQuotaNotifier? instance;
  final Ref _ref;
  bool _isFetching = false;
  String? _currentEmail;

  StorageQuotaNotifier(this._ref) : super(const AsyncValue.loading()) {
    instance = this;
    StorageDebug.log('[STORAGE NOTIFIER] Initialized in constructor');
    final active = _ref.read(activeAccountProvider);
    if (active.email.isNotEmpty) {
      _currentEmail = active.email;
    }
    fetchQuota(_currentEmail);
  }

  @override
  void dispose() {
    StorageDebug.log('[STORAGE NOTIFIER] DISPOSE CALLED, mounted=$mounted');
    if (instance == this) instance = null;
    super.dispose();
  }

  Future<void> fetchQuota([String? accountEmail]) async {
    final targetEmail = (accountEmail != null && accountEmail.trim().isNotEmpty)
        ? accountEmail.trim().toLowerCase()
        : (_currentEmail ?? _ref.read(activeAccountProvider).email.trim().toLowerCase());

    if (targetEmail.isNotEmpty) {
      _currentEmail = targetEmail;
    }

    if (_isFetching) {
      StorageDebug.log('[STORAGE] Duplicate request prevented');
      return;
    }
    _isFetching = true;
    if (state.hasValue && state.valueOrNull != null) {
      state = AsyncLoading<StorageQuota>().copyWithPrevious(state);
    } else {
      state = const AsyncValue.loading();
    }
    try {
      final quota = await StorageRepository.fetchStorageQuota(targetEmail.isNotEmpty ? targetEmail : null);
      if (mounted) {
        state = AsyncValue.data(quota);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    if (_isFetching) {
      StorageDebug.log('[STORAGE] Duplicate request prevented');
      return;
    }
    await fetchQuota(_currentEmail);
  }

  Future<void> onAccountSwitched(String newEmail) async {
    final clean = newEmail.trim().toLowerCase();
    StorageDebug.log('[STORAGE] Account switch detected ($clean), resetting quota');
    _currentEmail = clean;
    state = const AsyncValue.loading();
    _isFetching = false;
    StorageRepository.resetInFlight(clean);
    await fetchQuota(clean);
  }
}

final storageQuotaProvider =
    StateNotifierProvider<StorageQuotaNotifier, AsyncValue<StorageQuota>>((ref) {
  final notifier = StorageQuotaNotifier(ref);

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

import 'package:flutter/material.dart';
import '../models/user_account.dart';
import '../services/local_storage_service.dart';
import '../services/user_profile_api_service.dart';
import '../../manage_account_api_bundle/core/network/token_service.dart';

class AccountProvider with ChangeNotifier {
  List<UserAccount> _accounts = [];
  UserAccount? _selectedAccount;
  final UserProfileApiService _profileApiService = UserProfileApiService();

  List<UserAccount> get accounts => _accounts;
  UserAccount? get selectedAccount => _selectedAccount;

  AccountProvider() {
    _loadAccounts();
  }

  bool _isSameAccount(UserAccount a, UserAccount b) {
    if (a.id.isNotEmpty && b.id.isNotEmpty && a.id == b.id) return true;
    final aEmail = a.email.trim().toLowerCase();
    final bEmail = b.email.trim().toLowerCase();
    if (aEmail.isNotEmpty && bEmail.isNotEmpty && aEmail == bEmail) return true;
    return false;
  }

  void _deduplicateAccounts() {
    final List<UserAccount> unique = [];
    for (var acc in _accounts) {
      final existingIndex = unique.indexWhere((u) => _isSameAccount(u, acc));
      if (existingIndex == -1) {
        unique.add(acc);
      } else {
        final existing = unique[existingIndex];
        if (acc.isPrimary && !existing.isPrimary) {
          unique[existingIndex] = acc;
        } else if (acc.lastUsed.isAfter(existing.lastUsed)) {
          unique[existingIndex] = acc;
        }
      }
    }
    _accounts = unique;
  }

  void _loadAccounts() {
    _accounts = LocalStorageService.getAccounts();
    _deduplicateAccounts();
    for (var acc in _accounts) {
      if (acc.token == null || acc.token!.isEmpty) {
        final savedTok = LocalStorageService.getAccountToken(acc.id) ??
            LocalStorageService.getString('token_${acc.id}') ??
            LocalStorageService.getString('token_${acc.email.toLowerCase()}');
        if (savedTok != null && savedTok.isNotEmpty) {
          acc.token = savedTok;
        }
      }
    }
    LocalStorageService.saveAccounts(_accounts);

    if (_accounts.isNotEmpty) {
      final selectedId = LocalStorageService.getSelectedAccountId();
      if (selectedId != null && _accounts.any((a) => a.id == selectedId)) {
        _selectedAccount = _accounts.firstWhere((a) => a.id == selectedId);
      } else {
        _selectedAccount = _accounts.firstWhere((a) => a.isPrimary, orElse: () => _accounts.first);
      }
    } else {
      _selectedAccount = null;
    }
    notifyListeners();
  }

  /// Sync real-time profile details from GET /users/me and GET /users/recovery
  Future<void> fetchProfileFromApi(String token, {String? targetAccountId}) async {
    if (token.isEmpty) return;

    try {
      UserAccount? target;
      if (targetAccountId != null && targetAccountId.isNotEmpty) {
        final idx = _accounts.indexWhere((a) => a.id == targetAccountId);
        if (idx != -1) target = _accounts[idx];
      }
      target ??= _selectedAccount;
      if (target == null) return;

      // 1. GET /users/me
      final meRes = await _profileApiService.fetchCurrentUser(accessToken: token);
      if (meRes.success && meRes.data is Map<String, dynamic>) {
        final data = meRes.data as Map<String, dynamic>;
        final apiEmail = data['email']?.toString().trim().toLowerCase();

        // Safety guard: only apply if apiEmail matches target.email (or if target.email is empty)
        if (target.email.isEmpty ||
            apiEmail == null ||
            apiEmail.isEmpty ||
            apiEmail == target.email.trim().toLowerCase()) {
          final String firstName = data['firstName'] ?? '';
          final String lastName = data['lastName'] ?? '';
          final String fullName = ('$firstName $lastName').trim();
          if (fullName.isNotEmpty) {
            target.name = fullName;
            target.displayName = fullName;
          } else if (data['displayName'] != null &&
              data['displayName'].toString().isNotEmpty) {
            target.displayName = data['displayName'].toString();
          }

          if (target.email.isEmpty && apiEmail != null && apiEmail.isNotEmpty) {
            target.email = apiEmail;
          }

          String? resolvedPic;
          final pp = data['profilePicture']?.toString();
          if (pp != null && pp.isNotEmpty && pp != 'null') {
            if (pp.startsWith('data:image') || pp.contains(';base64,')) {
              resolvedPic = pp;
            } else if (pp.length > 100 && !pp.startsWith('/') && !pp.startsWith('http')) {
              resolvedPic = pp.startsWith('data:') ? pp : 'data:image/png;base64,$pp';
            }
          }
          if (resolvedPic == null) {
            final av = data['avatarUrl']?.toString() ?? data['avatar']?.toString();
            if (av != null && av.isNotEmpty && av != 'null') {
              resolvedPic = av;
            }
          }
          if (resolvedPic == null) {
            final ppUrl = data['profilePictureUrl']?.toString();
            if (ppUrl != null && ppUrl.isNotEmpty && ppUrl != 'null') {
              resolvedPic = ppUrl;
            }
          }

          if (resolvedPic != null &&
              resolvedPic.isNotEmpty &&
              resolvedPic != 'null') {
            final String fullPicUrl = (resolvedPic.startsWith('http') || resolvedPic.startsWith('data:'))
                ? resolvedPic
                : 'https://api.bnxmail.com${resolvedPic.startsWith('/') ? '' : '/'}$resolvedPic';
            target.avatarUrl = fullPicUrl;
          } else {
            target.avatarUrl = null;
          }

          if (data['accountType'] != null) {
            final String typeStr = data['accountType'].toString().toUpperCase();
            target.type = (typeStr == 'BUSINESS' || typeStr == 'ORG_ADMIN')
                ? AccountType.business
                : AccountType.personal;
          }
        }
      }

      // 2. GET /users/recovery
      final recRes = await _profileApiService.fetchRecoveryOptions(accessToken: token);
      if (recRes.success && recRes.data is Map<String, dynamic>) {
        final recData = recRes.data as Map<String, dynamic>;
        final recEmail = recData['recoveryEmail']?.toString();
        final phone = recData['phoneNumber']?.toString();
        if (recEmail != null && recEmail.isNotEmpty) {
          target.recoveryEmail = recEmail;
          LocalStorageService.setString('recovery_email_${target.id}', recEmail);
        }
        if (phone != null && phone.isNotEmpty) {
          target.phoneNumber = phone;
          LocalStorageService.setString('recovery_phone_${target.id}', phone);
        }
      }

      updateAccount(target);
    } catch (e) {
      debugPrint('⚠️ [ACCOUNT PROVIDER] Real-time profile sync note: $e');
    }
  }

  /// Update recovery options via PATCH /users/recovery
  Future<Map<String, dynamic>> updateRecoveryOptions({
    required String token,
    required String recoveryEmail,
    required String phoneNumber,
  }) async {
    final response = await _profileApiService.updateRecoveryOptions(
      accessToken: token,
      recoveryEmail: recoveryEmail,
      phoneNumber: phoneNumber,
    );

    if (_selectedAccount != null) {
      _selectedAccount!.recoveryEmail = recoveryEmail;
      _selectedAccount!.phoneNumber = phoneNumber;
      LocalStorageService.setString('recovery_email_${_selectedAccount!.id}', recoveryEmail);
      LocalStorageService.setString('recovery_phone_${_selectedAccount!.id}', phoneNumber);
      updateAccount(_selectedAccount!);
    }

    return {
      'success': response.success,
      'message': response.message,
    };
  }

  void switchAccount(String id, {dynamic authNotifier}) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _selectedAccount = _accounts[index];
    } else if (_accounts.isNotEmpty) {
      _selectedAccount = _accounts.first;
    } else {
      return;
    }
    _selectedAccount!.lastUsed = DateTime.now();

    final cleanEmail = _selectedAccount!.email.trim().toLowerCase();
    final accountToken = _selectedAccount!.token ??
        LocalStorageService.getAccountToken(_selectedAccount!.id) ??
        LocalStorageService.getString('token_${_selectedAccount!.id}') ??
        (cleanEmail.isNotEmpty ? LocalStorageService.getString('token_$cleanEmail') : null);

    if (accountToken != null && accountToken.isNotEmpty) {
      _selectedAccount!.token = accountToken;
      LocalStorageService.setString('access_token', accountToken);
      if (cleanEmail.isNotEmpty) {
        LocalStorageService.setString('active_email', cleanEmail);
        LocalStorageService.setString('token_$cleanEmail', accountToken);
        TokenService.switchActiveAccountSession(cleanEmail);
      }
      LocalStorageService.setAccountToken(_selectedAccount!.id, accountToken);

      if (authNotifier != null) {
        try {
          authNotifier.loginSuccess(accessToken: accountToken, email: _selectedAccount!.email);
        } catch (_) {}
      }

      fetchProfileFromApi(accountToken, targetAccountId: _selectedAccount!.id);
    }

    LocalStorageService.setSelectedAccountId(_selectedAccount!.id);
    LocalStorageService.saveAccounts(_accounts);
    notifyListeners();
  }

  void updateAccount(UserAccount account) {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      _accounts[index] = account;
    } else {
      _accounts.add(account);
    }
    _deduplicateAccounts();
    LocalStorageService.saveAccounts(_accounts);
    notifyListeners();
  }

  void addAccount(UserAccount account) {
    if (account.avatarUrl == null || account.avatarUrl!.isEmpty) {
      account.avatarUrl = account.effectiveAvatarUrl;
    }
    final cleanEmail = account.email.trim().toLowerCase();
    if (account.token != null && account.token!.isNotEmpty) {
      LocalStorageService.setAccountToken(account.id, account.token!);
      LocalStorageService.setString('token_${account.id}', account.token!);
      if (cleanEmail.isNotEmpty) {
        LocalStorageService.setString('token_$cleanEmail', account.token!);
      }
    } else {
      final existingToken = LocalStorageService.getAccountToken(account.id) ??
          LocalStorageService.getString('token_${account.id}') ??
          (cleanEmail.isNotEmpty ? LocalStorageService.getString('token_$cleanEmail') : null);
      if (existingToken != null && existingToken.isNotEmpty) {
        account.token = existingToken;
        LocalStorageService.setAccountToken(account.id, existingToken);
      }
    }

    // Remove any existing duplicate instances of this account
    _accounts.removeWhere((a) => _isSameAccount(a, account));
    _accounts.add(account);
    _selectedAccount = account;
    _deduplicateAccounts();

    LocalStorageService.setSelectedAccountId(_selectedAccount!.id);
    LocalStorageService.saveAccounts(_accounts);
    notifyListeners();
  }

  void setPrimary(String id) {
    for (var a in _accounts) {
      a.isPrimary = (a.id == id);
    }
    LocalStorageService.saveAccounts(_accounts);
    notifyListeners();
  }

  void clearAccounts() {
    _accounts.clear();
    _selectedAccount = null;
    LocalStorageService.clearAllData();
    notifyListeners();
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    LocalStorageService.saveAccounts(_accounts);
    notifyListeners();
  }

  void updateLocation(String newLocation) {
    if (_selectedAccount != null) {
      _selectedAccount!.location = newLocation;
      updateAccount(_selectedAccount!);
    }
  }
}

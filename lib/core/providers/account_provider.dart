import 'package:flutter/material.dart';
import '../models/user_account.dart';
import '../services/local_storage_service.dart';
import '../services/user_profile_api_service.dart';

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
    if (a.id == b.id) return true;
    final aEmail = a.email.trim().toLowerCase();
    final bEmail = b.email.trim().toLowerCase();
    if (aEmail.isNotEmpty && bEmail.isNotEmpty && aEmail == bEmail) return true;
    final aUname = a.username.trim().toLowerCase();
    final bUname = b.username.trim().toLowerCase();
    if (aUname.isNotEmpty && bUname.isNotEmpty && aUname == bUname) return true;
    final aPrefix = aEmail.contains('@') ? aEmail.split('@').first : aEmail;
    final bPrefix = bEmail.contains('@') ? bEmail.split('@').first : bEmail;
    if (aPrefix.isNotEmpty && bPrefix.isNotEmpty && aPrefix == bPrefix) return true;
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
        } else if (acc.email.contains('@') && !existing.email.contains('@')) {
          unique[existingIndex] = acc;
        } else if (acc.lastUsed.isAfter(existing.lastUsed)) {
          if (existing.email.contains('@') && !acc.email.contains('@')) {
            acc.email = existing.email;
          }
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
      if (acc.avatarUrl == null || acc.avatarUrl!.isEmpty) {
        acc.avatarUrl = acc.effectiveAvatarUrl;
      }
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

  /// Sync real-time profile details from GET /users/me, GET /emails/list, GET /users/recovery
  Future<void> fetchProfileFromApi(String token) async {
    if (token.isEmpty) return;

    try {
      // 1. GET /users/me
      final meRes = await _profileApiService.fetchCurrentUser(accessToken: token);
      if (meRes.success && meRes.data is Map<String, dynamic>) {
        final data = meRes.data as Map<String, dynamic>;
        if (_selectedAccount != null) {
          final String firstName = data['firstName'] ?? '';
          final String lastName = data['lastName'] ?? '';
          final String fullName = ('$firstName $lastName').trim();
          if (fullName.isNotEmpty) {
            _selectedAccount!.name = fullName;
            _selectedAccount!.displayName = fullName;
          }
          if (data['username'] != null) _selectedAccount!.username = data['username'].toString();
          if (data['email'] != null) _selectedAccount!.email = data['email'].toString();

          final String? rawPicUrl = data['profilePictureUrl'] ?? data['avatarUrl'] ?? data['avatar'] ?? data['profilePicture'];
          if (rawPicUrl != null && rawPicUrl.isNotEmpty) {
            final String fullPicUrl = rawPicUrl.startsWith('http')
                ? rawPicUrl
                : 'https://api.bnxmail.com${rawPicUrl.startsWith('/') ? '' : '/'}$rawPicUrl';
            _selectedAccount!.avatarUrl = fullPicUrl;
          } else {
            _selectedAccount!.avatarUrl = _selectedAccount!.effectiveAvatarUrl;
          }

          if (data['accountType'] != null) {
            final String typeStr = data['accountType'].toString().toUpperCase();
            _selectedAccount!.type = typeStr == 'BUSINESS' ? AccountType.business : AccountType.personal;
          }
        }
      }

      // 2. GET /emails/list
      final emailRes = await _profileApiService.fetchUserEmails(accessToken: token);
      if (emailRes.success && emailRes.data is List) {
        final list = emailRes.data as List;
        if (list.isNotEmpty && _selectedAccount != null) {
          final primary = list.firstWhere((e) => e is Map && e['isPrimary'] == true, orElse: () => list.first);
          if (primary is Map && primary['emailId'] != null) {
            _selectedAccount!.email = primary['emailId'].toString();
          }
        }
      }

      // 3. GET /users/recovery
      final recRes = await _profileApiService.fetchRecoveryOptions(accessToken: token);
      if (recRes.success && recRes.data is Map<String, dynamic>) {
        final recData = recRes.data as Map<String, dynamic>;
        if (_selectedAccount != null) {
          final recEmail = recData['recoveryEmail']?.toString();
          final phone = recData['phoneNumber']?.toString();
          if (recEmail != null && recEmail.isNotEmpty) {
            _selectedAccount!.recoveryEmail = recEmail;
            LocalStorageService.setString('recovery_email_${_selectedAccount!.id}', recEmail);
          }
          if (phone != null && phone.isNotEmpty) {
            _selectedAccount!.phoneNumber = phone;
            LocalStorageService.setString('recovery_phone_${_selectedAccount!.id}', phone);
          }
        }
      }

      if (_selectedAccount != null) {
        updateAccount(_selectedAccount!);
      }
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
    _selectedAccount = _accounts.firstWhere(
      (a) => a.id == id,
      orElse: () => _accounts.first,
    );
    _selectedAccount!.lastUsed = DateTime.now();

    final accountToken = _selectedAccount!.token ??
        LocalStorageService.getAccountToken(_selectedAccount!.id) ??
        LocalStorageService.getString('token_${_selectedAccount!.id}') ??
        LocalStorageService.getString('token_${_selectedAccount!.email.toLowerCase()}') ??
        LocalStorageService.getString('token_${_selectedAccount!.username.toLowerCase()}') ??
        LocalStorageService.getString('access_token');

    if (accountToken != null && accountToken.isNotEmpty) {
      _selectedAccount!.token = accountToken;
      LocalStorageService.setString('access_token', accountToken);
      LocalStorageService.setString('active_email', _selectedAccount!.email);
      LocalStorageService.setAccountToken(_selectedAccount!.id, accountToken);
      LocalStorageService.setString('token_${_selectedAccount!.email.toLowerCase()}', accountToken);

      if (authNotifier != null) {
        try {
          authNotifier.loginSuccess(accessToken: accountToken, email: _selectedAccount!.email);
        } catch (_) {}
      }

      fetchProfileFromApi(accountToken);
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
    if (account.token != null && account.token!.isNotEmpty) {
      LocalStorageService.setAccountToken(account.id, account.token!);
      LocalStorageService.setString('token_${account.id}', account.token!);
      LocalStorageService.setString('token_${account.email.toLowerCase()}', account.token!);
    } else {
      final existingToken = LocalStorageService.getAccountToken(account.id) ??
          LocalStorageService.getString('token_${account.id}') ??
          LocalStorageService.getString('token_${account.email.toLowerCase()}') ??
          LocalStorageService.getString('access_token');
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

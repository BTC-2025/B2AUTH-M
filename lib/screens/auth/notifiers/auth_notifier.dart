import 'package:flutter/material.dart';
import '../../../core/services/local_storage_service.dart';

class AuthState {
  final bool isLoggedIn;
  final String? activeEmail;
  final String? accessToken;
  final String? tempToken;

  AuthState({
    this.isLoggedIn = false,
    this.activeEmail,
    this.accessToken,
    this.tempToken,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? activeEmail,
    String? accessToken,
    String? tempToken,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      activeEmail: activeEmail ?? this.activeEmail,
      accessToken: accessToken ?? this.accessToken,
      tempToken: tempToken ?? this.tempToken,
    );
  }
}

class AuthNotifier with ChangeNotifier {
  AuthState _state = AuthState();

  AuthNotifier() {
    _loadPersistedAuth();
  }

  AuthState get state => _state;
  bool get isLoggedIn => _state.isLoggedIn;
  String? get accessToken => _state.accessToken;
  String? get tempToken => _state.tempToken;
  String? get activeEmail => _state.activeEmail;

  void _loadPersistedAuth() {
    final token = LocalStorageService.getString('access_token');
    final email = LocalStorageService.getString('active_email');
    if (token != null && token.isNotEmpty) {
      _state = AuthState(
        isLoggedIn: true,
        accessToken: token,
        activeEmail: email,
      );
      notifyListeners();
    }
  }

  void setTempToken(String tempToken, String email) {
    _state = _state.copyWith(tempToken: tempToken, activeEmail: email);
    LocalStorageService.setString('temp_token', tempToken);
    LocalStorageService.setString('active_email', email);
    notifyListeners();
  }

  void loginSuccess({required String accessToken, required String email}) {
    _state = AuthState(
      isLoggedIn: true,
      accessToken: accessToken,
      activeEmail: email,
    );
    LocalStorageService.setString('access_token', accessToken);
    LocalStorageService.setString('active_email', email);
    notifyListeners();
  }

  void logout() {
    _state = AuthState(isLoggedIn: false);
    LocalStorageService.remove('access_token');
    LocalStorageService.remove('temp_token');
    LocalStorageService.remove('active_email');
    notifyListeners();
  }
}

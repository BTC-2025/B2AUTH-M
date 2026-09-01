import 'package:flutter/material.dart';

enum PasskeyType { biometric, yubikeyUsb, yubikeyNfc, windowsHello }

class PasskeyItem {
  final String id;
  final String name;
  final PasskeyType type;
  final String deviceName;
  final DateTime createdAt;
  DateTime lastUsed;
  bool isSynced;

  PasskeyItem({
    required this.id,
    required this.name,
    required this.type,
    required this.deviceName,
    required this.createdAt,
    required this.lastUsed,
    this.isSynced = true,
  });
}

class PasskeyProvider with ChangeNotifier {
  List<PasskeyItem> _passkeys = [];

  List<PasskeyItem> get passkeys => _passkeys;

  PasskeyProvider() {
    _initSampleKeys();
  }

  void _initSampleKeys() {
    _passkeys = [
      PasskeyItem(
        id: 'pk-1',
        name: 'Primary MacBook TouchID',
        type: PasskeyType.biometric,
        deviceName: 'macOS Monterey',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        lastUsed: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
      PasskeyItem(
        id: 'pk-2',
        name: 'YubiKey 5C NFC (Backup)',
        type: PasskeyType.yubikeyNfc,
        deviceName: 'Hardware Token',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        lastUsed: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PasskeyItem(
        id: 'pk-3',
        name: 'Work Windows Hello',
        type: PasskeyType.windowsHello,
        deviceName: 'Dell XPS 15',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastUsed: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  void addPasskey(String name, PasskeyType type, String deviceName) {
    final newKey = PasskeyItem(
      id: 'pk-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      deviceName: deviceName,
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
      isSynced: true,
    );
    _passkeys.insert(0, newKey);
    notifyListeners();
  }

  void removePasskey(String id) {
    _passkeys.removeWhere((k) => k.id == id);
    notifyListeners();
  }

  void updateLastUsed(String id) {
    final key = _passkeys.firstWhere((k) => k.id == id);
    key.lastUsed = DateTime.now();
    notifyListeners();
  }
}

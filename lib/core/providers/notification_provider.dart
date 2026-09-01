import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/local_storage_service.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  NotificationCategory _filter = NotificationCategory.system; // Default to 'all' logic in UI
  bool _isAscending = false;
  String _searchQuery = '';

  List<NotificationModel> get notifications {
    var filtered = _notifications.where((n) {
      final matchesSearch = n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            n.message.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    filtered.sort((a, b) => _isAscending 
        ? a.timestamp.compareTo(b.timestamp) 
        : b.timestamp.compareTo(a.timestamp));
    
    return filtered;
  }

  NotificationProvider() {
    _loadNotifications();
  }

  void _loadNotifications() {
    // In a real app, load from LocalStorageService. For now, seed realistic data.
    _notifications = [
      NotificationModel(
        id: const Uuid().v4(),
        title: 'MFA RECOVERY',
        message: 'Backup verification codes generated. Store them securely.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        category: NotificationCategory.security,
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'MFA ENABLED',
        message: 'Push notification and biometric authentication enabled.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        category: NotificationCategory.security,
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'PASSWORDLESS SIGN-IN ENABLED',
        message: 'Passwordless sign-in enabled.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        category: NotificationCategory.critical,
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'DEVICE UPDATED',
        message: 'Device "RAVI KUMAR" set as your primary device.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        category: NotificationCategory.devices,
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'DEVICE ADDED',
        message: 'Device "RAVI KUMAR" added to your B2Auth account.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        category: NotificationCategory.devices,
      ),
    ];
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSort() {
    _isAscending = !_isAscending;
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }
}

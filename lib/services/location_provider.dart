import 'package:flutter/material.dart';
import 'location_service.dart';

class LocationProvider with ChangeNotifier {
  UserLocation? _location;
  bool _isLoading = false;
  String? _errorMessage;

  UserLocation? get location => _location;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LocationProvider() {
    _location = UserLocation(
      city: 'Tiruvallur',
      zip: '602001',
      streetAddress: 'Tiruvallur, Tamil Nadu',
      latitude: 13.1438,
      longitude: 79.9083,
    );
  }

  Future<void> detectGPSLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final loc = await LocationService.determinePosition();
      _location = loc;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> searchAndSetLocation(String query) async {
    if (query.trim().isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final loc = await LocationService.searchPosition(query);
      if (loc != null) {
        _location = loc;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Location not found.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to find location.';
      notifyListeners();
      return false;
    }
  }

  void setCustomLocation(UserLocation loc) {
    _location = loc;
    _errorMessage = null;
    notifyListeners();
  }
}


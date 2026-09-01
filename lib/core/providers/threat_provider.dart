import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

enum ThreatLevel { low, medium, high, critical }
enum SensitivityMode { relaxed, balanced, strict }

class ThreatAlert {
  final String id;
  final String title;
  final String description;
  final String location;
  final String ipAddress;
  final ThreatLevel level;
  final DateTime timestamp;
  bool isResolved;

  ThreatAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.ipAddress,
    required this.level,
    required this.timestamp,
    this.isResolved = false,
  });
}

class ThreatProvider with ChangeNotifier {
  int _riskScore = 24; // 0 to 100
  SensitivityMode _sensitivity = SensitivityMode.balanced;
  bool _isQuarantined = false;
  bool _isPanicMode = false;
  List<ThreatAlert> _alerts = [];

  int get riskScore => _riskScore;
  SensitivityMode get sensitivity => _sensitivity;
  bool get isQuarantined => _isQuarantined;
  bool get isPanicMode => _isPanicMode;
  List<ThreatAlert> get alerts => _alerts;

  ThreatLevel get currentRiskLevel {
    if (_riskScore >= 75) return ThreatLevel.critical;
    if (_riskScore >= 50) return ThreatLevel.high;
    if (_riskScore >= 25) return ThreatLevel.medium;
    return ThreatLevel.low;
  }

  ThreatProvider() {
    _initAlerts();
  }

  void _initAlerts() {
    _alerts = [
      ThreatAlert(
        id: 't-1',
        title: 'Impossible Travel Anomaly',
        description: 'Login attempt from Frankfurt 12 mins after Mumbai session.',
        location: 'Frankfurt, Germany',
        ipAddress: '185.220.101.5',
        level: ThreatLevel.high,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      ThreatAlert(
        id: 't-2',
        title: 'Unknown OS Fingerprint',
        description: 'Unrecognized Linux Kernel browser agent accessed OAuth token.',
        location: 'Moscow, Russia',
        ipAddress: '95.173.136.72',
        level: ThreatLevel.medium,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ThreatAlert(
        id: 't-3',
        title: 'Brute-Force Threshold Exceeded',
        description: '5 failed password attempts within 30 seconds.',
        location: 'Manavalanagar, India',
        ipAddress: '49.207.210.14',
        level: ThreatLevel.low,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ];
    _recalculateRiskScore();
  }

  void setSensitivity(SensitivityMode mode) {
    _sensitivity = mode;
    _recalculateRiskScore();
    notifyListeners();
  }

  void toggleQuarantine() {
    _isQuarantined = !_isQuarantined;
    notifyListeners();
  }

  void togglePanicMode() {
    _isPanicMode = !_isPanicMode;
    if (_isPanicMode) {
      _riskScore = 95;
    } else {
      _recalculateRiskScore();
    }
    notifyListeners();
  }

  void resolveAlert(String id) {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alerts[idx].isResolved = true;
      _recalculateRiskScore();
      notifyListeners();
    }
  }

  void _recalculateRiskScore() {
    if (_isPanicMode) return;
    int score = 10;
    for (var alert in _alerts) {
      if (!alert.isResolved) {
        switch (alert.level) {
          case ThreatLevel.critical:
            score += 40;
            break;
          case ThreatLevel.high:
            score += 25;
            break;
          case ThreatLevel.medium:
            score += 15;
            break;
          case ThreatLevel.low:
            score += 5;
            break;
        }
      }
    }
    if (_sensitivity == SensitivityMode.strict) score = (score * 1.3).round();
    if (_sensitivity == SensitivityMode.relaxed) score = (score * 0.8).round();
    _riskScore = score.clamp(0, 100);
  }
}

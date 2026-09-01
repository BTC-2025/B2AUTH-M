import 'package:flutter/material.dart';

enum PolicyAction { allow, requireMfa, requireHardwareKey, deny }

class ZeroTrustPolicy {
  final String id;
  final String name;
  final String conditionIf;
  final PolicyAction actionThen;
  bool isEnabled;
  final String category;

  ZeroTrustPolicy({
    required this.id,
    required this.name,
    required this.conditionIf,
    required this.actionThen,
    this.isEnabled = true,
    required this.category,
  });
}

class ZeroTrustProvider with ChangeNotifier {
  List<ZeroTrustPolicy> _policies = [];
  String _simulationResult = '';

  List<ZeroTrustPolicy> get policies => _policies;
  String get simulationResult => _simulationResult;

  ZeroTrustProvider() {
    _initPolicies();
  }

  void _initPolicies() {
    _policies = [
      ZeroTrustPolicy(
        id: 'zt-1',
        name: 'Untrusted Country Access Guard',
        conditionIf: 'Location outside Home Region (India)',
        actionThen: PolicyAction.requireHardwareKey,
        category: 'Geo Location',
      ),
      ZeroTrustPolicy(
        id: 'zt-2',
        name: 'High AI Risk Score Defense',
        conditionIf: 'AI Threat Score > 60',
        actionThen: PolicyAction.requireMfa,
        category: 'Risk Engine',
      ),
      ZeroTrustPolicy(
        id: 'zt-3',
        name: 'Unrooted / Healthy Device Mandate',
        conditionIf: 'Device OS Integrity Status == Compromised',
        actionThen: PolicyAction.deny,
        category: 'Device Health',
      ),
      ZeroTrustPolicy(
        id: 'zt-4',
        name: 'Off-Hours Admin Action Step-Up',
        conditionIf: 'Access requested between 12 AM - 5 AM',
        actionThen: PolicyAction.requireMfa,
        category: 'Time Window',
      ),
    ];
  }

  void togglePolicy(String id) {
    final policy = _policies.firstWhere((p) => p.id == id);
    policy.isEnabled = !policy.isEnabled;
    notifyListeners();
  }

  void addPolicy(String name, String conditionIf, PolicyAction actionThen, String category) {
    _policies.add(
      ZeroTrustPolicy(
        id: 'zt-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        conditionIf: conditionIf,
        actionThen: actionThen,
        category: category,
      ),
    );
    notifyListeners();
  }

  void deletePolicy(String id) {
    _policies.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void runSimulation({required String location, required int riskScore, required bool isDeviceCompromised}) {
    for (var policy in _policies.where((p) => p.isEnabled)) {
      if (isDeviceCompromised && policy.actionThen == PolicyAction.deny) {
        _simulationResult = '⛔ ACCESS DENIED: Triggered by "${policy.name}"';
        notifyListeners();
        return;
      }
      if (riskScore > 60 && policy.actionThen == PolicyAction.requireMfa) {
        _simulationResult = '⚠️ STEP-UP REQUIRED: Triggered by "${policy.name}" (Require TOTP / Push)';
        notifyListeners();
        return;
      }
      if (location.toLowerCase() != 'india' && policy.actionThen == PolicyAction.requireHardwareKey) {
        _simulationResult = '🔑 HARDWARE KEY REQUIRED: Triggered by "${policy.name}" (Require YubiKey)';
        notifyListeners();
        return;
      }
    }
    _simulationResult = '✅ ACCESS GRANTED: All Zero Trust checks passed cleanly.';
    notifyListeners();
  }
}

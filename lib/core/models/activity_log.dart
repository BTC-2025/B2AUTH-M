enum ActivityStatus { successful, failed, blocked }

class ActivityLog {
  final String id;
  final String deviceName;
  final String country;
  final String ipAddress;
  final String browser;
  final String os;
  final DateTime timestamp;
  final ActivityStatus status;

  ActivityLog({
    required this.id,
    required this.deviceName,
    required this.country,
    required this.ipAddress,
    required this.browser,
    required this.os,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceName': deviceName,
      'country': country,
      'ipAddress': ipAddress,
      'browser': browser,
      'os': os,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'],
      deviceName: map['deviceName'],
      country: map['country'],
      ipAddress: map['ipAddress'],
      browser: map['browser'],
      os: map['os'],
      timestamp: DateTime.parse(map['timestamp']),
      status: ActivityStatus.values[map['status']],
    );
  }
}

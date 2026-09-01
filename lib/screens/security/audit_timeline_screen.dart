import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class AuditTimelineScreen extends StatefulWidget {
  const AuditTimelineScreen({super.key});

  @override
  State<AuditTimelineScreen> createState() => _AuditTimelineScreenState();
}

class _AuditTimelineScreenState extends State<AuditTimelineScreen> {
  double _timeScrubberValue = 30.0; // Days ago scrubber (0 to 30)
  String _selectedSeverity = 'ALL';

  final List<Map<String, dynamic>> _events = [
    {
      'title': 'OAuth 2.0 Token Issued',
      'device': 'Chrome 122 on macOS',
      'ip': '49.207.210.14',
      'location': 'Manavalanagar, India',
      'daysAgo': 0,
      'severity': 'INFO',
      'timestamp': 'Today, 10:24 AM',
    },
    {
      'title': 'TOTP 2FA Verification',
      'device': 'b2auth Mobile App',
      'ip': '49.207.210.14',
      'location': 'Manavalanagar, India',
      'daysAgo': 1,
      'severity': 'INFO',
      'timestamp': 'Yesterday, 04:15 PM',
    },
    {
      'title': 'Suspicious Login Anomaly',
      'device': 'Firefox on Linux (Unknown OS)',
      'ip': '185.220.101.5',
      'location': 'Frankfurt, Germany',
      'daysAgo': 3,
      'severity': 'CRITICAL',
      'timestamp': '3 days ago, 02:40 AM',
    },
    {
      'title': 'Passkey Created (TouchID)',
      'device': 'MacBook Pro',
      'ip': '49.207.210.14',
      'location': 'Manavalanagar, India',
      'daysAgo': 7,
      'severity': 'INFO',
      'timestamp': '7 days ago, 11:10 AM',
    },
    {
      'title': 'Session Terminated Remotely',
      'device': 'Safari on iPhone 15',
      'ip': '103.44.52.1',
      'location': 'Mumbai, India',
      'daysAgo': 14,
      'severity': 'WARNING',
      'timestamp': '14 days ago, 06:30 PM',
    },
  ];

  Color _getSeverityColor(String sev) {
    switch (sev) {
      case 'CRITICAL':
        return AppColors.errorRed;
      case 'WARNING':
        return Colors.orangeAccent;
      default:
        return AppColors.primaryBlue;
    }
  }

  void _showEventDetail(BuildContext context, Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final color = _getSeverityColor(event['severity']);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(20.0),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security_rounded, color: color, size: 28),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          event['title'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Timestamp: ${event['timestamp']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Device & OS: ${event['device']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('IP Address: ${event['ip']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Geo Location: ${event['location']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export Forensic Evidence Report (PDF)'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Forensic Evidence Report exported.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _events.where((e) {
      final matchesDays = (e['daysAgo'] as int) <= _timeScrubberValue.round();
      final matchesSeverity = _selectedSeverity == 'ALL' || e['severity'] == _selectedSeverity;
      return matchesDays && matchesSeverity;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Forensic Audit Timeline'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Scrubber Filter Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scrub Timeline Window', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(
                        'Last ${_timeScrubberValue.round()} Days',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ],
                  ),
                  Slider(
                    value: _timeScrubberValue,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) => setState(() => _timeScrubberValue = val),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ['ALL', 'CRITICAL', 'WARNING', 'INFO'].map((sev) {
                        final selected = _selectedSeverity == sev;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(sev, style: TextStyle(fontSize: 10, color: selected ? Colors.white : AppColors.textPrimary)),
                            selected: selected,
                            selectedColor: AppColors.primaryBlue,
                            onSelected: (val) {
                              if (val) setState(() => _selectedSeverity = sev);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Audit Logs (${filteredEvents.length} records)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Timeline Tree View
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                final sevColor = _getSeverityColor(event['severity']);

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: sevColor, shape: BoxShape.circle),
                          ),
                          Expanded(
                            child: Container(width: 2, color: Colors.grey.withOpacity(0.3)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: () => _showEventDetail(context, event),
                            borderRadius: BorderRadius.circular(12),
                            child: GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          event['title'],
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        event['timestamp'],
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${event['device']} • ${event['location']}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

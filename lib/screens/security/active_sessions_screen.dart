import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/neumorphic_card.dart';
import '../../core/services/security_api_service.dart';
import '../../core/services/local_storage_service.dart';
import '../auth/notifiers/auth_notifier.dart';

class ActiveSessionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialSessions;
  const ActiveSessionsScreen({super.key, required this.initialSessions});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  late List<Map<String, dynamic>> _sessions;
  final SecurityApiService _securityApiService = SecurityApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessions = List.from(widget.initialSessions);
    _refreshSessions();
  }

  Future<void> _refreshSessions() async {
    final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
    if (token.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await _securityApiService.fetchActiveSessions(token);
      if (response.success && response.data is List) {
        final List list = response.data as List;
        setState(() {
          _sessions = list.map<Map<String, dynamic>>((s) {
            return {
              'id': s['id']?.toString() ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
              'name': '${s['deviceInfo'] ?? 'Desktop/Browser'} • ${s['ipAddress'] ?? '192.168.1.1'}',
              'status': 'Last active: ${s['lastActive'] ?? 'Just now'}',
              'icon': (s['deviceInfo']?.toString().toLowerCase().contains('phone') ?? false) ? 'phone' : 'desktop',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error refreshing sessions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _terminateSession(String sessionId) async {
    final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
    await _securityApiService.terminateSession(accessToken: token, sessionId: sessionId);
    setState(() => _sessions.removeWhere((s) => s['id'] == sessionId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session terminated successfully'), backgroundColor: AppColors.primary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Active Sessions', style: AppTextStyles.cardTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(
                  child: Text('No active sessions found.', style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final isCurrent = session['status']?.toString().contains('Current') ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: NeumorphicCard(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCurrent ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                session['icon'] == 'phone' ? Icons.smartphone : Icons.desktop_windows,
                                color: isCurrent ? AppColors.success : AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(session['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(session['status'] ?? '', style: TextStyle(fontSize: 12, color: isCurrent ? AppColors.success : AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            if (!isCurrent)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.error),
                                onPressed: () => _terminateSession(session['id']),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

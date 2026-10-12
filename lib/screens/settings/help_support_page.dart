import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/neumorphic_card.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  bool _shareDiagnostics = true;
  bool _shareEmail = true;
  bool _enableCrashReporting = true;
  bool _shakeToFeedback = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int? _expandedFaqIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do FIDO2 Passkeys & YubiKeys work in B2Auth?',
      'answer':
          'Passkeys replace traditional passwords using WebAuthn/FIDO2 public key cryptography. Your private key remains hardware-isolated inside your YubiKey or device TPM, preventing phishing attacks.',
      'category': 'Passkeys'
    },
    {
      'question': 'What triggers a Zero-Trust Step-Up MFA challenge?',
      'answer':
          'B2Auth continuously evaluates device health, IP risk scores, and geographic geofencing. Connecting from an unverified location or proxy automatically triggers a Step-Up MFA prompt.',
      'category': 'Zero-Trust'
    },
    {
      'question': 'How do I manage or revoke Linked Apps (Bnxmail, cliks)?',
      'answer':
          'Navigate to Dashboard > Linked Apps. You can inspect OAuth 2.0 PKCE tokens, force re-sync sessions, or instantly revoke app access.',
      'category': 'Linked Apps'
    },
    {
      'question': 'What happens during Emergency Panic Lockdown?',
      'answer':
          'Panic Lockdown immediately revokes all active OAuth session tokens across all linked enterprise applications and locks account access to whitelisted IP addresses only.',
      'category': 'Security'
    },
    {
      'question': 'How do I generate backup MFA recovery codes?',
      'answer':
          'Go to Settings > Account Security > Recovery Codes to generate 10 single-use emergency bypass codes.',
      'category': 'Account'
    },
  ];

  void _showActionFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSystemHealthDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.monitor_heart_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('System Health Diagnostics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHealthRow('API Gateway (Asia-South)', '18 ms', 'Optimal', AppColors.success),
              const Divider(height: 20),
              _buildHealthRow('OAuth 2.0 Token Broker', '99.99%', 'Operational', AppColors.success),
              const Divider(height: 20),
              _buildHealthRow('Zero-Trust Geofence Engine', '12 ms', 'Optimal', AppColors.success),
              const Divider(height: 20),
              _buildHealthRow('FIDO2 WebAuthn Relay', '100.0%', 'Operational', AppColors.primary),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String name, String metric, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              Text('Latency/Uptime: $metric', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }

  void _showFaqModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          final filteredFaqs = _faqs.where((f) {
            if (_searchQuery.isEmpty) return true;
            final q = f['question']!.toLowerCase();
            final a = f['answer']!.toLowerCase();
            final c = f['category']!.toLowerCase();
            return q.contains(_searchQuery) || a.contains(_searchQuery) || c.contains(_searchQuery);
          }).toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Knowledge Base & FAQs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setStateModal(() => _searchQuery = val.toLowerCase().trim()),
                  decoration: InputDecoration(
                    hintText: 'Search FAQs & Guides...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setStateModal(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredFaqs.isEmpty
                      ? const Center(child: Text('No matching FAQs found.', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredFaqs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final faq = filteredFaqs[idx];
                            final isExpanded = _expandedFaqIndex == idx;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () => setStateModal(() => _expandedFaqIndex = isExpanded ? null : idx),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            faq['category']!,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            faq['question']!,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Icon(
                                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isExpanded) ...[
                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    Text(
                                      faq['answer']!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSupportTicketModal() {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Authentication';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Support Ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Authentication', child: Text('Authentication & MFA')),
                  DropdownMenuItem(value: 'Passkeys', child: Text('Passkeys & YubiKey')),
                  DropdownMenuItem(value: 'Linked Apps', child: Text('OAuth & Linked Apps')),
                  DropdownMenuItem(value: 'Billing', child: Text('Enterprise Billing')),
                ],
                onChanged: (val) {
                  if (val != null) category = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject', hintText: 'Brief summary of issue'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Provide error logs or steps'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (subjectCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                final ticketId = '#TK-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                _showActionFeedback('Ticket $ticketId submitted successfully!');
              }
            },
            child: const Text('Submit Ticket'),
          ),
        ],
      ),
    );
  }

  void _showContactHotlineBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('24/7 Priority Hotline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Our enterprise security operations team is available 24/7/365.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.email_outlined, color: AppColors.primary),
              ),
              title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('support@b2auth.com', style: TextStyle(fontSize: 12)),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'support@b2auth.com'));
                Navigator.pop(context);
                _showActionFeedback('Support email copied to clipboard!');
              },
            ),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.phone_outlined, color: AppColors.success),
              ),
              title: const Text('24/7 Priority Hotline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('+1 (800) 555-B2AUTH (Direct SLA)', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showActionFeedback('Calling B2Auth Security Operations Hotline...');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Standalone Card 1: Knowledge Base & FAQs
              NeumorphicCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: const Text(
                    'Knowledge Base & FAQs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: _showFaqModal,
                ),
              ),
              const SizedBox(height: 16),

              // Standalone Card 2: System Health Diagnostics
              NeumorphicCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: const Text(
                    'System Health & Diagnostics',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  subtitle: const Text('99.99% Uptime • All Systems Operational', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: _showSystemHealthDialog,
                ),
              ),
              const SizedBox(height: 16),

              // Grouped Multi-Item Card 3: Support Actions
              NeumorphicCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'Submit Support Ticket',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text('Create a ticket with guaranteed priority SLA response.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: _showSupportTicketModal,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: const Text(
                        '24/7 Priority Hotline',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text('Direct phone line for urgent enterprise security incidents.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: _showContactHotlineBottomSheet,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: const Text(
                        'Email Technical Support',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text('Reach our engineering team directly at support@b2auth.com.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: 'support@b2auth.com'));
                        _showActionFeedback('Support email copied to clipboard!');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Grouped Multi-Item Card 4: Toggles (matching Privacy Page format in Screenshot 1)
              NeumorphicCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Share usage stats',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text(
                        'Share usage stats with our developers. This helps us improve the app.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                      value: _shareDiagnostics,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _shareDiagnostics = val);
                        _showActionFeedback(val ? 'Usage stats sharing enabled' : 'Usage stats sharing disabled');
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text(
                        'Share your email address',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text(
                        'By sharing your email address with usage stats, we can better troubleshoot any problems you might encounter and contact you if necessary.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                      value: _shareEmail,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _shareEmail = val);
                        _showActionFeedback(val ? 'Email sharing enabled' : 'Email sharing disabled');
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text(
                        'Enable crash reporting',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text(
                        'Share crash data with our developers if the app shuts abruptly. This will help us identify bugs and put out fixes.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                      value: _enableCrashReporting,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _enableCrashReporting = val);
                        _showActionFeedback(val ? 'Crash reporting enabled' : 'Crash reporting disabled');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Grouped Card 5: Bottom Toggle
              NeumorphicCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SwitchListTile(
                  title: const Text(
                    'Shake to send feedback',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    'Shake your device to send us quick diagnostic feedback anytime.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                  value: _shakeToFeedback,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _shakeToFeedback = val);
                    _showActionFeedback(val ? 'Shake gesture feedback enabled' : 'Shake gesture feedback disabled');
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

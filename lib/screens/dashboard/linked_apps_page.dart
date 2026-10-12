import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/custom_button.dart';
import '../../core/models/linked_app_info.dart';

class LinkedAppsPage extends StatefulWidget {
  final List<LinkedAppInfo>? initialApps;
  const LinkedAppsPage({super.key, this.initialApps});

  @override
  State<LinkedAppsPage> createState() => _LinkedAppsPageState();
}

class _LinkedAppsPageState extends State<LinkedAppsPage> {
  late List<LinkedAppInfo> _apps;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _apps = widget.initialApps ??
        [
          LinkedAppInfo(
            id: 'bnxmail',
            name: 'Bnxmail',
            category: 'Corporate Mail & Workspace',
            icon: Icons.mark_email_read_rounded,
            brandColor: const Color(0xFF4F46E5),
            scopes: ['OAuth 2.0', 'Read/Write Mail', 'SSO'],
            lastSync: '2 mins ago',
            isConnected: true,
          ),
          LinkedAppInfo(
            id: 'cliks_biz',
            name: 'cliks business',
            category: 'Enterprise Analytics',
            icon: Icons.analytics_rounded,
            brandColor: const Color(0xFF0D9488),
            scopes: ['Analytics Data', 'SSO', 'Audit Logs'],
            lastSync: '15 mins ago',
            isConnected: true,
          ),
          LinkedAppInfo(
            id: 'cliks',
            name: 'cliks',
            category: 'Productivity Portal',
            icon: Icons.dashboard_customize_rounded,
            brandColor: const Color(0xFF2563EB),
            scopes: ['SSO', 'Profile Read'],
            lastSync: '1 hour ago',
            isConnected: true,
          ),
          LinkedAppInfo(
            id: 'bit_tool',
            name: 'Bit tool',
            category: 'DevOps & Audit Pipeline',
            icon: Icons.developer_board_rounded,
            brandColor: const Color(0xFF7C3AED),
            scopes: ['API Access', 'CI/CD Token', 'SSO'],
            lastSync: 'Yesterday',
            isConnected: true,
          ),
        ];
  }

  void _showFeedback(String message) {
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

  void _showAppDetailsModal(LinkedAppInfo app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: app.brandColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(app.icon, color: app.brandColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Text(app.category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('OAuth 2.0 Integration Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Client ID', 'app_client_id_${app.id}_9821'),
                    const Divider(height: 16),
                    _buildDetailRow('Grant Type', 'Authorization Code (PKCE)'),
                    const Divider(height: 16),
                    _buildDetailRow('SSO Domain', 'auth.${app.id.replaceAll('_', '')}.com'),
                    const Divider(height: 16),
                    _buildDetailRow('Token Status', app.isConnected ? 'Valid (Expires in 24d)' : 'Revoked'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Force Re-Sync',
                      icon: Icons.sync_rounded,
                      onPressed: () {
                        Navigator.pop(context);
                        _showFeedback('${app.name} synchronized!');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: app.isConnected ? 'Revoke Access' : 'Re-connect',
                      isPremium: !app.isConnected,
                      onPressed: () {
                        setState(() => app.isConnected = !app.isConnected);
                        Navigator.pop(context);
                        _showFeedback(app.isConnected ? '${app.name} re-connected!' : '${app.name} access revoked!');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAddAppDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Connect Enterprise App'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Application Name', hintText: 'e.g. Acme CRM'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Category', hintText: 'e.g. Sales & Support'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _apps.add(
                    LinkedAppInfo(
                      id: nameCtrl.text.toLowerCase().replaceAll(' ', '_'),
                      name: nameCtrl.text,
                      category: catCtrl.text.isEmpty ? 'Enterprise Service' : catCtrl.text,
                      icon: Icons.apps_rounded,
                      brandColor: AppColors.primary,
                      scopes: ['SSO', 'Profile Read'],
                      lastSync: 'Just now',
                      isConnected: true,
                    ),
                  );
                });
                Navigator.pop(context);
                _showFeedback('${nameCtrl.text} connected successfully!');
              }
            },
            child: const Text('Connect App'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = _apps.where((app) {
      final matchesSearch = app.name.toLowerCase().contains(_searchQuery) ||
          app.category.toLowerCase().contains(_searchQuery);
      if (_selectedCategory == 'All') return matchesSearch;
      if (_selectedCategory == 'Connected') return matchesSearch && app.isConnected;
      if (_selectedCategory == 'Revoked') return matchesSearch && !app.isConnected;
      return matchesSearch;
    }).toList();

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
          'Linked Applications',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link_rounded, color: AppColors.primary),
            tooltip: 'Connect App',
            onPressed: _showAddAppDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Filter
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                decoration: InputDecoration(
                  hintText: 'Search linked applications...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Connected', 'Revoked'].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              if (filteredApps.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('No applications match your filter.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredApps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];
                    return NeumorphicCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: app.brandColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(app.icon, color: app.brandColor, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            app.name,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: app.isConnected ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            app.isConnected ? 'CONNECTED' : 'REVOKED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: app.isConnected ? AppColors.success : AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${app.category} • Synced ${app.lastSync}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: app.isConnected,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => app.isConnected = val);
                                  _showFeedback(val ? '${app.name} connected' : '${app.name} access revoked');
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: app.scopes
                                      .map(
                                        (s) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showAppDetailsModal(app),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text('Inspect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      SizedBox(width: 2),
                                      Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

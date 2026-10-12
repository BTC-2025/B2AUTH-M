import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/services/local_storage_service.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/notifiers/auth_notifier.dart';
import '../theme/macos_theme.dart';
import '../components/macos_sidebar.dart';
import '../components/macos_toolbar.dart';
import 'macos_dashboard_view.dart';
import 'macos_security_view.dart';
import 'macos_settings_view.dart';

class MacOsHomeShell extends StatefulWidget {
  const MacOsHomeShell({super.key});

  @override
  State<MacOsHomeShell> createState() => _MacOsHomeShellState();
}

class _MacOsHomeShellState extends State<MacOsHomeShell> {
  int _selectedTabIndex = 0; // 0: Dashboard, 1: Security, 2: Settings
  int _selectedFilterIndex = 0; // 0: All Accounts, 1: Primary, 2: Business, 3: Personal, 4: Child

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = LocalStorageService.getString('access_token') ?? '';
      if (token.isNotEmpty) {
        context.read<AccountProvider>().fetchProfileFromApi(token);
      }
    });
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MacOsTheme.radiusMedium),
        ),
        title: const Text(
          'Confirm Sign Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to sign out from your B2Auth account?',
          style: TextStyle(fontSize: 13, color: MacOsTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: MacOsTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MacOsTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MacOsTheme.radiusSmall),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AccountProvider>().clearAccounts();
              context.read<AuthNotifier>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleAddAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final activeAccount = accountProvider.selectedAccount;
    final activeId = activeAccount?.id ?? 'default';

    return Scaffold(
      backgroundColor: MacOsTheme.background,
      body: Column(
        children: [
          // Top Navigation Bar
          MacOsToolbar(
            activeIndex: _selectedTabIndex,
            onTabSelected: (index) {
              setState(() => _selectedTabIndex = index);
            },
            onSignOut: _handleSignOut,
            onAddAccount: _handleAddAccount,
          ),

          // Main Workspace (Sidebar + Content)
          Expanded(
            child: Row(
              children: [
                // Left Sidebar: Accounts & Actions
                MacOsSidebar(
                  selectedFilterIndex: _selectedFilterIndex,
                  onFilterSelected: (index) {
                    setState(() {
                      _selectedFilterIndex = index;
                      _selectedTabIndex = 0; // Return to Dashboard to view filtered accounts
                    });
                  },
                  onAddAccount: _handleAddAccount,
                  onSignOut: _handleSignOut,
                ),

                // Active Tab Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      MacOsDashboardView(
                        key: ValueKey('dash_$activeId'),
                        selectedFilterIndex: _selectedFilterIndex,
                      ),
                      MacOsSecurityView(
                        key: ValueKey('sec_$activeId'),
                      ),
                      MacOsSettingsView(
                        key: ValueKey('sett_$activeId'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

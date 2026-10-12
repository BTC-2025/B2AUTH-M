import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/section_header.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/settings_tile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/user_account.dart';
import '../../core/services/local_storage_service.dart';

import 'edit_profile_screen.dart';
import 'privacy_screen.dart';
import 'timeout_screen.dart';
import 'personalize_screen.dart';
import 'help_support_page.dart';
import '../auth/login_screen.dart';
import '../auth/notifiers/auth_notifier.dart';

class SettingsPage extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const SettingsPage({super.key, this.onSwitchTab});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isEditing = false;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  void _syncControllersWithAccount(UserAccount? user) {
    if (user == null || _isEditing) return;
    final savedEmail = LocalStorageService.getString('recovery_email_${user.id}');
    final savedPhone = LocalStorageService.getString('recovery_phone_${user.id}');
    
    final emailVal = (savedEmail != null && savedEmail.isNotEmpty)
        ? savedEmail
        : ((user.recoveryEmail != null && user.recoveryEmail!.isNotEmpty) ? user.recoveryEmail! : user.email);
        
    final phoneVal = (savedPhone != null && savedPhone.isNotEmpty)
        ? savedPhone
        : ((user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ? user.phoneNumber! : '');

    if (_emailController.text != emailVal) {
      _emailController.text = emailVal;
    }
    if (_phoneController.text != phoneVal) {
      _phoneController.text = phoneVal;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showActionFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primary,
      ),
    );
  }



  void _showSignOutDialog() {
    context.read<AccountProvider>().clearAccounts();
    context.read<AuthNotifier>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showWidgetsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Widget Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Show verification codes on your device home screen.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enable Home Screen Widget', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Enable widgets for quick verification lookup.', style: TextStyle(fontSize: 12)),
                      value: settings.enableHomeScreenWidget,
                      activeThumbColor: settings.accentColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        settings.setEnableHomeScreenWidget(val);
                        _showActionFeedback(val ? 'Home screen widget enabled' : 'Home screen widget disabled');
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Show Hidden/Masked Codes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Obscure widget codes until tapped.', style: TextStyle(fontSize: 12)),
                      value: settings.showHiddenMaskedCodes,
                      activeThumbColor: settings.accentColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        settings.setShowHiddenMaskedCodes(val);
                        _showActionFeedback(val ? 'Masked widget codes enabled' : 'Masked widget codes disabled');
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Confirm Widget Settings',
                      isFullWidth: true,
                      isPremium: true,
                      onPressed: () {
                        Navigator.pop(context);
                        _showActionFeedback('Home Screen Widget options configured.');
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showWearOsSyncDialog() {
    final settings = context.read<SettingsProvider>();
    if (settings.wearOsSynced) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Wear OS Synced'),
          content: const Text('Your smart watch is currently configured and synced with B2Auth.'),
          actions: [
            TextButton(
              onPressed: () {
                settings.setWearOsSynced(false);
                Navigator.pop(context);
                _showActionFeedback('Smart watch sync deactivated.');
              },
              child: const Text('Disconnect Watch', style: TextStyle(color: AppColors.error)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _triggerWearOsSyncFlow(settings);
              },
              child: const Text('Sync Again'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      _triggerWearOsSyncFlow(settings);
    }
  }

  void _triggerWearOsSyncFlow(SettingsProvider settings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
            settings.setWearOsSynced(true);
            Navigator.pop(dialogCtx);
            if (mounted) {
              _showActionFeedback('Synced successfully with Smart Watch!');
            }
          }
        });
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 24),
                Expanded(
                  child: Text('Connecting to Smart Watch via Bluetooth...', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _simulateRefreshApp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
            Navigator.pop(dialogCtx);
            if (mounted) {
              _showActionFeedback('App data synced and refreshed!');
            }
          }
        });
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 24),
                Expanded(
                  child: Text('Synchronizing identity databases...', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We value your feedback. Let us know how we can improve.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your comment here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          CustomButton(
            text: 'Submit',
            isPremium: true,
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _showActionFeedback('Thank you for your feedback!');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final user = accountProvider.selectedAccount;

    _syncControllersWithAccount(user);

    if (user == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: AppTextStyles.pageTitle),
          const SizedBox(height: 16),

          _buildQuickActionTile(
            Icons.notifications_none, 
            'Not receiving notifications?', 
            AppColors.error,
            () {
              if (widget.onSwitchTab != null) {
                widget.onSwitchTab!(4); // Alerts tab index
                _showActionFeedback('Checking notification settings...');
              }
            }
          ),
          const SizedBox(height: 6),
          _buildQuickActionTile(
            Icons.person_outline, 
            'Account settings', 
            AppColors.primary,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))
          ),
          const SizedBox(height: 6),
          _buildQuickActionTile(
            Icons.refresh, 
            'Recover Account (2FA & B2Auth)', 
            AppColors.success,
            () {
              if (widget.onSwitchTab != null) {
                widget.onSwitchTab!(2); // Security tab index
                _showActionFeedback('Redirecting to Security Settings...');
              }
            }
          ),
          const SizedBox(height: 10),

          _buildSectionLabel('INTEGRATIONS'),
          NeumorphicCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.widgets_outlined, 
                  title: 'Widgets', 
                  description: '', 
                  showDivider: true,
                  onTap: _showWidgetsBottomSheet,
                ),
                SettingsTile(
                  icon: Icons.watch_outlined, 
                  title: 'Wear OS', 
                  description: settingsProvider.wearOsSynced ? 'Status: Synced' : 'Not configured',
                  onTap: _showWearOsSyncDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildSectionLabel('SECURITY & PREFERENCES'),
          NeumorphicCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.phonelink_lock_outlined,
                  title: 'App lock',
                  description: "Use your phone's PIN, pattern, or biometrics to unlock B2Auth.",
                  trailing: Switch(
                    value: settingsProvider.appLockEnabled,
                    onChanged: (val) {
                      settingsProvider.toggleAppLock(val);
                      _showActionFeedback(val ? 'App lock enabled' : 'App lock disabled');
                    },
                    activeThumbColor: settingsProvider.accentColor,
                  ),
                  showDivider: true,
                ),
                SettingsTile(
                  icon: Icons.security_outlined, 
                  title: 'Privacy', 
                  description: '', 
                  showDivider: true,
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                SettingsTile(
                  icon: Icons.timer_outlined, 
                  title: 'Authentication Timeout', 
                  description: 'Current: ${settingsProvider.authTimeoutSeconds}s',
                  showDivider: true,
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const TimeoutScreen()),
                  ),
                ),
                SettingsTile(
                  icon: Icons.edit_outlined, 
                  title: 'Personalize', 
                  description: '', 
                  showDivider: true,
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const PersonalizeScreen()),
                  ),
                ),
                SettingsTile(
                  icon: Icons.refresh_outlined, 
                  title: 'Refresh App', 
                  description: 'Solve inconsistencies.',
                  onTap: _simulateRefreshApp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildSectionLabel('SUPPORT & ABOUT'),
          NeumorphicCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  description: '',
                  showDivider: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpSupportPage()),
                  ),
                ),
                SettingsTile(
                  icon: Icons.chat_bubble_outline, 
                  title: 'Feedback', 
                  description: 'Report bugs or improvements.', 
                  showDivider: true,
                  onTap: _showFeedbackDialog,
                ),
                SettingsTile(
                  icon: Icons.info_outline, 
                  title: 'About B2Auth', 
                  description: 'Version 4.2.8',
                  onTap: () => _showActionFeedback('B2Auth Version 4.2.8'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildSocialCard(),
          const SizedBox(height: 10),

          _buildQuickActionTile(
            Icons.share_outlined, 
            'Share B2Auth', 
            AppColors.primary,
            () {
              Clipboard.setData(const ClipboardData(text: 'https://b2auth.com/download'));
              _showActionFeedback('B2Auth download link copied to clipboard!');
            }
          ),
          const SizedBox(height: 6),
          _buildQuickActionTile(
            Icons.logout_outlined, 
            'Sign out', 
            AppColors.error,
            _showSignOutDialog
          ),
          
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Account Settings',
            subtitle: 'Manage your recovery information.',
          ),
          const SizedBox(height: 8),
          _buildRecoveryCard(),
        ],
      ),
    );
  }



  Widget _buildQuickActionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: AppColors.darkShadow, offset: Offset(2, 2), blurRadius: 4),
                    BoxShadow(color: AppColors.lightShadow, offset: Offset(-2, -2), blurRadius: 4),
                  ],
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold))),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSocialCard() {
    return NeumorphicCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSocialItem(Icons.camera_alt_outlined, 'Instagram'),
          _buildSocialItem(Icons.close, 'X'),
          _buildSocialItem(Icons.play_circle_outline, 'Youtube'),
        ],
      ),
    );
  }

  Widget _buildSocialItem(IconData icon, String label) {
    return InkWell(
      onTap: () => _showActionFeedback('Opening $label...'),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textPrimary),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecoveryCard() {
    return NeumorphicCard(
      title: 'Recovery Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CustomTextField(label: 'Recovery Email', hint: 'Add recovery email', leadingIcon: Icons.mail_outline, controller: _emailController, isEnabled: _isEditing),
          const SizedBox(height: 24),
          CustomTextField(label: 'Phone Number', hint: 'Add phone number', leadingIcon: Icons.phone_outlined, controller: _phoneController, isEnabled: _isEditing),
          const SizedBox(height: 32),
          CustomButton(
            text: _isEditing ? 'Save Details' : 'Edit Details',
            icon: _isEditing ? Icons.check : Icons.edit_outlined,
            isPremium: _isEditing,
            onPressed: () async {
              if (_isEditing) {
                final accountProvider = context.read<AccountProvider>();
                final authNotifier = context.read<AuthNotifier>();
                final activeAccount = accountProvider.selectedAccount;
                final token = authNotifier.accessToken ?? LocalStorageService.getString('access_token') ?? '';

                if (activeAccount != null) {
                  LocalStorageService.setString('recovery_email_${activeAccount.id}', _emailController.text);
                  LocalStorageService.setString('recovery_phone_${activeAccount.id}', _phoneController.text);

                  // Execute PATCH /users/recovery
                  final result = await accountProvider.updateRecoveryOptions(
                    token: token,
                    recoveryEmail: _emailController.text.trim(),
                    phoneNumber: _phoneController.text.trim(),
                  );

                  if (mounted) {
                    final msg = result['success'] == true
                        ? (result['message'] ?? 'Recovery options updated successfully')
                        : 'Recovery details updated locally.';
                    _showActionFeedback(msg);
                  }
                }
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
    );
  }

}

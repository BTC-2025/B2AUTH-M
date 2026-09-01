import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/security_provider.dart';
import '../../core/models/user_account.dart';
import '../../widgets/profile_avatar.dart';
import 'sessions_map_screen.dart';

class MfaPage extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const MfaPage({super.key, this.onSwitchTab});

  @override
  State<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends State<MfaPage> {

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

  void _showPassphraseSetupDialog(SecurityProvider security) {
    final controller = TextEditingController(text: security.passphrase);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Secure Passphrase',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a unique passphrase to authorize transactions and recover your profiles offline.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter Passphrase',
                  hintText: 'Minimum 6 characters',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.password_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.length < 6) {
                  _showFeedback('Passphrase must be at least 6 characters.');
                  return;
                }
                security.setPassphrase(txt);
                Navigator.pop(context);
                _showFeedback('Passphrase updated successfully!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Passphrase'),
            ),
          ],
        );
      },
    );
  }

  void _showEditMfaDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<SecurityProvider>(
          builder: (context, security, child) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Configure MFA Modes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Passwordless'),
                    subtitle: const Text('Use screen lock authentication'),
                    value: security.passwordlessEnabled,
                    onChanged: (val) {
                      security.togglePasswordless(val);
                    },
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: const Text('Push Notification'),
                    subtitle: const Text('Approve log-in requests instantly'),
                    value: security.pushNotificationEnabled,
                    onChanged: (val) {
                      security.togglePushNotification(val);
                    },
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: const Text('Fingerprint'),
                    subtitle: const Text('Use biometrics for verification'),
                    value: security.fingerprintEnabled,
                    onChanged: (val) {
                      security.toggleFingerprint(val);
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScannerWizard() {
    int step = 1; // 1 = Scanning animation, 2 = Sync Dialog, 3 = Success
    String detectedEmail = 'demo.otp@bnxmail.com';
    String detectedName = 'Demo Profile';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (step == 1) {
              Future.delayed(const Duration(milliseconds: 2500), () {
                if (mounted && Navigator.canPop(context)) {
                  setDialogState(() {
                    step = 2;
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(step == 1 
                ? 'Scanning QR Code...' 
                : (step == 2 ? 'New Profile Detected' : 'Success!')),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (step == 1) ...[
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 160,
                            width: 160,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.qr_code_2, size: 100, color: AppColors.textSecondary),
                            ),
                          ),
                          const _ScannerAnimationLine(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Align the QR code within the frame to sync your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ] else if (step == 2) ...[
                      const Icon(Icons.account_circle, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        detectedName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        detectedEmail,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'A verified B2Auth sync profile was found in this QR code. Would you like to add it to this device?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                    ] else ...[
                      const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                      const SizedBox(height: 16),
                      const Text(
                        'Profile synchronized successfully!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can now switch to this identity from your profile dropdown.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (step < 3)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                if (step == 2)
                  ElevatedButton(
                    onPressed: () {
                      final accountProvider = context.read<AccountProvider>();
                      final exists = accountProvider.accounts.any((a) => a.email == detectedEmail);
                      if (!exists) {
                        final newAcc = UserAccount(
                          id: const Uuid().v4(),
                          name: detectedName,
                          displayName: 'Demo',
                          username: 'demo_user',
                          email: detectedEmail,
                          avatarLetter: 'D',
                          type: AccountType.personal,
                          createdAt: DateTime.now(),
                          lastUsed: DateTime.now(),
                          securityScore: 88,
                          storageUsage: 0.1,
                        );
                        accountProvider.addAccount(newAcc);
                      }
                      setDialogState(() {
                        step = 3;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sync Account'),
                  ),
                if (step == 3)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final securityProvider = context.watch<SecurityProvider>();
    final user = accountProvider.selectedAccount;
 
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
 
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Executive Profile MFA Card
          _buildProfileMfaCard(user, accountProvider),
          const SizedBox(height: 20),

          // 2. Devices & Sessions Hub
          _buildDevicesSessionsCard(),
          const SizedBox(height: 20),

          // 3. QR Scan Action Card
          _buildScanActionCard(),
          const SizedBox(height: 20),

          // 4. Passphrase Alert Banner
          _buildPassphraseCard(securityProvider, user.email),
          const SizedBox(height: 20),

          // 5. Recovery Warning Card
          _buildRecoveryWarningCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPassphraseCard(SecurityProvider security, String email) {
    final hasPassphrase = security.passphrase.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: hasPassphrase ? AppColors.success.withOpacity(0.3) : Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasPassphrase ? AppColors.success.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPassphrase ? Icons.verified_user : Icons.lock_outline_rounded,
              color: hasPassphrase ? AppColors.success : Colors.amber.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'B2Auth Passphrase Secure Link',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hasPassphrase ? AppColors.success.withOpacity(0.12) : Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasPassphrase ? 'Active' : 'Incomplete',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: hasPassphrase ? AppColors.success : Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasPassphrase ? 'Your secure passphrase is active.' : 'Set up passphrase',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPassphrase ? 'Tap below to modify your security passphrase.' : 'Configure recovery passphrase to secure your credentials offline.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showPassphraseSetupDialog(security),
                  icon: Icon(hasPassphrase ? Icons.edit : Icons.settings, size: 14),
                  label: Text(hasPassphrase ? 'Modify Passphrase' : 'Set Up Passphrase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPassphrase ? AppColors.success : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryWarningCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.onSwitchTab != null) {
              widget.onSwitchTab!(3); // Navigate to settings page
              _showFeedback('Redirected to settings. Please update your Recovery Info.');
            } else {
              _showFeedback('Opening Recovery Setup...');
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recovery Backup Alert',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.amber.shade700,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set up a recovery option to guarantee account access if you get locked out.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900.withOpacity(0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMfaCard(dynamic user, AccountProvider accountProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Status Badge Header with Flexible wrapping to prevent overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shield_rounded, color: AppColors.success, size: 14),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'MFA COMMAND CENTER • PROTECTED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _showEditMfaDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Profile Info Header
          Row(
            children: [
              ProfileAvatar(
                letter: user.avatarLetter,
                size: 52,
                backgroundColor: AppColors.primary,
                imageUrl: user.avatarUrl,
                imagePath: user.profileImagePath,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Account selector dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: user.id,
                          isDense: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue != user.id) {
                              accountProvider.switchAccount(newValue);
                              _showFeedback('Switched to ${accountProvider.accounts.firstWhere((a) => a.id == newValue).displayName}');
                            }
                          },
                          items: () {
                            final Map<String, UserAccount> uniqueMap = {};
                            for (var acc in accountProvider.accounts) {
                              final key = acc.email.trim().toLowerCase();
                              if (key.isNotEmpty && (!uniqueMap.containsKey(key) || acc.id == user.id)) {
                                uniqueMap[key] = acc;
                              }
                            }
                            return uniqueMap.values.map((UserAccount account) {
                              return DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  account.email,
                                  style: const TextStyle(color: AppColors.textPrimary),
                                ),
                              );
                            }).toList();
                          }(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // MFA modes section label
          Row(
            children: const [
              Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Text(
                'Active MFA Authentication Shields',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // MFA items list
          Consumer<SecurityProvider>(
            builder: (context, security, child) {
              final items = <Widget>[];
              if (security.passwordlessEnabled) {
                items.add(_buildMfaModeItem(icon: Icons.vpn_key_outlined, title: 'Passwordless Authorization'));
              }
              if (security.pushNotificationEnabled) {
                items.add(_buildMfaModeItem(icon: Icons.notifications_active_outlined, title: 'Push Alerts Sync'));
              }
              if (security.fingerprintEnabled) {
                items.add(_buildMfaModeItem(icon: Icons.fingerprint_rounded, title: 'Biometric Touch ID'));
              }

              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No MFA modes enabled on this device.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => items[index],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMfaModeItem({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanActionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showScannerWizard,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Scan Verification QR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Instantly link any authenticator profile by scanning its QR code.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevicesSessionsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smartphone_rounded, color: AppColors.primary, size: 20),
            ),
            title: const Text(
              'Devices',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            subtitle: const Text('CPH2455 • Active Now', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
            onTap: () {
              _showFeedback('Devices list: CPH2455 (This Device)');
            },
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
            ),
            title: const Text(
              'Sessions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            subtitle: const Text('2 Active Sessions • View Map', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SessionsMapScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScannerAnimationLine extends StatefulWidget {
  const _ScannerAnimationLine();

  @override
  State<_ScannerAnimationLine> createState() => _ScannerAnimationLineState();
}

class _ScannerAnimationLineState extends State<_ScannerAnimationLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: 140).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: 10 + _animation.value,
          child: Container(
            height: 3,
            width: 140,
            decoration: BoxDecoration(
              color: Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.8),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/models/user_account.dart';
import '../../core/services/local_storage_service.dart';
import '../theme/macos_theme.dart';

class MacOsSettingsView extends StatefulWidget {
  const MacOsSettingsView({super.key});

  @override
  State<MacOsSettingsView> createState() => _MacOsSettingsViewState();
}

class _MacOsSettingsViewState extends State<MacOsSettingsView> {
  bool _isEditingRecovery = false;
  late TextEditingController _recoveryEmailController;
  late TextEditingController _recoveryPhoneController;

  @override
  void initState() {
    super.initState();
    _recoveryEmailController = TextEditingController();
    _recoveryPhoneController = TextEditingController();
  }

  void _syncControllersWithAccount(UserAccount? user) {
    if (user == null || _isEditingRecovery) return;
    final savedEmail = LocalStorageService.getString('recovery_email_${user.id}');
    final savedPhone = LocalStorageService.getString('recovery_phone_${user.id}');

    final emailVal = (savedEmail != null && savedEmail.isNotEmpty)
        ? savedEmail
        : ((user.recoveryEmail != null && user.recoveryEmail!.isNotEmpty)
            ? user.recoveryEmail!
            : (user.email.isNotEmpty ? user.email : ''));

    final phoneVal = (savedPhone != null && savedPhone.isNotEmpty)
        ? savedPhone
        : ((user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
            ? user.phoneNumber!
            : '');

    if (_recoveryEmailController.text != emailVal) {
      _recoveryEmailController.text = emailVal;
    }
    if (_recoveryPhoneController.text != phoneVal) {
      _recoveryPhoneController.text = phoneVal;
    }
  }

  @override
  void dispose() {
    _recoveryEmailController.dispose();
    _recoveryPhoneController.dispose();
    super.dispose();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: MacOsTheme.brandBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MacOsTheme.radiusSmall)),
        width: 380,
      ),
    );
  }

  void _saveRecoveryDetails(UserAccount user) {
    final email = _recoveryEmailController.text.trim();
    final phone = _recoveryPhoneController.text.trim();

    if (email.isNotEmpty) {
      LocalStorageService.setString('recovery_email_${user.id}', email);
    }
    if (phone.isNotEmpty) {
      LocalStorageService.setString('recovery_phone_${user.id}', phone);
    }

    setState(() {
      _isEditingRecovery = false;
    });

    _showFeedback('Recovery details updated successfully!');
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final user = accountProvider.selectedAccount;

    _syncControllersWithAccount(user);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          const Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MacOsTheme.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your recovery information and security preferences.',
            style: TextStyle(
              fontSize: 14,
              color: MacOsTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 28),

          // 2. Main Content Grid (Two Cards side by side)
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 760;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildRecoveryCard(user),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildPreferencesCard(),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRecoveryCard(user),
                    const SizedBox(height: 24),
                    _buildPreferencesCard(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCard(UserAccount user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MacOsTheme.radiusCard),
        border: Border.all(color: MacOsTheme.border, width: 1.0),
        boxShadow: MacOsTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: MacOsTheme.brandBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Recovery Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MacOsTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Keep your recovery details up to date to secure your account.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: MacOsTheme.textTertiary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Recovery Email
          const Text(
            'Recovery Email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MacOsTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Used to recover your account and receive important notifications.',
            style: TextStyle(
              fontSize: 12,
              color: MacOsTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(MacOsTheme.radiusMedium),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isEditingRecovery
                      ? TextField(
                          controller: _recoveryEmailController,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: MacOsTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(
                          _recoveryEmailController.text.isNotEmpty
                              ? _recoveryEmailController.text
                              : (user.email.isNotEmpty ? user.email : 'Not set'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: MacOsTheme.textPrimary,
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Phone Number
          const Text(
            'Phone Number',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MacOsTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Used for account recovery and security alerts.',
            style: TextStyle(
              fontSize: 12,
              color: MacOsTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(MacOsTheme.radiusMedium),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isEditingRecovery
                      ? TextField(
                          controller: _recoveryPhoneController,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: MacOsTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(
                          _recoveryPhoneController.text.isNotEmpty
                              ? _recoveryPhoneController.text
                              : 'Not set',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: MacOsTheme.textPrimary,
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Action Button (Bottom Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isEditingRecovery) ...[
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingRecovery = false;
                      _syncControllersWithAccount(user);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MacOsTheme.radiusMedium),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  if (_isEditingRecovery) {
                    _saveRecoveryDetails(user);
                  } else {
                    setState(() {
                      _isEditingRecovery = true;
                    });
                  }
                },
                icon: Icon(
                  _isEditingRecovery ? Icons.check_rounded : Icons.edit_outlined,
                  size: 15,
                  color: Colors.white,
                ),
                label: Text(
                  _isEditingRecovery ? 'Save Details' : 'Edit Details',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MacOsTheme.brandBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MacOsTheme.radiusMedium),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MacOsTheme.radiusCard),
        border: Border.all(color: MacOsTheme.border, width: 1.0),
        boxShadow: MacOsTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F3FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MacOsTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Customize your account experience and security preferences.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: MacOsTheme.textTertiary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 52),

          // Center illustration & placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F3FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Small floating dots
                    Positioned(
                      top: 4,
                      right: 12,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF818CF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 8,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.settings_outlined,
                      size: 34,
                      color: Color(0xFF7C3AED),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Additional settings coming soon',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MacOsTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "We're working on new features to give you more\ncontrol over your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: MacOsTheme.textTertiary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 52),
        ],
      ),
    );
  }
}

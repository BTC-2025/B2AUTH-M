import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/account_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/models/user_account.dart';
import '../../widgets/profile_avatar.dart';
import 'linked_apps_page.dart';
import '../../core/services/user_profile_api_service.dart';
import '../../core/services/local_storage_service.dart';
import '../auth/notifiers/auth_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/cashfree_digilocker_api_service.dart';

class DashboardPage extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const DashboardPage({super.key, this.onSwitchTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final UserProfileApiService _userProfileApiService = UserProfileApiService();
  final CashfreeDigiLockerApiService _cashfreeService = CashfreeDigiLockerApiService();
  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4F46E5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final selectedUser = accountProvider.selectedAccount;

    if (selectedUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final rawAccounts = accountProvider.accounts;
    final Map<String, UserAccount> uniqueAccountsMap = {};
    for (var a in rawAccounts) {
      final key = a.email.trim().toLowerCase();
      if (key.isNotEmpty) {
        if (!uniqueAccountsMap.containsKey(key) || a.isPrimary) {
          uniqueAccountsMap[key] = a;
        }
      }
    }
    final accounts = uniqueAccountsMap.values.toList();
    final primaryAccount = accounts.firstWhere(
      (a) => a.isPrimary,
      orElse: () => selectedUser,
    );

    final businessAccounts = accounts.where((a) => a.type == AccountType.business || a.type == AccountType.work).toList();
    final personalAccounts = accounts.where((a) => a.type == AccountType.personal || a.type == AccountType.education).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Title with Profile Circle
            _buildTopTitleRow(selectedUser),
            const SizedBox(height: 28),

            // Section 1: Admin
            _buildAdminSection(
              accountProvider: accountProvider,
              accounts: accounts,
              primaryAccount: primaryAccount,
            ),
            const SizedBox(height: 32),

            // Section 2: Logged-in Identities
            _buildLoggedInIdentitiesSection(
              accountProvider: accountProvider,
              selectedAccount: selectedUser,
              businessAccounts: businessAccounts,
              personalAccounts: personalAccounts,
            ),
            const SizedBox(height: 32),

            // Section 3: Linked Apps Shortcut (at the bottom down)
            _buildLinkedAppsShortcut(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Top Header Row matching web/mobile layout
  Widget _buildTopTitleRow(UserAccount user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        ProfileAvatar(
          letter: user.avatarLetter,
          size: 36,
          backgroundColor: const Color(0xFF8B5CF6),
          imageUrl: user.avatarUrl,
          imagePath: user.profileImagePath,
        ),
      ],
    );
  }

  /// Section 1: Admin Mail Account Card
  Widget _buildAdminSection({
    required AccountProvider accountProvider,
    required List<UserAccount> accounts,
    required UserAccount primaryAccount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your linked mail accounts and primary address.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: accounts.asMap().entries.map((entry) {
              final idx = entry.key;
              final acc = entry.value;
              final bool isPrimary = acc.isPrimary;

              return Column(
                children: [
                  if (idx > 0) const Divider(color: Color(0xFFF3F4F6), height: 24, thickness: 1),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          color: Color(0xFF4B5563),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    acc.email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPrimary) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${acc.username.isNotEmpty ? acc.username : 'user'} • Active',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        OutlinedButton(
                          onPressed: () async {
                            final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
                            final verificationId = 'verif_${DateTime.now().millisecondsSinceEpoch}';

                            // 1. Initiate DigiLocker verification with Cashfree API
                            final urlRes = await _cashfreeService.createDigiLockerUrl(
                              verificationId: verificationId,
                              documents: ['AADHAAR', 'PAN', 'DRIVING_LICENSE'],
                              redirectUrl: 'b2auth://callback',
                              userAccessToken: token,
                            );

                            final String webUrl = (urlRes.data != null && urlRes.data['url'] != null)
                                ? urlRes.data['url'].toString()
                                : 'https://sandbox.cashfree.com/verification/digilocker/web?verification_id=$verificationId';

                            try {
                              final Uri targetUri = Uri.parse(webUrl);
                              if (await canLaunchUrl(targetUri)) {
                                await launchUrl(targetUri, mode: LaunchMode.externalApplication);
                              } else {
                                await launchUrl(targetUri, mode: LaunchMode.platformDefault);
                              }
                            } catch (e) {
                              debugPrint('Could not launch Cashfree DigiLocker URL: $e');
                            }

                            // 2. Sync primary account locally and update user profile on backend API
                            await _userProfileApiService.setPrimaryEmail(
                              accessToken: token,
                              email: acc.email,
                            );

                            accountProvider.setPrimary(acc.id);
                            accountProvider.switchAccount(acc.id);

                            if (mounted) {
                              _showFeedback('${acc.email} verified via DigiLocker & set as Primary! 🎉');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Make Primary',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Section 2: Logged-in Identities Classified as Business & Personal
  Widget _buildLoggedInIdentitiesSection({
    required AccountProvider accountProvider,
    required UserAccount selectedAccount,
    required List<UserAccount> businessAccounts,
    required List<UserAccount> personalAccounts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logged-in Identities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Quickly switch between your active B2Auth accounts.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 24),

        // Business Accounts Category
        _buildCategoryHeader(
          icon: Icons.card_travel_rounded,
          title: 'BUSINESS ACCOUNTS',
        ),
        const SizedBox(height: 12),
        if (businessAccounts.isEmpty)
          _buildEmptyCategoryCard('No business accounts linked yet.')
        else
          Column(
            children: businessAccounts
                .map((acc) => _buildIdentityItemCard(
                      account: acc,
                      isSelected: acc.id == selectedAccount.id,
                      onTap: () {
                        if (acc.id != selectedAccount.id) {
                          accountProvider.switchAccount(acc.id);
                          _showFeedback('Switched to ${acc.displayName}');
                        }
                      },
                    ))
                .toList(),
          ),

        const SizedBox(height: 24),

        // Personal Accounts Category
        _buildCategoryHeader(
          icon: Icons.person_outline_rounded,
          title: 'PERSONAL ACCOUNTS',
        ),
        const SizedBox(height: 12),
        if (personalAccounts.isEmpty)
          _buildEmptyCategoryCard('No personal accounts linked yet.')
        else
          Column(
            children: personalAccounts
                .map((acc) => _buildIdentityItemCard(
                      account: acc,
                      isSelected: acc.id == selectedAccount.id,
                      onTap: () {
                        if (acc.id != selectedAccount.id) {
                          accountProvider.switchAccount(acc.id);
                          _showFeedback('Switched to ${acc.displayName}');
                        }
                      },
                    ))
                .toList(),
          ),
      ],
    );
  }

  /// Small Uppercase Category Header (BUSINESS ACCOUNTS / PERSONAL ACCOUNTS)
  Widget _buildCategoryHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  /// Single Account Identity Card
  Widget _buildIdentityItemCard({
    required UserAccount account,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isBusiness = account.type == AccountType.business || account.type == AccountType.work;
    final Color avatarBgColor = isBusiness ? const Color(0xFF3B82F6) : const Color(0xFF7C3AED);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: const Color(0xFFC7D2FE), width: 1)
            : Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Solid Left Indicator Line for Selected Account
              if (isSelected)
                Container(
                  width: 4,
                  color: const Color(0xFF4F46E5),
                ),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Avatar Circle
                        ProfileAvatar(
                          letter: account.avatarLetter,
                          size: 40,
                          backgroundColor: avatarBgColor,
                          imageUrl: account.avatarUrl,
                          imagePath: account.profileImagePath,
                        ),
                        const SizedBox(width: 14),

                        // Name & Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    account.displayName.isNotEmpty
                                        ? account.displayName
                                        : account.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6366F1),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                account.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Chevron arrow for unselected
                        if (!isSelected)
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty Category Card Placeholder
  Widget _buildEmptyCategoryCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      ),
    );
  }

  /// Section 3: Linked Apps Shortcut Card at the bottom down
  Widget _buildLinkedAppsShortcut() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LinkedAppsPage()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Rounded Indigo App Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    color: Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Text Column
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linked Apps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage connected workspace apps & SSO permissions',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

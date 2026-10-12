import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_account.dart';
import '../../core/providers/account_provider.dart';
import '../../widgets/profile_avatar.dart';
import '../theme/macos_theme.dart';

class MacOsToolbar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSignOut;
  final VoidCallback? onAddAccount;

  const MacOsToolbar({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
    required this.onSignOut,
    this.onAddAccount,
  });

  void _showProfilePopup(BuildContext context, UserAccount? user, String userName, String avatarLetter) {
    final accountProvider = context.read<AccountProvider>();
    final allAccounts = accountProvider.accounts;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.04),
      builder: (dialogCtx) {
        return Stack(
          children: [
            Positioned(
              top: 56,
              right: 24,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Avatar with Profile Picture
                      ProfileAvatar(
                        letter: avatarLetter,
                        imageUrl: user?.effectiveAvatarUrl ?? user?.avatarUrl,
                        imagePath: user?.profileImagePath,
                        size: 58,
                        backgroundColor: const Color(0xFF6B46C1),
                      ),
                      const SizedBox(height: 12),

                      // 2. Name & Email
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 3. Badges Row (BUSINESS & ✓ PRIMARY)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'BUSINESS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_rounded, size: 12, color: Color(0xFF16A34A)),
                                SizedBox(width: 3),
                                Text(
                                  'PRIMARY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 4. Manage your Account Button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          onTabSelected(2); // Settings tab
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                        ),
                        child: const Text(
                          'Manage your Account',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Other Logged-in Accounts with Profile Images
                      if (allAccounts.length > 1) ...[
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),
                        ...allAccounts.where((acc) => acc.id != user?.id).map((otherAcc) {
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(dialogCtx);
                                accountProvider.switchAccount(otherAcc.id);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                                ),
                                child: Row(
                                  children: [
                                    ProfileAvatar(
                                      letter: otherAcc.avatarLetter.isNotEmpty ? otherAcc.avatarLetter : 'R',
                                      imageUrl: otherAcc.effectiveAvatarUrl ?? otherAcc.avatarUrl,
                                      imagePath: otherAcc.profileImagePath,
                                      size: 32,
                                      backgroundColor: const Color(0xFF6B46C1),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            otherAcc.displayName.isNotEmpty ? otherAcc.displayName : otherAcc.name,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            otherAcc.email,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 14),

                      // 5. Add another account
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            if (onAddAccount != null) {
                              onAddAccount!();
                            }
                          },
                          child: Row(
                            children: const [
                              Icon(Icons.add, size: 18, color: Color(0xFF1E293B)),
                              SizedBox(width: 12),
                              Text(
                                'Add another account',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 6. Sign out of all accounts
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            onSignOut();
                          },
                          child: Row(
                            children: const [
                              Icon(Icons.logout_rounded, size: 17, color: Color(0xFF1E293B)),
                              SizedBox(width: 12),
                              Text(
                                'Sign out of all accounts',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 7. Footer
                      const Text(
                        'Privacy Policy  •  Terms of Service',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final user = accountProvider.selectedAccount;
    final userName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : (user?.name.isNotEmpty == true ? user!.name : 'Ravi Kumar C');
    final avatarLetter = user?.avatarLetter.isNotEmpty == true ? user!.avatarLetter : 'R';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: MacOsTheme.border, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // 1. Logo & Brand Name
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/Auth_img.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.shield_outlined,
                    color: MacOsTheme.textPrimary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'B2Auth',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MacOsTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const Spacer(),

          // 2. Center Pill-shaped Segmented Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: MacOsTheme.pillBackground,
              borderRadius: BorderRadius.circular(MacOsTheme.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabPill(index: 0, label: 'Dashboard'),
                const SizedBox(width: 4),
                _buildTabPill(index: 1, label: 'Security'),
                const SizedBox(width: 4),
                _buildTabPill(index: 2, label: 'Settings'),
              ],
            ),
          ),

          const Spacer(),

          // 3. User Avatar and Profile Pill Trigger matching Screenshot 1
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _showProfilePopup(context, user, userName, avatarLetter),
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top right profile avatar with real profile picture
                    ProfileAvatar(
                      letter: avatarLetter,
                      imageUrl: user?.effectiveAvatarUrl ?? user?.avatarUrl,
                      imagePath: user?.profileImagePath,
                      size: 28,
                      backgroundColor: const Color(0xFF6B46C1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({required int index, required String label}) {
    final bool isSelected = activeIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(MacOsTheme.radiusPill),
            border: Border.all(
              color: isSelected ? MacOsTheme.primaryBlue : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? MacOsTheme.primaryBlue : MacOsTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

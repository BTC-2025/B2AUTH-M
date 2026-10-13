import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/account_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/notifiers/auth_notifier.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of B2Auth? You will be redirected to the Login Screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthNotifier>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDrawer = Scaffold.of(context).hasDrawer;
    final user = context.watch<AccountProvider>().selectedAccount;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkShadow,
            offset: Offset(4, 0),
            blurRadius: 10,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, isDrawer ? 24 : 32, 16, 32),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Transform.scale(
                        scale: 1.5,
                        child: Image.asset(
                          'assets/Auth_img.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.shield_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'B2Auth',
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 18,
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _SidebarItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              isSelected: selectedIndex == 0,
              onTap: () => onItemSelected(0),
            ),
            _SidebarItem(
              icon: Icons.security_outlined,
              label: 'Security',
              isSelected: selectedIndex == 1,
              onTap: () => onItemSelected(1),
            ),
            _SidebarItem(
              icon: Icons.notifications_none_outlined,
              label: 'Notifications',
              isSelected: selectedIndex == 2,
              onTap: () => onItemSelected(2),
            ),
            _SidebarItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              isSelected: selectedIndex == 3,
              onTap: () => onItemSelected(3),
            ),
            const Spacer(),
            if (user != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Signed in as ${user.displayName}',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ),
              const SizedBox(height: 8),
            ],
            _SidebarItem(
              icon: Icons.logout_outlined,
              label: 'Sign Out',
              isSelected: false,
              onTap: () => _showSignOutDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isSelected
                  ? [
                      // Inset/Selected state
                      BoxShadow(
                        color: AppColors.darkShadow.withValues(alpha: 0.8),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                      const BoxShadow(
                        color: AppColors.lightShadow,
                        offset: Offset(-2, -2),
                        blurRadius: 4,
                      ),
                    ]
                  : (_isHovered
                        ? [
                            // Hover state
                            const BoxShadow(
                              color: AppColors.darkShadow,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                            const BoxShadow(
                              color: AppColors.lightShadow,
                              offset: Offset(-2, -2),
                              blurRadius: 4,
                            ),
                          ]
                        : []),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: AppTextStyles.body.copyWith(
                    color: widget.isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

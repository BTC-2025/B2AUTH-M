import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'profile_avatar.dart';
import 'neumorphic_card.dart';

class IdentityCard extends StatelessWidget {
  final String name;
  final String email;
  final bool isCurrent;
  final VoidCallback? onTap;
  final String? avatarUrl;
  final String? profileImagePath;

  const IdentityCard({
    super.key,
    required this.name,
    required this.email,
    this.isCurrent = false,
    this.onTap,
    this.avatarUrl,
    this.profileImagePath,
  });

  void _showAccountMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Manage $name', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 20),
                _buildMenuItem(context, Icons.edit_outlined, 'Rename'),
                _buildMenuItem(context, Icons.copy_outlined, 'Copy Email'),
                _buildMenuItem(context, Icons.star_outline, 'Make Primary'),
                _buildMenuItem(context, Icons.delete_outline, 'Delete Account', isDestructive: true),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label, {bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary),
        title: Text(label, style: TextStyle(color: isDestructive ? AppColors.error : AppColors.textPrimary)),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label clicked for $email'), behavior: SnackBarBehavior.floating),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      isInset: isCurrent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => print('Switching to account: $email'),
          onLongPress: () => _showAccountMenu(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ProfileAvatar(
                  letter: name.isNotEmpty ? name[0] : 'R',
                  size: 40,
                  backgroundColor: isCurrent ? AppColors.primary : AppColors.textSecondary,
                  imageUrl: avatarUrl,
                  imagePath: profileImagePath,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name, 
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold, 
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email, 
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
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
}

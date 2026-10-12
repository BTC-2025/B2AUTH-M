import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;
  final bool showDivider;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
    this.showDivider = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => debugPrint('$title clicked'),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center aligned for better list feel
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description, 
                        style: AppTextStyles.caption.copyWith(height: 1.2, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: 4),
            Divider(color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

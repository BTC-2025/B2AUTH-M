import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(0xFF6B7280)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.sectionTitle,
                softWrap: true,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.subtitle,
            softWrap: true,
          ),
        ],
      ],
    );
  }
}

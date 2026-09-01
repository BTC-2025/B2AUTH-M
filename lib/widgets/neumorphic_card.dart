import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final String? title;
  final Widget? trailing;
  final bool isInset;
  final Color? color;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.padding = const EdgeInsets.all(20),
    this.title,
    this.trailing,
    this.isInset = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.background,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isInset 
          ? [
              // Inset shadow simulation (subtle)
              BoxShadow(
                color: AppColors.darkShadow.withValues(alpha: 0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: AppColors.lightShadow.withValues(alpha: 0.8),
                offset: const Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: -2,
              ),
            ]
          : [
              // Standard Raised Neumorphic Shadow
              const BoxShadow(
                color: AppColors.darkShadow,
                offset: Offset(8, 8),
                blurRadius: 16,
              ),
              const BoxShadow(
                color: AppColors.lightShadow,
                offset: Offset(-8, -8),
                blurRadius: 16,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null || trailing != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

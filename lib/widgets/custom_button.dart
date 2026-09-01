import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final bool isPremium;
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.isPremium = false,
    this.backgroundColor,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? (widget.isPremium ? AppColors.primary : AppColors.background),
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.isPremium 
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                )
              ]
            : (_isPressed
                ? [
                    // Pressed/Inset effect
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
                : [
                    // Standard raised effect
                    const BoxShadow(
                      color: AppColors.darkShadow,
                      offset: Offset(4, 4),
                      blurRadius: 8,
                    ),
                    const BoxShadow(
                      color: AppColors.lightShadow,
                      offset: Offset(-4, -4),
                      blurRadius: 8,
                    ),
                  ]),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon, 
                size: 18, 
                color: widget.isPremium ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                widget.text,
                style: AppTextStyles.button.copyWith(
                  color: widget.isPremium ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

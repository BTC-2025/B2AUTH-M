import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String hint;
  final IconData? leadingIcon;
  final TextEditingController? controller;
  final bool isEnabled;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    this.label,
    String? hint,
    String? hintText,
    this.leadingIcon,
    this.controller,
    this.isEnabled = true,
    this.onChanged,
  }) : hint = hint ?? hintText ?? '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label!, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              // Inset shadow simulation
              BoxShadow(
                color: AppColors.darkShadow.withValues(alpha: 0.8),
                offset: const Offset(4, 4),
                blurRadius: 8,
                spreadRadius: -2,
              ),
              const BoxShadow(
                color: AppColors.lightShadow,
                offset: Offset(-4, -4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: isEnabled,
            onChanged: onChanged,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              prefixIcon: leadingIcon != null ? Icon(leadingIcon, size: 20, color: AppColors.primary) : null,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

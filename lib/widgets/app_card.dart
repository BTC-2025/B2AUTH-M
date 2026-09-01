import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final double? height;
  final bool isHoverable;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.height,
    this.isHoverable = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.isHoverable ? setState(() => _isHovered = true) : null,
      onExit: (_) => widget.isHoverable ? setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: _isHovered 
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null || widget.trailing != null) ...[
              Row(
                children: [
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    widget.trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
            widget.child,
          ],
        ),
      ),
    );
  }
}

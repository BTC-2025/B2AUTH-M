import 'package:flutter/material.dart';
import '../core/providers/zero_trust_provider.dart';
import '../core/theme/app_colors.dart';
import 'glass_card.dart';

class PolicyRuleCard extends StatelessWidget {
  final ZeroTrustPolicy policy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const PolicyRuleCard({
    super.key,
    required this.policy,
    required this.onToggle,
    required this.onDelete,
  });

  Color _getActionColor(PolicyAction action) {
    switch (action) {
      case PolicyAction.deny:
        return AppColors.errorRed;
      case PolicyAction.requireHardwareKey:
        return Colors.amber.shade800;
      case PolicyAction.requireMfa:
        return AppColors.primaryBlue;
      case PolicyAction.allow:
        return AppColors.successGreen;
    }
  }

  String _getActionLabel(PolicyAction action) {
    switch (action) {
      case PolicyAction.deny:
        return 'DENY ACCESS';
      case PolicyAction.requireHardwareKey:
        return 'REQUIRE HARDWARE KEY';
      case PolicyAction.requireMfa:
        return 'STEP-UP MFA';
      case PolicyAction.allow:
        return 'ALLOW ACCESS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _getActionColor(policy.actionThen);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  policy.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const Spacer(),
              Switch(
                value: policy.isEnabled,
                onChanged: onToggle,
                activeThumbColor: AppColors.primaryBlue,
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            policy.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: policy.isEnabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'IF ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        policy.conditionIf,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_right_alt_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'THEN ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getActionLabel(policy.actionThen),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: actionColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

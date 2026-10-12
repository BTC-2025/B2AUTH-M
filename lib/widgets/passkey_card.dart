import 'package:flutter/material.dart';
import '../core/providers/passkey_provider.dart';
import '../core/theme/app_colors.dart';
import 'glass_card.dart';

class PasskeyCard extends StatelessWidget {
  final PasskeyItem item;
  final VoidCallback onDelete;

  const PasskeyCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  IconData _getKeyIcon(PasskeyType type) {
    switch (type) {
      case PasskeyType.biometric:
        return Icons.fingerprint_rounded;
      case PasskeyType.yubikeyUsb:
        return Icons.usb_rounded;
      case PasskeyType.yubikeyNfc:
        return Icons.nfc_rounded;
      case PasskeyType.windowsHello:
        return Icons.laptop_windows_rounded;
    }
  }

  Color _getKeyColor(PasskeyType type) {
    switch (type) {
      case PasskeyType.biometric:
        return AppColors.primaryBlue;
      case PasskeyType.yubikeyUsb:
      case PasskeyType.yubikeyNfc:
        return Colors.amber.shade700;
      case PasskeyType.windowsHello:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getKeyColor(item.type);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_getKeyIcon(item.type), color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.deviceName} • Last active ${_formatTimeAgo(item.lastUsed)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.isSynced ? AppColors.successGreen.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  size: 12,
                  color: item.isSynced ? AppColors.successGreen : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  item.isSynced ? 'Synced' : 'Local',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: item.isSynced ? AppColors.successGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
            onPressed: onDelete,
            tooltip: 'Remove Key',
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

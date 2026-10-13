import 'package:flutter/material.dart';
import '../../widgets/neumorphic_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import 'package:provider/provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _searchController = TextEditingController();

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notifications', style: AppTextStyles.pageTitle),
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.filter_list,
                    label: 'Filter',
                    onTap: () => _showFeedback('Filter clicked'),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.swap_vert,
                    label: 'Sort',
                    onTap: provider.toggleSort,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: provider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search notifications...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (notifications.isEmpty)
            const Center(child: Text('No notifications found'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Dismissible(
                  key: Key(n.id),
                  onDismissed: (_) => provider.deleteNotification(n.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: _buildNotificationCard(
                    icon: _getIconForCategory(n.category),
                    iconColor: _getColorForCategory(n.category),
                    title: n.title,
                    message: n.message,
                    time: 'Just now', // Mock time
                    isCritical: n.category == NotificationCategory.critical,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.critical:
        return Icons.security;
      case NotificationCategory.devices:
        return Icons.smartphone;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForCategory(NotificationCategory cat) {
    switch (cat) {
      case NotificationCategory.critical:
        return AppColors.error;
      case NotificationCategory.devices:
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkShadow.withValues(alpha: 0.8),
              offset: const Offset(3, 3),
              blurRadius: 6,
            ),
            const BoxShadow(
              color: AppColors.lightShadow,
              offset: Offset(-3, -3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    bool isCritical = false,
  }) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showFeedback('Notification Details: $title'),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCritical) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Critical',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/settings_provider.dart';
import 'doc_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Terms of Service Tile
            _buildLinkCard(
              context: context,
              title: 'Terms of service',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocScreen(title: 'Terms of service'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Privacy Policy Tile
            _buildLinkCard(
              context: context,
              title: 'Privacy policy',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocScreen(title: 'Privacy policy'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Main Settings Switch Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Share usage stats',
                    subtitle:
                        'Share usage stats with our developers. This helps us improve the app.',
                    value: settings.shareUsageStats,
                    onChanged: (val) => settings.setShareUsageStats(val),
                    accentColor: settings.accentColor,
                    showDivider: true,
                  ),
                  _buildSwitchTile(
                    title: 'Share your email address',
                    subtitle:
                        'By sharing your email address with usage stats, we can better troubleshoot any problems you might encounter and contact you if necessary.',
                    value: settings.shareEmailAddress,
                    onChanged: (val) => settings.setShareEmailAddress(val),
                    accentColor: settings.accentColor,
                    showDivider: true,
                  ),
                  _buildSwitchTile(
                    title: 'Enable crash reporting',
                    subtitle:
                        'Share crash data with our developers if the app shuts abruptly. This will help us identify bugs and put out fixes.',
                    value: settings.enableCrashReporting,
                    onChanged: (val) => settings.setEnableCrashReporting(val),
                    accentColor: settings.accentColor,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shake to send feedback Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildSwitchTile(
                title: 'Shake to send feedback',
                subtitle:
                    'Shake your device to send us feedback or report a bug.',
                value: settings.shakeToSendFeedback,
                onChanged: (val) => settings.setShakeToSendFeedback(val),
                accentColor: settings.accentColor,
                showDivider: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: accentColor,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: AppColors.border,
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/settings_provider.dart';
import 'language_screen.dart';

class PersonalizeScreen extends StatelessWidget {
  const PersonalizeScreen({super.key});

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
          'Personalize',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LANGUAGE Header
            _buildSectionHeader('LANGUAGE'),
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: const Text(
                    'Select Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    settings.language,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // DEFAULT HOMEPAGE Header
            _buildSectionHeader('DEFAULT HOMEPAGE'),
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
              child: Text(
                'Select the tab to view when you open B2Auth',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
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
                  _buildSelectableTile(
                    title: 'MFA',
                    isSelected: settings.defaultHomepage == 'mfa',
                    accentColor: settings.accentColor,
                    onTap: () => settings.setDefaultHomepage('mfa'),
                    showDivider: true,
                  ),
                  _buildSelectableTile(
                    title: 'Authenticator',
                    isSelected: settings.defaultHomepage == 'authenticator',
                    accentColor: settings.accentColor,
                    onTap: () => settings.setDefaultHomepage('authenticator'),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // THEME Header
            _buildSectionHeader('THEME'),
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
                  _buildSelectableTile(
                    title: 'Follow device theme',
                    isSelected: settings.themeMode == ThemeMode.system,
                    accentColor: settings.accentColor,
                    onTap: () => settings.setThemeMode(ThemeMode.system),
                    showDivider: true,
                  ),
                  _buildSelectableTile(
                    title: 'Light',
                    isSelected: settings.themeMode == ThemeMode.light,
                    accentColor: settings.accentColor,
                    onTap: () => settings.setThemeMode(ThemeMode.light),
                    showDivider: true,
                  ),
                  _buildSelectableTile(
                    title: 'Dark',
                    isSelected: settings.themeMode == ThemeMode.dark,
                    accentColor: settings.accentColor,
                    onTap: () => settings.setThemeMode(ThemeMode.dark),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF667085),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSelectableTile({
    required String title,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: accentColor,
                  size: 24,
                )
              : null,
          onTap: onTap,
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

import 'package:flutter/material.dart';
import '../theme/macos_theme.dart';

class MacOsSidebar extends StatelessWidget {
  final int selectedFilterIndex;
  final ValueChanged<int> onFilterSelected;
  final VoidCallback onAddAccount;
  final VoidCallback onSignOut;

  const MacOsSidebar({
    super.key,
    required this.selectedFilterIndex,
    required this.onFilterSelected,
    required this.onAddAccount,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: MacOsTheme.border, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title: "YOUR ACCOUNTS"
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 16),
            child: Text(
              'YOUR ACCOUNTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MacOsTheme.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Menu Items
          _buildItem(
            index: 0,
            icon: Icons.mail_outline_rounded,
            label: 'All Accounts',
          ),
          const SizedBox(height: 4),
          _buildItem(
            index: 1,
            icon: Icons.check_circle_outline_rounded,
            label: 'Primary Account',
          ),
          const SizedBox(height: 4),
          _buildItem(
            index: 2,
            icon: Icons.domain_outlined,
            label: 'Business Account',
          ),
          const SizedBox(height: 4),
          _buildItem(
            index: 3,
            icon: Icons.person_outline_rounded,
            label: 'Personal Account',
          ),
          const SizedBox(height: 4),
          _buildItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            label: 'Child Account',
          ),

          const SizedBox(height: 16),

          // Add Account Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onAddAccount,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: const [
                    Icon(Icons.add, size: 16, color: MacOsTheme.textSecondary),
                    SizedBox(width: 12),
                    Text(
                      'Add account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: MacOsTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Bottom: Sign Out
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onSignOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded, size: 16, color: MacOsTheme.textSecondary),
                    SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: MacOsTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedFilterIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onFilterSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0F5FE) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? MacOsTheme.primaryBlue : MacOsTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? MacOsTheme.primaryBlue : MacOsTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

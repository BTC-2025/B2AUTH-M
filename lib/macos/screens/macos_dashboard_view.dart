import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/models/user_account.dart';
import '../../widgets/profile_avatar.dart';
import '../theme/macos_theme.dart';

class MacOsDashboardView extends StatefulWidget {
  final int selectedFilterIndex; // 0: All, 1: Primary, 2: Business, 3: Personal, 4: Child

  const MacOsDashboardView({
    super.key,
    this.selectedFilterIndex = 0,
  });

  @override
  State<MacOsDashboardView> createState() => _MacOsDashboardViewState();
}

class _MacOsDashboardViewState extends State<MacOsDashboardView> {
  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: MacOsTheme.brandBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MacOsTheme.radiusSmall)),
        width: 380,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final selectedUser = accountProvider.selectedAccount;

    if (selectedUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final rawAccounts = accountProvider.accounts;
    final Map<String, UserAccount> uniqueAccountsMap = {};
    for (var a in rawAccounts) {
      final key = a.email.trim().toLowerCase();
      if (key.isNotEmpty) {
        if (!uniqueAccountsMap.containsKey(key) || a.isPrimary) {
          uniqueAccountsMap[key] = a;
        }
      }
    }
    final accounts = uniqueAccountsMap.values.toList();
    final primaryAccount = accounts.firstWhere(
      (a) => a.isPrimary,
      orElse: () => selectedUser,
    );

    // Filter accounts based on sidebar selection matching the design specifications
    List<UserAccount> filteredAccounts = [];
    IconData categoryIcon = Icons.business_center_outlined;
    String categoryTitle = 'BUSINESS ACCOUNTS';
    String emptyMessage = 'No business accounts found.';

    switch (widget.selectedFilterIndex) {
      case 1:
        categoryIcon = Icons.check_circle_outline_rounded;
        categoryTitle = 'PRIMARY ACCOUNTS';
        emptyMessage = 'No primary accounts found.';
        filteredAccounts = accounts.where((a) => a.isPrimary).toList();
        break;
      case 2:
        categoryIcon = Icons.smartphone_rounded;
        categoryTitle = 'BUSINESS ACCOUNTS';
        emptyMessage = 'No business accounts found.';
        // Shows business identities (or primary identity if it acts as the business profile)
        filteredAccounts = accounts.where((a) => a.type == AccountType.business || a.type == AccountType.work || (accounts.length == 1 && a.id == selectedUser.id)).toList();
        break;
      case 3:
        categoryIcon = Icons.person_outline_rounded;
        categoryTitle = 'PERSONAL ACCOUNTS';
        emptyMessage = 'No personal accounts found.';
        filteredAccounts = accounts.where((a) => a.type == AccountType.personal && accounts.length > 1).toList();
        break;
      case 4:
        categoryIcon = Icons.person_outline_rounded;
        categoryTitle = 'CHILD ACCOUNTS';
        emptyMessage = 'No child accounts found.';
        filteredAccounts = [];
        break;
      case 0:
      default:
        categoryIcon = Icons.smartphone_rounded;
        categoryTitle = 'BUSINESS ACCOUNTS';
        emptyMessage = 'No accounts found.';
        filteredAccounts = accounts;
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Admin Section
          const Text(
            'Admin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MacOsTheme.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your linked mail accounts and primary address.',
            style: TextStyle(
              fontSize: 14,
              color: MacOsTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),

          // Admin Mail Account Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MacOsTheme.radiusCard),
              border: Border.all(color: MacOsTheme.border, width: 1.0),
              boxShadow: MacOsTheme.cardShadow,
            ),
            child: Row(
              children: [
                // Primary Account Circular Profile Avatar
                ProfileAvatar(
                  letter: primaryAccount.avatarLetter.isNotEmpty ? primaryAccount.avatarLetter : 'R',
                  imageUrl: primaryAccount.effectiveAvatarUrl ?? primaryAccount.avatarUrl,
                  imagePath: primaryAccount.profileImagePath,
                  size: 44,
                  backgroundColor: const Color(0xFF6B46C1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryAccount.email,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: MacOsTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            primaryAccount.username.isNotEmpty ? primaryAccount.username : 'user',
                            style: const TextStyle(
                              fontSize: 13,
                              color: MacOsTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: MacOsTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 13,
                              color: MacOsTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Green PRIMARY Badge matching screenshot
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: MacOsTheme.successLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: MacOsTheme.successBorder, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.workspace_premium_outlined, color: MacOsTheme.success, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'PRIMARY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: MacOsTheme.success,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 2. Logged-in Identities Section
          const Text(
            'Logged-in Identities',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: MacOsTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quickly switch between your active B2Auth accounts.',
            style: TextStyle(
              fontSize: 14,
              color: MacOsTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 24),

          // Category Subheader matching selected filter
          Row(
            children: [
              Icon(categoryIcon, size: 15, color: MacOsTheme.textTertiary),
              const SizedBox(width: 8),
              Text(
                categoryTitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MacOsTheme.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Identity Cards or Empty State Dashed Container
          if (filteredAccounts.isEmpty)
            CustomPaint(
              painter: const DashedBorderPainter(
                color: Color(0xFFCBD5E1),
                radius: 12.0,
                dashWidth: 5.0,
                dashSpace: 4.0,
              ),
              child: Container(
                width: double.infinity,
                height: 56,
                alignment: Alignment.center,
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            ...filteredAccounts.map((acc) {
              final bool isCurrent = acc.id == selectedUser.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFFF6F8FE) : Colors.white,
                  borderRadius: BorderRadius.circular(MacOsTheme.radiusCard),
                  border: Border.all(
                    color: isCurrent ? const Color(0xFFD6E2FB) : MacOsTheme.border,
                    width: 1.2,
                  ),
                  boxShadow: MacOsTheme.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(MacOsTheme.radiusCard),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Left vertical purple accent bar if current
                        if (isCurrent)
                          Container(
                            width: 4,
                            color: const Color(0xFF4F46E5),
                          ),
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                if (!isCurrent) {
                                  accountProvider.switchAccount(acc.id);
                                  _showFeedback('Switched to ${acc.displayName}');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    // Circular Profile Avatar with fallback to uppercase letter
                                    ProfileAvatar(
                                      letter: acc.avatarLetter.isNotEmpty ? acc.avatarLetter : 'R',
                                      imageUrl: acc.effectiveAvatarUrl ?? acc.avatarUrl,
                                      imagePath: acc.profileImagePath,
                                      size: 44,
                                      backgroundColor: const Color(0xFF6B46C1),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                acc.displayName.isNotEmpty ? acc.displayName : acc.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: MacOsTheme.textPrimary,
                                                ),
                                              ),
                                              if (isCurrent) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEEF2FF),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Text(
                                                    'CURRENT',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF4F46E5),
                                                      letterSpacing: 0.6,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            acc.email,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: MacOsTheme.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Right Chevron in subtle container
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isCurrent ? const Color(0xFFEEF2FF) : MacOsTheme.pillBackground,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: isCurrent ? const Color(0xFF4F46E5) : MacOsTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Custom painter to draw rounded rectangle dashed border matching empty state in designs
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  const DashedBorderPainter({
    this.color = const Color(0xFFCBD5E1),
    this.strokeWidth = 1.0,
    this.radius = 12.0,
    this.dashWidth = 5.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashWidth, metric.length - distance);
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => false;
}

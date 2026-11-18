import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers/account_provider.dart';
import '../screens/manage_account_screen.dart';

/// Desktop & Web dropdown account profile card.
/// Matches the official profile popup card with account switcher,
/// quick navigation, and sign out actions.
class AccountMenuCard extends ConsumerWidget {
  final VoidCallback? onClose;
  final VoidCallback? onManageBranches;
  final VoidCallback? onManageSubIds;
  final VoidCallback? onAddAccount;
  final VoidCallback? onSignOut;

  const AccountMenuCard({
    super.key,
    this.onClose,
    this.onManageBranches,
    this.onManageSubIds,
    this.onAddAccount,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAccount = ref.watch(activeAccountProvider);
    final email = activeAccount.email.trim().isNotEmpty
        ? activeAccount.email.trim()
        : '';
    final username = email.contains('@')
        ? email.split('@').first
        : (activeAccount.name.isNotEmpty ? activeAccount.name : 'User');
    final initialLetter = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with camera badge
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D68BD),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (activeAccount.avatarUrl != null &&
                              activeAccount.avatarUrl!.isNotEmpty)
                          ? Image.network(
                              activeAccount.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Text(
                                  initialLetter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initialLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 13,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // User Display Name
                Text(
                  activeAccount.name.isNotEmpty
                      ? activeAccount.name
                      : username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),

                // User Email
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),

                // Active Account Status Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle_outline,
                        size: 12,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Active Account',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Manage your account button
                InkWell(
                  onTap: () {
                    onClose?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageAccountScreen(initialTab: 0),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Color(0xFF374151),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Manage your account',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Switch Account: Other Available Accounts List
                Builder(
                  builder: (context) {
                    final allAccounts = ref.watch(accountsProvider);
                    final otherAccounts = allAccounts
                        .where((a) =>
                            !a.isActive &&
                            a.id != 'loading' &&
                            a.email.isNotEmpty)
                        .toList();

                    if (otherAccounts.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SWITCH ACCOUNT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              Text(
                                '${otherAccounts.length} other ${otherAccounts.length == 1 ? "ID" : "IDs"}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...otherAccounts.map((acc) {
                          final accInitial = acc.name.isNotEmpty
                              ? acc.name[0].toUpperCase()
                              : (acc.email.isNotEmpty
                                  ? acc.email[0].toUpperCase()
                                  : 'U');
                          return InkWell(
                            onTap: () {
                              ref
                                  .read(accountsProvider.notifier)
                                  .switchAccount(acc.id, ref);
                              onClose?.call();
                            },
                            borderRadius: BorderRadius.circular(10),
                            hoverColor: const Color(0xFFF9FAFB),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 7),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        const Color(0xFF0D9488),
                                    backgroundImage: (acc.avatarUrl != null &&
                                            acc.avatarUrl!.isNotEmpty)
                                        ? NetworkImage(acc.avatarUrl!)
                                        : null,
                                    child: (acc.avatarUrl == null ||
                                            acc.avatarUrl!.isEmpty)
                                        ? Text(
                                            accInitial,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          acc.name.isNotEmpty
                                              ? acc.name
                                              : acc.email.split('@').first,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          acc.email,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 14),
                                    color: const Color(0xFF9CA3AF),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    tooltip: 'Remove account',
                                    onPressed: () {
                                      ref
                                          .read(accountsProvider.notifier)
                                          .signOutSingleAccount(
                                            targetEmail: acc.email,
                                            ref: ref,
                                            context: context,
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 4),

                // Manage Branches Menu Item
                _buildMenuItem(
                  icon: Icons.storefront_outlined,
                  title: 'Manage Branches',
                  onTap: () {
                    onClose?.call();
                    onManageBranches?.call();
                  },
                ),

                // Manage SubIDs Menu Item
                _buildMenuItem(
                  icon: Icons.people_outline,
                  title: 'Manage SubIDs',
                  onTap: () {
                    onClose?.call();
                    onManageSubIds?.call();
                  },
                ),

                // Add Another Account Menu Item
                _buildMenuItem(
                  icon: Icons.person_add_outlined,
                  title: 'Add another account',
                  onTap: () {
                    onClose?.call();
                    onAddAccount?.call();
                  },
                ),

                // Sign Out of All Accounts Menu Item
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Sign out of all accounts',
                  onTap: () async {
                    onClose?.call();
                    await ref.read(accountsProvider.notifier).signOutSingleAccount(
                          targetEmail: activeAccount.email,
                          ref: ref,
                          context: context,
                          onAllAccountsLoggedOut: onSignOut,
                        );
                  },
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),

                // Sign Out Button
                InkWell(
                  onTap: () async {
                    onClose?.call();
                    await ref.read(accountsProvider.notifier).signOutSingleAccount(
                          targetEmail: activeAccount.email,
                          ref: ref,
                          context: context,
                          onAllAccountsLoggedOut: onSignOut,
                        );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.logout,
                          size: 15,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sign out',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      hoverColor: const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF4B5563),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

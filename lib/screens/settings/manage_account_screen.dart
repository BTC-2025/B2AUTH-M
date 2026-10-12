import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/models/user_account.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/login_screen.dart';
import '../auth/notifiers/auth_notifier.dart';

class ManageAccountScreen extends StatefulWidget {
  final int initialTab;
  const ManageAccountScreen({super.key, this.initialTab = 0});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedTab;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Active Workspace State
  String _selectedWorkspace = 'BNX Tech Enterprise';
  String _userRole = 'Senior Product Lead';
  final List<String> _workspaces = [
    'BNX Tech Enterprise',
    'Cliks Corporate Suite',
    'Bit Tool Developer Lab',
  ];

  // Shared Mailboxes State
  final List<Map<String, String>> _sharedMailboxes = [
    {
      'email': 'tech-leads@bnxmail.com',
      'subtitle': 'Primary Shared Mailbox • Delegate Access Granted',
    },
  ];

  // Subscription State
  final String _subPlanName = 'Cliks Business';
  final String _subPrice = '\$29/month';
  final String _subRenewalDate = 'Aug 15, 2026';
  String _subPaymentMethod = '•••• 4242 (Visa)';
  int _subTeamSeats = 25;

  // Advanced Privacy Toggles
  bool _zeroKnowledgeEncryption = true;
  bool _biometricLock = false;
  bool _webAppActivity = true;
  bool _locationScrubbing = true;
  bool _autoPurgeSearch = true;

  // Local state for fields
  DateTime? _birthday;
  String _language = 'English (US)';
  String _accessibility = 'Default';

  static const _brandBlue = Color(0xFF195BAC);
  static const _brandBlueLight = Color(0xFF2563EB);
  static const _accentGreen = Color(0xFF16A34A);

  final List<_TabItem> _tabs = const [
    _TabItem(title: 'Home', icon: Icons.grid_view_rounded, selectedIcon: Icons.grid_view_rounded),
    _TabItem(title: 'Personal information', icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded),
    _TabItem(title: 'Payment and subscription', icon: Icons.card_membership_rounded, selectedIcon: Icons.card_membership_rounded),
    _TabItem(title: 'Account storage', icon: Icons.cloud_outlined, selectedIcon: Icons.cloud_rounded),
    _TabItem(title: 'B2 auth', icon: Icons.security_outlined, selectedIcon: Icons.security_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (mounted) {
      context.read<AccountProvider>().clearAccounts();
      context.read<AuthNotifier>().logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _switchTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final user = accountProvider.selectedAccount;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No account found')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    const bgColor = Color(0xFFE9F4FF);
    const surfaceColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(surfaceColor),
            Expanded(
              child: isMobile
                  ? _buildMobileLayout(user, surfaceColor)
                  : _buildDesktopLayout(user, surfaceColor),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP APP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAppBar(Color surfaceColor) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF475569),
            ),
            tooltip: 'Back',
          ),
          // Top Left Brand Logo Container
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _brandBlue,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: _brandBlue.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/beta_logo .jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _brandBlue,
                  child: const Center(
                    child: Text(
                      'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'My Account',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
            tooltip: 'Help',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(UserAccount user, Color surfaceColor) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final isSelected = _selectedTab == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _switchTab(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(colors: [_brandBlue, _brandBlueLight])
                            : null,
                        color: isSelected ? null : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [BoxShadow(color: _brandBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? tab.selectedIcon : tab.icon,
                            size: 16,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              key: ValueKey<int>(_selectedTab),
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: _buildActiveTabContent(user, true),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(UserAccount user, Color surfaceColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 240,
          child: Container(
            color: surfaceColor,
            child: Column(
              children: [
                const SizedBox(height: 16),
                ...List.generate(_tabs.length, (index) {
                  final tab = _tabs[index];
                  final isSelected = _selectedTab == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: InkWell(
                      onTap: () => _switchTab(index),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [_brandBlue.withValues(alpha: 0.12), _brandBlueLight.withValues(alpha: 0.06)])
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected ? Border.all(color: _brandBlue.withValues(alpha: 0.2), width: 1) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? tab.selectedIcon : tab.icon,
                              size: 20,
                              color: isSelected ? _brandBlue : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tab.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? _brandBlue : const Color(0xFF334155),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: InkWell(
                    onTap: _handleSignOut,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                          SizedBox(width: 12),
                          Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: SingleChildScrollView(
                  key: ValueKey<int>(_selectedTab),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: _buildActiveTabContent(user, false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB ROUTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActiveTabContent(UserAccount user, bool isMobile) {
    switch (_selectedTab) {
      case 0:
        return _buildHomeTab(user, isMobile);
      case 1:
        return _buildPersonalInfoTab(user, isMobile);
      case 2:
        return _buildPaymentAndSubscriptionTab(user, isMobile);
      case 3:
        return _buildAccountStorageTab(user, isMobile);
      case 4:
        return _buildB2AuthTab(user, isMobile);
      default:
        return _buildHomeTab(user, isMobile);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 0. HOME TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeTab(UserAccount user, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHero(user),

        // Quick Links Grid
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Quick Links', Icons.flash_on_rounded),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: isMobile ? 2 : 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                children: [
                  _buildQuickLinkChip(Icons.person_rounded, 'Profile', _brandBlue, () => _switchTab(1)),
                  _buildQuickLinkChip(Icons.lock_rounded, 'Security', _brandBlue, () => _switchTab(4)),
                  _buildQuickLinkChip(Icons.credit_card_rounded, 'Billing', _brandBlue, () => _switchTab(2)),
                  _buildQuickLinkChip(Icons.cloud_rounded, 'Storage', _brandBlue, () => _switchTab(3)),
                  _buildQuickLinkChip(Icons.palette_rounded, 'Theme', _brandBlue, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Theme settings coming soon'), behavior: SnackBarBehavior.floating),
                    );
                  }),
                  _buildQuickLinkChip(Icons.notifications_rounded, 'Alerts', _brandBlue, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alert settings coming soon'), behavior: SnackBarBehavior.floating),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Active Workspace
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Active Workspace', Icons.workspaces_rounded),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_brandBlue.withValues(alpha: 0.06), _brandBlueLight.withValues(alpha: 0.03)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _brandBlue.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _brandBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business_rounded, color: _brandBlue, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedWorkspace,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userRole,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.unfold_more_rounded, color: Color(0xFF64748B)),
                      onSelected: (val) {
                        if (val == '_add') {
                          _showAddWorkspaceModal();
                        } else {
                          setState(() => _selectedWorkspace = val);
                        }
                      },
                      itemBuilder: (ctx) => [
                        ..._workspaces.map((ws) => PopupMenuItem(
                              value: ws,
                              child: Row(
                                children: [
                                  Icon(
                                    ws == _selectedWorkspace ? Icons.check_circle_rounded : Icons.circle_outlined,
                                    size: 18,
                                    color: ws == _selectedWorkspace ? _brandBlue : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(ws),
                                ],
                              ),
                            )),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: '_add',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 18, color: _accentGreen),
                              SizedBox(width: 10),
                              Text('Create Workspace', style: TextStyle(color: _accentGreen)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _editUserRole,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      const Text('Edit Role / Designation', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Shared Mailboxes
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Shared Mailboxes', Icons.mail_outline_rounded),
                  IconButton(
                    onPressed: _showAddSharedMailboxModal,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: _accentGreen, size: 22),
                    tooltip: 'Add Shared Mailbox',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._sharedMailboxes.map((mb) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _brandBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.alternate_email_rounded, color: _brandBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mb['email']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                              Text(mb['subtitle']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF94A3B8)),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. PERSONAL INFO TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPersonalInfoTab(UserAccount user, bool isMobile) {
    final dobText = _birthday != null
        ? '${_birthday!.month}/${_birthday!.day}/${_birthday!.year}'
        : 'Not set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHero(user),

        // Profile Photo
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Profile Photo', Icons.camera_alt_outlined),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _brandBlue.withValues(alpha: 0.3), width: 2),
                          ),
                          child: ProfileAvatar(
                            letter: user.avatarLetter,
                            size: 80,
                            imagePath: user.profileImagePath,
                            imageUrl: user.avatarUrl,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Photo upload coming soon!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _brandBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Basic Info
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Basic Information', Icons.info_outline_rounded),
              const SizedBox(height: 12),
              _buildInfoRow('Full Name', user.name, Icons.person_outline_rounded, () => _editFullName(user)),
              _buildInfoRow('Username', '@${user.username}', Icons.alternate_email_rounded, () => _editUsername(user)),
              _buildInfoRow('Email', user.email, Icons.email_outlined, null),
              _buildInfoRow('Recovery Email', user.recoveryEmail ?? 'Not set', Icons.mark_email_read_outlined, () => _editRecoveryEmail(user)),
              _buildInfoRow('Phone', user.phoneNumber ?? 'Not set', Icons.phone_outlined, () => _editPhone(user)),
              _buildInfoRow('Birthday', dobText, Icons.cake_outlined, () => _selectBirthday(user)),
              _buildInfoRow('Account Type', user.type.name.toUpperCase(), Icons.badge_outlined, () => _editAccountType(user)),
              _buildInfoRow('Language', _language, Icons.language_rounded, () => _selectLanguage()),
              _buildInfoRow('Accessibility', _accessibility, Icons.accessibility_new_rounded, () => _selectAccessibility(), showDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. PAYMENT & SUBSCRIPTION TAB (FULLY RENDERED!)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPaymentAndSubscriptionTab(UserAccount user, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active Plan Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_brandBlue, _brandBlueLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _brandBlue.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _subPlanName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subPrice,
                          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildSubStat('Next Renewal', _subRenewalDate, Icons.event_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSubStat('Payment Method', _subPaymentMethod, Icons.credit_card_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSubStat('Team Allocations', '$_subTeamSeats Active Seats', Icons.group_rounded)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Management Actions
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Subscription Controls', Icons.tune_rounded),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.upgrade_rounded,
                iconColor: _brandBlue,
                title: 'Upgrade Plan',
                subtitle: 'Unlock premium enterprise features & higher limits',
                onTap: () => _showManageSubscriptionDialog(),
              ),
              _buildActionTile(
                icon: Icons.credit_card_rounded,
                iconColor: const Color(0xFF0EA5E9),
                title: 'Update Payment Method',
                subtitle: 'Manage your primary credit card or PayPal',
                onTap: () => _showEditPaymentMethodDialog(),
              ),
              _buildActionTile(
                icon: Icons.group_add_rounded,
                iconColor: _accentGreen,
                title: 'Manage Team Seats',
                subtitle: 'Add or adjust seats for your team members',
                onTap: () => _showEditSeatsDialog(),
              ),
              _buildActionTile(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFFF97316),
                title: 'Billing History & Invoices',
                subtitle: 'Download past payment receipts and tax invoices',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Billing history & invoices loaded'), behavior: SnackBarBehavior.floating),
                  );
                },
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Payment Methods Section
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Payment Methods', Icons.payment_rounded),
                  IconButton(
                    onPressed: _showEditPaymentMethodDialog,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: _brandBlue, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _brandBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.credit_card_rounded, color: _brandBlue, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_subPaymentMethod, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          const Text('Default Payment Method • Expires 12/28', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('DEFAULT', style: TextStyle(color: _accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ACCOUNT STORAGE TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAccountStorageTab(UserAccount user, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Storage Overview', Icons.cloud_outlined),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: user.storageUsage / 15.0,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(_brandBlue),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${user.storageUsage.toStringAsFixed(1)} GB used',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    '15.0 GB total',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildStorageBreakdownItem('B2 Auth Data', 0.02, _brandBlue),
              _buildStorageBreakdownItem('Identity Documents', 0.01, const Color(0xFF0EA5E9)),
              _buildStorageBreakdownItem('Backup Keys', 0.005, _accentGreen),
              _buildStorageBreakdownItem('Logs & Activity', 0.005, const Color(0xFFF97316)),

              const SizedBox(height: 20),
              _buildActionTile(
                icon: Icons.unarchive_outlined,
                iconColor: _accentGreen,
                title: 'Clean up space',
                subtitle: 'Remove large files and old data',
                onTap: () {},
              ),
              _buildActionTile(
                icon: Icons.add_shopping_cart_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Upgrade storage',
                subtitle: 'Get more space for your account',
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. B2 AUTH TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildB2AuthTab(UserAccount user, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_brandBlue, _brandBlueLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: _brandBlue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.security_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('B2 Auth Suite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Unified Identity & Security Management', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open B2 Auth App', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _brandBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Security Score
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Security Score', Icons.shield_outlined),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: user.securityScore / 100.0,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          user.securityScore >= 80 ? _accentGreen : (user.securityScore >= 50 ? Colors.orange : Colors.red),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${user.securityScore}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const Text('/ 100', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.securityScore >= 80 ? 'Excellent Security' : (user.securityScore >= 50 ? 'Good Security' : 'Needs Improvement'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: user.securityScore >= 80 ? _accentGreen : (user.securityScore >= 50 ? Colors.orange : Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Advanced Privacy
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Advanced Privacy', Icons.privacy_tip_outlined),
              const SizedBox(height: 12),
              _buildPrivacyToggle('Zero-Knowledge Encryption', 'End-to-end encrypted data at rest', _zeroKnowledgeEncryption, (v) => setState(() => _zeroKnowledgeEncryption = v)),
              _buildPrivacyToggle('Biometric Lock', 'Require fingerprint/face to open app', _biometricLock, (v) => setState(() => _biometricLock = v)),
              _buildPrivacyToggle('Web & App Activity', 'Track activity for personalized experience', _webAppActivity, (v) => setState(() => _webAppActivity = v)),
              _buildPrivacyToggle('Location Data Scrubbing', 'Remove location metadata from uploads', _locationScrubbing, (v) => setState(() => _locationScrubbing = v)),
              _buildPrivacyToggle('Auto-Purge Search History', 'Clear search history every 30 days', _autoPurgeSearch, (v) => setState(() => _autoPurgeSearch = v)),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE HERO CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileHero(UserAccount user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandBlue, _brandBlueLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _brandBlue.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: ProfileAvatar(
              letter: user.avatarLetter,
              size: 48,
              imagePath: user.profileImagePath,
              imageUrl: user.avatarUrl,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.type.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleSignOut,
            icon: Icon(Icons.logout_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGET HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _brandBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _brandBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, VoidCallback? onTap, {bool showDivider = true}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF64748B)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onTap != null) Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildQuickLinkChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubStat(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.65), fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageBreakdownItem(String label, double gb, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
          Text('${gb.toStringAsFixed(3)} GB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _brandBlue,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDIT DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════

  void _editFullName(UserAccount user) {
    final ctrl = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Full Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Enter full name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                user.name = newName;
                user.displayName = newName;
                user.avatarLetter = newName[0].toUpperCase();
                context.read<AccountProvider>().updateAccount(user);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editUsername(UserAccount user) {
    final ctrl = TextEditingController(text: user.username);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Username'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Username', hintText: 'Enter username'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newUsername = ctrl.text.trim();
              if (newUsername.isNotEmpty) {
                user.username = newUsername;
                context.read<AccountProvider>().updateAccount(user);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Username set to "@$newUsername"!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editRecoveryEmail(UserAccount user) {
    final ctrl = TextEditingController(text: user.recoveryEmail ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Recovery Email'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Recovery Email', hintText: 'user@example.com'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              user.recoveryEmail = ctrl.text.trim();
              context.read<AccountProvider>().updateAccount(user);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recovery email updated!'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPhone(UserAccount user) {
    final ctrl = TextEditingController(text: user.phoneNumber ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+1 234 567 8900'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              user.phoneNumber = ctrl.text.trim();
              context.read<AccountProvider>().updateAccount(user);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone number updated!'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _selectBirthday(UserAccount user) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthday = picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Birthday updated!'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _editAccountType(UserAccount user) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Account Type'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        children: AccountType.values.map((type) {
          final isSelected = user.type == type;
          return SimpleDialogOption(
            onPressed: () {
              user.type = type;
              context.read<AccountProvider>().updateAccount(user);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account type set to ${type.name.toUpperCase()}'), behavior: SnackBarBehavior.floating),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(type.name.toUpperCase(), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                if (isSelected) const Icon(Icons.check_rounded, color: _brandBlue, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _selectLanguage() {
    final langs = ['English (US)', 'English (UK)', 'Spanish', 'French', 'German', 'Hindi', 'Japanese', 'Chinese'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Language'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        children: langs.map((lang) {
          final isSelected = _language == lang;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _language = lang);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language set to $lang'), behavior: SnackBarBehavior.floating),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                if (isSelected) const Icon(Icons.check_rounded, color: _brandBlue, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _selectAccessibility() {
    final options = ['Default', 'High Contrast', 'Large Text', 'Screen Reader Optimized'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Accessibility Preference'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        children: options.map((opt) {
          final isSelected = _accessibility == opt;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _accessibility = opt);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Accessibility set to $opt'), behavior: SnackBarBehavior.floating),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(opt, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                if (isSelected) const Icon(Icons.check_rounded, color: _brandBlue, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _editUserRole() {
    final ctrl = TextEditingController(text: _userRole);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Role / Designation'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Role', hintText: 'e.g. Senior Product Lead'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newRole = ctrl.text.trim();
              if (newRole.isNotEmpty) {
                setState(() => _userRole = newRole);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Role updated!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddWorkspaceModal() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create New Workspace'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Workspace Name', hintText: 'e.g. Acme Corp Labs'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _workspaces.add(name);
                  _selectedWorkspace = name;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created & switched to "$name"!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddSharedMailboxModal() {
    final mailCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Shared Mailbox'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: mailCtrl, decoration: const InputDecoration(labelText: 'Mailbox Email', hintText: 'team@bnxmail.com')),
            const SizedBox(height: 10),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Description / Role', hintText: 'Support Shared Mailbox')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final email = mailCtrl.text.trim();
              if (email.isNotEmpty) {
                setState(() {
                  _sharedMailboxes.add({
                    'email': email,
                    'subtitle': titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Shared Mailbox Access',
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Shared Mailbox "$email" added!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Add Mailbox'),
          ),
        ],
      ),
    );
  }

  void _showManageSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Manage Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Plan: $_subPlanName ($_subPrice)', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Next Renewal: $_subRenewalDate'),
            Text('Payment Method: $_subPaymentMethod'),
            Text('Active Seats: $_subTeamSeats Seats'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditPaymentMethodDialog();
            },
            child: const Text('Edit Payment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showEditPaymentMethodDialog() {
    final ctrl = TextEditingController(text: _subPaymentMethod);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Payment Method'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Payment Method', hintText: '•••• 4242 (Visa)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                setState(() => _subPaymentMethod = val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment method updated!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditSeatsDialog() {
    final ctrl = TextEditingController(text: _subTeamSeats.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Manage Team Seats'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Number of Seats', hintText: '25'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                setState(() => _subTeamSeats = val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Team seats updated to $val!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;

  const _TabItem({required this.title, required this.icon, required this.selectedIcon});
}

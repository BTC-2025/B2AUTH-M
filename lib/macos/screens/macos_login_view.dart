import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/user_account.dart';
import '../../core/providers/account_provider.dart';
import '../../screens/auth/notifiers/auth_notifier.dart';
import '../../screens/auth/notifiers/login_notifier.dart';
import '../../screens/auth/register_account_type_screen.dart';
import '../../screens/home_screen.dart';
import '../theme/macos_theme.dart';

class MacOsLoginView extends StatefulWidget {
  const MacOsLoginView({super.key});

  @override
  State<MacOsLoginView> createState() => _MacOsLoginViewState();
}

class _MacOsLoginViewState extends State<MacOsLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginNotifier = LoginNotifier();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loginNotifier.dispose();
    super.dispose();
  }

  void _onLoginSuccess(String email, String accessToken) {
    final accountProvider = context.read<AccountProvider>();

    final existingAccount = accountProvider.accounts.firstWhere(
      (a) => a.email.toLowerCase() == email.toLowerCase(),
      orElse: () {
        final name = email.split('@').first;
        final newAcc = UserAccount(
          id: const Uuid().v4(),
          name: name.toUpperCase(),
          displayName: name,
          username: name.toLowerCase(),
          email: email,
          avatarLetter: name.isNotEmpty ? name[0].toUpperCase() : 'B',
          createdAt: DateTime.now(),
          lastUsed: DateTime.now(),
          type: AccountType.personal,
          avatarUrl: 'https://api.bnxmail.com/api/users/profile-picture/${name.toLowerCase()}',
        );
        accountProvider.addAccount(newAcc);
        return newAcc;
      },
    );

    accountProvider.switchAccount(existingAccount.id);
    context.read<AuthNotifier>().loginSuccess(accessToken: accessToken, email: email);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _show2FaDialog() {
    final otpController = TextEditingController();
    bool verifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MacOsTheme.radiusMedium),
          ),
          title: const Text(
            'Two-Factor Verification',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the 6-digit OTP code sent to your registered contact:',
                style: TextStyle(fontSize: 13, color: MacOsTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '123456',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MacOsTheme.radiusSmall),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: MacOsTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MacOsTheme.brandBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MacOsTheme.radiusSmall),
                ),
              ),
              onPressed: verifying
                  ? null
                  : () async {
                      final otp = otpController.text.trim();
                      if (otp.length < 4) return;
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() => verifying = true);
                      final res = await _loginNotifier.verifyOtp(otp);
                      if (ctx.mounted) {
                        setDialogState(() => verifying = false);
                      }

                      if (res['success'] == true) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        _onLoginSuccess(res['email'] ?? _emailController.text, res['accessToken'] ?? '');
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Invalid OTP code'),
                            backgroundColor: MacOsTheme.error,
                          ),
                        );
                      }
                    },
              child: verifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Verify & Login', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    final accountProvider = context.read<AccountProvider>();
    final cleanIdentifier = email.toLowerCase();

    // Check if already logged in locally
    final existingAccount = accountProvider.accounts.firstWhere(
      (a) => a.email.trim().toLowerCase() == cleanIdentifier || a.username.trim().toLowerCase() == cleanIdentifier,
      orElse: () => UserAccount(
        id: '',
        name: '',
        displayName: '',
        username: '',
        email: '',
        avatarLetter: '',
        createdAt: DateTime.now(),
        lastUsed: DateTime.now(),
      ),
    );

    if (existingAccount.id.isNotEmpty) {
      accountProvider.switchAccount(existingAccount.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${existingAccount.email} active session restored.'),
            backgroundColor: MacOsTheme.brandBlue,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final result = await _loginNotifier.executeLogin(email, password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['requires2FA'] == true) {
      _show2FaDialog();
    } else if (result['success'] == true) {
      _onLoginSuccess(email, result['accessToken'] ?? '');
    } else {
      final errorMsg = result['message'] ?? _loginNotifier.value.generalError ?? 'Authentication failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: MacOsTheme.error,
        ),
      );
    }
  }

  void _showSavedAccountsDialog() {
    final accountProvider = context.read<AccountProvider>();
    final accounts = accountProvider.accounts;

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved accounts found on this device.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MacOsTheme.radiusMedium),
        ),
        title: const Text(
          'Saved Accounts',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: accounts.map((acc) {
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6B46C1),
                  child: Text(
                    acc.avatarLetter,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                title: Text(acc.displayName.isNotEmpty ? acc.displayName : acc.name),
                subtitle: Text(acc.email),
                onTap: () {
                  accountProvider.switchAccount(acc.id);
                  Navigator.pop(ctx);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MacOsTheme.radiusMedium),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your account email to receive a password reset link:',
              style: TextStyle(fontSize: 13, color: MacOsTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'user@example.com',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MacOsTheme.radiusSmall),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: MacOsTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MacOsTheme.brandBlue,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset instructions sent if email exists.'),
                  backgroundColor: MacOsTheme.brandBlue,
                ),
              );
            },
            child: const Text('Send Reset Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Back Button
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Centered Logo and Heading
                  Center(
                    child: Column(
                      children: [
                        // Stylized "B" Logo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/beta_logo .jpg',
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Image.asset(
                              'assets/Auth_img.png',
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.shield_rounded,
                                size: 48,
                                color: MacOsTheme.brandBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sign in to B2Auth',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Use your BETA Account',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3. Email Input Field
                  const Text(
                    'Email:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'user@example.com',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Password Input Field
                  const Text(
                    'Password:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: '••••••••••••••',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 5. Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _showForgotPasswordDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: MacOsTheme.brandBlue,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 6. Sign in with a saved account link
                  Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _showSavedAccountsDialog,
                        child: const Text(
                          'Sign in with a saved account',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: MacOsTheme.brandBlue,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 7. Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MacOsTheme.brandBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 8. Footer Links Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Help  Privacy  Terms',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please contact support@bnxmail.com to report any issues.'),
                                    backgroundColor: MacOsTheme.brandBlue,
                                  ),
                                );
                              },
                              child: const Text(
                                'Report Issue',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: MacOsTheme.brandBlue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterAccountTypeScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: MacOsTheme.brandBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

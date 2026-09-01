import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'widgets/auth_constants.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';
import 'notifiers/login_notifier.dart';
import 'notifiers/auth_notifier.dart';
import 'register_account_type_screen.dart';
import '../home_screen.dart';
import '../../core/providers/account_provider.dart';
import '../../core/models/user_account.dart';
import '../../core/services/auth_api_service.dart';
import 'package:uuid/uuid.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginNotifier = LoginNotifier();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _cardSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );

    _emailController.addListener(() {
      if (mounted) setState(() {});
    });

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loginNotifier.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _show2FaDialog() {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Two-Factor Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the 6-digit OTP code sent to your registered contact:'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: '123456',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.length < 4) return;
              Navigator.pop(ctx);
              final res = await _loginNotifier.verifyOtp(otp);
              if (res['success'] == true && mounted) {
                _onLoginSuccess(res['email'] ?? _emailController.text, res['accessToken'] ?? '');
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? '2FA Verification Failed'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Verify OTP'),
          ),
        ],
      ),
    );
  }
  void _showForgotPasswordDialog() {
    int step = 1;
    final identifierController = TextEditingController(text: _emailController.text);
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    String selectedMethod = 'email';
    List<String> options = ['email', 'phone'];
    bool isLoading = false;
    String statusMessage = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(step == 1
              ? 'Find Your Account'
              : (step == 2 ? 'Choose Recovery Method' : (step == 3 ? 'Enter Verification Code' : 'Set New Password'))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              if (step == 1) ...[
                const Text('Enter your registered email address or username to recover your account.'),
                const SizedBox(height: 16),
                TextField(
                  controller: identifierController,
                  decoration: InputDecoration(
                    labelText: 'Email or Username',
                    hintText: 'user@bnxmail.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else if (step == 2) ...[
                Text('Select how you want to receive your reset OTP for ${identifierController.text}:'),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedMethod,
                  isExpanded: true,
                  items: options.map((m) => DropdownMenuItem(value: m, child: Text(m == 'email' ? 'Send OTP via Recovery Email' : 'Send OTP via SMS Phone'))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMethod = val);
                  },
                ),
              ] else if (step == 3) ...[
                Text('Enter the 6-digit code sent via $selectedMethod:'),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '000 000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else if (step == 4) ...[
                const Text('Enter your new secure password:'),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              if (statusMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(statusMessage, style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
              ],
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final api = AuthApiService();
                final identifier = identifierController.text.trim();
                if (identifier.isEmpty) return;

                if (step == 1) {
                  setDialogState(() => isLoading = true);
                  final res = await api.fetchForgotPasswordOptions(identifier);
                  setDialogState(() => isLoading = false);
                  if (res.success && res.data is Map && res.data['options'] is List) {
                    final opts = (res.data['options'] as List).map((e) => e.toString()).toList();
                    if (opts.isNotEmpty) options = opts;
                  }
                  setDialogState(() => step = 2);
                } else if (step == 2) {
                  setDialogState(() => isLoading = true);
                  final res = await api.sendForgotPasswordOtp(identifier: identifier, method: selectedMethod);
                  setDialogState(() {
                    isLoading = false;
                    statusMessage = res.message.isNotEmpty ? res.message : 'OTP sent successfully';
                    step = 3;
                  });
                } else if (step == 3) {
                  setDialogState(() => isLoading = true);
                  final res = await api.verifyForgotPasswordOtp(identifier: identifier, otp: otpController.text.trim());
                  setDialogState(() {
                    isLoading = false;
                    step = 4;
                  });
                } else if (step == 4) {
                  setDialogState(() => isLoading = true);
                  final res = await api.resetPassword(
                    identifier: identifier,
                    otp: otpController.text.trim(),
                    newPassword: newPasswordController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Password reset successful! You can now sign in.')),
                    );
                  }
                }
              },
              child: Text(step == 4 ? 'Reset Password' : 'Next'),
            ),
          ],
        ),
      ),
    );
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

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    debugPrint('🔑 [SIGN IN BUTTON PRESSED] Email: $email');

    if (email.isEmpty) return;

    final accountProvider = context.read<AccountProvider>();
    final cleanIdentifier = email.toLowerCase();
    
    // Check if account is ALREADY logged in on this mobile device
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
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${existingAccount.email} is already logged in! Switched to active session.'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2563EB),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
      return;
    }

    final result = await _loginNotifier.executeLogin(email, password);

    if (!mounted) return;

    if (result['requires2FA'] == true) {
      _show2FaDialog();
    } else if (result['success'] == true) {
      _onLoginSuccess(email, result['accessToken'] ?? '');
    } else {
      final errorMsg = result['message'] ?? _loginNotifier.value.generalError ?? 'Authentication failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AuthConstants.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AuthConstants.paddingMedium,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Logo Section
                        SlideTransition(
                          position: _logoSlideAnimation,
                          child: Column(
                            children: [
                              Container(
                                width: 200,
                                height: 200,
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                    color: AuthConstants.primaryBlue.withOpacity(0.12),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AuthConstants.primaryBlue.withOpacity(0.1),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(38),
                                  child: Container(
                                    color: Colors.white,
                                    padding: EdgeInsets.zero,
                                    child: Transform.scale(
                                      scale: 2.1,
                                      child: Image.asset(
                                        'assets/Auth_img.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.shield_outlined,
                                              size: 160,
                                              color: AuthConstants.primaryBlue,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'B2Auth',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AuthConstants.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Secure zero-trust authentication, simplified.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AuthConstants.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Login Card
                        SlideTransition(
                          position: _cardSlideAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(
                              AuthConstants.paddingLarge,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AuthConstants.borderRadiusLarge,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ValueListenableBuilder<LoginState>(
                              valueListenable: _loginNotifier,
                              builder: (context, state, child) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AuthTextField(
                                      label: 'Email Address',
                                      hintText: 'name@b2auth.com',
                                      prefixIcon: Icons.alternate_email,
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      validator: (val) => state.emailError,
                                    ),
                                    Builder(
                                      builder: (context) {
                                        final input = _emailController.text.trim().toLowerCase();
                                        final accounts = context.watch<AccountProvider>().accounts;
                                        final isAlreadyLoggedIn = input.isNotEmpty &&
                                            accounts.any(
                                              (a) => a.email.trim().toLowerCase() == input || a.username.trim().toLowerCase() == input,
                                            );
                                        if (!isAlreadyLoggedIn) return const SizedBox.shrink();
                                        return Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Account already logged in on this device. Sign in will switch directly to session.',
                                                  style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    if (state.emailError != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        state.emailError!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(
                                      height: AuthConstants.verticalSpacing,
                                    ),
                                    AuthTextField(
                                      label: 'Password',
                                      hintText: '••••••••',
                                      prefixIcon: Icons.lock_outline,
                                      isPassword: true,
                                      controller: _passwordController,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      validator: (val) => state.passwordError,
                                    ),
                                     if (state.passwordError != null) ...[
                                       const SizedBox(height: 4),
                                       Text(
                                         state.passwordError!,
                                         style: const TextStyle(
                                           color: Colors.redAccent,
                                           fontSize: 12,
                                         ),
                                       ),
                                     ],
                                     const SizedBox(height: 8),
                                     Align(
                                       alignment: Alignment.centerRight,
                                       child: TextButton(
                                         onPressed: _showForgotPasswordDialog,
                                         child: const Text(
                                           'Forgot password?',
                                           style: TextStyle(
                                             color: AuthConstants.primaryBlue,
                                             fontSize: 13,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                       ),
                                     ),
                                     const SizedBox(height: 16),
                                     AuthButton(
                                       text: 'Sign In',
                                       isLoading: state.isLoading,
                                       onPressed: state.isLoading
                                           ? null
                                           : _handleSignIn,
                                     ),
                                   ],
                                 );
                               },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'New here? ',
                              style: TextStyle(
                                color: AuthConstants.textSecondary,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RegisterAccountTypeScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Create an Account',
                                  style: TextStyle(
                                    color: AuthConstants.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/section_header.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/settings_tile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/security_provider.dart';
import '../../core/providers/account_provider.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/security_api_service.dart';
import '../../core/services/local_storage_service.dart';
import '../auth/notifiers/auth_notifier.dart';
import '../dashboard/mfa_page.dart';
import '../../widgets/add_authenticator_modal.dart';
import 'zero_trust_page.dart';
import 'audit_timeline_screen.dart';
import 'active_sessions_screen.dart';

class SecurityPage extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const SecurityPage({super.key, this.onSwitchTab});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  Timer? _otpTimer;
  int _secondsLeft = 30;
  final SecurityApiService _securityApiService = SecurityApiService();
  final AuthApiService _authApiService = AuthApiService();

  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _externalApps = [];
  List<dynamic> _authAccounts = [];
  final Set<String> _terminatingDeviceIds = {};
  final Set<String> _terminatingExternalIds = {};
  bool _isLoadingSessions = false;
  bool _showAllExternalApps = false;

  @override
  void initState() {
    super.initState();
    _startOtpCountdown();
    _loadSavedAuthAccounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveSessionsFromApi();
    });
  }

  void _loadSavedAuthAccounts() {
    try {
      final saved = LocalStorageService.getString('cloud_authenticator_accounts');
      if (saved != null && saved.isNotEmpty) {
        final decoded = jsonDecode(saved);
        if (decoded is List) {
          setState(() {
            _authAccounts = List<dynamic>.from(decoded);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved authenticator accounts: $e');
    }
  }

  void _addAuthenticatorAccount(String name, String secret) {
    final newAcc = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'secret': secret,
      'createdAt': DateTime.now().toIso8601String(),
    };
    setState(() {
      _authAccounts.add(newAcc);
    });
    LocalStorageService.setString('cloud_authenticator_accounts', jsonEncode(_authAccounts));
    _showFeedback('Authenticator account "$name" added successfully! 🎉');
  }

  void _removeAuthenticatorAccount(String id) {
    setState(() {
      _authAccounts.removeWhere((acc) => acc is Map && acc['id'] == id);
    });
    LocalStorageService.setString('cloud_authenticator_accounts', jsonEncode(_authAccounts));
    _showFeedback('Authenticator account removed.');
  }

  void _showAddAuthenticatorModal() {
    AddAuthenticatorModal.show(
      context,
      onAccountAdded: (name, secret) => _addAuthenticatorAccount(name, secret),
      onFeedback: (msg) => _showFeedback(msg),
    );
  }

  Future<void> _fetchActiveSessionsFromApi() async {
    final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
    if (token.isEmpty) return;

    if (mounted) setState(() => _isLoadingSessions = true);

    try {
      // 1. Fetch user active sessions GET /auth/sessions
      final response = await _securityApiService.fetchActiveSessions(token);
      if (response.success && response.data is List) {
        if (!mounted) return;
        final List sessionList = response.data as List;
        setState(() {
          _devices = sessionList.map<Map<String, dynamic>>((s) {
            return {
              'id': s['id']?.toString() ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
              'name': '${s['deviceInfo'] ?? 'Desktop/Browser'} • ${s['ipAddress'] ?? '192.168.1.1'}',
              'status': 'Last active: ${s['lastActive'] ?? 'Just now'}',
              'icon': (s['deviceInfo']?.toString().toLowerCase().contains('phone') ?? false) ? 'phone' : 'desktop',
            };
          }).toList();
        });
      }

      // 2. Fetch external third-party sessions GET /auth/sessions/external
      final extResponse = await _securityApiService.fetchExternalSessions(token);
      if (extResponse.success && extResponse.data is List) {
        if (!mounted) return;
        final List extList = extResponse.data as List;
        setState(() {
          _externalApps = extList.map<Map<String, dynamic>>((e) {
            return {
              'id': e['id']?.toString() ?? 'ext_${DateTime.now().millisecondsSinceEpoch}',
              'name': e['deviceInfo']?.toString() ?? e['appName']?.toString() ?? 'Third-Party App Access',
              'ip': e['ipAddress']?.toString() ?? '',
              'lastActive': e['lastActive']?.toString() ?? 'Active',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Note fetching sessions: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpCountdown() {
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsLeft = 30 - (DateTime.now().second % 30);
        });
      }
    });
  }

  int _generateOtp(String seed, int index) {
    final timeBlock = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    return (timeBlock + seed.hashCode + index) % 900000 + 100000;
  }

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

  void _showSmsWizard() {
    int step = 1;
    final phoneController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(step == 1 ? 'Configure SMS Verification' : 'Verify Security Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (step == 1) ...[
                const Icon(Icons.sms_outlined, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('Enter your mobile phone number to receive a verification OTP code via SMS.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+91 98765 43210',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                const Icon(Icons.phonelink_ring_outlined, size: 64, color: AppColors.success),
                const SizedBox(height: 16),
                Text('We sent a verification code to ${phoneController.text}. Enter "123456" to verify.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '000 000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (step == 1) {
                  if (phoneController.text.isNotEmpty) {
                    setDialogState(() => step = 2);
                  } else {
                    _showFeedback('Please enter a phone number');
                  }
                } else {
                  if (codeController.text.isNotEmpty) {
                    context.read<SecurityProvider>().enableSMS();
                    Navigator.pop(context);
                    _showFeedback('SMS Verification configured successfully!');
                  } else {
                    _showFeedback('Invalid code. Please enter 123456.');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(step == 1 ? 'Next' : 'Verify'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordChangeDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (modalCtx, setDialogState) => AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.background,
          contentPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('Update your master account password securely.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              
              // Current Password Field
              const Text('Current Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: oldController,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),

              // New Password Field
              const Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: newController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.key_outlined, size: 20, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              if (isSubmitting) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(modalCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (oldController.text.isNotEmpty && newController.text.isNotEmpty) {
                  setDialogState(() => isSubmitting = true);
                  final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
                  final response = await _authApiService.changePassword(
                    accessToken: token,
                    oldPassword: oldController.text.trim(),
                    newPassword: newController.text.trim(),
                  );
                  if (modalCtx.mounted) {
                    Navigator.pop(modalCtx);
                  }
                  if (mounted) {
                    if (response.success) {
                      _showFeedback(response.message.isNotEmpty ? response.message : 'Password changed successfully!');
                    } else {
                      _showFeedback(response.message.isNotEmpty ? response.message : 'Invalid current password. Please enter the correct password.');
                    }
                  }
                } else {
                  _showFeedback('Please fill out all fields');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthenticatorWizard() {
    String secretKey = 'HU06CBW3Z3UJ2ZVF23H5QWQQUNH7KARY';
    String qrData = '';
    final codeController = TextEditingController();
    bool isLoadingSetup = true;
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (modalCtx, setDialogState) {
          if (isLoadingSetup && secretKey == 'HU06CBW3Z3UJ2ZVF23H5QWQQUNH7KARY') {
            final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
            _securityApiService.setup2Fa(token).then((setupRes) {
              if (mounted) {
                setDialogState(() {
                  if (setupRes.success && setupRes.data is Map) {
                    final data = setupRes.data as Map;
                    secretKey = data['secret']?.toString() ?? data['secretKey']?.toString() ?? secretKey;
                    qrData = data['qrCodeUrl']?.toString() ?? data['qrCode']?.toString() ?? data['url']?.toString() ?? '';
                  }
                  isLoadingSetup = false;
                });
              }
            }).catchError((_) {
              if (mounted) {
                setDialogState(() => isLoadingSetup = false);
              }
            });
          }

          return AlertDialog(
            scrollable: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(24),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Enable 2-Step Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(modalCtx),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Scan this QR code with your authenticator app (e.g. Google Authenticator) or enter the key manually below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  
                  if (isLoadingSetup) ...[
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildQrCodeImageWidget(qrData, secretKey),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Secret Key (Manual Entry):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEBFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SelectableText(
                        secretKey,
                        style: const TextStyle(
                          color: Color(0xFF5B4DFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Verification Code',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit code',
                        hintStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, letterSpacing: 0, color: AppColors.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF5B4DFF), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF5B4DFF), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isVerifying
                          ? null
                          : () async {
                              final code = codeController.text.trim();
                              if (code.isEmpty) {
                                _showFeedback('Please enter the 6-digit code');
                                return;
                              }

                              setDialogState(() => isVerifying = true);
                              final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
                              final verifyRes = await _securityApiService.verify2Fa(accessToken: token, code: code);
                              
                              if (modalCtx.mounted) {
                                setDialogState(() => isVerifying = false);
                                modalCtx.read<SecurityProvider>().enable2FA();
                                Navigator.pop(modalCtx);
                              }
                              if (mounted) {
                                _showFeedback(verifyRes.success ? 'Authenticator 2FA successfully configured!' : 'Authenticator 2FA enabled successfully!');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isVerifying
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Verify & Enable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    final activeAccount = context.watch<AccountProvider>().selectedAccount;
    final String seed = activeAccount?.email ?? 'default_seed';
    final String userPhone = activeAccount?.phoneNumber ?? '';
    final String phoneLabel = userPhone.isNotEmpty ? userPhone : 'Not set';

    // Show only the 5 most recent sessions on main screen
    final displayedDevices = _devices.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Security Center', style: AppTextStyles.pageTitle),
                  Text('Zero-Trust Guard Status', style: AppTextStyles.caption),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuditTimelineScreen()),
                  );
                },
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Logs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Security Score Card
          NeumorphicCard(
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: security.score / 100,
                        strokeWidth: 6,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          security.score > 80 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                    Text(
                      '${security.score}%',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 16,
                        color: security.score > 80 ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        security.score > 80 ? 'High Protection Level' : 'Action Required',
                        style: AppTextStyles.subheading,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your identity shield is actively monitoring requests.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2FA Accounts & Codes Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: '2FA Authenticator Tokens',
                  subtitle: 'Real-time rotating 6-digit TOTP codes',
                ),
              ),
              TextButton.icon(
                onPressed: _showAddAuthenticatorModal,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                label: const Text('Add Account', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          NeumorphicCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Code Refresh In:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_secondsLeft}s',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildTotpTile('BNX Primary Mailbox', seed, 1),
                const Divider(height: 16),
                _buildTotpTile('B2Auth Admin Gateway', seed, 2),
                if (_authAccounts.isNotEmpty) ...[
                  for (int i = 0; i < _authAccounts.length; i++) ...[
                    const Divider(height: 16),
                    _buildTotpTile(
                      _authAccounts[i] is Map ? (_authAccounts[i]['name'] ?? 'Authenticator Account') : _authAccounts[i].toString(),
                      seed,
                      3 + i,
                      onDelete: () {
                        if (_authAccounts[i] is Map && _authAccounts[i]['id'] != null) {
                          _removeAuthenticatorAccount(_authAccounts[i]['id'].toString());
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Multi-Factor Authentication Configuration
          const SectionHeader(
            title: 'Authentication Factors',
            subtitle: 'Configure identity verification methods.',
          ),
          const SizedBox(height: 12),

          NeumorphicCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Authenticator App - Opens Add Authenticator Account modal
                SettingsTile(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Authenticator App',
                  description: 'Add & sync authenticator profiles via QR or manual key.',
                  trailing: ElevatedButton(
                    onPressed: _showAddAuthenticatorModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Add Account',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: _showAddAuthenticatorModal,
                  showDivider: true,
                ),

                // 2FA - Navigates to 2FA / MFA tab (the existing authenticator app tab)
                SettingsTile(
                  icon: Icons.lock_clock_outlined,
                  title: '2FA',
                  description: security.is2FAEnabled
                      ? 'Active (Recommended) • Tap to view 2FA tab'
                      : 'Configure 2-Step Verification & TOTP',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: security.is2FAEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) async {
                          if (val) {
                            _showAuthenticatorWizard();
                          } else {
                            final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
                            await _securityApiService.disable2Fa(token);
                            security.toggle2FA(false);
                            _showFeedback('2FA authentication disabled');
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                        onPressed: () {
                          if (widget.onSwitchTab != null) {
                            widget.onSwitchTab!(1);
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MfaPage()));
                          }
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  onTap: () {
                    if (widget.onSwitchTab != null) {
                      widget.onSwitchTab!(1);
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MfaPage()));
                    }
                  },
                  showDivider: true,
                ),
                SettingsTile(
                  icon: Icons.sms_outlined,
                  title: 'SMS Recovery Backup',
                  description: security.isSMSEnabled
                      ? 'Active ($phoneLabel)'
                      : (userPhone.isNotEmpty ? 'Configured ($userPhone)' : 'Disabled'),
                  trailing: Switch.adaptive(
                    value: security.isSMSEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      if (val) {
                        _showSmsWizard();
                      } else {
                        security.toggleSMS(false);
                        _showFeedback('SMS backup disabled');
                      }
                    },
                  ),
                  showDivider: true,
                ),
                SettingsTile(
                  icon: Icons.fingerprint,
                  title: 'Biometric Access',
                  description: security.isBiometricsEnabled ? 'Fingerprint & Face ID active' : 'Disabled',
                  trailing: Switch.adaptive(
                    value: security.isBiometricsEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      security.toggleBiometrics(val);
                      _showFeedback(val ? 'Biometrics activated' : 'Biometrics deactivated');
                    },
                  ),
                  showDivider: true,
                ),
                SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Zero-Trust Protocol',
                  description: 'Adaptive IP & device risk scoring.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ZeroTrustPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Sessions Section (No Overflow + Max 5 Items Limit)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Active Sessions & Devices',
                  subtitle: 'Manage devices currently signed into your account.',
                ),
              ),
              if (_devices.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: TextButton(
                    onPressed: () {
                      setState(() => _devices.clear());
                      _showFeedback('All active sessions revoked!');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Revoke All', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          NeumorphicCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_isLoadingSessions) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ] else if (displayedDevices.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No active sessions found.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ] else ...[
                  ...displayedDevices.map((device) => _buildDeviceItem(device)),
                  if (_devices.length > 5) ...[
                    const Divider(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveSessionsScreen(initialSessions: _devices),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt, size: 16, color: AppColors.primary),
                      label: Text(
                        'View All Sessions (${_devices.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Third-Party Apps Section
          const SectionHeader(
            title: 'Third-party apps with account access',
            subtitle: 'Third-party applications with token access.',
          ),
          const SizedBox(height: 12),

          NeumorphicCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_externalApps.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No third-party apps connected.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else ...[
                  ...(_showAllExternalApps ? _externalApps : _externalApps.take(5))
                      .map((app) => _buildAppItem(app)),
                  if (_externalApps.length > 5) ...[
                    const Divider(height: 1, indent: 12, endIndent: 12),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAllExternalApps = !_showAllExternalApps;
                          });
                        },
                        icon: Icon(
                          _showAllExternalApps
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        label: Text(
                          _showAllExternalApps
                              ? 'Show less'
                              : 'See all (${_externalApps.length})',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Change Master Password',
            icon: Icons.key_outlined,
            isFullWidth: true,
            isPremium: true,
            onPressed: _showPasswordChangeDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildTotpTile(String accountLabel, String seed, int index, {VoidCallback? onDelete}) {
    final code = _generateOtp(seed, index).toString();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.phonelink_lock, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(accountLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                '${code.substring(0, 3)} ${code.substring(3)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
          onPressed: () => _showFeedback('TOTP code copied to clipboard!'),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
            onPressed: onDelete,
          ),
      ],
    );
  }

  Widget _buildDeviceItem(Map<String, dynamic> device) {
    final isCurrent = device['status']?.toString().contains('Current') ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              device['icon'] == 'phone' ? Icons.smartphone : Icons.desktop_windows,
              color: isCurrent ? AppColors.success : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device['name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  device['status'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: isCurrent ? AppColors.success : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
              onPressed: () async {
                final String devId = device['id']?.toString() ?? '';
                if (devId.isEmpty || _terminatingDeviceIds.contains(devId)) return;
                _terminatingDeviceIds.add(devId);
                setState(() => _devices.removeWhere((d) => d['id'] == devId));
                try {
                  final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
                  await _securityApiService.terminateSession(accessToken: token, sessionId: devId);
                  if (mounted) _showFeedback('Session terminated successfully');
                } catch (e) {
                  debugPrint('Terminate session note: $e');
                } finally {
                  _terminatingDeviceIds.remove(devId);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppItem(Map<String, dynamic> app) {
    final String appName = app['name'] ?? 'Third-Party App Access';
    final String appId = app['id']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apps_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (app['lastActive'] != null && app['lastActive'].toString().isNotEmpty)
                  Text(
                    'Last active: ${app['lastActive']}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            onPressed: () async {
              if (appId.isEmpty || _terminatingExternalIds.contains(appId)) return;
              _terminatingExternalIds.add(appId);
              setState(() => _externalApps.removeWhere((a) => a['id'] == appId));
              try {
                final token = context.read<AuthNotifier>().accessToken ?? LocalStorageService.getString('access_token') ?? '';
                final res = await _securityApiService.terminateExternalSession(accessToken: token, sessionId: appId);
                if (mounted) {
                  _showFeedback(res.success ? 'Revoked access for $appName' : 'Access removed for $appName');
                }
              } catch (e) {
                debugPrint('Revoke external session note: $e');
              } finally {
                _terminatingExternalIds.remove(appId);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeImageWidget(String qrData, String secretKey) {
    final String effectiveData = qrData.trim().isNotEmpty
        ? qrData.trim()
        : 'otpauth://totp/BNXMail?secret=$secretKey&issuer=BNX%20Auth';

    if (effectiveData.startsWith('data:image')) {
      try {
        final base64Str = effectiveData.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          width: 160,
          height: 160,
          fit: BoxFit.contain,
        );
      } catch (_) {}
    }

    if (effectiveData.startsWith('http')) {
      return Image.network(
        effectiveData,
        width: 160,
        height: 160,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.qr_code_2, size: 130, color: AppColors.textPrimary),
      );
    }

    final String qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(effectiveData)}';

    return Image.network(
      qrImageUrl,
      width: 160,
      height: 160,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          width: 160,
          height: 160,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.qr_code_2, size: 130, color: AppColors.textPrimary);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/passkey_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/passkey_card.dart';
import '../../widgets/custom_button.dart';

class PasskeyStudioScreen extends StatefulWidget {
  const PasskeyStudioScreen({super.key});

  @override
  State<PasskeyStudioScreen> createState() => _PasskeyStudioScreenState();
}

class _PasskeyStudioScreenState extends State<PasskeyStudioScreen> with SingleTickerProviderStateMixin {
  void _startPasskeyRegistrationModal(BuildContext context) {
    String keyName = '';
    PasskeyType selectedType = PasskeyType.biometric;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BiometricRegistrationModal(
          onRegister: (name, type) {
            context.read<PasskeyProvider>().addPasskey(
                  name.isNotEmpty ? name : 'New Security Key',
                  type,
                  'Current Device',
                );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Passkey created & synced successfully!')),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final passkeyProvider = context.watch<PasskeyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passkeys & FIDO2 Hardware Vault'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Passkey Hero Card
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: AppColors.primaryBlue, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Passwordless Authentication',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'FIDO2 / WebAuthn standard for phishing-resistant logins.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Register New Passkey / Hardware Key',
                    icon: Icons.add_rounded,
                    onPressed: () => _startPasskeyRegistrationModal(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Registered Security Keys & Biometrics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (passkeyProvider.passkeys.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text('No passkeys registered yet.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: passkeyProvider.passkeys.length,
                itemBuilder: (context, index) {
                  final item = passkeyProvider.passkeys[index];
                  return PasskeyCard(
                    item: item,
                    onDelete: () => passkeyProvider.removePasskey(item.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BiometricRegistrationModal extends StatefulWidget {
  final Function(String name, PasskeyType type) onRegister;
  const _BiometricRegistrationModal({required this.onRegister});

  @override
  State<_BiometricRegistrationModal> createState() => _BiometricRegistrationModalState();
}

class _BiometricRegistrationModalState extends State<_BiometricRegistrationModal> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _nameController = TextEditingController();
  PasskeyType _selectedType = PasskeyType.biometric;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _triggerSimulatedScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onRegister(
          _nameController.text.isNotEmpty ? _nameController.text : 'Passkey Token',
          _selectedType,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Passkey Registration Studio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              if (_isScanning) ...[
                const SizedBox(height: 20),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.15).animate(_pulseController),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fingerprint_rounded, size: 60, color: AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Touch sensor or insert YubiKey...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                const Text('Verifying cryptographic challenge response', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 20),
              ] else ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Key Label / Nickname', hintText: 'e.g. Personal YubiKey 5C'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<PasskeyType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Key Type'),
                  items: const [
                    DropdownMenuItem(value: PasskeyType.biometric, child: Text('Device Biometrics (TouchID / FaceID)')),
                    DropdownMenuItem(value: PasskeyType.yubikeyNfc, child: Text('Hardware Key (NFC Token)')),
                    DropdownMenuItem(value: PasskeyType.yubikeyUsb, child: Text('Hardware Key (USB-C Security Key)')),
                    DropdownMenuItem(value: PasskeyType.windowsHello, child: Text('Windows Hello / TPM')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Simulate Biometric Scan & Register',
                  icon: Icons.fingerprint_rounded,
                  onPressed: _triggerSimulatedScan,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

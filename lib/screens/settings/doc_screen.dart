import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DocScreen extends StatelessWidget {
  final String title;
  const DocScreen({super.key, required this.title});

  String _getDocText() {
    if (title.toLowerCase().contains('terms')) {
      return '''
B2Auth Terms of Service
Last updated: July 2026

1. ACCEPTANCE OF TERMS
By accessing and using B2Auth (the "App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.

2. DESCRIPTION OF SERVICE
B2Auth provides secure two-factor authentication (2FA) and multi-factor authentication (MFA) services. All code generation, key storage, and authentication steps are processed locally on your device using industry-standard cryptography.

3. PRIVACY AND DATA PROTECTION
Your security and privacy are our highest priorities:
- Seed keys and secret tokens are stored securely in your device's sandbox.
- We do not transmit your secrets or private keys to our servers.
- Any local backup option syncs highly-encrypted snapshots which can only be decrypted using your device PIN/biometric authentication.

4. USER RESPONSIBILITIES
You are solely responsible for:
- Maintaining the security of your device and app lock settings.
- Creating secure backups of your account configurations.
- Any actions taken using your authentication codes.

5. DISCLAIMER OF WARRANTIES
The App is provided "as is" without warranties of any kind, either express or implied. We do not guarantee that the authentication processes will be uninterrupted or error-free.
      ''';
    } else {
      return '''
B2Auth Privacy Policy
Last updated: July 2026

1. INFORMATION WE DO NOT COLLECT
B2Auth is designed with privacy-first principles:
- We do not collect your personal details.
- We do not have access to your authentication codes or seed secrets.
- We do not sell or monetize any authentication metadata.

2. INFORMATION WE COLLECT (IF PERMITTED)
- Usage Stats: If you enable "Share usage stats", anonymous app usage telemetry is collected to help us improve UI/UX.
- Email Sharing: Sharing your email is completely optional and only used for direct communication or premium support.
- Crash Logs: Anonymous crash data helps us fix stability issues.

3. LOCAL SECURITY METRICS
All cryptographic calculations, TOTP/HOTP codes, and PIN code validations are processed strictly on-device. No security metrics or biometrics leave your local device storage.

4. UPDATES TO THIS POLICY
We may update this policy periodically. We will notify you of any changes by updating the "Last updated" date of this Privacy Policy.
      ''';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getDocText(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF344054),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

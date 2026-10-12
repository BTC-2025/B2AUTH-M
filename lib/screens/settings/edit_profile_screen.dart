import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/account_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AccountProvider>().selectedAccount;
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            NeumorphicCard(
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your name',
                    leadingIcon: Icons.person_outline,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Bio',
                    hint: 'Tell us about yourself',
                    leadingIcon: Icons.info_outline,
                    controller: _bioController,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Save',
                          isPremium: true,
                          onPressed: () {
                            final user = context.read<AccountProvider>().selectedAccount;
                            if (user != null) {
                              user.name = _nameController.text;
                              user.bio = _bioController.text;
                              context.read<AccountProvider>().updateAccount(user);
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated successfully')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

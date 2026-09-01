import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/providers/account_provider.dart';
import '../core/models/user_account.dart';
import '../core/services/local_storage_service.dart';
import 'profile_avatar.dart';
import 'neumorphic_card.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/notifiers/auth_notifier.dart';
import '../screens/settings/manage_account_screen.dart';

class ProfileOverlay extends StatelessWidget {
  const ProfileOverlay({super.key});

  void _showFeedback(BuildContext context, String message) {
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

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'John Doe',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'john.doe@company.com',
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
            onPressed: () {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                final accountProvider = context.read<AccountProvider>();
                final newAcc = UserAccount(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  displayName: nameController.text.split(' ')[0],
                  username: nameController.text.replaceAll(' ', '').toLowerCase(),
                  email: emailController.text,
                  avatarLetter: nameController.text.substring(0, 1).toUpperCase(),
                  type: AccountType.personal,
                  createdAt: DateTime.now(),
                  lastUsed: DateTime.now(),
                  securityScore: 85,
                  storageUsage: 0.1,
                );
                accountProvider.addAccount(newAcc);
                accountProvider.switchAccount(newAcc.id);
                Navigator.pop(ctx);
                _showFeedback(context, 'Account ${newAcc.email} added!');
              } else {
                _showFeedback(context, 'Please enter name and email');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _performSignOut(BuildContext context) {
    context.read<AccountProvider>().clearAccounts();
    context.read<AuthNotifier>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AccountProvider>().selectedAccount;
    if (user == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: NeumorphicCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ProfileAvatar(
                    letter: user.avatarLetter,
                    size: 64,
                    imagePath: user.profileImagePath,
                    imageUrl: user.avatarUrl,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          String? pickedPath;
                          try {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              pickedPath = image.path;
                            }
                          } catch (pickerErr) {
                            debugPrint('ImagePicker note: $pickerErr');
                          }

                          if (pickedPath == null) {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
                              pickedPath = result.files.single.path;
                            }
                          }

                          if (pickedPath != null && pickedPath.isNotEmpty) {
                            String savePath = pickedPath;
                            try {
                              final File tempFile = File(pickedPath);
                              if (tempFile.existsSync()) {
                                final String parentPath = tempFile.parent.path;
                                final Directory targetDir = Directory('$parentPath/b2auth_avatars');
                                if (!targetDir.existsSync()) {
                                  targetDir.createSync(recursive: true);
                                }
                                final String newPath = '${targetDir.path}/avatar_${user.id.replaceAll('-', '_')}.jpg';
                                final File copiedFile = tempFile.copySync(newPath);
                                savePath = copiedFile.path;
                              }
                            } catch (copyErr) {
                              debugPrint('Avatar copy note: $copyErr');
                            }

                            user.profileImagePath = savePath;
                            user.avatarUrl = savePath;
                            LocalStorageService.setString('profile_image_${user.id}', savePath);
                            LocalStorageService.setString('profile_image_${user.email.trim().toLowerCase()}', savePath);
                            context.read<AccountProvider>().updateAccount(user);
                            _showFeedback(context, 'Profile picture updated! 📸');
                          }
                        } catch (e) {
                          debugPrint('Error picking profile image: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: user.id,
                  isDense: true,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != user.id) {
                      context.read<AccountProvider>().switchAccount(newValue);
                    }
                  },
                  items: () {
                    final rawList = context.watch<AccountProvider>().accounts;
                    final Map<String, UserAccount> uniqueMap = {};
                    for (var acc in rawList) {
                      final key = acc.email.trim().toLowerCase();
                      if (key.isNotEmpty && (!uniqueMap.containsKey(key) || acc.id == user.id)) {
                        uniqueMap[key] = acc;
                      }
                    }
                    return uniqueMap.values.map((UserAccount account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Text(
                          account.email,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList();
                  }(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManageAccountScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Manage your Account', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: AppColors.darkShadow.withOpacity(0.5)),
              const SizedBox(height: 12),
              
              // Add another account option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: 12),
                      Text('Add another account', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),

              // Sign out option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _performSignOut(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: 12),
                      Text('Sign out of all accounts', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Privacy Policy', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('•', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ),
                  Text('Terms of Service', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

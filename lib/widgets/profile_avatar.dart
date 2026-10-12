import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String letter;
  final double size;
  final Color backgroundColor;
  final String? imagePath;
  final String? imageUrl;

  const ProfileAvatar({
    super.key,
    required this.letter,
    this.size = 40,
    this.backgroundColor = AppColors.accent,
    this.imagePath,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final String displayLetter = (letter.trim().isNotEmpty) ? letter.trim().substring(0, 1).toUpperCase() : 'R';

    Widget fallbackLetter() {
      return Text(
        displayLetter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    Widget content;

    final String? effectiveLocalPath = (imagePath != null && imagePath!.isNotEmpty)
        ? imagePath
        : (imageUrl != null && !imageUrl!.startsWith('http') && File(imageUrl!).existsSync())
            ? imageUrl
            : null;

    if (effectiveLocalPath != null && File(effectiveLocalPath).existsSync()) {
      content = Image.file(
        File(effectiveLocalPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallbackLetter(),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      final String fullUrl = imageUrl!.startsWith('http')
          ? imageUrl!
          : 'https://api.bnxmail.com${imageUrl!.startsWith('/') ? '' : '/'}$imageUrl';
      content = Image.network(
        fullUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallbackLetter(),
      );
    } else {
      content = fallbackLetter();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ClipOval(child: content),
    );
  }
}

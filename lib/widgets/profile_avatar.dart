import 'dart:convert';
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
    final String displayLetter = (letter.trim().isNotEmpty)
        ? letter.trim().substring(0, 1).toUpperCase()
        : 'U';

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

    final String? effectiveUri = (imagePath != null && imagePath!.isNotEmpty)
        ? imagePath
        : (imageUrl != null && imageUrl!.isNotEmpty ? imageUrl : null);

    if (effectiveUri != null &&
        (effectiveUri.startsWith('data:image') || effectiveUri.contains(';base64,'))) {
      try {
        final commaIdx = effectiveUri.indexOf(',');
        final b64 = commaIdx != -1 ? effectiveUri.substring(commaIdx + 1) : effectiveUri;
        final bytes = base64Decode(b64.trim());
        content = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallbackLetter(),
        );
      } catch (_) {
        content = fallbackLetter();
      }
    } else if (effectiveUri != null && !effectiveUri.startsWith('http') && !effectiveUri.startsWith('/') && File(effectiveUri).existsSync()) {
      content = Image.file(
        File(effectiveUri),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallbackLetter(),
      );
    } else if (effectiveUri != null && effectiveUri.isNotEmpty) {
      final String fullUrl = effectiveUri.startsWith('http')
          ? effectiveUri
          : 'https://api.bnxmail.com${effectiveUri.startsWith('/') ? '' : '/'}$effectiveUri';
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
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: ClipOval(child: content),
    );
  }
}

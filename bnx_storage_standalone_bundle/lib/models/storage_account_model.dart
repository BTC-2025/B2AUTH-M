import 'package:flutter/material.dart';

/// User account data representation for the Storage Suite.
class StorageAccountModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final Color avatarColor;

  const StorageAccountModel({
    this.id = '',
    this.name = '',
    this.email = '',
    this.avatarUrl,
    this.avatarColor = const Color(0xFF6366F1),
  });

  String get avatarLetter => name.isNotEmpty
      ? name[0].toUpperCase()
      : (email.isNotEmpty ? email[0].toUpperCase() : 'U');

  factory StorageAccountModel.fromJson(Map<String, dynamic> json) {
    final email = json['email']?.toString() ?? '';
    final name = json['name']?.toString() ??
        json['fullName']?.toString() ??
        (email.isNotEmpty ? email.split('@').first : 'User');
    return StorageAccountModel(
      id: json['id']?.toString() ?? email,
      name: name,
      email: email,
      avatarUrl: () {
        final pp = json['profilePicture']?.toString();
        if (pp != null && pp.isNotEmpty && pp != 'null') {
          if (pp.startsWith('data:image') || pp.contains(';base64,')) return pp;
          if (pp.length > 100 && !pp.startsWith('/') && !pp.startsWith('http')) {
            return pp.startsWith('data:') ? pp : 'data:image/png;base64,$pp';
          }
        }
        final av = json['avatarUrl']?.toString() ?? json['avatar']?.toString();
        if (av != null && av.isNotEmpty && av != 'null') return av;
        final ppUrl = json['profilePictureUrl']?.toString();
        if (ppUrl != null && ppUrl.isNotEmpty && ppUrl != 'null') return ppUrl;
        return pp;
      }(),
      avatarColor: const Color(0xFF6366F1),
    );
  }

  StorageAccountModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    Color? avatarColor,
  }) {
    return StorageAccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}

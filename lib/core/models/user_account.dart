import 'dart:convert';

enum AccountType { personal, business, work, education }

class UserAccount {
  final String id;
  String name;
  String displayName;
  String username;
  String email;
  String? bio;
  String? location;
  String? website;
  String avatarLetter;
  AccountType type;
  bool isPrimary;
  bool isActive;
  DateTime createdAt;
  DateTime lastUsed;
  double storageUsage; // In GB
  int securityScore; // 0-100
  String? recoveryEmail;
  String? phoneNumber;
  String? avatarUrl;
  String? profileImagePath;
  String? token;

  UserAccount({
    required this.id,
    required this.name,
    required this.displayName,
    required this.username,
    required this.email,
    this.bio,
    this.location,
    this.website,
    required this.avatarLetter,
    this.type = AccountType.personal,
    this.isPrimary = false,
    this.isActive = true,
    required this.createdAt,
    required this.lastUsed,
    this.storageUsage = 0.0,
    this.securityScore = 80,
    this.recoveryEmail,
    this.phoneNumber,
    this.avatarUrl,
    this.profileImagePath,
    this.token,
  });

  /// Dynamically resolves the full profile picture URL for this account.
  /// Works across active account, switched accounts, and newly added accounts.
  String? get effectiveAvatarUrl {
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty && avatarUrl!.trim() != 'null') {
      final trimmed = avatarUrl!.trim();
      if (trimmed.startsWith('http') || trimmed.startsWith('data:')) return trimmed;
      return 'https://api.bnxmail.com${trimmed.startsWith('/') ? '' : '/'}$trimmed';
    }
    if (profileImagePath != null && profileImagePath!.trim().isNotEmpty && profileImagePath!.trim() != 'null') {
      final trimmed = profileImagePath!.trim();
      if (trimmed.startsWith('http') || trimmed.startsWith('data:')) return trimmed;
      if (trimmed.startsWith('/')) return 'https://api.bnxmail.com$trimmed';
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'username': username,
      'email': email,
      'bio': bio,
      'location': location,
      'website': website,
      'avatarLetter': avatarLetter,
      'type': type.index,
      'isPrimary': isPrimary,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'storageUsage': storageUsage,
      'securityScore': securityScore,
      'recoveryEmail': recoveryEmail,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'profileImagePath': profileImagePath,
      'token': token,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      displayName: map['displayName'] ?? map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'],
      location: map['location'],
      website: map['website'],
      avatarLetter: (map['avatarLetter'] != null && map['avatarLetter'].toString().isNotEmpty)
          ? map['avatarLetter'].toString()
          : (map['name'] != null && map['name'].toString().isNotEmpty
              ? map['name'].toString()[0].toUpperCase()
              : (map['email'] != null && map['email'].toString().isNotEmpty
                  ? map['email'].toString()[0].toUpperCase()
                  : 'U')),
      type: map['type'] != null ? AccountType.values[map['type']] : AccountType.personal,
      isPrimary: map['isPrimary'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      lastUsed: map['lastUsed'] != null ? DateTime.parse(map['lastUsed']) : DateTime.now(),
      storageUsage: (map['storageUsage'] as num?)?.toDouble() ?? 0.0,
      securityScore: map['securityScore'] ?? 80,
      recoveryEmail: map['recoveryEmail'],
      phoneNumber: map['phoneNumber'],
      avatarUrl: () {
        final pp = map['profilePicture']?.toString();
        if (pp != null && pp.isNotEmpty && pp != 'null') {
          if (pp.startsWith('data:image') || pp.contains(';base64,')) return pp;
        }
        return map['profilePictureUrl'] ?? map['avatarUrl'] ?? map['avatar'] ?? map['logo'] ?? pp;
      }(),
      profileImagePath: map['profileImagePath'] ?? map['profilePictureUrl'] ?? map['avatarUrl'] ?? map['avatar'],
      token: map['token'] ?? map['accessToken'],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory UserAccount.fromJson(String source) => UserAccount.fromMap(jsonDecode(source));
}

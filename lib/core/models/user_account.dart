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
  });

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
      avatarLetter: map['avatarLetter'] ?? (map['name'] != null && map['name'].isNotEmpty ? map['name'][0] : 'R'),
      type: map['type'] != null ? AccountType.values[map['type']] : AccountType.personal,
      isPrimary: map['isPrimary'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      lastUsed: map['lastUsed'] != null ? DateTime.parse(map['lastUsed']) : DateTime.now(),
      storageUsage: (map['storageUsage'] as num?)?.toDouble() ?? 0.0,
      securityScore: map['securityScore'] ?? 80,
      recoveryEmail: map['recoveryEmail'],
      phoneNumber: map['phoneNumber'],
      avatarUrl: map['profilePictureUrl'] ?? map['avatarUrl'] ?? map['avatar'] ?? map['logo'],
      profileImagePath: map['profileImagePath'] ?? map['profilePictureUrl'] ?? map['avatarUrl'] ?? map['avatar'],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory UserAccount.fromJson(String source) => UserAccount.fromMap(jsonDecode(source));
}

enum VaultCategory { passwords, recoveryKeys, secureNotes, documents, files }

class VaultItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? content;
  final VaultCategory category;
  final DateTime lastModified;

  VaultItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.content,
    required this.category,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'category': category.index,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory VaultItem.fromMap(Map<String, dynamic> map) {
    return VaultItem(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      content: map['content'],
      category: VaultCategory.values[map['category']],
      lastModified: DateTime.parse(map['lastModified']),
    );
  }
}

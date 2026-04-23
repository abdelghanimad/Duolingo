class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.nativeLang,
    required this.learningLang,
    this.level = 1,
    this.xp = 0,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String nativeLang;
  final String learningLang;
  final int level;
  final int xp;
  final String? avatarUrl;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        nativeLang: json['native_lang'] as String,
        learningLang: json['learning_lang'] as String,
        level: (json['level'] as num?)?.toInt() ?? 1,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'native_lang': nativeLang,
        'learning_lang': learningLang,
        'level': level,
        'xp': xp,
        'avatar_url': avatarUrl,
      };
}

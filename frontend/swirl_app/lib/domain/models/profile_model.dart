class ProfileModel {
  const ProfileModel({
    required this.name,
    required this.avatarUrl,
    required this.currentStreak,
    required this.bestStreak,
    required this.learnedWordsCount,
    required this.completedLevelsCount,
    required this.sectionsProgress,
  });

  final String name;
  final String avatarUrl;
  final int currentStreak;
  final int bestStreak;
  final int learnedWordsCount;
  final int completedLevelsCount;
  final List<SectionProgressModel> sectionsProgress;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sectionsProgress'];
    final sections = rawSections is List
        ? rawSections
              .whereType<Map>()
              .map(
                (item) => SectionProgressModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <SectionProgressModel>[];

    return ProfileModel(
      name: _stringValue(json['name']),
      avatarUrl: _stringValue(json['avatarUrl']),
      currentStreak: _intValue(json['currentStreak']),
      bestStreak: _intValue(json['bestStreak']),
      learnedWordsCount: _intValue(json['learnedWordsCount']),
      completedLevelsCount: _intValue(json['completedLevelsCount']),
      sectionsProgress: sections,
    );
  }
}

class SectionProgressModel {
  const SectionProgressModel({
    required this.sectionId,
    required this.title,
    required this.progressPercent,
  });

  final int sectionId;
  final String title;
  final int progressPercent;

  factory SectionProgressModel.fromJson(Map<String, dynamic> json) {
    return SectionProgressModel(
      sectionId: _intValue(json['sectionId']),
      title: _stringValue(json['title']),
      progressPercent: _intValue(json['progressPercent']),
    );
  }
}

String _stringValue(Object? value) {
  return value is String ? value : '';
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

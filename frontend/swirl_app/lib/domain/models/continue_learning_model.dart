class ContinueSectionModel {
  const ContinueSectionModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.progressPercent,
    required this.completedLevels,
    required this.totalLevels,
  });

  final int id;
  final String title;
  final String imageUrl;
  final int progressPercent;
  final int completedLevels;
  final int totalLevels;

  factory ContinueSectionModel.fromJson(Map<String, dynamic> json) {
    return ContinueSectionModel(
      id: _intValue(json['id']),
      title: _stringValue(json['title']),
      imageUrl: _stringValue(json['imageUrl']),
      progressPercent: _intValue(json['progressPercent']),
      completedLevels: _intValue(json['completedLevels']),
      totalLevels: _intValue(json['totalLevels']),
    );
  }
}

class ContinueLevelModel {
  const ContinueLevelModel({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.levelNumber,
    required this.status,
    required this.isFinalTest,
    required this.completedAt,
  });

  final int id;
  final int sectionId;
  final String title;
  final int levelNumber;
  final String status;
  final bool isFinalTest;
  final DateTime? completedAt;

  factory ContinueLevelModel.fromJson(Map<String, dynamic> json) {
    return ContinueLevelModel(
      id: _intValue(json['id']),
      sectionId: _intValue(json['sectionId']),
      title: _stringValue(json['title']),
      levelNumber: _intValue(json['levelNumber']),
      status: _stringValue(json['status']),
      isFinalTest: json['isFinalTest'] == true,
      completedAt: _dateTimeValue(json['completedAt']),
    );
  }
}

class ContinueLearningModel {
  const ContinueLearningModel({
    required this.section,
    required this.nextLevel,
    required this.completedLevels,
    required this.totalLevels,
  });

  final ContinueSectionModel section;
  final ContinueLevelModel nextLevel;
  final int completedLevels;
  final int totalLevels;

  double get progressValue {
    if (totalLevels <= 0) {
      return 0;
    }

    return (completedLevels / totalLevels).clamp(0, 1);
  }

  String get progressText {
    if (totalLevels <= 0) {
      return '$completedLevels';
    }

    return '$completedLevels/$totalLevels';
  }

  String get nextLevelText {
    if (nextLevel.isFinalTest) {
      return 'Финальный тест';
    }

    final difficulty = _levelDifficultyName(nextLevel.levelNumber);
    if (difficulty == null) {
      return 'Уровень ${nextLevel.levelNumber}';
    }

    return 'Уровень ${nextLevel.levelNumber} - $difficulty';
  }
}

String? _levelDifficultyName(int levelNumber) {
  switch (levelNumber) {
    case 1:
      return 'Базовый';
    case 2:
      return 'Легкий';
    case 3:
      return 'Средний';
    case 4:
      return 'Продвинутый';
    case 5:
      return 'Эксперт';
    default:
      return null;
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

DateTime? _dateTimeValue(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}

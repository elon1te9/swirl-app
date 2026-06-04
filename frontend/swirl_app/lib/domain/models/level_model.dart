class LevelModel {
  const LevelModel({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.levelNumber,
    required this.cefrLevel,
    required this.description,
    required this.wordsCount,
    required this.exercisesCount,
    required this.isFinalTest,
    required this.status,
  });

  final int id;
  final int sectionId;
  final String title;
  final int levelNumber;
  final String cefrLevel;
  final String description;
  final int wordsCount;
  final int exercisesCount;
  final bool isFinalTest;
  final String status;

  bool get isLocked => status == 'locked';

  bool get isCompleted => status == 'completed';

  bool get isAvailable => status == 'available';

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: _intValue(json['id']),
      sectionId: _intValue(json['sectionId']),
      title: _stringValue(json['title']),
      levelNumber: _intValue(json['levelNumber']),
      cefrLevel: _stringValue(json['cefrLevel']),
      description: _stringValue(json['description']),
      wordsCount: _intValue(json['wordsCount']),
      exercisesCount: _intValue(json['exercisesCount']),
      isFinalTest: json['isFinalTest'] == true,
      status: _stringValue(json['status']),
    );
  }
}

class LevelDetailsModel extends LevelModel {
  const LevelDetailsModel({
    required super.id,
    required super.sectionId,
    required super.title,
    required super.levelNumber,
    required super.cefrLevel,
    required super.description,
    required super.wordsCount,
    required super.exercisesCount,
    required super.isFinalTest,
    required super.status,
    required this.sectionTitle,
    required this.wordsLearned,
  });

  final String sectionTitle;
  final bool wordsLearned;

  factory LevelDetailsModel.fromJson(Map<String, dynamic> json) {
    return LevelDetailsModel(
      id: _intValue(json['id']),
      sectionId: _intValue(json['sectionId']),
      sectionTitle: _stringValue(json['sectionTitle']),
      title: _stringValue(json['title']),
      levelNumber: _intValue(json['levelNumber']),
      cefrLevel: _stringValue(json['cefrLevel']),
      description: _stringValue(json['description']),
      wordsCount: _intValue(json['wordsCount']),
      exercisesCount: _intValue(json['exercisesCount']),
      isFinalTest: json['isFinalTest'] == true,
      status: _stringValue(json['status']),
      wordsLearned: json['wordsLearned'] == true,
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

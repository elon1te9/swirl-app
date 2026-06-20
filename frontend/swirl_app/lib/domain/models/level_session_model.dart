class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.type,
    required this.questionText,
    required this.questionImageUrl,
    required this.questionAudioUrl,
    required this.correctAnswer,
    required this.options,
  });

  final int id;
  final String type;
  final String questionText;
  final String questionImageUrl;
  final String questionAudioUrl;
  final String correctAnswer;
  final List<String> options;

  bool get isInput => type.endsWith('_input');

  bool get isChoice => type.endsWith('_choice');

  bool get isAudioChoice => type == 'audio_to_russian_choice';

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: _intValue(json['id']),
      type: _stringValue(json['type']),
      questionText: _stringValue(json['questionText']),
      questionImageUrl: _stringValue(json['questionImageUrl']),
      questionAudioUrl: _stringValue(json['questionAudioUrl']),
      correctAnswer: _stringValue(json['correctAnswer']),
      options: _stringList(json['options']),
    );
  }
}

class LevelSessionModel {
  const LevelSessionModel({
    required this.levelId,
    required this.title,
    required this.sectionTitle,
    required this.isFinalTest,
    required this.exercises,
  });

  final int levelId;
  final String title;
  final String sectionTitle;
  final bool isFinalTest;
  final List<ExerciseModel> exercises;

  factory LevelSessionModel.fromJson(Map<String, dynamic> json) {
    return LevelSessionModel(
      levelId: _intValue(json['levelId']),
      title: _stringValue(json['title']),
      sectionTitle: _stringValue(json['sectionTitle']),
      isFinalTest: json['isFinalTest'] == true,
      exercises: _jsonList(
        json['exercises'],
      ).map((item) => ExerciseModel.fromJson(item)).toList(),
    );
  }
}

class LevelAnswerModel {
  const LevelAnswerModel({
    required this.exerciseId,
    required this.userAnswer,
    required this.isCorrect,
    required this.timeSpentMs,
  });

  final int exerciseId;
  final String userAnswer;
  final bool isCorrect;
  final int timeSpentMs;

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timeSpentMs': timeSpentMs,
    };
  }
}

class CompleteLevelResultModel {
  const CompleteLevelResultModel({
    required this.isLevelCompleted,
    required this.mistakesCount,
    required this.currentStreak,
    required this.bestStreak,
    required this.openedNextLevelId,
  });

  final bool isLevelCompleted;
  final int mistakesCount;
  final int currentStreak;
  final int bestStreak;
  final int? openedNextLevelId;

  factory CompleteLevelResultModel.fromJson(Map<String, dynamic> json) {
    final openedNextLevelId = json['openedNextLevelId'];

    return CompleteLevelResultModel(
      isLevelCompleted: json['isLevelCompleted'] == true,
      mistakesCount: _intValue(json['mistakesCount']),
      currentStreak: _intValue(json['currentStreak']),
      bestStreak: _intValue(json['bestStreak']),
      openedNextLevelId: openedNextLevelId == null
          ? null
          : _intValue(openedNextLevelId),
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

List<String> _stringList(Object? data) {
  if (data is List) {
    return data.whereType<String>().toList();
  }

  return const [];
}

List<Map<String, dynamic>> _jsonList(Object? data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  return const [];
}

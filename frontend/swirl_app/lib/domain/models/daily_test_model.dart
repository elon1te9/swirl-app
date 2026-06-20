class DailyTestModel {
  const DailyTestModel({
    required this.date,
    required this.isAvailable,
    required this.exercisesCount,
    required this.reason,
    required this.exercises,
  });

  final String date;
  final bool isAvailable;
  final int exercisesCount;
  final String reason;
  final List<DailyTestExerciseModel> exercises;

  factory DailyTestModel.fromJson(Map<String, dynamic> json) {
    return DailyTestModel(
      date: _stringValue(json['date']),
      isAvailable: json['isAvailable'] == true,
      exercisesCount: _intValue(json['exercisesCount']),
      reason: _stringValue(json['reason']),
      exercises: _jsonList(
        json['exercises'],
      ).map((item) => DailyTestExerciseModel.fromJson(item)).toList(),
    );
  }
}

class DailyTestExerciseModel {
  const DailyTestExerciseModel({
    required this.id,
    required this.wordId,
    required this.type,
    required this.questionText,
    required this.questionImageUrl,
    required this.questionAudioUrl,
    required this.correctAnswer,
    required this.options,
  });

  final int id;
  final int wordId;
  final String type;
  final String questionText;
  final String questionImageUrl;
  final String questionAudioUrl;
  final String correctAnswer;
  final List<String> options;

  bool get isInput => type.endsWith('_input');

  bool get isChoice => type.endsWith('_choice');

  bool get isAudioChoice => type == 'audio_to_russian_choice';

  factory DailyTestExerciseModel.fromJson(Map<String, dynamic> json) {
    return DailyTestExerciseModel(
      id: _intValue(json['id']),
      wordId: _intValue(json['wordId']),
      type: _stringValue(json['type']),
      questionText: _stringValue(json['questionText']),
      questionImageUrl: _stringValue(json['questionImageUrl']),
      questionAudioUrl: _stringValue(json['questionAudioUrl']),
      correctAnswer: _stringValue(json['correctAnswer']),
      options: _stringList(json['options']),
    );
  }
}

class DailyTestAnswerModel {
  const DailyTestAnswerModel({
    required this.wordId,
    required this.exerciseType,
    required this.userAnswer,
    required this.isCorrect,
  });

  final int wordId;
  final String exerciseType;
  final String userAnswer;
  final bool isCorrect;

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'exerciseType': exerciseType,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
    };
  }
}

class CompleteDailyTestResultModel {
  const CompleteDailyTestResultModel({
    required this.completed,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.currentStreak,
    required this.bestStreak,
  });

  final bool completed;
  final int correctAnswers;
  final int totalAnswers;
  final int currentStreak;
  final int bestStreak;

  factory CompleteDailyTestResultModel.fromJson(Map<String, dynamic> json) {
    return CompleteDailyTestResultModel(
      completed: json['completed'] == true,
      correctAnswers: _intValue(json['correctAnswers']),
      totalAnswers: _intValue(json['totalAnswers']),
      currentStreak: _intValue(json['currentStreak']),
      bestStreak: _intValue(json['bestStreak']),
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

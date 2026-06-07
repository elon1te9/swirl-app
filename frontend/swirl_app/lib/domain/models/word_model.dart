class WordModel {
  const WordModel({
    required this.id,
    required this.english,
    required this.russian,
    required this.transcription,
    required this.partOfSpeech,
    required this.imageUrl,
    required this.audioUrl,
  });

  final int id;
  final String english;
  final String russian;
  final String transcription;
  final String partOfSpeech;
  final String imageUrl;
  final String audioUrl;

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: _intValue(json['id']),
      english: _stringValue(json['english']),
      russian: _stringValue(json['russian']),
      transcription: _stringValue(json['transcription']),
      partOfSpeech: _stringValue(json['partOfSpeech']),
      imageUrl: _stringValue(json['imageUrl']),
      audioUrl: _stringValue(json['audioUrl']),
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

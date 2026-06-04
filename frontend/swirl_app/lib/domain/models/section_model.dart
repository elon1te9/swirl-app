class SectionModel {
  const SectionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.progressPercent,
    required this.completedLevels,
    required this.totalLevels,
  });

  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final int progressPercent;
  final int completedLevels;
  final int totalLevels;

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: _intValue(json['id']),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      imageUrl: _stringValue(json['imageUrl']),
      progressPercent: _intValue(json['progressPercent']),
      completedLevels: _intValue(json['completedLevels']),
      totalLevels: _intValue(json['totalLevels']),
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

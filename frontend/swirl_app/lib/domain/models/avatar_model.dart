class AvatarModel {
  const AvatarModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String imageUrl;

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    return AvatarModel(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

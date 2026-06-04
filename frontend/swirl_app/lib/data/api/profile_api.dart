import 'package:dio/dio.dart';

import '../../domain/models/avatar_model.dart';
import '../../domain/models/profile_model.dart';
import 'api_paths.dart';

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<ProfileModel> getProfile() async {
    final response = await _dio.get(ApiPaths.profile);
    return ProfileModel.fromJson(_jsonMap(response.data));
  }

  Future<List<AvatarModel>> getAvatars() async {
    final response = await _dio.get(ApiPaths.avatars);
    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => AvatarModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ProfileModel> updateProfile({
    required String name,
    required int avatarId,
  }) async {
    final response = await _dio.put(
      ApiPaths.profile,
      data: {'name': name, 'avatarId': avatarId},
    );

    return ProfileModel.fromJson(_jsonMap(response.data));
  }

  Future<void> changeAvatar({required int avatarId}) async {
    await _dio.put(ApiPaths.profileAvatar, data: {'avatarId': avatarId});
  }

  Map<String, dynamic> _jsonMap(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }
}

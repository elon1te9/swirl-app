import 'package:dio/dio.dart';

import '../../domain/models/auth_response_model.dart';
import '../../domain/models/avatar_model.dart';
import '../../domain/models/user_model.dart';
import 'api_paths.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

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

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiPaths.authLogin,
      data: {'email': email, 'password': password},
    );

    return AuthResponseModel.fromJson(_jsonMap(response.data));
  }

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required int avatarId,
  }) async {
    final response = await _dio.post(
      ApiPaths.authRegister,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'avatarId': avatarId,
      },
    );

    return AuthResponseModel.fromJson(_jsonMap(response.data));
  }

  Future<UserModel> me() async {
    final response = await _dio.get(ApiPaths.authMe);

    return UserModel.fromJson(_jsonMap(response.data));
  }

  Map<String, dynamic> _jsonMap(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }
}

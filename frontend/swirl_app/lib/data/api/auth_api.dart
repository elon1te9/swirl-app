import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../domain/models/auth_response_model.dart';
import '../../domain/models/avatar_model.dart';
import '../../domain/models/user_model.dart';
import 'api_paths.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApi(dio);
});

class AuthApi {
  AuthApi(this.dio);

  final Dio dio;

  Future<List<AvatarModel>> getAvatars() async {
    final response = await dio.get(ApiPaths.avatars);
    final List avatarsJson = response.data;

    final avatars = avatarsJson.map((avatarJson) {
      return AvatarModel.fromJson(avatarJson);
    }).toList();

    return avatars;
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      ApiPaths.authLogin,
      data: {
        'email': email,
        'password': password,
      },
    );

    final Map<String, dynamic> responseJson = response.data;
    final authResponse = AuthResponseModel.fromJson(responseJson);

    return authResponse;
  }

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required int avatarId,
  }) async {
    final response = await dio.post(
      ApiPaths.authRegister,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'avatarId': avatarId,
      },
    );

    final Map<String, dynamic> responseJson = response.data;
    final authResponse = AuthResponseModel.fromJson(responseJson);

    return authResponse;
  }

  Future<UserModel> me() async {
    final response = await dio.get(ApiPaths.authMe);
    final Map<String, dynamic> userJson = response.data;
    final user = UserModel.fromJson(userJson);

    return user;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/api_error_utils.dart';
import '../../data/api/profile_api.dart';
import '../../domain/models/avatar_model.dart';
import '../../domain/models/profile_model.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(dioProvider));
});

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(
    profileApi: ref.watch(profileApiProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class ProfileController {
  ProfileController({required this.profileApi, required this.tokenStorage});

  final ProfileApi profileApi;
  final TokenStorage tokenStorage;

  Future<ProfileModel> loadProfile() async {
    try {
      return await profileApi.getProfile();
    } on DioException catch (error) {
      if (isUnauthorizedError(error)) {
        throw ProfileUnauthorizedException();
      }

      throw Exception(profileErrorText(error));
    }
  }

  Future<List<AvatarModel>> loadAvatars() async {
    try {
      return await profileApi.getAvatars();
    } on DioException catch (error) {
      if (isUnauthorizedError(error)) {
        throw ProfileUnauthorizedException();
      }

      throw Exception(profileErrorText(error));
    }
  }

  Future<ProfileModel> updateProfile({
    required String name,
    required int avatarId,
  }) async {
    try {
      return await profileApi.updateProfile(name: name, avatarId: avatarId);
    } on DioException catch (error) {
      if (isUnauthorizedError(error)) {
        throw ProfileUnauthorizedException();
      }

      if (error.response?.statusCode == 404 ||
          error.response?.statusCode == 405) {
        await profileApi.changeAvatar(avatarId: avatarId);
        throw Exception(
          'Аватарка сохранена. Чтобы менять имя, перезапустите backend.',
        );
      }

      if (error.response?.statusCode == 400) {
        throw Exception('Проверьте имя и аватарку.');
      }

      throw Exception(
        friendlyDioMessage(
          error,
          fallback: 'Не удалось сохранить профиль. Попробуйте еще раз.',
        ),
      );
    }
  }

  Future<void> logout() {
    return tokenStorage.deleteAccessToken();
  }
}

class ProfileUnauthorizedException implements Exception {
  const ProfileUnauthorizedException();

  @override
  String toString() {
    return 'Нужно войти снова.';
  }
}

String profileErrorText(DioException error) {
  return friendlyDioMessage(
    error,
    fallback: 'Не удалось загрузить профиль. Попробуйте еще раз.',
  );
}

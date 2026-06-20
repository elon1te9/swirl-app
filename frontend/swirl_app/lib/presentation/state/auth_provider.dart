import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/api_error_utils.dart';
import '../../data/api/auth_api.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    authApi: ref.watch(authApiProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class AuthController {
  AuthController({required this.authApi, required this.tokenStorage});

  final AuthApi authApi;
  final TokenStorage tokenStorage;

  Future<bool> checkAuth() async {
    final token = await tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      await authApi.me();
      return true;
    } on DioException catch (error) {
      if (isUnauthorizedError(error)) {
        await tokenStorage.deleteAccessToken();
        return false;
      }

      throw Exception(
        friendlyDioMessage(
          error,
          fallback: 'Не удалось проверить вход. Попробуйте еще раз.',
        ),
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await authApi.login(email: email, password: password);
      await tokenStorage.saveAccessToken(response.accessToken);
    } on DioException catch (error) {
      throw Exception(loginErrorText(error));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required int avatarId,
  }) async {
    try {
      final response = await authApi.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        avatarId: avatarId,
      );
      await tokenStorage.saveAccessToken(response.accessToken);
    } on DioException catch (error) {
      throw Exception(registerErrorText(error));
    }
  }

  Future<void> logout() {
    return tokenStorage.deleteAccessToken();
  }
}

String loginErrorText(DioException error) {
  if (error.response?.statusCode == 401 ||
      apiErrorCode(error.response?.data) == 'invalid_credentials') {
    return 'Неверная почта или пароль.';
  }

  return friendlyDioMessage(
    error,
    fallback: 'Не удалось войти. Попробуйте еще раз.',
  );
}

String registerErrorText(DioException error) {
  if (error.response?.statusCode == 409 ||
      apiErrorCode(error.response?.data) == 'email_already_exists') {
    return 'Пользователь с такой почтой уже есть.';
  }

  if (error.response?.statusCode == 400) {
    return 'Проверьте данные формы.';
  }

  return friendlyDioMessage(
    error,
    fallback: 'Не удалось зарегистрироваться. Попробуйте еще раз.',
  );
}

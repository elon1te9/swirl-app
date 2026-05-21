import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swirl_app/data/api/api_paths.dart';
import 'package:swirl_app/data/api/auth_api.dart';

void main() {
  Dio createFakeDio({
    required void Function(RequestOptions options) onRequest,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          onRequest(options);

          Object responseData;
          if (options.path == ApiPaths.avatars) {
            responseData = [
              {
                'id': 1,
                'name': 'Avatar 1',
                'imageUrl': '/media/avatars/avatar_1.png',
              },
            ];
          } else if (options.path == ApiPaths.authMe) {
            responseData = {
              'id': 'user-id',
              'name': 'Vladimir',
              'email': 'user@example.com',
              'avatarUrl': '/media/avatars/avatar_1.png',
            };
          } else {
            responseData = {
              'accessToken': 'jwt-token',
              'user': {
                'id': 'user-id',
                'name': 'Vladimir',
                'email': 'user@example.com',
                'avatarUrl': '/media/avatars/avatar_1.png',
              },
            };
          }

          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: responseData,
            ),
          );
        },
      ),
    );

    return dio;
  }

  group('AuthApi', () {
    test('gets avatars from ApiPaths.avatars', () async {
      late RequestOptions sentRequest;
      final api = AuthApi(
        createFakeDio(onRequest: (options) => sentRequest = options),
      );

      final avatars = await api.getAvatars();

      expect(sentRequest.method, 'GET');
      expect(sentRequest.path, ApiPaths.avatars);
      expect(avatars, hasLength(1));
      expect(avatars.first.name, 'Avatar 1');
    });

    test('logs in through ApiPaths.authLogin', () async {
      late RequestOptions sentRequest;
      final api = AuthApi(
        createFakeDio(onRequest: (options) => sentRequest = options),
      );

      final response = await api.login(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(sentRequest.method, 'POST');
      expect(sentRequest.path, ApiPaths.authLogin);
      expect(sentRequest.data, {
        'email': 'user@example.com',
        'password': 'password123',
      });
      expect(response.accessToken, 'jwt-token');
      expect(response.user.email, 'user@example.com');
    });

    test('registers through ApiPaths.authRegister', () async {
      late RequestOptions sentRequest;
      final api = AuthApi(
        createFakeDio(onRequest: (options) => sentRequest = options),
      );

      final response = await api.register(
        name: 'Vladimir',
        email: 'user@example.com',
        password: 'password123',
        confirmPassword: 'password123',
        avatarId: 2,
      );

      expect(sentRequest.method, 'POST');
      expect(sentRequest.path, ApiPaths.authRegister);
      expect(sentRequest.data, {
        'name': 'Vladimir',
        'email': 'user@example.com',
        'password': 'password123',
        'confirmPassword': 'password123',
        'avatarId': 2,
      });
      expect(response.accessToken, 'jwt-token');
      expect(response.user.name, 'Vladimir');
    });

    test('loads current user from ApiPaths.authMe', () async {
      late RequestOptions sentRequest;
      final api = AuthApi(
        createFakeDio(onRequest: (options) => sentRequest = options),
      );

      final user = await api.me();

      expect(sentRequest.method, 'GET');
      expect(sentRequest.path, ApiPaths.authMe);
      expect(user.id, 'user-id');
      expect(user.name, 'Vladimir');
    });
  });
}

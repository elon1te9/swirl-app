import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swirl_app/app/router.dart';
import 'package:swirl_app/core/storage/token_storage.dart';
import 'package:swirl_app/data/api/auth_api.dart';
import 'package:swirl_app/domain/models/user_model.dart';
import 'package:swirl_app/presentation/screens/splash_screen.dart';

void main() {
  Widget buildTestApp({
    required FakeTokenStorage tokenStorage,
    required FakeAuthApi authApi,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.first,
          builder: (context, state) => const Scaffold(body: Text('first page')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('home page')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authApiProvider.overrideWithValue(authApi),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('opens first screen when token is missing', (tester) async {
    await tester.pumpWidget(
      buildTestApp(tokenStorage: FakeTokenStorage(), authApi: FakeAuthApi()),
    );

    await tester.pumpAndSettle();

    expect(find.text('first page'), findsOneWidget);
  });

  testWidgets('opens home screen when saved token is valid', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        tokenStorage: FakeTokenStorage('saved-token'),
        authApi: FakeAuthApi(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('home page'), findsOneWidget);
  });

  testWidgets('deletes invalid token and opens first screen', (tester) async {
    final tokenStorage = FakeTokenStorage('bad-token');
    final authApi = FakeAuthApi()..error = unauthorizedError();

    await tester.pumpWidget(
      buildTestApp(tokenStorage: tokenStorage, authApi: authApi),
    );

    await tester.pumpAndSettle();

    expect(find.text('first page'), findsOneWidget);
    expect(tokenStorage.savedToken, isNull);
  });

  testWidgets('shows retry button when auth check fails by network', (
    tester,
  ) async {
    final authApi = FakeAuthApi()..error = networkError();

    await tester.pumpWidget(
      buildTestApp(
        tokenStorage: FakeTokenStorage('saved-token'),
        authApi: authApi,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Не получилось проверить вход'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}

UserModel testUser() {
  return const UserModel(
    id: 'user-id',
    name: 'Vladimir',
    email: 'user@example.com',
    avatarUrl: '/media/avatars/avatar_1.png',
  );
}

DioException unauthorizedError() {
  final requestOptions = RequestOptions(path: '/auth/me');

  return DioException(
    requestOptions: requestOptions,
    response: Response(requestOptions: requestOptions, statusCode: 401),
  );
}

DioException networkError() {
  return DioException(
    requestOptions: RequestOptions(path: '/auth/me'),
    type: DioExceptionType.connectionError,
    error: 'No connection',
  );
}

class FakeAuthApi extends AuthApi {
  FakeAuthApi() : super(Dio());

  Object? error;

  @override
  Future<UserModel> me() async {
    final currentError = error;
    if (currentError != null) {
      throw currentError;
    }

    return testUser();
  }
}

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage([this.savedToken]);

  String? savedToken;

  @override
  Future<void> saveAccessToken(String token) async {
    savedToken = token;
  }

  @override
  Future<String?> readAccessToken() async {
    return savedToken;
  }

  @override
  Future<void> deleteAccessToken() async {
    savedToken = null;
  }
}

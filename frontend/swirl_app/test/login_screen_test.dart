import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swirl_app/app/router.dart';
import 'package:swirl_app/core/storage/token_storage.dart';
import 'package:swirl_app/data/api/auth_api.dart';
import 'package:swirl_app/domain/models/auth_response_model.dart';
import 'package:swirl_app/domain/models/user_model.dart';
import 'package:swirl_app/presentation/screens/login_screen.dart';

void main() {
  Widget buildTestApp({
    required FakeAuthApi authApi,
    required FakeTokenStorage tokenStorage,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('home page')),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) =>
              const Scaffold(body: Text('signup page')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authApiProvider.overrideWithValue(authApi),
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('shows email and password fields', (tester) async {
    await tester.pumpWidget(
      buildTestApp(authApi: FakeAuthApi(), tokenStorage: FakeTokenStorage()),
    );

    expect(find.text('Авторизация'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Почта'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Пароль'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('validates empty form', (tester) async {
    await tester.pumpWidget(
      buildTestApp(authApi: FakeAuthApi(), tokenStorage: FakeTokenStorage()),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Войти'));
    await tester.pump();

    expect(find.text('Введите почту'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
  });

  testWidgets('validates email format', (tester) async {
    await tester.pumpWidget(
      buildTestApp(authApi: FakeAuthApi(), tokenStorage: FakeTokenStorage()),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Почта'), 'bad');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Войти'));
    await tester.pump();

    expect(find.text('Введите корректную почту'), findsOneWidget);
  });

  testWidgets('logs in and opens home screen', (tester) async {
    final tokenStorage = FakeTokenStorage();
    final authApi = FakeAuthApi();

    await tester.pumpWidget(
      buildTestApp(authApi: authApi, tokenStorage: tokenStorage),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Почта'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(authApi.loginEmail, 'user@example.com');
    expect(authApi.loginPassword, 'password123');
    expect(tokenStorage.savedToken, 'jwt-token');
    expect(find.text('home page'), findsOneWidget);
  });

  testWidgets('shows login error', (tester) async {
    final authApi = FakeAuthApi()
      ..loginError = Exception('login failed');

    await tester.pumpWidget(
      buildTestApp(authApi: authApi, tokenStorage: FakeTokenStorage()),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Почта'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      'wrong-password',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось войти. Попробуйте еще раз.'), findsOneWidget);
  });

  testWidgets('opens signup screen from signup link', (tester) async {
    await tester.pumpWidget(
      buildTestApp(authApi: FakeAuthApi(), tokenStorage: FakeTokenStorage()),
    );

    await tester.ensureVisible(find.text('Зарегистрироваться'));
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pumpAndSettle();

    expect(find.text('signup page'), findsOneWidget);
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

class FakeAuthApi extends AuthApi {
  FakeAuthApi() : super(Dio());

  String? loginEmail;
  String? loginPassword;
  Object? loginError;

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    loginEmail = email;
    loginPassword = password;

    final error = loginError;
    if (error != null) {
      throw error;
    }

    return AuthResponseModel(accessToken: 'jwt-token', user: testUser());
  }
}

class FakeTokenStorage extends TokenStorage {
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

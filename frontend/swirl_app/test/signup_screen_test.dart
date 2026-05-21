import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swirl_app/app/router.dart';
import 'package:swirl_app/core/storage/token_storage.dart';
import 'package:swirl_app/data/api/auth_api.dart';
import 'package:swirl_app/domain/models/auth_response_model.dart';
import 'package:swirl_app/domain/models/avatar_model.dart';
import 'package:swirl_app/domain/models/user_model.dart';
import 'package:swirl_app/presentation/screens/signup_screen.dart';

void main() {
  Widget buildTestApp({
    required FakeAuthApi authApi,
    required FakeTokenStorage tokenStorage,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.signup,
      routes: [
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('home page')),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const Scaffold(body: Text('login page')),
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

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Имя'), 'Vova');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Почта'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Подтвердите пароль'),
      'password123',
    );
  }

  Future<void> tapRegisterButton(WidgetTester tester) async {
    final button = find.widgetWithText(ElevatedButton, 'Зарегистрироваться');

    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  testWidgets('shows registration fields', (tester) async {
    await tester.pumpWidget(
      buildTestApp(authApi: FakeAuthApi(), tokenStorage: FakeTokenStorage()),
    );

    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Имя'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Почта'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Пароль'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Подтвердите пароль'),
      findsOneWidget,
    );
  });

  testWidgets('validates empty form', (tester) async {
    await tester.pumpWidget(
      buildTestApp(authApi: FakeAuthApi(), tokenStorage: FakeTokenStorage()),
    );

    await tapRegisterButton(tester);
    await tester.pump();

    expect(find.text('Введите имя'), findsOneWidget);
    expect(find.text('Введите почту'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
    expect(find.text('Повторите пароль'), findsOneWidget);
  });

  testWidgets('validates confirm password', (tester) async {
    await tester.pumpWidget(
      buildTestApp(authApi: FakeAuthApi(), tokenStorage: FakeTokenStorage()),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Имя'), 'Vova');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Почта'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Пароль'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Подтвердите пароль'),
      'password456',
    );
    await tapRegisterButton(tester);
    await tester.pump();

    expect(find.text('Пароли не совпадают'), findsOneWidget);
  });

  testWidgets('shows error when avatars list is empty', (tester) async {
    final authApi = FakeAuthApi()..defaultAvatars = const [];

    await tester.pumpWidget(
      buildTestApp(authApi: authApi, tokenStorage: FakeTokenStorage()),
    );

    await fillValidForm(tester);
    await tapRegisterButton(tester);
    await tester.pumpAndSettle();

    expect(find.text('Нет доступных аватаров'), findsOneWidget);
  });

  testWidgets('registers with random avatar and opens home', (tester) async {
    final authApi = FakeAuthApi()
      ..defaultAvatars = const [
        AvatarModel(id: 3, name: 'Avatar 3', imageUrl: '/avatar_3.png'),
      ];
    final tokenStorage = FakeTokenStorage();

    await tester.pumpWidget(
      buildTestApp(authApi: authApi, tokenStorage: tokenStorage),
    );

    await fillValidForm(tester);
    await tapRegisterButton(tester);
    await tester.pumpAndSettle();

    expect(authApi.registerName, 'Vova');
    expect(authApi.registerEmail, 'user@example.com');
    expect(authApi.registerAvatarId, 3);
    expect(tokenStorage.savedToken, 'jwt-token');
    expect(find.text('home page'), findsOneWidget);
  });

  testWidgets('shows register error', (tester) async {
    final authApi = FakeAuthApi()..registerError = Exception('register failed');

    await tester.pumpWidget(
      buildTestApp(authApi: authApi, tokenStorage: FakeTokenStorage()),
    );

    await fillValidForm(tester);
    await tapRegisterButton(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Не удалось зарегистрироваться. Попробуйте еще раз.'),
      findsOneWidget,
    );
  });

  testWidgets('opens login screen from login link', (tester) async {
    await tester.pumpWidget(
      buildTestApp(authApi: FakeAuthApi(), tokenStorage: FakeTokenStorage()),
    );

    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('login page'), findsOneWidget);
  });
}

UserModel testUser() {
  return const UserModel(
    id: 'user-id',
    name: 'Vova',
    email: 'user@example.com',
    avatarUrl: '/media/avatars/avatar_1.png',
  );
}

class FakeAuthApi extends AuthApi {
  FakeAuthApi() : super(Dio());

  List<AvatarModel> defaultAvatars = const [
    AvatarModel(id: 1, name: 'Avatar 1', imageUrl: '/avatar_1.png'),
  ];
  Object? registerError;

  String? registerName;
  String? registerEmail;
  int? registerAvatarId;

  @override
  Future<List<AvatarModel>> getAvatars() async {
    return defaultAvatars;
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required int avatarId,
  }) async {
    registerName = name;
    registerEmail = email;
    registerAvatarId = avatarId;

    final error = registerError;
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

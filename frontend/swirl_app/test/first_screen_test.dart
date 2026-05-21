import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swirl_app/app/router.dart';
import 'package:swirl_app/presentation/screens/first_screen.dart';

void main() {
  Widget buildTestApp() {
    final router = GoRouter(
      initialLocation: AppRoutes.first,
      routes: [
        GoRoute(
          path: AppRoutes.first,
          builder: (context, state) => const FirstScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const Scaffold(body: Text('login page')),
        ),
        GoRoute(
          path: AppRoutes.signup,
          builder: (context, state) =>
              const Scaffold(body: Text('signup page')),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('shows main actions from the design', (tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('swirl.'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('Нет аккаунта? Зарегистрироваться'), findsOneWidget);
  });

  testWidgets('opens login screen from login button', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('login page'), findsOneWidget);
  });

  testWidgets('opens signup screen from signup link', (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
    await tester.pumpAndSettle();

    expect(find.text('signup page'), findsOneWidget);
  });
}

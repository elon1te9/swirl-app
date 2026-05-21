import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/daily_test_screen.dart';
import '../presentation/screens/first_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/learn_word_screen.dart';
import '../presentation/screens/level_map_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/sections_screen.dart';
import '../presentation/screens/signup_screen.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/tasks_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.first,
        builder: (context, state) => const FirstScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.sections,
        builder: (context, state) => const SectionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.sectionLevels,
        builder: (context, state) {
          final sectionId = state.pathParameters['sectionId'] ?? '';
          return LevelMapScreen(sectionId: sectionId);
        },
      ),
      GoRoute(
        path: AppRoutes.levelLearn,
        builder: (context, state) {
          final levelId = state.pathParameters['levelId'] ?? '';
          return LearnWordScreen(levelId: levelId);
        },
      ),
      GoRoute(
        path: AppRoutes.levelTasks,
        builder: (context, state) {
          final levelId = state.pathParameters['levelId'] ?? '';
          return TasksScreen(levelId: levelId);
        },
      ),
      GoRoute(
        path: AppRoutes.dailyTest,
        builder: (context, state) => const DailyTestScreen(),
      ),
    ],
  );
});

class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const first = '/first';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const profile = '/profile';
  static const sections = '/sections';
  static const sectionLevels = '/sections/:sectionId/levels';
  static const levelLearn = '/levels/:levelId/learn';
  static const levelTasks = '/levels/:levelId/tasks';
  static const dailyTest = '/daily-test';

  static String levelsForSection(String sectionId) =>
      '/sections/$sectionId/levels';

  static String learnLevel(String levelId) => '/levels/$levelId/learn';

  static String tasksForLevel(String levelId) => '/levels/$levelId/tasks';
}

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Главная',
      description:
          'Будущий экран с прогрессом, дневным тестом и продолжением обучения.',
      actions: [
        PlaceholderAction(label: 'Разделы', route: AppRoutes.sections),
        PlaceholderAction(label: 'Профиль', route: AppRoutes.profile),
        PlaceholderAction(label: 'Дневной тест', route: AppRoutes.dailyTest),
      ],
    );
  }
}

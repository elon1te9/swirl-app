import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({required this.levelId, super.key});

  final String levelId;

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(
      title: 'Задания',
      description: 'Здесь позже появится локальная сессия упражнений уровня.',
      routeInfo: 'levelId: $levelId',
      actions: const [
        PlaceholderAction(label: 'На главную', route: AppRoutes.home),
        PlaceholderAction(label: 'К разделам', route: AppRoutes.sections),
      ],
    );
  }
}

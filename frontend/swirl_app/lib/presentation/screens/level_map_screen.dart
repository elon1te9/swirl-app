import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({required this.sectionId, super.key});

  final String sectionId;

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(
      title: 'Карта уровней',
      description: 'Здесь позже появятся уровни выбранного раздела.',
      routeInfo: 'sectionId: $sectionId',
      actions: [
        PlaceholderAction(
          label: 'Учить слова',
          route: AppRoutes.learnLevel('1'),
        ),
        PlaceholderAction(
          label: 'Тренировка',
          route: AppRoutes.tasksForLevel('1'),
        ),
        const PlaceholderAction(label: 'К разделам', route: AppRoutes.sections),
      ],
    );
  }
}

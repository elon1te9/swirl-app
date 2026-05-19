import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class LearnWordScreen extends StatelessWidget {
  const LearnWordScreen({required this.levelId, super.key});

  final String levelId;

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(
      title: 'Учить слова',
      description: 'Здесь позже появятся карточки слов, картинки и аудио.',
      routeInfo: 'levelId: $levelId',
      actions: [
        PlaceholderAction(
          label: 'Перейти к заданиям',
          route: AppRoutes.tasksForLevel(levelId.isEmpty ? '1' : levelId),
        ),
        const PlaceholderAction(label: 'К разделам', route: AppRoutes.sections),
      ],
    );
  }
}

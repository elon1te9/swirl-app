import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenPlaceholder(
      title: 'Разделы',
      description: 'Здесь позже появится список тематических разделов.',
      actions: [
        PlaceholderAction(
          label: 'Открыть карту уровней',
          route: AppRoutes.levelsForSection('1'),
        ),
        const PlaceholderAction(label: 'На главную', route: AppRoutes.home),
      ],
    );
  }
}

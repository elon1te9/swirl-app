import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'swirl',
      description: 'Стартовый экран для проверки сохраненного JWT.',
      actions: [
        PlaceholderAction(label: 'Начать', route: AppRoutes.first),
        PlaceholderAction(label: 'Домой', route: AppRoutes.home),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class DailyTestScreen extends StatelessWidget {
  const DailyTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Дневной тест',
      description: 'Здесь позже появится повторение изученных слов за день.',
      actions: [PlaceholderAction(label: 'На главную', route: AppRoutes.home)],
    );
  }
}

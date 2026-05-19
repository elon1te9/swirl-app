import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Профиль',
      description:
          'Здесь позже появятся аватар, серия и статистика пользователя.',
      actions: [
        PlaceholderAction(label: 'На главную', route: AppRoutes.home),
        PlaceholderAction(label: 'Выйти', route: AppRoutes.first),
      ],
    );
  }
}

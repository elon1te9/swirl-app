import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Добро пожаловать',
      description: 'Первый экран перед входом или регистрацией.',
      actions: [
        PlaceholderAction(label: 'Войти', route: AppRoutes.login),
        PlaceholderAction(label: 'Зарегистрироваться', route: AppRoutes.signup),
      ],
    );
  }
}

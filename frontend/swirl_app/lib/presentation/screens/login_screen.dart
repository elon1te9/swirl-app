import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Вход',
      description: 'Здесь позже появится форма входа.',
      actions: [
        PlaceholderAction(label: 'Войти в демо', route: AppRoutes.home),
        PlaceholderAction(label: 'Регистрация', route: AppRoutes.signup),
      ],
    );
  }
}

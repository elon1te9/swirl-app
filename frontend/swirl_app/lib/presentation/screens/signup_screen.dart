import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPlaceholder(
      title: 'Регистрация',
      description: 'Здесь позже появится форма регистрации и выбор аватара.',
      actions: [
        PlaceholderAction(label: 'Создать демо-профиль', route: AppRoutes.home),
        PlaceholderAction(label: 'У меня есть аккаунт', route: AppRoutes.login),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/api_error_utils.dart';
import '../state/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkAuth);
  }

  Future<void> _checkAuth() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final isAuthenticated = await ref
          .read(authControllerProvider)
          .checkAuth();

      if (!mounted) {
        return;
      }

      context.go(isAuthenticated ? AppRoutes.home : AppRoutes.first);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = friendlyErrorMessage(
          error,
          fallback: 'Не удалось проверить вход. Попробуйте еще раз.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/backgrounds/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('images/backgrounds/logo.png', width: 96),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    const Text(
                      'Проверяем вход...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromRGBO(67, 74, 107, 1),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _checkAuth,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

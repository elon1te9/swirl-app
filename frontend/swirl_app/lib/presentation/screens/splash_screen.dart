import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/storage/token_storage.dart';
import '../../data/api/auth_api.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isChecking = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  AuthApi get _authApi {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authApiProvider);
  }

  TokenStorage get _tokenStorage {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(tokenStorageProvider);
  }

  Future<void> _checkAuth() async {
    setState(() {
      _isChecking = true;
      _hasError = false;
    });

    final token = await _tokenStorage.readAccessToken();

    if (!mounted) {
      return;
    }

    if (token == null || token.isEmpty) {
      context.go(AppRoutes.first);
      return;
    }

    try {
      await _authApi.me();

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.home);
    } catch (error) {
      final isUnauthorized = error is DioException;
      final statusCode = isUnauthorized ? error.response?.statusCode : null;

      if (statusCode == 401) {
        await _tokenStorage.deleteAccessToken();

        if (!mounted) {
          return;
        }

        context.go(AppRoutes.first);
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'swirl',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isChecking) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Загружаем...'),
                ],
                if (_hasError) ...[
                  const Text(
                    'Не получилось проверить вход',
                    textAlign: TextAlign.center,
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
    );
  }
}

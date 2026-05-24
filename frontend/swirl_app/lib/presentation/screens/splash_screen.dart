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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _purpleColor = Color(0xFF6F73D2);
  static const Color _skyColor = Color(0xFF97DBFF);
  static const Color _inkColor = Color(0xFF27233A);

  bool _isChecking = true;
  bool _hasError = false;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
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
    _progressController.repeat(reverse: true);

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
      final isDioError = error is DioException;
      final statusCode = isDioError ? error.response?.statusCode : null;

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

      _progressController.stop();

      setState(() {
        _isChecking = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purpleColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 700;
            final mascotSize = (constraints.maxWidth * 0.52).clamp(
              156.0,
              isCompact ? 176.0 : 206.0,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 38),
              child: Column(
                children: [
                  Spacer(flex: isCompact ? 1 : 2),
                  Image.asset(
                    'images/mascot_home.png',
                    width: mascotSize,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: isCompact ? 28 : 40),
                  const Text(
                    'Готовимся к обучению!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _hasError
                          ? 'Не получилось проверить вход'
                          : 'Проверяем профиль...',
                      key: ValueKey(_hasError),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.22,
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 30 : 38),
                  if (_isChecking)
                    _SplashProgressBar(animation: _progressController)
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _inkColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _checkAuth,
                        child: const Text('Повторить'),
                      ),
                    ),
                  Spacer(flex: isCompact ? 2 : 3),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SplashProgressBar extends StatelessWidget {
  const _SplashProgressBar({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 20,
            color: Colors.white.withValues(alpha: 0.5),
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final widthFactor = 0.58 + (animation.value * 0.16);

                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widthFactor,
                  child: child,
                );
              },
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: _SplashScreenState._skyColor,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

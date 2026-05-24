import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/widget_previews.dart';

import '../../app/router.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  static const Color _skyColor = Color(0xFF97DBFF);
  static const Color _purpleColor = Color(0xFF6F73D2);
  static const Color _buttonTextColor = Color(0xFF27233A);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _skyColor,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _FirstBgPainter())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Column(
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.13),
                      const Text(
                        'swirl.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 96,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _buttonTextColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: () => context.go(AppRoutes.login),
                          child: const Text('Войти'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.signup),
                        style: TextButton.styleFrom(
                          foregroundColor: _purpleColor,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        child: const Text(
                          'Нет аккаунта? Зарегистрироваться',
                        ),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.14),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstBgPainter extends CustomPainter {
  const _FirstBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = FirstScreen._purpleColor;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.43)
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.59,
        size.width * 0.61,
        size.height * 0.63,
        size.width * 0.47,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.52,
        size.width * 0.29,
        size.height * 0.40,
        0,
        size.height * 0.35,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  static const _blue = Color.fromRGBO(151, 219, 255, 1);
  static const _purple = Color.fromRGBO(111, 115, 210, 1);
  static const _darkText = Color.fromRGBO(39, 35, 58, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blue,
      body: Stack(
        children: [
          ClipPath(
            clipper: _FirstScreenBlobClipper(),
            child: Container(
              height: MediaQuery.sizeOf(context).height * 0.64,
              color: _purple,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 620;
                final topGap =
                    constraints.maxHeight * (isCompact ? 0.08 : 0.14);
                final bottomGap =
                    constraints.maxHeight * (isCompact ? 0.07 : 0.14);

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(42, topGap, 42, bottomGap),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - topGap - bottomGap,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'swirl.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 96,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: FilledButton(
                                onPressed: () => context.go(AppRoutes.login),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _darkText,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Войти'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Нет аккаунта? ',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: _purple,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.signup),
                                  child: const Text(
                                    'Зарегистрироваться',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _FirstScreenBlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height * 0.54)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.56,
        size.width * 0.18,
        size.height * 0.84,
        size.width * 0.38,
        size.height * 0.92,
      )
      ..cubicTo(
        size.width * 0.62,
        size.height * 1.02,
        size.width * 0.82,
        size.height * 0.82,
        size.width,
        size.height * 0.66,
      )
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

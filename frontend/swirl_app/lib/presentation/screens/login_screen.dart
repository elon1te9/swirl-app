import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/api_error_utils.dart';
import '../state/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _designWidth = 393.0;
  static const _designHeight = 852.0;
  static const _keyboardVisibleBottomY = 517.0;
  static const _backgroundColor = Color.fromRGBO(151, 219, 255, 1);
  static const _blobColor = Color.fromRGBO(111, 115, 210, 1);
  static const _darkColor = Color.fromRGBO(39, 35, 58, 1);
  static const _softDarkColor = Color.fromRGBO(39, 35, 58, 0.8);
  static const _linkColor = Color.fromRGBO(111, 115, 210, 1);
  static const _placeholderColor = Color.fromRGBO(39, 35, 58, 0.7);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  double? _focusedFieldY;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      _setFocusedField(_emailFocusNode, 397);
    });
    _passwordFocusNode.addListener(() {
      _setFocusedField(_passwordFocusNode, 462);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final emailError = _validateEmail(_emailController.text);
    final passwordError = _validatePassword(_passwordController.text);

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _errorMessage = null;
    });

    if (emailError != null || passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.home);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _messageFromError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/backgrounds/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
              final scale = _layoutScale(constraints);
              final left = (constraints.maxWidth - _designWidth * scale) / 2;
              final keyboardShift = _keyboardShift(
                constraints: constraints,
                keyboardBottom: keyboardBottom,
                scale: scale,
              );
              final formErrorMessage = _formErrorMessage;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    top: -keyboardShift,
                    left: 0,
                    right: 0,
                    height: constraints.maxHeight,
                    child: Form(
                      key: _formKey,
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _positioned(
                              left: left,
                              scale: scale,
                              x: 0,
                              y: 307,
                              width: _designWidth,
                              child: const Text(
                                'Авторизация',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: _softDarkColor,
                                ),
                              ),
                            ),
                            _positioned(
                              left: left,
                              scale: scale,
                              x: 50,
                              y: 397,
                              width: 293,
                              child: _buildTextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                hint: 'Почта',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                errorText: _visibleEmailError,
                                onChanged: _handleFieldChanged,
                              ),
                            ),
                            _positioned(
                              left: left,
                              scale: scale,
                              x: 50,
                              y: 462,
                              width: 293,
                              child: _buildTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                hint: 'Пароль',
                                obscure: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) =>
                                    _isLoading ? null : _submit(),
                                errorText: _visiblePasswordError,
                                onChanged: _handleFieldChanged,
                                icon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _darkColor,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                            if (formErrorMessage != null)
                              _positioned(
                                left: left,
                                scale: scale,
                                x: 50,
                                y: 525,
                                width: 293,
                                child: _buildFieldError(formErrorMessage),
                              ),
                            _positioned(
                              left: left,
                              scale: scale,
                              x: 50,
                              y: 669,
                              width: 293,
                              child: SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _softDarkColor,
                                    disabledBackgroundColor: _softDarkColor
                                        .withValues(alpha: 0.55),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Войти',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            _positioned(
                              left: left,
                              scale: scale,
                              x: 0,
                              y: 734,
                              width: _designWidth,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Нет аккаунта?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _darkColor,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => context.go(AppRoutes.signup),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.only(left: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Зарегистрироваться',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: _linkColor,
                                        decoration: TextDecoration.underline,
                                        decorationColor: _linkColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipPath(
                        clipper: _AuthForegroundBlobClipper(),
                        child: const ColoredBox(color: _blobColor),
                      ),
                    ),
                  ),
                  _positioned(
                    left: left,
                    scale: scale,
                    x: 153,
                    y: 105,
                    width: 87,
                    child: Image.asset('images/backgrounds/logo.png'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  double _layoutScale(BoxConstraints constraints) {
    final widthScale = constraints.maxWidth / _designWidth;
    final heightScale = constraints.maxHeight / _designHeight;
    return widthScale < heightScale ? widthScale : heightScale;
  }

  Widget _positioned({
    required double left,
    required double scale,
    required double x,
    required double y,
    required double width,
    required Widget child,
  }) {
    return Positioned(
      left: left + x * scale,
      top: y * scale,
      width: width * scale,
      child: child,
    );
  }

  void _setFocusedField(FocusNode node, double fieldY) {
    if (!mounted || !node.hasFocus) {
      return;
    }

    setState(() {
      _focusedFieldY = fieldY;
    });
  }

  double _keyboardShift({
    required BoxConstraints constraints,
    required double keyboardBottom,
    required double scale,
  }) {
    final focusedFieldY = _focusedFieldY;
    if (keyboardBottom <= 0 || focusedFieldY == null) {
      return 0;
    }

    final focusedFieldBottomY = focusedFieldY + 55;
    final targetBottomY = focusedFieldBottomY > _keyboardVisibleBottomY
        ? focusedFieldBottomY
        : _keyboardVisibleBottomY;
    final fieldBottom = targetBottomY * scale;
    final keyboardTop = constraints.maxHeight - keyboardBottom;
    final overlap = fieldBottom - keyboardTop + 24;
    return overlap > 0 ? overlap : 0;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required String? errorText,
    Widget? icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    final borderColor = errorText == null
        ? _softDarkColor
        : Colors.red.shade400;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: _darkColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: _placeholderColor,
        ),
        suffixIcon: icon,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildFieldError(String message) {
    return SizedBox(
      height: 14,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 12,
            height: 1,
          ),
        ),
      ),
    );
  }

  String? get _formErrorMessage {
    return _emailError ?? _passwordError ?? _errorMessage;
  }

  String? get _visibleEmailError => _emailError;

  String? get _visiblePasswordError {
    return _emailError == null ? _passwordError : null;
  }

  bool get _hasValidationErrors {
    return _emailError != null || _passwordError != null;
  }

  void _handleFieldChanged(String _) {
    if (!_hasValidationErrors && _errorMessage == null) {
      return;
    }

    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _errorMessage = null;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Введите почту.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Введите корректную почту.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль.';
    }
    return null;
  }

  String _messageFromError(Object error) {
    return friendlyErrorMessage(
      error,
      fallback: 'Не удалось войти. Попробуйте еще раз.',
    );
  }
}

class _AuthForegroundBlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.14)
      ..cubicTo(
        size.width * 0.87,
        size.height * 0.28,
        size.width * 0.67,
        size.height * 0.34,
        size.width * 0.55,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.34,
        size.width * 0.28,
        size.height * 0.24,
        size.width * 0.16,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.24,
        size.width * 0.03,
        size.height * 0.25,
        0,
        size.height * 0.26,
      )
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

import 'package:flutter/material.dart';

import '../../app/router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordVisible = false;

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  Image.asset('images/backgrounds/logo.png', width: 90),

                  const SizedBox(height: 140),

                  const Text(
                    'Авторизация',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF434A6B),
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildTextField(hint: 'Почта', icon: null),

                  const SizedBox(height: 22),

                  _buildTextField(
                    hint: 'Пароль',
                    icon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF434A6B),
                        size: 32,
                      ),
                      padding: EdgeInsets.only(right: 20),
                    ),
                    obscure: !isPasswordVisible,
                  ),

                  const SizedBox(height: 140),

                  SizedBox(
                    width: double.infinity,
                    height: 68,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.popAndPushNamed(context, AppRoutes.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF434A6B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Нет аккаунта?',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF434A6B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          ' Зарегистрироваться',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF6F73D2),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF6F73D2),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    Widget? icon,
    bool obscure = false,
  }) {
    return SizedBox(
      height: 68,
      child: TextField(
        obscureText: obscure,
        style: const TextStyle(fontSize: 20, color: Color(0xFF434A6B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 20, color: Color(0xFF434A6B)),
          suffixIcon: icon,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF434A6B), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF434A6B), width: 2),
          ),
        ),
      ),
    );
  }
}

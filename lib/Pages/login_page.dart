import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flame/components/button.dart';
import 'package:flame/components/text_field.dart';
import 'package:flutter/material.dart';

import '../Pages/home_page.dart';
import '../Pages/forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password.');
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthService.login(email, password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } on DioException catch (e) {
      if (mounted) _showError(AuthService.mapDioError(e));
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.cardRadiusLg),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppColors.glassBlur,
                    sigmaY: AppColors.glassBlur,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: AppColors.glassPanel,
                      borderRadius: BorderRadius.circular(
                        AppColors.cardRadiusLg,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/FLAME_LOGO.png',
                          width: 90,
                          height: 90,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Pass the FLAME",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.text1),
                        ),
                        const SizedBox(height: 30),
                        MyTextField(
                          controller: emailController,
                          hintText: 'EMAIL',
                          obscureText: false,
                        ),
                        const SizedBox(height: 12),
                        MyTextField(
                          controller: passwordController,
                          hintText: 'PASSWORD',
                          obscureText: true,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(color: AppColors.text2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _busy
                            ? const CircularProgressIndicator(
                                color: AppColors.amber,
                              )
                            : MyButton(onTap: signIn, text: 'Sign in'),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: AppColors.border),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                "Not a member?",
                                style: TextStyle(color: AppColors.text3),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: AppColors.border),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            'Register now',
                            style: TextStyle(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

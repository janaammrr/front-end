import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flame/components/button.dart';
import 'package:flame/components/text_field.dart';
import 'package:flutter/material.dart';

import '../Pages/preferences_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PreferencesScreen()),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                        const SizedBox(height: 12),
                        Text(
                          "Create your account",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.text1, fontSize: 20),
                        ),
                        const SizedBox(height: 24),
                        MyTextField(
                          controller: firstNameController,
                          hintText: 'FIRST NAME',
                          obscureText: false,
                        ),
                        const SizedBox(height: 12),
                        MyTextField(
                          controller: lastNameController,
                          hintText: 'LAST NAME',
                          obscureText: false,
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        MyTextField(
                          controller: confirmPasswordController,
                          hintText: 'CONFIRM PASSWORD',
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        _busy
                            ? CircularProgressIndicator(color: AppColors.amber)
                            : MyButton(onTap: signUp, text: 'Sign up'),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(color: AppColors.text2),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: widget.onTap,
                              child: Text(
                                'Login Page',
                                style: TextStyle(
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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

import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flame/components/button.dart';
import 'package:flame/components/text_field.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email.');
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthService.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _busy = false;
      });
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(
          ApiClient.errorMessage(e, fallback: 'Could not send reset email.'),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _showError('Something went wrong. Please try again.');
      }
    }
  }

  void _showError(String message) {
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
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.text1,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.lock_reset_rounded,
                          color: AppColors.amber,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Forgot Password',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.text1),
                        ),
                        const SizedBox(height: 10),
                        if (!_sent)
                          Text(
                            "Enter your email and we'll send you a reset link.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.text2),
                          ),
                        const SizedBox(height: 24),
                        if (_sent) ...[
                          const Icon(
                            Icons.mark_email_read_rounded,
                            color: Color(0xFF10B981),
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'If an account exists for ${_emailController.text.trim()}, a reset link has been sent.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.text2),
                          ),
                          const SizedBox(height: 24),
                          MyButton(
                            text: 'I have a reset code',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordScreen(),
                              ),
                            ),
                          ),
                        ] else ...[
                          MyTextField(
                            controller: _emailController,
                            hintText: 'EMAIL',
                            obscureText: false,
                          ),
                          const SizedBox(height: 20),
                          _busy
                              ? CircularProgressIndicator(
                                  color: AppColors.amber,
                                )
                              : MyButton(
                                  onTap: _submit,
                                  text: 'Send reset link',
                                ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordScreen(),
                              ),
                            ),
                            child: Text(
                              'Already have a reset code?',
                              style: TextStyle(
                                color: AppColors.text2,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
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

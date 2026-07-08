import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flame/components/button.dart';
import 'package:flame/components/text_field.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../auth/login_or_register.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (token.isEmpty) {
      _showError('Please enter your reset code.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthService.resetPassword(token: token, newPassword: password);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(
          ApiClient.errorMessage(e, fallback: 'Could not reset password.'),
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
                        if (!_done)
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
                          _done
                              ? Icons.check_circle_rounded
                              : Icons.password_rounded,
                          color: _done
                              ? const Color(0xFF10B981)
                              : AppColors.amber,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _done ? 'Password Reset' : 'Reset Password',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.text1),
                        ),
                        const SizedBox(height: 10),
                        if (_done) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Your password has been updated. Please sign in again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.text2),
                          ),
                          const SizedBox(height: 24),
                          MyButton(
                            text: 'Back to sign in',
                            onTap: () =>
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginOrRegister(),
                                  ),
                                  (_) => false,
                                ),
                          ),
                        ] else ...[
                          Text(
                            'Paste the code from your reset email and choose a new password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.text2),
                          ),
                          const SizedBox(height: 24),
                          MyTextField(
                            controller: _tokenController,
                            hintText: 'RESET CODE',
                            obscureText: false,
                          ),
                          const SizedBox(height: 12),
                          MyTextField(
                            controller: _passwordController,
                            hintText: 'NEW PASSWORD',
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          MyTextField(
                            controller: _confirmController,
                            hintText: 'CONFIRM PASSWORD',
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          _busy
                              ? CircularProgressIndicator(
                                  color: AppColors.amber,
                                )
                              : MyButton(
                                  onTap: _submit,
                                  text: 'Reset password',
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

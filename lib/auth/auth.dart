import 'package:flutter/material.dart';
import '../Pages/home_page.dart';
import '../services/auth_service.dart';
import 'login_or_register.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF09090B),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7A18)),
            ),
          );
        }
        if (snapshot.data == true) {
          return const HomePage();
        }
        return const LoginOrRegister();
      },
    );
  }
}

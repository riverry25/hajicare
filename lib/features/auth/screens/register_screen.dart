import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Register screen wrapper for backward-compatibility with [AppRoutes.register].
/// The authentication interface is now unified within [LoginScreen] using tabs.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialTab: 1);
  }
}

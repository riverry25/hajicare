import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';

void main() {
  runApp(const HajiCareApp());
}

class HajiCareApp extends StatelessWidget {
  const HajiCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HajiCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}

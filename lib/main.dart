import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/state/app_settings_controller.dart';
import 'core/state/hajicare_controller.dart';
import 'core/locales/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final settings = AppSettingsController();
  await settings.loadSettings();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => HajiCareController()),
      ],
      child: const HajiCareApp(),
    ),
  );
}

class HajiCareApp extends StatelessWidget {
  const HajiCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();

    return MaterialApp(
      title: 'HajiCare',
      debugShowCheckedModeBanner: false,

      // Theming
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.currentThemeMode,

      // Localization
      locale: settings.currentLocale,
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Routing
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,

      // Global text scale clamping
      builder: (context, child) {
        final factor = settings.textScaleFactor;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(factor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

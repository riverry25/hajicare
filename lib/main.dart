import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/state/app_settings_controller.dart';
import 'core/state/hajicare_controller.dart';
import 'core/locales/app_localizations.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // Register global permanent controllers before runApp.
  final settings = Get.put(AppSettingsController(), permanent: true);
  await settings.loadSettings();
  Get.put(HajiCareController(), permanent: true);

  runApp(const HajiCareApp());
}

class HajiCareApp extends StatelessWidget {
  const HajiCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();

    return Obx(
      () => GetMaterialApp(
        title: 'HajiCare',
        debugShowCheckedModeBanner: false,

        // Theming
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.currentThemeMode,

        // Localization
        locale: settings.currentLocale,
        fallbackLocale: AppTranslations.fallbackLocale,
        translations: AppTranslations(),
        supportedLocales: AppTranslations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
          FallbackWidgetsLocalizationsDelegate(),
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return AppTranslations.fallbackLocale;
        },

        // GetX route management with bindings attached per-route
        initialRoute: AppRoutes.splash,
        getPages: AppRoutes.pages,

        // Global text scale clamping for accessibility
        builder: (context, child) {
          final factor = settings.textScaleFactor;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(factor),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

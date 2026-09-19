import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/state/app_settings_controller.dart';
import 'core/state/app_startup_controller.dart';
import 'core/state/hajicare_controller.dart';
import 'core/locales/app_localizations.dart';
import 'features/notification/controllers/notification_controller.dart';

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
  Get.put(AppStartupController(), permanent: true);
  Get.put(HajiCareController(), permanent: true);
  Get.put(NotificationController(), permanent: true);

  runApp(const HajiCareApp());
}

class HajiCareApp extends StatelessWidget {
  const HajiCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();

    // ── Reactive text scale wrapper ─────────────────────────────────────────
    // Reading rxTextScale.value directly inside Obx ensures any change to the
    // text scale Rx immediately rebuilds this widget, which re-injects the
    // updated MediaQuery *above* the entire GetMaterialApp tree.  This is the
    // correct way to drive global text scaling: the MediaQuery ancestor must
    // live outside GetMaterialApp so the whole navigator/route tree inherits it.
    return Obx(() {
      final textScaleFactor = settings.rxTextScale.value.factor;
      final themeMode = settings.rxThemeMode.value;
      final locale = settings.rxLocale.value;

      return GetMaterialApp(
        title: 'HajiCare',
        debugShowCheckedModeBanner: false,

        // Theming
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,

        // Localization
        locale: locale,
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

        // Apply dynamic text scaling to the entire widget tree
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
    });
  }
}

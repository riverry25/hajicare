import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'dart:async';
import 'core/services/adhan_notification_service.dart';
import 'core/services/app_check_service.dart';
import 'core/theme/app_theme.dart';
import 'core/locales/app_localizations.dart';
import 'core/routes/app_routes.dart';
import 'core/state/app_settings_controller.dart';
import 'core/state/app_startup_controller.dart';
import 'core/state/hajicare_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'features/notification/controllers/notification_controller.dart';
import 'features/map/controllers/map_controller.dart';
import 'features/dashboard/services/hajj_guide_service.dart';
import 'features/smartband/services/smartband_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi controller pengaturan awal
  final settings = Get.put(AppSettingsController(), permanent: true);
  final adhanNotifService = AdhanNotificationService();

  // Inisialisasi service utama secara paralel
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    settings.loadSettings(),
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      AndroidAlarmManager.initialize().catchError((e) {
        debugPrint('[Main] AndroidAlarmManager initialization error: $e');
        return false;
      }),
    adhanNotifService.initialize().catchError((e) {
      debugPrint('[Main] AdhanNotificationService initialization error: $e');
    }),
    SmartbandStorageService.instance.init().catchError((e) {
      debugPrint('[Main] SmartbandStorageService initialization error: $e');
    }),
  ]);

  // Inisialisasi Firebase App Check
  await AppCheckService.initialize();

  // Registrasi controller global
  Get.put(AppStartupController(), permanent: true);
  Get.put(HajiCareController(), permanent: true);
  Get.put(NotificationController(), permanent: true);
  Get.put(HajjGuideService(), permanent: true);
  Get.lazyPut<MapController>(() => MapController(), fenix: true);

  unawaited(adhanNotifService.scheduleFromPreferences());

  runApp(const HajiCareApp());
}

class HajiCareApp extends StatelessWidget {
  const HajiCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();

    return GetMaterialApp(
      title: 'HajiCare',
      debugShowCheckedModeBanner: false,

      // Konfigurasi tema
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.rxThemeMode.value,

      // Konfigurasi bahasa
      locale: settings.rxLocale.value,
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

      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,

      builder: (context, child) =>
          _TextScaleMediaQuery(settings: settings, child: child),
    );
  }
}

// Wrapper MediaQuery untuk menangani perubahan skala teks
class _TextScaleMediaQuery extends StatefulWidget {
  final AppSettingsController settings;
  final Widget? child;

  const _TextScaleMediaQuery({required this.settings, this.child});

  @override
  State<_TextScaleMediaQuery> createState() => _TextScaleMediaQueryState();
}

class _TextScaleMediaQueryState extends State<_TextScaleMediaQuery> {
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _worker = ever(widget.settings.rxTextScale, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = widget.settings.rxTextScale.value.factor;
    final mediaQuery = MediaQuery.of(context);
    final systemScale = mediaQuery.textScaler.scale(1);
    final effectiveScale = (systemScale * textScaleFactor).clamp(0.8, 3.0);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(effectiveScale)),
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

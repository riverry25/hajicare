import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

    // ── Stable GetMaterialApp ────────────────────────────────────────────────
    // GetMaterialApp must NOT be rebuilt from scratch on every Rx tick.
    // Rebuilding it tears down all InheritedWidget descendants (including
    // MediaQuery) while dependents still hold references → _dependents.isEmpty
    // assertion failure.
    //
    // Instead:
    //  • themeMode / locale are passed as Obx-observed values on the
    //    GetMaterialApp itself — GetX updates those fields without a full
    //    rebuild when they change.
    //  • textScaleFactor is consumed inside `builder` via a narrow Obx that
    //    only recreates the thin MediaQuery wrapper, leaving the navigator tree
    //    untouched.
    return GetMaterialApp(
      title: 'HajiCare',
      debugShowCheckedModeBanner: false,

      // Theming — Obx() reads rxThemeMode so GetX can patch themeMode reactively
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.rxThemeMode.value,

      // Localization
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

      // GetX route management with bindings attached per-route
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,

      // Wrap child with a stable StatefulWidget — NEVER use Obx inside builder.
      // Obx replaces the MediaQuery node on every Rx tick, which triggers
      // _dependents.isEmpty when dialogs are being dismissed mid-frame.
      builder: (context, child) =>
          _TextScaleMediaQuery(settings: settings, child: child),
    );
  }
}

// ── Stable text-scale MediaQuery wrapper ─────────────────────────────────────
// Uses GetX ever() to call setState when rxTextScale changes.
// Because this is a StatefulWidget, the element is REUSED across rebuilds —
// Flutter updates the MediaQuery data in-place (updateShouldNotify) instead
// of deactivating the node, so dependents are never invalidated mid-frame.
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
    // Listen to rxTextScale and trigger an in-place rebuild of this widget.
    // ever() fires only when the value actually changes — no spurious frames.
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

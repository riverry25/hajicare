import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_pages.dart';
import 'core/bindings/app_binding.dart';
import 'core/state/app_settings_controller.dart';
import 'core/locales/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = Get.put(AppSettingsController(), permanent: true);
  await settings.loadSettings();
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

      // Theming
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.currentThemeMode,

      // Localization
      translations: AppTranslations(),
      locale: settings.currentLocale,
      fallbackLocale: AppTranslations.fallbackLocale,

      // Bindings & Routing
      initialBinding: AppBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,

      // Global text scale clamping — dynamically reactive via Obx only inside builder
      builder: (context, child) {
        return Obx(() {
          final factor = settings.textScaleFactor;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(factor),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        });
      },
    );
  }
}

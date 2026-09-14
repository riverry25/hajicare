import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/locales/en.dart';
import 'package:hajicare/core/locales/id.dart';
import 'package:hajicare/core/locales/jv.dart';
import 'package:hajicare/core/locales/su.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/dashboard/bindings/dashboard_binding.dart';
import 'package:hajicare/features/dashboard/screens/dashboard_jamaah_screen.dart';
import 'package:hajicare/features/dashboard/screens/dashboard_pendamping_screen.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Dashboard Localization Completeness Tests', () {
    const requiredKeys = [
      'subuh',
      'terbit',
      'dzuhur',
      'ashar',
      'maghrib',
      'isya',
      'prayerScheduleTitle',
      'qiblaDegree',
      'nextPrayerLabel',
      'inCountdownPrefix',
      'distanceToCompanion',
      'viewCompanionOnMap',
      'meterUnit',
      'statusSafe',
      'statusWarning',
      'statusDanger',
      'sosConfirmTitle',
      'sosConfirmMessage',
      'sosSendButton',
      'sosSentTo',
      'sosButtonTitle',
      'sosButtonSubtitle',
      'sosForwardedTo',
      'sosSectorOfficers',
      'sosAnd',
      'sosFamilyCompanion',
      'sos24HoursResponse',
      'separatedWarning',
      'officerAdviceTitle',
      'officerAdviceBody',
      'pendampingGreeting',
      'pendampingSubtitleDesc',
      'monitoredPilgrims',
      'syncSmartBand',
      'realtimePosition',
      'gpsAccuracy',
      'youLabel',
      'openFullNavigation',
      'elderlyRoute',
      'tentMaktab',
      'pendampingServices',
      'serviceIntegratedMap',
      'serviceIntegratedMapSub',
      'servicePilgrimBand',
      'servicePilgrimBandSub',
      'serviceScheduleAgenda',
      'serviceScheduleAgendaSub',
      'serviceMaktabContact',
      'serviceMaktabContactSub',
      'sosEmergencyActive',
      'sosNeedsImmediateHelp',
      'contactOfficer',
      'endSos',
      'sosStatusStandby',
      'sosStandbyBadge',
      'sosStandbyDesc',
      'testAlarmSignal',
      'responseCenter',
      'separatedAlertDetail',
      'serviceMapTitle',
      'serviceMapSubtitle',
      'serviceMoneyTitle',
      'serviceMoneySubtitle',
      'serviceCommTitle',
      'serviceCommSubtitle',
      'serviceBandTitle',
      'serviceBandSubtitle',
      'servicePrayerTitle',
      'servicePrayerSubtitle',
      'serviceCallTitle',
      'serviceCallSubtitle',
      'independentServices',
      'easyTouch',
      'changeTextSize',
      'connectedWith',
    ];

    final dictionaries = {
      'Indonesian (id)': idTranslations,
      'English (en)': enTranslations,
      'Sundanese (su)': suTranslations,
      'Javanese (jv)': jvTranslations,
    };

    for (final entry in dictionaries.entries) {
      test('Language ${entry.key} contains all dashboard keys', () {
        final dict = entry.value;
        for (final key in requiredKeys) {
          expect(dict.containsKey(key), isTrue,
              reason: 'Missing key "$key" in ${entry.key}');
          expect(dict[key], isNotEmpty,
              reason: 'Empty translation for key "$key" in ${entry.key}');
        }
      });
    }
  });

  group('Dashboard Jamaah Dynamic Theme & Text Scaling Tests', () {
    Widget buildTestWidget({
      required ThemeMode themeMode,
      double textScaleFactor = 1.0,
      Locale locale = const Locale('id', 'ID'),
    }) {
      return MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
        child: GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: const DashboardJamaahScreen(),
        ),
      );
    }

    testWidgets('Renders DashboardJamaah in Light Mode without error',
        (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.light));
      await tester.pump();

      expect(find.byType(DashboardJamaahScreen), findsOneWidget);
      expect(Get.isRegistered<PrayerTimesController>(), isTrue);
    });

    testWidgets('Renders DashboardJamaah in Dark Mode without error',
        (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.dark));
      await tester.pump();

      expect(find.byType(DashboardJamaahScreen), findsOneWidget);
    });

    testWidgets('Renders DashboardJamaah with Large Text Scale (1.5x) cleanly',
        (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      await tester.pumpWidget(buildTestWidget(
        themeMode: ThemeMode.light,
        textScaleFactor: 1.5,
      ));
      await tester.pump();

      expect(find.byType(DashboardJamaahScreen), findsOneWidget);
    });
  });

  group('Dashboard Pendamping Dynamic Theme & Text Scaling Tests', () {
    Widget buildTestWidget({
      required ThemeMode themeMode,
      double textScaleFactor = 1.0,
      Locale locale = const Locale('id', 'ID'),
    }) {
      return MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
        child: GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: const DashboardPendampingScreen(),
        ),
      );
    }

    testWidgets('Renders DashboardPendamping in Light Mode without error',
        (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.light));
      await tester.pump();

      expect(find.byType(DashboardPendampingScreen), findsOneWidget);
    });

    testWidgets('Renders DashboardPendamping in Dark Mode without error',
        (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.dark));
      await tester.pump();

      expect(find.byType(DashboardPendampingScreen), findsOneWidget);
    });

    testWidgets(
        'Renders DashboardPendamping with Large Text Scale (1.5x) cleanly',
        (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      await tester.pumpWidget(buildTestWidget(
        themeMode: ThemeMode.light,
        textScaleFactor: 1.5,
      ));
      await tester.pump();

      expect(find.byType(DashboardPendampingScreen), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/dashboard/screens/dashboard_jamaah_screen.dart';
import 'package:hajicare/features/smartband/controllers/smartband_ble_test_controller.dart';
import 'package:hajicare/features/smartband/controllers/smartband_ldr_controller.dart';
import 'package:hajicare/features/smartband/screens/smartband_ble_test_screen.dart';
import 'package:hajicare/features/smartband/screens/smartband_ldr_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp({
    required Widget child,
    Locale locale = const Locale('id'),
    double textScale = 1.0,
    ThemeData? theme,
  }) {
    if (!Get.isRegistered<AppSettingsController>()) {
      Get.put(AppSettingsController(), permanent: true);
    }

    return GetMaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      translations: AppTranslations(),
      locale: locale,
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child,
          );
        },
      ),
    );
  }

  group('Smartband UI Responsiveness & Text Scaling Tests', () {
    testWidgets(
      'SmartbandLdrPage renders without overflow on small screen with 1.5x text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(720, 1280); // 360 x 640 dp
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final ctrl = Get.put(SmartbandLdrController());
        ctrl.toggleSimulation(true);

        await tester.pumpWidget(
          buildTestApp(child: const SmartbandLdrPage(), textScale: 1.5),
        );
        await tester.pumpAndSettle();

        // Verifikasi tidak ada error overflow
        expect(tester.takeException(), isNull);

        // Verifikasi elemen visual penting ter-render
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.byType(SmartbandLdrPage), findsOneWidget);

        // Uji coba trigger simulasi jatuh
        ctrl.triggerFallSimulation();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(ctrl.isFallDetected.value, isTrue);

        // Batalkan alert jatuh
        ctrl.cancelFallAlert();
        await tester.pumpAndSettle();
        expect(ctrl.isFallDetected.value, isFalse);

        ctrl.toggleSimulation(false);
        ctrl.onClose();
      },
    );

    testWidgets(
      'SmartbandBleTestScreen renders without overflow with large text scaling',
      (tester) async {
        tester.view.physicalSize = const Size(720, 1280);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final bleCtrl = Get.put(SmartbandBleTestController());

        await tester.pumpWidget(
          buildTestApp(child: const SmartbandBleTestScreen(), textScale: 1.4),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(SmartbandBleTestScreen), findsOneWidget);
        bleCtrl.onClose();
      },
    );

    testWidgets('SmartbandLdrPage switches sensor categories seamlessly', (
      tester,
    ) async {
      final ctrl = Get.put(SmartbandLdrController());
      ctrl.toggleSimulation(true);

      await tester.pumpWidget(buildTestApp(child: const SmartbandLdrPage()));
      await tester.pumpAndSettle();

      // Switch ke MCP9808 (Index 1)
      ctrl.selectSensor(1);
      await tester.pumpAndSettle();
      expect(ctrl.selectedSensorIndex.value, equals(1));

      // Switch ke MPU6050 (Index 2)
      ctrl.selectSensor(2);
      await tester.pumpAndSettle();
      expect(ctrl.selectedSensorIndex.value, equals(2));

      // Switch ke LiPo (Index 4)
      ctrl.selectSensor(4);
      await tester.pumpAndSettle();
      expect(ctrl.selectedSensorIndex.value, equals(4));

      expect(tester.takeException(), isNull);
      ctrl.toggleSimulation(false);
      ctrl.onClose();
    });

    testWidgets(
      'Smartband Dialog displays senior-friendly fallback without raw coords when disconnected',
      (tester) async {
        final ctrl = Get.put(SmartbandLdrController());
        ctrl.toggleSimulation(false);

        await tester.pumpWidget(
          buildTestApp(
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      DashboardJamaahScreen.showSmartbandDialog(context),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Dialog harus terbuka
        expect(find.byType(Dialog), findsOneWidget);

        // Memastikan tidak ada teks koordinat latitude/longitude teknis
        expect(find.textContaining('Latitude'), findsNothing);
        expect(find.textContaining('Longitude'), findsNothing);
        expect(find.textContaining('21.422487'), findsNothing);

        // Memastikan fallback ramah lansia muncul
        expect(find.text('Lokasi Belum Terdeteksi'), findsOneWidget);
        expect(find.text('Buka Peta Utama'), findsOneWidget);
        expect(tester.takeException(), isNull);

        ctrl.onClose();
      },
    );

    testWidgets(
      'Smartband Dialog displays mini map preview without raw coords when simulation is active',
      (tester) async {
        final ctrl = Get.put(SmartbandLdrController());
        ctrl.toggleSimulation(true);

        await tester.pumpWidget(
          buildTestApp(
            theme: AppTheme.darkTheme,
            textScale: 1.3,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      DashboardJamaahScreen.showSmartbandDialog(context),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);

        // Tidak ada koordinat mentah
        expect(find.textContaining('Latitude'), findsNothing);
        expect(find.textContaining('Longitude'), findsNothing);

        // Mini map preview harus terpasang
        expect(find.byType(fmap.FlutterMap), findsOneWidget);
        expect(find.text('Area Masjidil Haram, Makkah'), findsOneWidget);
        expect(find.text('GPS Aktif'), findsOneWidget);
        expect(tester.takeException(), isNull);

        ctrl.toggleSimulation(false);
        ctrl.onClose();
      },
    );
  });
}

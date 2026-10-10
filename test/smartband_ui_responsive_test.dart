import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
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
  }) {
    if (!Get.isRegistered<AppSettingsController>()) {
      Get.put(AppSettingsController(), permanent: true);
    }

    return GetMaterialApp(
      theme: AppTheme.lightTheme,
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
  });
}

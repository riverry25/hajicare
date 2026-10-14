import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_translations.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:hajicare/features/prayer/widgets/qibla_astrolabe_compass.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestPrayerTimesController extends PrayerTimesController {
  @override
  Future<void> initialize() async {
    // Avoid background location/timer/sensor initialization in widget test
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp(Widget child) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('id'),
      fallbackLocale: const Locale('id'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('QiblaAstrolabeCompass Tests', () {
    testWidgets('Renders dynamic turn right guidance when offset <= 180°', (
      tester,
    ) async {
      final controller = Get.put<PrayerTimesController>(
        _TestPrayerTimesController(),
      );
      controller.hasCompassSensor.value = true;
      controller.isQiblaAligned.value = false;
      controller.qiblaBearing.value = 295.0;
      controller.qiblaOffset.value = 45.0;

      await tester.pumpWidget(
        buildTestApp(QiblaAstrolabeCompass(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('295°'), findsOneWidget);
      expect(find.textContaining('ke kanan ➔'), findsOneWidget);
      expect(find.textContaining('45°'), findsWidgets);
      expect(find.byIcon(Icons.mosque_rounded), findsOneWidget);
    });

    testWidgets('Renders dynamic turn left guidance when offset > 180°', (
      tester,
    ) async {
      final controller = Get.put<PrayerTimesController>(
        _TestPrayerTimesController(),
      );
      controller.hasCompassSensor.value = true;
      controller.isQiblaAligned.value = false;
      controller.qiblaBearing.value = 295.0;
      controller.qiblaOffset.value = 335.0; // 360 - 335 = 25° to turn left

      await tester.pumpWidget(
        buildTestApp(QiblaAstrolabeCompass(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('ke kiri'), findsOneWidget);
      expect(find.textContaining('25°'), findsWidgets);
    });

    testWidgets('Renders aligned state with checkmark when perfectly aligned', (
      tester,
    ) async {
      final controller = Get.put<PrayerTimesController>(
        _TestPrayerTimesController(),
      );
      controller.hasCompassSensor.value = true;
      controller.isQiblaAligned.value = true;
      controller.qiblaBearing.value = 295.0;
      controller.qiblaOffset.value = 0.0;

      await tester.pumpWidget(
        buildTestApp(QiblaAstrolabeCompass(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.toLowerCase().contains('kaaba') == true ||
                  w.data?.toLowerCase().contains("ka'bah") == true ||
                  w.data?.toLowerCase().contains('kiblat') == true ||
                  w.data?.toLowerCase().contains('qibla') == true),
        ),
        findsWidgets,
      );
    });

    testWidgets(
      'Renders sensor missing fallback view when device lacks compass',
      (tester) async {
        final controller = Get.put<PrayerTimesController>(
          _TestPrayerTimesController(),
        );
        controller.hasCompassSensor.value = false;

        await tester.pumpWidget(
          buildTestApp(QiblaAstrolabeCompass(controller: controller)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.sensors_off_rounded), findsOneWidget);
        expect(find.byIcon(Icons.mosque_rounded), findsNothing);
      },
    );
  });
}

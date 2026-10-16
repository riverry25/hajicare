import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_translations.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:hajicare/features/prayer/widgets/next_prayer_luxury_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestPrayerTimesController extends PrayerTimesController {
  @override
  Future<void> initialize() async {
    // Avoid background location/network initialization in isolated widget test
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({'prayer_sound_dzuhur': true});
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

  group('NextPrayerLuxuryHero Tests', () {
    testWidgets(
      'Renders prayer name, time, Arabic calligraphy and segmented countdown',
      (tester) async {
        final controller = Get.put<PrayerTimesController>(
          _TestPrayerTimesController(),
        );
        controller.nextPrayerName.value = 'Dzuhur';
        controller.nextPrayerArabic.value = 'الظُّهْر';
        controller.nextPrayerTime.value = '12:05 WIB';
        controller.countdownHours.value = 1;
        controller.countdownMinutes.value = 24;
        controller.countdownSeconds.value = 35;
        controller.prayerSoundEnabled['dzuhur'] = true;

        await tester.pumpWidget(
          buildTestApp(NextPrayerLuxuryHero(controller: controller)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'Dzuhur' || widget.data == 'Dhuhr'),
          ),
          findsOneWidget,
        );
        expect(find.text('الظُّهْر'), findsOneWidget);
        expect(find.text('12:05 WIB'), findsOneWidget);
        expect(find.text('01'), findsOneWidget);
        expect(find.text('24'), findsOneWidget);
        expect(find.text('35'), findsOneWidget);
        expect(find.text('JAM'), findsOneWidget);
        expect(find.text('MENIT'), findsOneWidget);
        expect(find.text('DETIK'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
      },
    );

    testWidgets('Tapping sound toggle button toggles sound state', (
      tester,
    ) async {
      final controller = Get.put<PrayerTimesController>(
        _TestPrayerTimesController(),
      );
      controller.nextPrayerName.value = 'Dzuhur';
      controller.prayerSoundEnabled['dzuhur'] = true;

      await tester.pumpWidget(
        buildTestApp(NextPrayerLuxuryHero(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_active_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.isPrayerSoundOn('dzuhur'), false);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    });

    testWidgets(
      'Adapts gracefully on compact screens (< 360px) without overflow',
      (tester) async {
        final controller = Get.put<PrayerTimesController>(
          _TestPrayerTimesController(),
        );
        controller.nextPrayerName.value = 'Maghrib';
        controller.nextPrayerArabic.value = 'المَغْرِب';
        controller.nextPrayerTime.value = '18:15 WIB';
        controller.countdownHours.value = 0;
        controller.countdownMinutes.value = 45;
        controller.countdownSeconds.value = 12;

        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              width: 310,
              child: NextPrayerLuxuryHero(controller: controller),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('Maghrib'), findsOneWidget);
        expect(find.text('18:15 WIB'), findsOneWidget);
      },
    );
  });
}

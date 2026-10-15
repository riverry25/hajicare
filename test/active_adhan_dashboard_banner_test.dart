import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_translations.dart';
import 'package:hajicare/core/services/adhan_audio_service.dart';
import 'package:hajicare/features/dashboard/widgets/active_adhan_dashboard_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp(Widget child) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('id'),
      fallbackLocale: const Locale('id'),
      home: Scaffold(body: child),
    );
  }

  group('ActiveAdhanDashboardBanner Tests', () {
    testWidgets('Renders SizedBox.shrink when adhan is not playing', (
      tester,
    ) async {
      final audioService = Get.put(AdhanAudioService());
      audioService.isPlaying.value = false;

      await tester.pumpWidget(buildTestApp(const ActiveAdhanDashboardBanner()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Matikan Adzan'), findsNothing);
      expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
    });

    testWidgets(
      'Renders banner with prayer name and "Matikan Adzan" button when adhan is playing',
      (tester) async {
        final audioService = Get.put(AdhanAudioService());
        audioService.currentPrayerName.value = 'Dzuhur';
        audioService.isPlaying.value = true;

        await tester.pumpWidget(
          buildTestApp(const ActiveAdhanDashboardBanner()),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('Berkumandang'), findsOneWidget);
        expect(find.text('Matikan Adzan'), findsOneWidget);
        expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
      },
    );

    testWidgets('Tapping "Matikan Adzan" stops playback and dismisses banner', (
      tester,
    ) async {
      final audioService = Get.put(AdhanAudioService());
      audioService.currentPrayerName.value = 'Ashar';
      audioService.isPlaying.value = true;

      await tester.pumpWidget(buildTestApp(const ActiveAdhanDashboardBanner()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Matikan Adzan'), findsOneWidget);

      await tester.tap(find.text('Matikan Adzan'));
      await tester.pump(const Duration(milliseconds: 100));

      // Audio is stopped and banner disappears
      expect(audioService.isPlaying.value, false);
      expect(find.text('Matikan Adzan'), findsNothing);
    });

    testWidgets('Adapts to compact screens (<360px) without overflow', (
      tester,
    ) async {
      final audioService = Get.put(AdhanAudioService());
      audioService.currentPrayerName.value = 'Subuh';
      audioService.isPlaying.value = true;

      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestApp(
          const SizedBox(width: 310, child: ActiveAdhanDashboardBanner()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Matikan Adzan'), findsOneWidget);
      expect(find.textContaining('Berkumandang'), findsOneWidget);
    });
  });
}

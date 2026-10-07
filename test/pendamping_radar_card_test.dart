import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/hajicare_state.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/dashboard/widgets/pendamping_radar_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  Widget buildTestRadarCard({
    required JamaahData jamaah,
    required double textScale,
    Locale locale = const Locale('en'),
  }) {
    final state = Get.put(HajiCareController(), permanent: true);
    state.setRole(UserRole.pendamping);
    state.activeRoomId.value = 'room-test-1';

    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: PendampingRadarCard(jamaah: jamaah, onTrackMap: () {}),
            ),
          ),
        ),
      ),
    );
  }

  group('PendampingRadarCard Dynamic Text Scale Tests', () {
    testWidgets(
      'Renders cleanly at normal text scale (1.0x) without overflow',
      (tester) async {
        final jamaah = JamaahData(
          id: 'j1',
          name: 'ferdiyusri9',
          shortLabel: 'ferdiyusri9',
          distance: 14053000, // 14,053 km
          isGpsActive: true,
          locationUpdatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          buildTestRadarCard(jamaah: jamaah, textScale: 1.0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('ferdiyusri9'), findsOneWidget);
        expect(find.text('RADAR ACTIVE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Does not overflow at large text scale (1.5x) with SEPARATED - DANGER label on narrow width',
      (tester) async {
        tester.view.physicalSize = const Size(720, 1600);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final jamaah = JamaahData(
          id: 'j1',
          name: 'ferdiyusri9',
          shortLabel: 'ferdiyusri9',
          distance: 14053000,
          isGpsActive: true,
          locationUpdatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          buildTestRadarCard(
            jamaah: jamaah,
            textScale: 1.5,
            locale: const Locale('en'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('ferdiyusri9'), findsOneWidget);
        expect(find.text('RADAR ACTIVE'), findsOneWidget);
        // Guarantee no RenderFlex overflow error was thrown!
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Does not overflow at extra large text scale (2.0x)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final jamaah = JamaahData(
        id: 'j1',
        name: 'ferdiyusri9',
        shortLabel: 'ferdiyusri9',
        distance: 14053000,
        isGpsActive: true,
        locationUpdatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestRadarCard(
          jamaah: jamaah,
          textScale: 2.0,
          locale: const Locale('en'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ferdiyusri9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

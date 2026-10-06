import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/dashboard/widgets/hajj_schedule_guide_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget({
    ThemeData? theme,
    double textScaleFactor = 1.0,
    Size size = const Size(390, 844),
  }) {
    return MaterialApp(
      locale: const Locale('id'),
      supportedLocales: AppTranslations.supportedLocales,
      theme: theme ?? AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
      ],
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScaleFactor),
          size: size,
        ),
        child: const Scaffold(body: HajjScheduleGuideSheet()),
      ),
    );
  }

  group('HajjScheduleGuideSheet Widget Tests', () {
    testWidgets(
      'Renders journey progress banner, horizontal day selector, and all stages',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Check header title & subtitle
        expect(find.text('Jadwal & Panduan Rukun Haji'), findsOneWidget);
        expect(
          find.text('Tahapan rangkaian ibadah haji dari hari ke hari'),
          findsOneWidget,
        );

        // Check gamified journey banner
        expect(find.text('Perjalanan Ibadah Haji'), findsOneWidget);
        expect(find.textContaining('Tahap Selesai'), findsOneWidget);

        // Check horizontal day selector items
        expect(find.text('8 Dzul'), findsOneWidget);
        expect(find.text('9 Dzul'), findsOneWidget);
        expect(find.text('Mlm 10'), findsOneWidget);
        expect(find.text('10 Dzul'), findsOneWidget);
        expect(find.text('11-13 Dzul'), findsOneWidget);
        expect(find.text('Wada\''), findsOneWidget);

        // Check stage titles in viewport
        expect(find.text('Hari Tarwiyah (Mina)'), findsOneWidget);

        // Scroll down to check further stages
        await tester.drag(find.byType(ListView), const Offset(0, -250));
        await tester.pumpAndSettle();
        expect(find.text('Wukuf di Padang Arafah'), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(find.text('Mabit di Muzdalifah'), findsOneWidget);
      },
    );

    testWidgets('Tapping horizontal day capsule highlights selection', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Tap on '9 Dzul' in the horizontal selector
      await tester.tap(find.text('9 Dzul'));
      await tester.pumpAndSettle();

      // Ensure 9 Dzul stage is rendered
      expect(find.text('Wukuf di Padang Arafah'), findsOneWidget);
    });

    testWidgets('Toggling stage completion updates progress counter', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Initially 1 stage completed (tarwiyah)
      expect(find.text('1 dari 6 Tahap Selesai'), findsOneWidget);

      // Scroll down so the second stage (arafah) is visible
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();

      // Find the second stage completion button (for arafah)
      final tandaiButtons = find.text('Tandai');
      expect(tandaiButtons, findsWidgets);

      // Tap to mark Arafah as completed
      await tester.tap(tandaiButtons.first);
      await tester.pumpAndSettle();

      // Progress counter updates to 2 dari 6 Tahap Selesai
      expect(find.text('2 dari 6 Tahap Selesai'), findsOneWidget);
    });

    testWidgets('Toggling tips accordion expands and collapses guidance', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Tarwiyah tips is expanded initially
      expect(
        find.textContaining('Kenakan pakaian ihram dari hotel/maktab'),
        findsOneWidget,
      );

      // Tap to collapse
      final tipsButton = find.text('Panduan & Catatan Penting').first;
      await tester.tap(tipsButton);
      await tester.pumpAndSettle();

      // Collapsed: Tarwiyah tips text is no longer shown
      expect(
        find.textContaining('Kenakan pakaian ihram dari hotel/maktab'),
        findsNothing,
      );
    });

    testWidgets(
      'Adapts gracefully to dynamic text scaling (1.4x) without any overflow',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(textScaleFactor: 1.4));
        await tester.pump();

        // Must render cleanly without throwing RenderFlex overflow errors
        expect(find.byType(HajjScheduleGuideSheet), findsOneWidget);
        expect(find.text('Jadwal & Panduan Rukun Haji'), findsOneWidget);
      },
    );

    testWidgets(
      'Scrolls through all stages at max text scaling (1.5x) on narrow screen without any overflow',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(textScaleFactor: 1.5, size: const Size(360, 780)),
        );
        await tester.pump();

        // Scroll until the last stage is visible without throwing any RenderFlex overflow
        await tester.scrollUntilVisible(
          find.text('Tawaf Wada’'),
          250,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        // Verify last stage is reached and rendered cleanly without overflow
        expect(find.text('Tawaf Wada’'), findsOneWidget);
      },
    );

    testWidgets('Renders properly in Dark Theme', (tester) async {
      await tester.pumpWidget(buildTestWidget(theme: AppTheme.darkTheme));
      await tester.pump();

      expect(find.byType(HajjScheduleGuideSheet), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/translator/widgets/translator_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('HajiCareTranslatorSheet Widget Tests', () {
    testWidgets(
      'Renders translator sheet with unified top language bar, cards, and quick phrases',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppTranslations.supportedLocales,
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              FallbackWidgetsLocalizationsDelegate(),
            ],
            home: const Scaffold(body: HajiCareTranslatorSheet()),
          ),
        );

        await tester.pump();

        // Check header
        expect(find.text('Penerjemah HajiCare'), findsOneWidget);

        // Check language bar items
        expect(find.text('Indonesia'), findsOneWidget);
        expect(find.text('العربية'), findsOneWidget);
        expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);

        // Check quick phrases
        expect(find.text('Frasa Penting Haji & Umrah'), findsOneWidget);
        expect(find.text('Tersesat'), findsOneWidget);
        expect(find.text('Pintu Keluar'), findsOneWidget);

        // Tap on a quick phrase
        await tester.tap(find.text('Tersesat'));
        await tester.pump();

        // Input should be filled with Indonesian text
        expect(
          find.text('Tolong, saya tersesat dan butuh bantuan'),
          findsOneWidget,
        );

        // Output should show translated Arabic text
        expect(
          find.text('من فضلك، لقد ضللت طريقي وأحتاج إلى مساعدة'),
          findsOneWidget,
        );

        // Copy and Voice buttons should be visible
        expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
        expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Renders center hero mic button and adapts smoothly to large text scaling (1.4x)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppTranslations.supportedLocales,
            theme: AppTheme.lightTheme,
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
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.4),
                size: Size(390, 844),
              ),
              child: const Scaffold(body: HajiCareTranslatorSheet()),
            ),
          ),
        );

        await tester.pump();

        // Check center mic icon is visible and tappable
        expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
        // Check elderly friendly instructions
        expect(find.text('Bicara Indonesia'), findsOneWidget);
        expect(
          find.text('Tekan tombol mikrofon lalu mulai berbicara'),
          findsOneWidget,
        );

        // Verify tapping microphone triggers without throwing
        await tester.tap(find.byIcon(Icons.mic_rounded));
        await tester.pump();
      },
    );

    testWidgets('Renders properly in Dark Theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: const Scaffold(body: HajiCareTranslatorSheet()),
        ),
      );

      await tester.pump();
      expect(find.byType(HajiCareTranslatorSheet), findsOneWidget);
    });

    testWidgets(
      'Renders dynamically in English locale with English phrases and titles',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppTranslations.supportedLocales,
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              FallbackWidgetsLocalizationsDelegate(),
            ],
            home: const Scaffold(body: HajiCareTranslatorSheet()),
          ),
        );

        await tester.pump();

        // Check English header
        expect(find.text('HajiCare Translator'), findsOneWidget);

        // Check language bar items
        expect(find.text('Indonesian'), findsOneWidget);
        expect(find.text('العربية'), findsOneWidget);

        // Check English instructions
        expect(find.text('Speak in Indonesian'), findsOneWidget);
        expect(
          find.text('Press microphone button then start speaking'),
          findsOneWidget,
        );

        // Check English quick phrases
        expect(find.text('Essential Hajj & Umrah Phrases'), findsOneWidget);
        expect(find.text('Lost'), findsOneWidget);
        expect(find.text('Exit Gate'), findsOneWidget);

        // Tap on Lost
        await tester.tap(find.text('Lost'));
        await tester.pump();

        // Output should show Arabic translation
        expect(
          find.text('من فضلك، لقد ضللت طريقي وأحتاج إلى مساعدة'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders without overflow under extreme 1.8x text scaling and small screen',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppTranslations.supportedLocales,
            theme: AppTheme.lightTheme,
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
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.8),
                size: Size(320, 568), // Small legacy screen (iPhone SE 1st gen)
              ),
              child: const Scaffold(body: HajiCareTranslatorSheet()),
            ),
          ),
        );

        await tester.pump();

        // Enter text into input to populate and show action buttons without requiring scroll
        await tester.enterText(find.byType(TextField), 'Halo');
        await tester.pump();

        // Should render without throw or overflow
        expect(find.byType(HajiCareTranslatorSheet), findsOneWidget);
        expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      },
    );
  });
}

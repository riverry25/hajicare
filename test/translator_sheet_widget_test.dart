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
  });
}

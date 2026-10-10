import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/communication/bindings/communication_binding.dart';
import 'package:hajicare/features/communication/widgets/communication_gesture_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    CommunicationBinding().dependencies();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          MethodCall methodCall,
        ) async {
          return 1;
        });
  });

  tearDown(() {
    Get.reset();
  });

  group('CommunicationGestureDialog Widget Tests', () {
    testWidgets(
      'Renders gesture dialog with header, tip, filter chips, and phrases in Indonesian',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              FallbackWidgetsLocalizationsDelegate(),
            ],
            home: const Scaffold(body: CommunicationGestureDialog()),
          ),
        );

        await tester.pumpAndSettle();

        // Check title and guidance
        expect(find.text('Komunikasi Cepat'), findsOneWidget);
        expect(find.text('Semua'), findsOneWidget);
        expect(find.text('Darurat & Kesehatan'), findsOneWidget);
        expect(find.text('Arah & Lokasi'), findsOneWidget);
        expect(find.text('Umum'), findsOneWidget);

        // Check phrase content
        expect(find.text('Tolong, saya butuh dokter'), findsOneWidget);
        expect(find.text('PENTING / DARURAT'), findsWidgets);

        // Tap on filter chip 'Umum'
        await tester.tap(find.text('Umum'));
        await tester.pumpAndSettle();

        // Urgent health phrase should be filtered out
        expect(find.text('Tolong, saya butuh dokter'), findsNothing);
        expect(find.text('Terima kasih'), findsOneWidget);
      },
    );

    testWidgets('Renders dynamically in English multi-language', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: const Scaffold(body: CommunicationGestureDialog()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Quick Communication'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Emergency & Health'), findsOneWidget);
      expect(find.text('Help, I need a doctor'), findsOneWidget);
    });

    testWidgets(
      'Renders without overflow under large accessibility text scale (1.8x)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.5;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
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
                size: Size(432, 960),
              ),
              child: const Scaffold(body: CommunicationGestureDialog()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Komunikasi Cepat'), findsOneWidget);
        expect(find.text('Tolong, saya butuh dokter'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Filters phrases dynamically via search bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: const Scaffold(body: CommunicationGestureDialog()),
        ),
      );

      await tester.pumpAndSettle();

      // Search for 'hotel'
      await tester.enterText(find.byType(TextField), 'hotel');
      await tester.pumpAndSettle();

      expect(find.text('Dimana hotel saya?'), findsOneWidget);
      expect(find.text('Tolong, saya butuh dokter'), findsNothing);
    });
  });
}

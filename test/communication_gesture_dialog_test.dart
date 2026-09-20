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
      'Renders gesture dialog with header, tip, filter chips, and phrases',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
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
  });
}

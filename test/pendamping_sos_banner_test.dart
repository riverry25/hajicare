import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/dashboard/widgets/pendamping_sos_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'PendampingSosBanner renders Uji Sinyal Alarm & Pusat Tanggap in Row and opens dynamic dialogs',
    (tester) async {
      final controller = Get.put(HajiCareController(), permanent: true);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id', 'ID'),
          supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: Scaffold(
            body: SingleChildScrollView(
              child: PendampingSosBanner(state: controller),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify both buttons exist in the standby card
      final alarmBtnFinder = find.text('Uji Sinyal Alarm');
      final responseCenterBtnFinder = find.text('Pusat Tanggap');

      expect(alarmBtnFinder, findsOneWidget);
      expect(responseCenterBtnFinder, findsOneWidget);

      // Verify they are within a Row
      final rowAncestor = find.ancestor(
        of: alarmBtnFinder,
        matching: find.byType(Row),
      );
      expect(rowAncestor, findsWidgets);

      // Tap Uji Sinyal Alarm to open dynamic alarm test dialog
      await tester.tap(alarmBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Uji Sinyal Alarm Berjalan'), findsOneWidget);
      expect(find.text('Selesai Uji Coba'), findsOneWidget);

      // Finish test
      await tester.tap(find.text('Selesai Uji Coba'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Uji Sinyal Alarm Berjalan'), findsNothing);

      // Tap Pusat Tanggap to open bottom sheet with hotlines
      await tester.tap(responseCenterBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pusat Tanggap Darurat'), findsOneWidget);
      expect(find.text('800-119-999'), findsOneWidget);
      expect(find.text('997'), findsOneWidget);
      expect(find.text('911'), findsOneWidget);
    },
  );
}

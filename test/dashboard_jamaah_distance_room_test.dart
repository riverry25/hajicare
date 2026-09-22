import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/dashboard/bindings/dashboard_binding.dart';
import 'package:hajicare/features/dashboard/screens/dashboard_jamaah_screen.dart';
import 'package:hajicare/features/dashboard/widgets/distance_sparkline_widget.dart';
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

  Widget buildTestWidget() {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('id', 'ID'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
      ],
      home: const DashboardJamaahScreen(),
    );
  }

  testWidgets(
    'Dashboard Jamaah shows "—" and "Belum Terhubung ke Room" when outside room',
    (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      final hajiCtrl = Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      // Outside room setup: activeRoomId is null, jamaah distance defaults to 0.0
      hajiCtrl.activeRoomId.value = null;
      hajiCtrl.calculatedDistance.value = null;
      hajiCtrl.jamaahList.value = [
        JamaahData(
          id: 'test_user_1',
          name: 'Ahmad Jamaah',
          shortLabel: 'Ahmad',
          distance: 0.0,
          activeRoomId: null,
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Should display "—" instead of hardcoded "20 m"
      expect(find.text('—'), findsWidgets);
      expect(find.text('20 m'), findsNothing);

      // Badge should show "Belum Terhubung ke Room"
      expect(find.text('Belum Terhubung ke Room'), findsWidgets);

      // Sparkline should receive distance 0.0
      final sparklineFinder = find.byType(DistanceSparklineWidget);
      expect(sparklineFinder, findsOneWidget);
      final sparklineWidget = tester.widget<DistanceSparklineWidget>(
        sparklineFinder,
      );
      expect(sparklineWidget.distance, 0.0);
    },
  );

  testWidgets(
    'Dashboard Jamaah shows real distance and "Jarak ke Petugas" when connected to room',
    (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      final hajiCtrl = Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      // Inside room setup: active room set and real distance calculated
      hajiCtrl.activeRoomId.value = 'room_vip_01';
      hajiCtrl.calculatedDistance.value = 45.0;
      hajiCtrl.jamaahList.value = [
        JamaahData(
          id: 'test_user_1',
          name: 'Ahmad Jamaah',
          shortLabel: 'Ahmad',
          distance: 45.0,
          activeRoomId: 'room_vip_01',
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Should display real distance "45 m"
      expect(find.text('45 m'), findsOneWidget);

      // Badge should show "Jarak ke Petugas"
      expect(find.text('Jarak ke Petugas'), findsOneWidget);

      // Sparkline should receive distance 45.0
      final sparklineFinder = find.byType(DistanceSparklineWidget);
      expect(sparklineFinder, findsOneWidget);
      final sparklineWidget = tester.widget<DistanceSparklineWidget>(
        sparklineFinder,
      );
      expect(sparklineWidget.distance, 45.0);
    },
  );
}

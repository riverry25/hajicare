import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/dashboard/controllers/dashboard_controller.dart';
import 'package:hajicare/features/dashboard/screens/dashboard_jamaah_screen.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:hajicare/features/room/services/room_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRoomService extends RoomService {
  final StreamController<List<Map<String, dynamic>>> sosController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  Stream<List<Map<String, dynamic>>> getActiveSosEventsStream({
    String? roomId,
  }) {
    return sosController.stream;
  }
}

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
    'Dashboard Jamaah SOS button reactively transitions from SOS (3) to Bantuan Darurat when events stream becomes empty',
    (tester) async {
      final mockRoomService = MockRoomService();
      final hajiController = Get.put(
        HajiCareController(roomService: mockRoomService),
        permanent: true,
      );
      hajiController.setTestUid('test_jamaah_1');
      Get.put(AppSettingsController(), permanent: true);
      Get.put(DashboardController(), permanent: true);
      Get.put(PrayerTimesController(), permanent: true);

      // Simulate active room
      hajiController.activeRoomId.value = 'room_123';

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id', 'ID'),
          supportedLocales: AppTranslations.supportedLocales,
          translations: AppTranslations(),
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
        ),
      );
      await tester.pump();

      // Initially with room and no SOS: shows "Bantuan Darurat"
      expect(find.text('Bantuan Darurat'), findsOneWidget);

      // Simulate 3 SOS events arriving from Firestore
      mockRoomService.sosController.add([
        {
          'id': 'evt_1',
          'userId': 'user_1',
          'userName': 'Jamaah 1',
          'roomId': 'room_123',
          'status': 'active',
        },
        {
          'id': 'evt_2',
          'userId': 'user_2',
          'userName': 'Jamaah 2',
          'roomId': 'room_123',
          'status': 'active',
        },
        {
          'id': 'evt_3',
          'userId': 'user_3',
          'userName': 'Jamaah 3',
          'roomId': 'room_123',
          'status': 'active',
        },
      ]);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Must display SOS (3)
      expect(hajiController.activeSosCount.value, equals(3));
      expect(hajiController.anySosActive, isTrue);
      expect(find.text('SOS (3)'), findsOneWidget);

      // Now simulate Firestore collection being emptied (0 events)
      mockRoomService.sosController.add([]);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Must reactively sync back to 0 and show Bantuan Darurat
      expect(hajiController.activeSosCount.value, equals(0));
      expect(hajiController.anySosActive, isFalse);
      expect(find.text('SOS (3)'), findsNothing);
      expect(find.text('Bantuan Darurat'), findsOneWidget);

      await mockRoomService.sosController.close();
    },
  );
}

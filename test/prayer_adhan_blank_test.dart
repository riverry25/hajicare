import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/services/adhan_audio_service.dart';
import 'package:hajicare/core/services/adhan_notification_service.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/core/widgets/bottom_nav_bar.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:hajicare/features/prayer/models/prayer_schedule_item.dart';
import 'package:hajicare/features/prayer/screens/prayer_times_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestFakeAdhanAudioService extends AdhanAudioService {
  @override
  void initPlayer() {}

  @override
  Future<void> playAdhan({required String prayerName}) async {
    isPlaying.value = true;
    currentPrayerName.value = prayerName;
  }

  @override
  Future<void> stopAdhan() async {
    isPlaying.value = false;
    currentPrayerName.value = '';
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
    'PrayerTimesScreen keeps all elements visible and functional during adhan playback',
    (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      Get.put(HajiCareController(), permanent: true);

      final fakeAudioService = TestFakeAdhanAudioService();
      Get.put<AdhanAudioService>(fakeAudioService);
      Get.put<AdhanNotificationService>(AdhanNotificationService());

      final controller = PrayerTimesController(
        adhanAudioService: fakeAudioService,
      );
      Get.put<PrayerTimesController>(controller);

      // Populate dummy schedule items so schedule list renders
      controller.prayers.assignAll([
        PrayerScheduleItem(
          name: 'Subuh',
          arabicName: 'الفجر',
          time: DateTime.now(),
          formattedTime: '04:30 WIB',
          isNext: false,
        ),
        PrayerScheduleItem(
          name: 'Terbit',
          arabicName: 'الشروق',
          time: DateTime.now(),
          formattedTime: '05:45 WIB',
          isNext: false,
        ),
        PrayerScheduleItem(
          name: 'Dzuhur',
          arabicName: 'الظهر',
          time: DateTime.now(),
          formattedTime: '12:05 WIB',
          isNext: false,
        ),
        PrayerScheduleItem(
          name: 'Ashar',
          arabicName: 'العصر',
          time: DateTime.now(),
          formattedTime: '15:20 WIB',
          isNext: true,
        ),
        PrayerScheduleItem(
          name: 'Maghrib',
          arabicName: 'المغرب',
          time: DateTime.now(),
          formattedTime: '18:10 WIB',
          isNext: false,
        ),
        PrayerScheduleItem(
          name: 'Isya',
          arabicName: 'العشاء',
          time: DateTime.now(),
          formattedTime: '19:20 WIB',
          isNext: false,
        ),
      ]);
      controller.nextPrayerName.value = 'Ashar';
      controller.nextPrayerArabic.value = 'العصر';
      controller.nextPrayerTime.value = '15:20 WIB';

      await tester.pumpWidget(
        GetMaterialApp(
          locale: const Locale('id'),
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          supportedLocales: AppTranslations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
            FallbackWidgetsLocalizationsDelegate(),
          ],
          home: const PrayerTimesScreen(showBottomNav: true),
        ),
      );

      await tester.pump();

      // Verify initial state (adhan not playing)
      expect(find.byType(HajiCareBottomNavBar), findsOneWidget);
      expect(find.text('Matikan'), findsNothing);

      // Now trigger adhan playback
      controller.isAdhanPlaying.value = true;
      controller.playingPrayerName.value = 'Ashar';

      await tester.pump();

      // 1. Verify Active Adhan banner is rendered
      expect(find.text('Adzan Ashar Berkumandang'), findsOneWidget);
      expect(find.text('Matikan'), findsOneWidget);

      // 2. Verify all other sections remain completely intact (NOTHING disappears)
      expect(
        find.text('Ashar'),
        findsWidgets,
      ); // In banner & hero card & schedule
      expect(find.text('Arah Kiblat'), findsOneWidget);
      expect(find.text('Jadwal Sholat'), findsOneWidget);
      expect(find.text('Subuh'), findsWidgets);
      expect(find.text('Dzuhur'), findsWidgets);
      expect(find.text('Maghrib'), findsWidgets);
      expect(find.text('Isya'), findsWidgets);

      // 3. Test tapping "Matikan" button in the adhan banner
      await tester.tap(find.text('Matikan'));
      await tester.pump();

      expect(controller.isAdhanPlaying.value, false);
      expect(find.text('Matikan'), findsNothing);
      expect(find.text('Jadwal Sholat'), findsOneWidget);
    },
  );
}

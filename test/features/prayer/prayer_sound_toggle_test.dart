import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Prayer Sound & Adzan Hening Toggle Tests', () {
    test('setAllPrayerSounds(false) disables all canonical prayer sounds and sets isAnySoundOn to false', () async {
      final controller = PrayerTimesController();

      // Initially enabled
      expect(controller.isAnySoundOn, isTrue);

      // Turn on Adzan Hening (mute all)
      await controller.setAllPrayerSounds(false);

      expect(controller.isAnySoundOn, isFalse);
      expect(controller.isPrayerSoundOn('subuh'), isFalse);
      expect(controller.isPrayerSoundOn('dzuhur'), isFalse);
      expect(controller.isPrayerSoundOn('ashar'), isFalse);
      expect(controller.isPrayerSoundOn('maghrib'), isFalse);
      expect(controller.isPrayerSoundOn('isya'), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('prayer_sound_master_enabled'), isFalse);
      expect(prefs.getBool('prayer_sound_subuh'), isFalse);
    });

    test('togglePrayerSound updates individual sound and master enabled state', () async {
      final controller = PrayerTimesController();

      // Mute all first
      await controller.setAllPrayerSounds(false);
      expect(controller.isAnySoundOn, isFalse);

      // Toggle Subuh on
      await controller.togglePrayerSound('subuh');
      expect(controller.isPrayerSoundOn('subuh'), isTrue);
      expect(controller.isAnySoundOn, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('prayer_sound_subuh'), isTrue);
      expect(prefs.getBool('prayer_sound_master_enabled'), isTrue);

      // Toggle Subuh back off
      await controller.togglePrayerSound('subuh');
      expect(controller.isPrayerSoundOn('subuh'), isFalse);
      expect(controller.isAnySoundOn, isFalse);
      expect(prefs.getBool('prayer_sound_master_enabled'), isFalse);
    });
  });
}

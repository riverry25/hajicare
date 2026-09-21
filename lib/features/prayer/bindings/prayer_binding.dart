import 'package:get/get.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/timezone_service.dart';
import '../../../core/services/adhan_audio_service.dart';
import '../../../core/services/prayer_calculation_service.dart';
import '../controllers/prayer_times_controller.dart';

class PrayerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AdhanAudioService>()) {
      Get.lazyPut<AdhanAudioService>(() => AdhanAudioService());
    }
    if (!Get.isRegistered<LocationService>()) {
      Get.lazyPut<LocationService>(() => LocationService());
    }
    if (!Get.isRegistered<GeocodingService>()) {
      Get.lazyPut<GeocodingService>(() => GeocodingService());
    }
    if (!Get.isRegistered<TimezoneService>()) {
      Get.lazyPut<TimezoneService>(() => TimezoneService());
    }
    if (!Get.isRegistered<PrayerCalculationService>()) {
      Get.lazyPut<PrayerCalculationService>(
        () => PrayerCalculationService(
          timezoneService: Get.find<TimezoneService>(),
        ),
      );
    }
    if (!Get.isRegistered<PrayerTimesController>()) {
      Get.lazyPut<PrayerTimesController>(() => PrayerTimesController());
    }
  }
}

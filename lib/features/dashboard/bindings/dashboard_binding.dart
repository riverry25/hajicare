import 'package:get/get.dart';

import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_calculation_service.dart';
import '../../../core/services/timezone_service.dart';
import '../../prayer/controllers/prayer_times_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(),
      fenix: true,
    );

    // Provide prayer dependencies so embedded PrayerTimesScreen resolves seamlessly
    if (!Get.isRegistered<LocationService>()) {
      Get.lazyPut<LocationService>(() => LocationService(), fenix: true);
    }
    if (!Get.isRegistered<GeocodingService>()) {
      Get.lazyPut<GeocodingService>(() => GeocodingService(), fenix: true);
    }
    if (!Get.isRegistered<TimezoneService>()) {
      Get.lazyPut<TimezoneService>(() => TimezoneService(), fenix: true);
    }
    if (!Get.isRegistered<PrayerCalculationService>()) {
      Get.lazyPut<PrayerCalculationService>(
        () => PrayerCalculationService(
          timezoneService: Get.find<TimezoneService>(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<PrayerTimesController>()) {
      Get.lazyPut<PrayerTimesController>(
        () => PrayerTimesController(),
        fenix: true,
      );
    }
  }
}

/// Type alias for compatibility with HomeBinding
typedef HomeBinding = DashboardBinding;

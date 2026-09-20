import 'package:get/get.dart';

import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_calculation_service.dart';
import '../../../core/services/timezone_service.dart';
import '../../communication/controllers/communication_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../prayer/controllers/prayer_times_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../smartband/controllers/smartband_ldr_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());

    // Provide prayer dependencies so embedded PrayerTimesScreen resolves seamlessly
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
    Get.lazyPut<MapController>(() => MapController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<SmartbandLdrController>(() => SmartbandLdrController());
    Get.lazyPut<CommunicationController>(() => CommunicationController());
  }
}

/// Type alias for compatibility with HomeBinding
typedef HomeBinding = DashboardBinding;

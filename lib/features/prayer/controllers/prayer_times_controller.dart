import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../../../core/services/geocoding_service.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_calculation_service.dart';
import '../../../core/services/timezone_service.dart';
import '../models/prayer_location_data.dart';
import '../models/prayer_schedule_item.dart';

class PrayerTimesController extends GetxController {
  // Services
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  final TimezoneService _timezoneService;
  final PrayerCalculationService _prayerCalculationService;

  PrayerTimesController({
    LocationService? locationService,
    GeocodingService? geocodingService,
    TimezoneService? timezoneService,
    PrayerCalculationService? prayerCalculationService,
  }) : _locationService =
           locationService ??
           (Get.isRegistered<LocationService>()
               ? Get.find<LocationService>()
               : LocationService()),
       _geocodingService =
           geocodingService ??
           (Get.isRegistered<GeocodingService>()
               ? Get.find<GeocodingService>()
               : GeocodingService()),
       _timezoneService =
           timezoneService ??
           (Get.isRegistered<TimezoneService>()
               ? Get.find<TimezoneService>()
               : TimezoneService()),
       _prayerCalculationService =
           prayerCalculationService ??
           (Get.isRegistered<PrayerCalculationService>()
               ? Get.find<PrayerCalculationService>()
               : PrayerCalculationService());

  // SharedPreferences Keys
  static const String _prefLatKey = 'prayer_cache_lat';
  static const String _prefLngKey = 'prayer_cache_lng';
  static const String _prefCityKey = 'prayer_cache_city';
  static const String _prefCountryKey = 'prayer_cache_country';
  static const String _prefCountryCodeKey = 'prayer_cache_country_code';
  static const String _prefTimezoneKey = 'prayer_cache_timezone';
  static const String _prefTimeKey = 'prayer_cache_timestamp';

  // Internal emergency calculation coordinates only (NEVER exposed to user as a location name)
  static const double emergencyCalcLat = -6.2088;
  static const double emergencyCalcLng = 106.8456;

  // Public aliases used in tests and diagnostics
  static const double fallbackLatitude = emergencyCalcLat;
  static const double fallbackLongitude = emergencyCalcLng;
  static const String fallbackCityName = 'Jakarta';
  static const String fallbackCountryCode = 'ID';

  // Minimum distance moved before triggering a new reverse-geocoding (meters)
  static const double distanceThresholdMeters = 500.0;

  /// True when GPS/LastKnown location is unavailable and we fell back to
  /// emergency internal coordinates. Used by UI to show/hide the Fallback badge.
  bool get isUsingFallbackLocation =>
      locationSource.value == LocationSource.unavailable;

  // ── Reactive State ──────────────────────────────────────────────────────────
  final locationSource = LocationSource.unavailable.obs;

  final currentLat = 0.0.obs;
  final currentLng = 0.0.obs;

  final locationName = 'Mencari lokasi...'.obs;
  final countryCode = ''.obs;
  final timezoneName = ''.obs;
  final timezoneAbbr = ''.obs;

  final calculationMethodName = ''.obs;
  final hijriDateText = ''.obs;

  // Prayers
  final prayers = <PrayerScheduleItem>[].obs;
  final nextPrayerName = ''.obs;
  final nextPrayerArabic = ''.obs;
  final nextPrayerTime = '--:--'.obs;
  final countdownText = '-- Menit -- Detik'.obs;

  // Compass & Qibla
  final qiblaBearing = 0.0.obs;
  final deviceHeading = 0.0.obs;
  final qiblaOffset = 0.0.obs;
  final isQiblaAligned = false.obs;
  final hasCompassSensor = true.obs;

  // Status flags
  final isLoadingLocation = false.obs;
  final locationErrorMessage = ''.obs;

  // Internal state
  DateTime? _targetNextPrayerTime;
  DateTime? _lastScheduleCalculationDate;
  double? _lastGeocodedLat;
  double? _lastGeocodedLng;

  Timer? _countdownTimer;
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _positionSubscription;
  bool _hasVibrated = false;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    _initHijriDate();
    _initCompass();

    // Priority order:
    // 1. Fresh GPS
    // 2. Last known device position
    // 3. Persistent cache (< 7 days)
    // 4. Unavailable ("Lokasi tidak tersedia")
    await loadInitialLocationAndSchedule();

    _startCountdownTimer();
    _listenToLocationUpdates();
  }

  void _initHijriDate() {
    try {
      final hijri = HijriCalendar.now();
      hijriDateText.value =
          '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} H';
    } catch (e) {
      debugPrint('[PrayerTimesController] Hijri date error: $e');
      hijriDateText.value = '14 Dzulhijjah 1445 H';
    }
  }

  /// Load location following strict priority:
  /// 1. Fresh GPS
  /// 2. Last known OS position
  /// 3. Valid persistent application cache (< 7 days)
  /// 4. Unavailable ("Lokasi tidak tersedia")
  Future<void> loadInitialLocationAndSchedule() async {
    isLoadingLocation.value = true;
    locationErrorMessage.value = '';

    final locationResult = await _locationService.getCurrentPosition();

    // Priority 1 & 2: GPS or LastKnown position from device
    if (locationResult.isSuccess && locationResult.position != null) {
      final pos = locationResult.position!;
      await _applyLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        source: locationResult.source,
      );
      isLoadingLocation.value = false;
      return;
    }

    // Priority 3: Persistent application cache
    final cached = await _loadCachedLocation();
    if (cached != null && cached.isValid) {
      locationSource.value = LocationSource.cache;
      currentLat.value = cached.latitude;
      currentLng.value = cached.longitude;
      locationName.value = cached.displayName;
      countryCode.value = cached.countryCode;
      timezoneName.value = cached.timezoneName;
      timezoneAbbr.value = cached.timezoneAbbr;

      _calculateScheduleAndQibla();
      isLoadingLocation.value = false;
      return;
    }

    // Priority 4: Completely Unavailable
    _applyUnavailableLocation(locationResult.errorMessage);
    isLoadingLocation.value = false;
  }

  /// Manual refresh triggered by user action
  Future<void> refreshLocation() async {
    isLoadingLocation.value = true;
    locationErrorMessage.value = '';

    final result = await _locationService.getCurrentPosition(
      timeout: const Duration(seconds: 12),
    );

    if (result.isSuccess && result.position != null) {
      await _applyLocation(
        lat: result.position!.latitude,
        lng: result.position!.longitude,
        source: result.source,
      );
    } else {
      if (result.state == LocationPermissionState.serviceDisabled) {
        AppAlert.warning(
          Get.context,
          title: 'Lokasi Ponsel Belum Aktif',
          message:
              'Aktifkan lokasi ponsel agar jadwal salat sesuai tempat Anda berada.',
          okText: 'Buka Pengaturan',
          onOk: () => _locationService.openLocationSettings(),
        );
      } else if (result.state == LocationPermissionState.deniedForever) {
        AppAlert.warning(
          Get.context,
          title: 'Izin Lokasi Diperlukan',
          message:
              'Buka pengaturan, lalu izinkan HajiCare memakai lokasi ponsel.',
          okText: 'Buka Pengaturan',
          onOk: () => _locationService.openAppSettings(),
        );
      } else if (result.errorMessage != null &&
          result.errorMessage!.isNotEmpty) {
        AppAlert.error(
          Get.context,
          title: 'Lokasi Belum Ditemukan',
          message: result.errorMessage!,
          okText: 'Coba Lagi',
        );
      }
    }
    isLoadingLocation.value = false;
  }

  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Applies a resolved latitude and longitude, with distance threshold guarding
  Future<void> _applyLocation({
    required double lat,
    required double lng,
    required LocationSource source,
  }) async {
    currentLat.value = lat;
    currentLng.value = lng;
    locationSource.value = source;

    // Check if we already geocoded nearby
    final shouldReverseGeocode =
        _lastGeocodedLat == null ||
        _lastGeocodedLng == null ||
        _locationService.calculateDistanceMeters(
              _lastGeocodedLat!,
              _lastGeocodedLng!,
              lat,
              lng,
            ) >=
            distanceThresholdMeters;

    if (shouldReverseGeocode) {
      final geoResult = await _geocodingService.reverseGeocode(lat, lng);
      locationName.value = geoResult.displayName;
      countryCode.value = geoResult.countryCode;

      final tzInfo = _timezoneService.getTimezoneInfo(lat, lng);
      timezoneName.value = tzInfo.timezoneId;
      timezoneAbbr.value = tzInfo.abbreviation;

      _lastGeocodedLat = lat;
      _lastGeocodedLng = lng;

      // Cache valid location to persistent storage
      await _saveCachedLocation(
        PrayerLocationData(
          latitude: lat,
          longitude: lng,
          cityName: geoResult.cityName,
          countryName: geoResult.countryName,
          countryCode: geoResult.countryCode,
          timezoneName: tzInfo.timezoneId,
          timezoneAbbr: tzInfo.abbreviation,
          timestamp: DateTime.now(),
          source: source,
        ),
      );
    }

    _calculateScheduleAndQibla();
  }

  /// Sets state when location is completely unavailable.
  /// NEVER displays "Jakarta, Indonesia".
  void _applyUnavailableLocation(String? errorMessage) {
    locationSource.value = LocationSource.unavailable;
    locationName.value = 'Lokasi tidak tersedia';
    if (errorMessage != null && errorMessage.isNotEmpty) {
      locationErrorMessage.value = errorMessage;
    }

    // Calculate emergency schedule using emergency coordinates internally only
    currentLat.value = emergencyCalcLat;
    currentLng.value = emergencyCalcLng;
    countryCode.value = 'ID';
    timezoneName.value = 'Asia/Jakarta';
    timezoneAbbr.value = 'WIB';

    _calculateScheduleAndQibla();
  }

  /// Saves valid location to SharedPreferences
  Future<void> _saveCachedLocation(PrayerLocationData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefLatKey, data.latitude);
      await prefs.setDouble(_prefLngKey, data.longitude);
      await prefs.setString(_prefCityKey, data.cityName);
      await prefs.setString(_prefCountryKey, data.countryName);
      await prefs.setString(_prefCountryCodeKey, data.countryCode);
      await prefs.setString(_prefTimezoneKey, data.timezoneName);
      await prefs.setString(_prefTimeKey, data.timestamp.toIso8601String());
    } catch (e) {
      debugPrint('[PrayerTimesController] Cache save error: $e');
    }
  }

  /// Loads cached location from SharedPreferences and checks validity (< 7 days)
  Future<PrayerLocationData?> _loadCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_prefLatKey) || !prefs.containsKey(_prefLngKey)) {
        return null;
      }

      final lat = prefs.getDouble(_prefLatKey)!;
      final lng = prefs.getDouble(_prefLngKey)!;
      final city = prefs.getString(_prefCityKey) ?? '';
      final country = prefs.getString(_prefCountryKey) ?? '';
      final cCode = prefs.getString(_prefCountryCodeKey) ?? '';
      final tz = prefs.getString(_prefTimezoneKey) ?? '';
      final timeStr = prefs.getString(_prefTimeKey) ?? '';

      final timestamp =
          DateTime.tryParse(timeStr) ?? DateTime.fromMillisecondsSinceEpoch(0);

      final tzInfo = _timezoneService.getTimezoneInfo(lat, lng);

      final data = PrayerLocationData(
        latitude: lat,
        longitude: lng,
        cityName: city,
        countryName: country,
        countryCode: cCode,
        timezoneName: tz.isNotEmpty ? tz : tzInfo.timezoneId,
        timezoneAbbr: tzInfo.abbreviation,
        timestamp: timestamp,
        source: LocationSource.cache,
      );

      // Validate cache age (must be < 7 days and coords != 0)
      if (data.isValid) {
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('[PrayerTimesController] Cache load error: $e');
      return null;
    }
  }

  /// Recalculates prayer schedule and Qibla angle from current coordinates
  void _calculateScheduleAndQibla() {
    if (currentLat.value == 0.0 && currentLng.value == 0.0) return;

    final now = DateTime.now();
    _lastScheduleCalculationDate = now;

    final result = _prayerCalculationService.calculatePrayerSchedule(
      latitude: currentLat.value,
      longitude: currentLng.value,
      countryCode: countryCode.value,
      timezoneId: timezoneName.value,
      date: now,
    );

    prayers.assignAll(result.prayers);
    nextPrayerName.value = result.nextPrayerName;
    nextPrayerArabic.value = result.nextPrayerArabic;
    _targetNextPrayerTime = result.nextPrayerTime;
    calculationMethodName.value = result.calculationMethodName;
    qiblaBearing.value = result.qiblaBearing;

    nextPrayerTime.value = _timezoneService.formatTime(
      result.nextPrayerTime,
      timezoneId: timezoneName.value,
      includeTimeZone: true,
    );

    _updateCountdownDifference();
    _updateQiblaOffset(deviceHeading.value);
  }

  /// Starts the 1-second periodic countdown timer.
  /// IMPORTANT: This does NOT recalculate PrayerTimes every second.
  /// It only computes DateTime difference to `_targetNextPrayerTime`.
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _updateCountdownDifference();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdownDifference();
    });
  }

  void _updateCountdownDifference() {
    if (_targetNextPrayerTime == null) {
      countdownText.value = '--:--:--';
      return;
    }

    final now = DateTime.now();

    // Check for day rollover
    if (_lastScheduleCalculationDate != null &&
        (_lastScheduleCalculationDate!.day != now.day ||
            _lastScheduleCalculationDate!.month != now.month ||
            _lastScheduleCalculationDate!.year != now.year)) {
      _initHijriDate();
      _calculateScheduleAndQibla();
      return;
    }

    final diff = _targetNextPrayerTime!.difference(now);

    // If next prayer time has arrived or passed, recalculate full schedule
    if (diff.isNegative || diff.inSeconds <= 0) {
      _calculateScheduleAndQibla();
      return;
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (hours > 0) {
      countdownText.value = '$hours Jam $minutes Menit $seconds Detik';
    } else {
      countdownText.value = '$minutes Menit $seconds Detik';
    }
  }

  /// Listens to position updates stream with distance filter (e.g. 500 meters)
  void _listenToLocationUpdates() {
    if (kIsWeb) return;

    try {
      _positionSubscription = _locationService
          .getPositionStream(distanceFilter: distanceThresholdMeters.toInt())
          .listen(
            (pos) {
              _applyLocation(
                lat: pos.latitude,
                lng: pos.longitude,
                source: LocationSource.gps,
              );
            },
            onError: (e) {
              debugPrint('[PrayerTimesController] Position stream error: $e');
            },
          );
    } catch (e) {
      debugPrint(
        '[PrayerTimesController] Failed to listen to position stream: $e',
      );
    }
  }

  /// Initializes device compass stream
  void _initCompass() {
    if (kIsWeb) {
      hasCompassSensor.value = false;
      return;
    }

    try {
      _compassSubscription = FlutterCompass.events?.listen(
        (event) {
          if (event.heading == null) return;

          final heading = event.heading!;
          deviceHeading.value = heading;
          _updateQiblaOffset(heading);
        },
        onError: (e) {
          debugPrint('[PrayerTimesController] Compass stream error: $e');
          hasCompassSensor.value = false;
        },
      );
    } catch (e) {
      debugPrint('[PrayerTimesController] Failed to listen to compass: $e');
      hasCompassSensor.value = false;
    }
  }

  void _updateQiblaOffset(double heading) {
    double diff = (qiblaBearing.value - heading) % 360;
    if (diff < 0) diff += 360;
    qiblaOffset.value = diff;

    // Check alignment within ±5 degrees (355° - 360° or 0° - 5°)
    final isAligned = diff <= 5.0 || diff >= 355.0;

    if (isAligned && !isQiblaAligned.value && !_hasVibrated) {
      _hasVibrated = true;
      try {
        Vibration.vibrate(duration: 40);
      } catch (e) {
        debugPrint('[PrayerTimesController] Vibration error: $e');
      }
    } else if (!isAligned) {
      _hasVibrated = false;
    }

    isQiblaAligned.value = isAligned;
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    super.onClose();
  }
}

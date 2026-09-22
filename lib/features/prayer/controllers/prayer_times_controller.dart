import '../../../core/locales/app_translations.dart';
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
import '../../../core/services/adhan_audio_service.dart';
import '../models/prayer_location_data.dart';
import '../models/prayer_schedule_item.dart';

class PrayerTimesController extends GetxController {
  // Services
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  final TimezoneService _timezoneService;
  final PrayerCalculationService _prayerCalculationService;
  final AdhanAudioService _adhanAudioService;

  PrayerTimesController({
    LocationService? locationService,
    GeocodingService? geocodingService,
    TimezoneService? timezoneService,
    PrayerCalculationService? prayerCalculationService,
    AdhanAudioService? adhanAudioService,
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
               : PrayerCalculationService()),
       _adhanAudioService =
           adhanAudioService ??
           (Get.isRegistered<AdhanAudioService>()
               ? Get.find<AdhanAudioService>()
               : Get.put(AdhanAudioService()));

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

  // Adhan Sound Preferences (prayer key -> bool)
  final prayerSoundEnabled = <String, bool>{}.obs;

  RxBool get isAdhanPlaying => _adhanAudioService.isPlaying;
  RxString get playingPrayerName => _adhanAudioService.currentPrayerName;

  String _lastPlayedAdhanKey = '';

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
  int _lifecycleGeneration = 0;

  bool _isCurrent(int generation) => generation == _lifecycleGeneration;

  @override
  void onInit() {
    super.onInit();
    unawaited(initialize());
  }

  Future<void> initialize() async {
    final generation = _lifecycleGeneration;
    _initHijriDate();
    _initCompass();
    await _loadPrayerSoundPreferences();

    // Priority order:
    // 1. Fresh GPS
    // 2. Last known device position
    // 3. Persistent cache (< 7 days)
    // 4. Unavailable ("Lokasi tidak tersedia")
    await loadInitialLocationAndSchedule();
    if (!_isCurrent(generation)) return;

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
    final generation = _lifecycleGeneration;
    isLoadingLocation.value = true;
    locationErrorMessage.value = '';

    final locationResult = await _locationService.getCurrentPosition();
    if (!_isCurrent(generation)) return;

    // Priority 1 & 2: GPS or LastKnown position from device
    if (locationResult.isSuccess && locationResult.position != null) {
      final pos = locationResult.position!;
      await _applyLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        source: locationResult.source,
      );
      if (!_isCurrent(generation)) return;
      isLoadingLocation.value = false;
      return;
    }

    // Priority 3: Persistent application cache
    final cached = await _loadCachedLocation();
    if (!_isCurrent(generation)) return;
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
    final generation = _lifecycleGeneration;
    isLoadingLocation.value = true;
    locationErrorMessage.value = '';

    final result = await _locationService.getCurrentPosition(
      timeout: const Duration(seconds: 12),
    );
    if (!_isCurrent(generation)) return;

    if (result.isSuccess && result.position != null) {
      await _applyLocation(
        lat: result.position!.latitude,
        lng: result.position!.longitude,
        source: result.source,
      );
      if (!_isCurrent(generation)) return;
    } else {
      if (result.state == LocationPermissionState.serviceDisabled) {
        AppAlert.warning(
          Get.context,
          title: AppTranslations.tr('prayer.phoneGpsInactive'),
          message:
              'Aktifkan lokasi ponsel agar jadwal salat sesuai tempat Anda berada.',
          okText: 'Buka Pengaturan',
          onOk: () => _locationService.openLocationSettings(),
        );
      } else if (result.state == LocationPermissionState.deniedForever) {
        AppAlert.warning(
          Get.context,
          title: AppTranslations.tr('prayer.locationPermissionRequired'),
          message:
              'Buka pengaturan, lalu izinkan HajiCare memakai lokasi ponsel.',
          okText: 'Buka Pengaturan',
          onOk: () => _locationService.openAppSettings(),
        );
      } else if (result.errorMessage != null &&
          result.errorMessage!.isNotEmpty) {
        AppAlert.error(
          Get.context,
          title: AppTranslations.tr('prayer.locationNotFound'),
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
    final generation = _lifecycleGeneration;
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
      if (!_isCurrent(generation)) return;
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
      if (!_isCurrent(generation)) return;
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

  bool _isCalculatingSchedule = false;

  /// Recalculates prayer schedule and Qibla angle from current coordinates
  void _calculateScheduleAndQibla() {
    if (_isCalculatingSchedule) return;
    if (currentLat.value == 0.0 && currentLng.value == 0.0) return;

    _isCalculatingSchedule = true;
    try {
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
      qiblaBearing.value =
          result.qiblaBearing.isFinite && !result.qiblaBearing.isNaN
          ? result.qiblaBearing
          : 0.0;

      nextPrayerTime.value = _timezoneService.formatTime(
        result.nextPrayerTime,
        timezoneId: timezoneName.value,
        includeTimeZone: true,
      );

      _updateCountdownDifference();
      _updateQiblaOffset(deviceHeading.value);
    } catch (e) {
      debugPrint('[PrayerTimesController] Calculation error: $e');
    } finally {
      _isCalculatingSchedule = false;
    }
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

    // If next prayer time has arrived or passed, trigger adhan & recalculate schedule
    if (diff.isNegative || diff.inSeconds <= 0) {
      if (nextPrayerName.value.isNotEmpty && _targetNextPrayerTime != null) {
        _triggerAdhanIfEligible(nextPrayerName.value, _targetNextPrayerTime!);
      }
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
          if (event.heading == null ||
              event.heading!.isNaN ||
              !event.heading!.isFinite) {
            return;
          }

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
    if (heading.isNaN ||
        !heading.isFinite ||
        qiblaBearing.value.isNaN ||
        !qiblaBearing.value.isFinite) {
      return;
    }

    double diff = (qiblaBearing.value - heading) % 360;
    if (diff < 0) diff += 360;
    if (diff.isNaN || !diff.isFinite) {
      diff = 0.0;
    }
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

  /// Check if adhan sound is turned on for the specified prayer
  bool isPrayerSoundOn(String rawName) {
    final key = _normalizePrayerKey(rawName);
    return prayerSoundEnabled[key] ?? true;
  }

  /// Toggles adhan sound on/off for the given prayer and saves preference
  Future<void> togglePrayerSound(String rawName) async {
    final key = _normalizePrayerKey(rawName);
    if (key == 'terbit' || key == 'sunrise') return;

    final current = isPrayerSoundOn(key);
    final next = !current;
    prayerSoundEnabled[key] = next;

    // If turned off while currently playing for this prayer, stop playback
    if (!next &&
        isAdhanPlaying.value &&
        _normalizePrayerKey(playingPrayerName.value) == key) {
      stopAdhan();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_sound_$key', next);
    } catch (e) {
      debugPrint('[PrayerTimesController] Error saving sound preference: $e');
    }
  }

  /// Check if at least one prayer has sound enabled
  bool get isAnySoundOn {
    const canonicalKeys = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
    return canonicalKeys.any((k) => isPrayerSoundOn(k));
  }

  /// Toggles all prayer sounds simultaneously (1-click master switch)
  Future<void> toggleAllPrayerSounds() async {
    final target = !isAnySoundOn;
    await setAllPrayerSounds(target);
  }

  /// Sets all prayer sounds to enabled or disabled and persists state
  Future<void> setAllPrayerSounds(bool enabled) async {
    const canonicalKeys = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
    for (final k in canonicalKeys) {
      prayerSoundEnabled[k] = enabled;
    }

    if (!enabled && isAdhanPlaying.value) {
      stopAdhan();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in canonicalKeys) {
        await prefs.setBool('prayer_sound_$k', enabled);
      }
    } catch (e) {
      debugPrint(
        '[PrayerTimesController] Error saving all sound preferences: $e',
      );
    }
  }

  /// Stop current adhan audio playback
  void stopAdhan() {
    _adhanAudioService.stopAdhan();
  }

  String _normalizePrayerKey(String rawName) {
    final name = rawName.trim().toLowerCase();
    if (name == 'subuh' || name == 'fajr') return 'subuh';
    if (name == 'terbit' || name == 'sunrise') return 'terbit';
    if (name == 'dzuhur' || name == 'dhuhr') return 'dzuhur';
    if (name == 'ashar' || name == 'asr') return 'ashar';
    if (name == 'maghrib') return 'maghrib';
    if (name == 'isya' || name == 'isha') return 'isya';
    return name;
  }

  Future<void> _loadPrayerSoundPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const canonicalKeys = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
      for (final k in canonicalKeys) {
        final prefKey = 'prayer_sound_$k';
        if (prefs.containsKey(prefKey)) {
          prayerSoundEnabled[k] = prefs.getBool(prefKey) ?? true;
        } else {
          prayerSoundEnabled[k] = true;
        }
      }
    } catch (e) {
      debugPrint('[PrayerTimesController] Error loading sound preferences: $e');
    }
  }

  Future<void> _triggerAdhanIfEligible(
    String prayerName,
    DateTime targetTime,
  ) async {
    final key = _normalizePrayerKey(prayerName);
    if (key == 'terbit' || key == 'sunrise') return;

    final triggerKey =
        '${key}_${targetTime.year}_${targetTime.month}_${targetTime.day}_${targetTime.hour}_${targetTime.minute}';
    if (_lastPlayedAdhanKey == triggerKey) {
      return;
    }

    final now = DateTime.now();
    // Only play if within 2 minutes of the prayer time (avoid playing stale past adhan)
    if (now.difference(targetTime).inMinutes.abs() > 2) {
      return;
    }

    _lastPlayedAdhanKey = triggerKey;

    if (isPrayerSoundOn(key)) {
      debugPrint('[PrayerTimesController] Triggering adhan for $prayerName');
      unawaited(_adhanAudioService.playAdhan(prayerName: prayerName));
    }
  }

  @override
  void onClose() {
    _lifecycleGeneration++;
    _countdownTimer?.cancel();
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    super.onClose();
  }
}

import 'package:flutter/foundation.dart';

/// Asal data sensor gelang yang dipakai sebagai konteks AI (100% Real, Tanpa Simulasi).
enum SensorDataSource {
  /// Gelang Smartband sedang terhubung via Bluetooth Low Energy (BLE).
  live,

  /// Gelang Smartband belum terhubung; AI menggunakan data nyata dari HP & aplikasi.
  disconnected,
}

extension SensorDataSourceX on SensorDataSource {
  String get label => switch (this) {
    SensorDataSource.live => 'Gelang Terhubung (BLE Live)',
    SensorDataSource.disconnected => 'Gelang Belum Terhubung',
  };

  bool get isReal => this == SensorDataSource.live;
}

/// Status koneksi BLE gelang yang relevan bagi fitur AI.
enum SmartbandLinkStatus { disconnected, scanning, connecting, connected }

/// Snapshot immutable kondisi nyata dari **Smartband BLE** + **Seluruh Aplikasi HajiCare**
/// (GPS HP, Rombongan/Room, Jarak Pendamping Real-Time, Jadwal Salat, Kiblat, SOS, & Notifikasi).
@immutable
class SensorContext {
  const SensorContext({
    required this.heartRateBpm,
    required this.temperatureC,
    required this.isFallDetected,
    required this.source,
    required this.capturedAt,
    this.isSmartbandConnected = false,
    this.braceletId = 'Belum Terhubung',
    this.spo2Percent,
    this.stepCount,
    this.batteryPercent,
    this.latitude,
    this.longitude,
    this.smartbandLatitude,
    this.smartbandLongitude,
    this.isSmartbandGpsFix = false,
    this.phoneLatitude,
    this.phoneLongitude,
    this.isPhoneGpsActive = false,
    this.locationCityName,
    this.hijriDateText,
    this.userName = 'Jamaah HajiCare',
    this.userRole = 'jamaah',
    this.hasActiveRoom = false,
    this.roomName,
    this.roomCode,
    this.kloter,
    this.maktab,
    this.companionName,
    this.isCompanionGpsActive = false,
    this.companionLatitude,
    this.companionLongitude,
    this.distanceToCompanionMeters,
    this.safeRadiusMeters,
    this.roomMembersCount = 0,
    this.roomMembersSummary,
    this.closestJamaahSummary,
    this.userProfileSummary,
    this.nextPrayerName,
    this.nextPrayerTime,
    this.nextPrayerCountdown,
    this.todayPrayerScheduleSummary,
    this.qiblaBearingDegrees,
    this.activeSosCount = 0,
    this.isSelfSosActive = false,
    this.unreadNotificationsCount = 0,
    this.latestNotificationSummary,
  });

  // 1. Data Sensor Smartband BLE (Hanya terisi jika gelang benar-benar terhubung)
  final bool isSmartbandConnected;
  final String braceletId;
  final int heartRateBpm;
  final double temperatureC;
  final bool isFallDetected;
  final int? spo2Percent;
  final int? stepCount;
  final int? batteryPercent;
  final double? smartbandLatitude;
  final double? smartbandLongitude;
  final bool isSmartbandGpsFix;

  // 2. Data Lokasi GPS HP & Kota Aktif
  /// Koordinat efektif terbaik (mengutamakan GPS HP aktif, lalu GPS gelang aktif).
  final double? latitude;
  final double? longitude;
  final double? phoneLatitude;
  final double? phoneLongitude;
  final bool isPhoneGpsActive;
  final String? locationCityName;
  final String? hijriDateText;

  // 3. Data Pengguna, Rombongan (Room), Pendamping & Jarak Real-Time
  final String userName;
  final String userRole;
  final bool hasActiveRoom;
  final String? roomName;
  final String? roomCode;
  final String? kloter;
  final String? maktab;
  final String? companionName;
  final bool isCompanionGpsActive;
  final double? companionLatitude;
  final double? companionLongitude;

  /// Jarak nyata ke pendamping (meter) dari GPS real-time. `null` jika belum tersedia.
  final double? distanceToCompanionMeters;

  /// Batas radius aman (meter).
  final double? safeRadiusMeters;
  final int roomMembersCount;
  final String? roomMembersSummary;

  /// Ringkasan jamaah terdekat, jamaah terjauh, dan pendamping terdekat beserta jaraknya.
  final String? closestJamaahSummary;

  /// Ringkasan identitas haji & profil medis pengguna (porsi, paspor, NIK, golongan darah, alergi, kondisi medis, kontak darurat).
  final String? userProfileSummary;

  // 4. Data Jadwal Salat, Arah Kiblat, SOS & Notifikasi Aplikasi
  final String? nextPrayerName;
  final String? nextPrayerTime;
  final String? nextPrayerCountdown;
  final String? todayPrayerScheduleSummary;
  final double? qiblaBearingDegrees;
  final int activeSosCount;
  final bool isSelfSosActive;
  final int unreadNotificationsCount;
  final String? latestNotificationSummary;

  final SensorDataSource source;
  final DateTime capturedAt;

  /// True jika gelang terhubung dan sudah mengirimkan pembacaan detak jantung.
  bool get hasSmartbandVitalSigns => isSmartbandConnected && heartRateBpm > 0;

  /// True jika ada koordinat GPS nyata (baik dari HP maupun dari gelang).
  bool get hasLocation => latitude != null && longitude != null;

  bool get hasPhoneLocation =>
      isPhoneGpsActive && phoneLatitude != null && phoneLongitude != null;

  bool get hasSmartbandLocation =>
      isSmartbandConnected &&
      isSmartbandGpsFix &&
      smartbandLatitude != null &&
      smartbandLongitude != null;

  bool get isOutsideSafeRadius {
    final d = distanceToCompanionMeters;
    final r = safeRadiusMeters;
    return d != null && r != null && d > r;
  }

  String get fallStatusLabel {
    if (!isSmartbandConnected) return 'Gelang Belum Terhubung';
    return isFallDetected ? 'TERDETEKSI JATUH' : 'Aman (Tidak Jatuh)';
  }

  String get heartRateDisplay =>
      hasSmartbandVitalSigns ? '$heartRateBpm BPM' : 'Belum terhubung';

  String get temperatureLabel =>
      (isSmartbandConnected && temperatureC > 0)
          ? temperatureC.toStringAsFixed(1)
          : '--';

  String? get distanceLabel => distanceToCompanionMeters?.round().toString();

  /// Penjelasan jujur mengenai status jarak ke pendamping saat ini.
  String get distanceStatusSummary {
    if (distanceToCompanionMeters != null) {
      final d = distanceToCompanionMeters!.round();
      final comp = (companionName != null && companionName!.trim().isNotEmpty)
          ? companionName!
          : 'Pendamping';
      final radius = (safeRadiusMeters ?? 200).round();
      final safety = d > radius ? 'DI LUAR radius aman' : 'di dalam radius aman';
      return '$d meter dari $comp ($safety, batas ${radius}m)';
    }
    if (!hasActiveRoom) {
      return 'Belum tergabung di Room Rombongan (jarak pendamping belum aktif)';
    }
    if (!hasPhoneLocation && !hasSmartbandLocation) {
      return 'Menunggu sinyal GPS HP Anda aktif untuk menghitung jarak';
    }
    if (!isCompanionGpsActive) {
      return 'Menunggu sinyal GPS dari HP ${companionName ?? "Pendamping"} aktif';
    }
    return 'Sedang menghitung jarak real-time ke pendamping';
  }

  /// Ringkasan posisi GPS HP & Gelang secara jujur.
  String get positionStatusSummary {
    final parts = <String>[];
    if (locationCityName != null &&
        locationCityName!.trim().isNotEmpty &&
        locationCityName != 'Mencari lokasi...') {
      parts.add('Kota/Area: $locationCityName');
    }
    if (hasPhoneLocation) {
      parts.add(
        'GPS HP: ${phoneLatitude!.toStringAsFixed(5)}, ${phoneLongitude!.toStringAsFixed(5)}',
      );
    } else {
      parts.add('GPS HP: Belum aktif / menunggu kunci lokasi');
    }
    if (hasSmartbandLocation) {
      parts.add(
        'GPS Gelang: ${smartbandLatitude!.toStringAsFixed(5)}, ${smartbandLongitude!.toStringAsFixed(5)}',
      );
    } else if (isSmartbandConnected) {
      parts.add('GPS Gelang: Menunggu sinyal satelit ATGM336H');
    } else {
      parts.add('GPS Gelang: Gelang belum terhubung');
    }
    return parts.join(' | ');
  }

  /// Penilaian sederhana untuk pewarnaan UI (hanya jika gelang benar-benar terhubung).
  bool get isHeartRateAbnormal =>
      hasSmartbandVitalSigns && (heartRateBpm < 50 || heartRateBpm > 110);
  bool get isTemperatureAbnormal =>
      isSmartbandConnected &&
      temperatureC > 0 &&
      (temperatureC >= 37.8 || temperatureC < 35.0);

  SensorContext copyWith({
    bool? isSmartbandConnected,
    String? braceletId,
    int? heartRateBpm,
    double? temperatureC,
    bool? isFallDetected,
    int? spo2Percent,
    int? stepCount,
    int? batteryPercent,
    double? latitude,
    double? longitude,
    double? smartbandLatitude,
    double? smartbandLongitude,
    bool? isSmartbandGpsFix,
    double? phoneLatitude,
    double? phoneLongitude,
    bool? isPhoneGpsActive,
    String? locationCityName,
    String? hijriDateText,
    String? userName,
    String? userRole,
    bool? hasActiveRoom,
    String? roomName,
    String? roomCode,
    String? kloter,
    String? maktab,
    String? companionName,
    bool? isCompanionGpsActive,
    double? companionLatitude,
    double? companionLongitude,
    double? distanceToCompanionMeters,
    double? safeRadiusMeters,
    int? roomMembersCount,
    String? roomMembersSummary,
    String? closestJamaahSummary,
    String? userProfileSummary,
    String? nextPrayerName,
    String? nextPrayerTime,
    String? nextPrayerCountdown,
    String? todayPrayerScheduleSummary,
    double? qiblaBearingDegrees,
    int? activeSosCount,
    bool? isSelfSosActive,
    int? unreadNotificationsCount,
    String? latestNotificationSummary,
    SensorDataSource? source,
    DateTime? capturedAt,
  }) {
    return SensorContext(
      isSmartbandConnected: isSmartbandConnected ?? this.isSmartbandConnected,
      braceletId: braceletId ?? this.braceletId,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      temperatureC: temperatureC ?? this.temperatureC,
      isFallDetected: isFallDetected ?? this.isFallDetected,
      spo2Percent: spo2Percent ?? this.spo2Percent,
      stepCount: stepCount ?? this.stepCount,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      smartbandLatitude: smartbandLatitude ?? this.smartbandLatitude,
      smartbandLongitude: smartbandLongitude ?? this.smartbandLongitude,
      isSmartbandGpsFix: isSmartbandGpsFix ?? this.isSmartbandGpsFix,
      phoneLatitude: phoneLatitude ?? this.phoneLatitude,
      phoneLongitude: phoneLongitude ?? this.phoneLongitude,
      isPhoneGpsActive: isPhoneGpsActive ?? this.isPhoneGpsActive,
      locationCityName: locationCityName ?? this.locationCityName,
      hijriDateText: hijriDateText ?? this.hijriDateText,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      hasActiveRoom: hasActiveRoom ?? this.hasActiveRoom,
      roomName: roomName ?? this.roomName,
      roomCode: roomCode ?? this.roomCode,
      kloter: kloter ?? this.kloter,
      maktab: maktab ?? this.maktab,
      companionName: companionName ?? this.companionName,
      isCompanionGpsActive: isCompanionGpsActive ?? this.isCompanionGpsActive,
      companionLatitude: companionLatitude ?? this.companionLatitude,
      companionLongitude: companionLongitude ?? this.companionLongitude,
      distanceToCompanionMeters:
          distanceToCompanionMeters ?? this.distanceToCompanionMeters,
      safeRadiusMeters: safeRadiusMeters ?? this.safeRadiusMeters,
      roomMembersCount: roomMembersCount ?? this.roomMembersCount,
      roomMembersSummary: roomMembersSummary ?? this.roomMembersSummary,
      closestJamaahSummary: closestJamaahSummary ?? this.closestJamaahSummary,
      userProfileSummary: userProfileSummary ?? this.userProfileSummary,
      nextPrayerName: nextPrayerName ?? this.nextPrayerName,
      nextPrayerTime: nextPrayerTime ?? this.nextPrayerTime,
      nextPrayerCountdown: nextPrayerCountdown ?? this.nextPrayerCountdown,
      todayPrayerScheduleSummary:
          todayPrayerScheduleSummary ?? this.todayPrayerScheduleSummary,
      qiblaBearingDegrees: qiblaBearingDegrees ?? this.qiblaBearingDegrees,
      activeSosCount: activeSosCount ?? this.activeSosCount,
      isSelfSosActive: isSelfSosActive ?? this.isSelfSosActive,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      latestNotificationSummary:
          latestNotificationSummary ?? this.latestNotificationSummary,
      source: source ?? this.source,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorContext &&
          other.isSmartbandConnected == isSmartbandConnected &&
          other.braceletId == braceletId &&
          other.heartRateBpm == heartRateBpm &&
          other.temperatureC == temperatureC &&
          other.isFallDetected == isFallDetected &&
          other.spo2Percent == spo2Percent &&
          other.stepCount == stepCount &&
          other.batteryPercent == batteryPercent &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.smartbandLatitude == smartbandLatitude &&
          other.smartbandLongitude == smartbandLongitude &&
          other.isSmartbandGpsFix == isSmartbandGpsFix &&
          other.phoneLatitude == phoneLatitude &&
          other.phoneLongitude == phoneLongitude &&
          other.isPhoneGpsActive == isPhoneGpsActive &&
          other.locationCityName == locationCityName &&
          other.hasActiveRoom == hasActiveRoom &&
          other.roomName == roomName &&
          other.roomMembersSummary == roomMembersSummary &&
          other.closestJamaahSummary == closestJamaahSummary &&
          other.userProfileSummary == userProfileSummary &&
          other.distanceToCompanionMeters == distanceToCompanionMeters &&
          other.safeRadiusMeters == safeRadiusMeters &&
          other.nextPrayerName == nextPrayerName &&
          other.nextPrayerTime == nextPrayerTime &&
          other.qiblaBearingDegrees == qiblaBearingDegrees &&
          other.activeSosCount == activeSosCount &&
          other.unreadNotificationsCount == unreadNotificationsCount &&
          other.source == source;

  @override
  int get hashCode => Object.hashAll([
    isSmartbandConnected,
    braceletId,
    heartRateBpm,
    temperatureC,
    isFallDetected,
    latitude,
    longitude,
    phoneLatitude,
    phoneLongitude,
    isPhoneGpsActive,
    hasActiveRoom,
    roomMembersSummary,
    closestJamaahSummary,
    userProfileSummary,
    distanceToCompanionMeters,
    safeRadiusMeters,
    nextPrayerName,
    qiblaBearingDegrees,
    activeSosCount,
    unreadNotificationsCount,
    source,
  ]);

  @override
  String toString() =>
      'SensorContext(bleConnected: $isSmartbandConnected, bpm: $heartRateBpm, '
      'temp: $temperatureLabel, phoneGps: $isPhoneGpsActive, '
      'dist: $distanceLabel, room: $roomName, nextPrayer: $nextPrayerName)';
}

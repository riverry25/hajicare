import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';

import '../../../core/state/hajicare_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../prayer/controllers/prayer_times_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../smartband/controllers/smartband_ldr_controller.dart';
import '../../smartband/services/smartband_ble_service.dart';
import '../models/oled_display_state.dart';
import '../models/sensor_context.dart';
import 'oled_text_formatter.dart';

/// Service jembatan real-time antara **HajiCare AI Assistant** dengan seluruh
/// modul nyata aplikasi:
/// 1. `SmartbandBleService` & `SmartbandLdrController` (BLE Hardware & Telemetri Asli)
/// 2. `HajiCareController` (GPS HP, Jarak Pendamping Real-Time, Room/Rombongan, Kloter, Maktab, SOS)
/// 3. `PrayerTimesController` (Kota Aktif, Tanggal Hijriah, Jadwal 5 Waktu Salat, Hitung Mundur, Arah Kiblat)
/// 4. `NotificationController` (Pesan & Peringatan Masuk dari Pendamping/Rombongan)
///
/// **100% Tanpa Simulasi:** Jika gelang BLE belum terhubung, status dilaporkan jujur
/// sebagai `Gelang Belum Terhubung` tanpa angka karangan.
class SmartbandAiBridgeService {
  SmartbandAiBridgeService({
    SmartbandLdrController? smartbandController,
    SmartbandBleService? bleService,
    HajiCareController? hajiCareController,
    PrayerTimesController? prayerTimesController,
    NotificationController? notificationController,
  }) : _explicitSmartbandCtrl = smartbandController,
       _explicitBleService = bleService,
       _explicitHajiCareCtrl = hajiCareController,
       _explicitPrayerCtrl = prayerTimesController,
       _explicitNotifCtrl = notificationController;

  final SmartbandLdrController? _explicitSmartbandCtrl;
  final SmartbandBleService? _explicitBleService;
  final HajiCareController? _explicitHajiCareCtrl;
  final PrayerTimesController? _explicitPrayerCtrl;
  final NotificationController? _explicitNotifCtrl;

  static const double defaultSafeRadiusMeters = 200.0;

  SmartbandLdrController? get _ldrCtrl {
    if (_explicitSmartbandCtrl != null) return _explicitSmartbandCtrl;
    if (Get.isRegistered<SmartbandLdrController>()) {
      return Get.find<SmartbandLdrController>();
    }
    return null;
  }

  SmartbandBleService? get _bleService {
    if (_explicitBleService != null) return _explicitBleService;
    final ldr = _ldrCtrl;
    if (ldr != null) return ldr.bleService;
    if (Get.isRegistered<SmartbandBleService>()) {
      return Get.find<SmartbandBleService>();
    }
    return null;
  }

  HajiCareController? get _hajiCtrl {
    if (_explicitHajiCareCtrl != null) return _explicitHajiCareCtrl;
    if (Get.isRegistered<HajiCareController>()) {
      return Get.find<HajiCareController>();
    }
    return null;
  }

  PrayerTimesController? get _prayerCtrl {
    if (_explicitPrayerCtrl != null) return _explicitPrayerCtrl;
    if (Get.isRegistered<PrayerTimesController>()) {
      return Get.find<PrayerTimesController>();
    }
    return null;
  }

  NotificationController? get _notifCtrl {
    if (_explicitNotifCtrl != null) return _explicitNotifCtrl;
    if (Get.isRegistered<NotificationController>()) {
      return Get.find<NotificationController>();
    }
    return null;
  }

  /// Status koneksi BLE perangkat fisik gelang (murni hardware).
  SmartbandLinkStatus get bleLinkStatus {
    final ble = _bleService;
    if (ble == null) return SmartbandLinkStatus.disconnected;
    return switch (ble.currentStatus) {
      SmartbandBleStatus.connected => SmartbandLinkStatus.connected,
      SmartbandBleStatus.scanning => SmartbandLinkStatus.scanning,
      SmartbandBleStatus.connecting => SmartbandLinkStatus.connecting,
      SmartbandBleStatus.disconnected => SmartbandLinkStatus.disconnected,
    };
  }

  bool get isBleHardwareConnected =>
      bleLinkStatus == SmartbandLinkStatus.connected;

  /// Ambil snapshot konteks nyata dari Smartband BLE + seluruh modul aplikasi.
  SensorContext readCurrentSensorContext() {
    final ldr = _ldrCtrl;
    final haji = _hajiCtrl;
    final prayer = _prayerCtrl;
    final notif = _notifCtrl;
    final bleConnected = isBleHardwareConnected;

    // 1. Telemetri Gelang BLE (Hanya bernilai jika gelang fisik benar-benar terhubung)
    final int hrBpm = (bleConnected && ldr != null)
        ? (ldr.heartRate.value ?? 0)
        : 0;
    final double tempC = (bleConnected && ldr != null)
        ? (ldr.mcpTemperature.value ?? 0.0)
        : 0.0;
    final int? spo2 = (bleConnected && ldr != null) ? ldr.spo2.value : null;
    final bool fallDetected =
        bleConnected && (ldr?.isFallDetected.value ?? false);
    final int? steps = (bleConnected && ldr != null) ? ldr.effectiveSteps : null;
    final int? battery =
        (bleConnected && ldr != null) ? ldr.batteryPercent.value : null;
    final String braceletId = (bleConnected && ldr != null)
        ? ldr.braceletId.value
        : 'Belum Terhubung';

    final bool sbGpsFix = bleConnected && (ldr?.isGpsFix.value ?? false);
    final double? sbLat =
        (bleConnected && ldr != null) ? ldr.latitude.value : null;
    final double? sbLng =
        (bleConnected && ldr != null) ? ldr.longitude.value : null;

    // 2. Lokasi GPS HP & Kota dari HajiCareController + PrayerTimesController
    final phonePos = haji?.myCurrentPosition.value;
    final bool hasHajiGps =
        (haji?.isMyGpsActive.value ?? false) && phonePos != null;
    final bool hasPrayerGps =
        prayer != null &&
        !prayer.isUsingFallbackLocation &&
        prayer.currentLat.value != 0.0 &&
        prayer.currentLng.value != 0.0;

    final bool phoneGpsActive = hasHajiGps || hasPrayerGps;
    final double? phoneLat = hasHajiGps
        ? phonePos.latitude
        : (hasPrayerGps ? prayer.currentLat.value : null);
    final double? phoneLng = hasHajiGps
        ? phonePos.longitude
        : (hasPrayerGps ? prayer.currentLng.value : null);

    final String? currentUid = haji?.currentUid;
    final RoomMemberModel? selfMember = (haji != null && currentUid != null)
        ? haji.activeRoomMembers.firstWhereOrNull((m) => m.uid == currentUid)
        : null;

    final double? effectiveLat = phoneLat ?? sbLat ?? selfMember?.latitude;
    final double? effectiveLng = phoneLng ?? sbLng ?? selfMember?.longitude;

    final rawCity = prayer?.locationName.value.trim();
    final String? cityName =
        (rawCity != null &&
            rawCity.isNotEmpty &&
            rawCity != 'Mencari lokasi...')
        ? rawCity
        : null;
    final String? hijriDate =
        (prayer != null && prayer.hijriDateText.value.trim().isNotEmpty)
        ? prayer.hijriDateText.value.trim()
        : null;

    // 3. Data Pengguna, Room / Rombongan, Pendamping, & Jarak Real-Time
    final String userRole = haji?.role.name ?? 'jamaah';
    final String userName = _resolveUserName(haji);
    final String? activeRoomId = haji?.activeRoomId.value?.trim();
    final bool hasRoom = activeRoomId != null && activeRoomId.isNotEmpty;
    final room = haji?.activeRoom.value;
    final String? roomName = room?.name;
    final String? roomCode = room?.code;
    final String? kloter = haji?.effectiveKloter;
    final String? maktab = haji?.effectiveMaktab;
    final String? companionName = hasRoom ? haji?.pendampingName.value : null;
    final bool companionGpsActive =
        hasRoom && (haji?.isPendampingGpsActive.value ?? false);
    final double? companionLat = haji?.pendampingLocation.value?.latitude;
    final double? companionLng = haji?.pendampingLocation.value?.longitude;

    final double safeRadius =
        haji?.safeRadiusMeters.value ??
        ldr?.activeSafeRadius.value ??
        defaultSafeRadiusMeters;

    // Jarak nyata (murni dari perhitungan GPS real-time, tanpa angka simulasi)
    double? realDistance = haji?.calculatedDistance.value;
    if (realDistance == null &&
        effectiveLat != null &&
        effectiveLng != null &&
        companionLat != null &&
        companionLng != null) {
      realDistance = _haversineMeters(
        effectiveLat,
        effectiveLng,
        companionLat,
        companionLng,
      );
    }
    if (realDistance == null &&
        bleConnected &&
        ldr != null &&
        ldr.currentDistanceToPosko.value > 0) {
      realDistance = ldr.currentDistanceToPosko.value;
    }

    final int membersCount = haji?.activeRoomMembers.length ?? 0;
    final (String? membersSummary, String? closestSummary) =
        _buildRoomMembersAndClosestSummary(
          haji: haji,
          myLat: effectiveLat,
          myLng: effectiveLng,
          safeRadius: safeRadius,
          realDistanceToCompanion: realDistance,
          companionName: companionName,
        );
    final String? profileSummary = _buildUserProfileSummary(haji);

    // 4. Data Jadwal Salat, Arah Kiblat, SOS, & Notifikasi
    final String? nextPrayerName =
        (prayer != null && prayer.nextPrayerName.value.trim().isNotEmpty)
        ? prayer.nextPrayerName.value.trim()
        : null;
    final String? nextPrayerTime =
        (prayer != null &&
            prayer.nextPrayerTime.value.trim().isNotEmpty &&
            prayer.nextPrayerTime.value != '--:--')
        ? prayer.nextPrayerTime.value.trim()
        : null;
    final String? nextPrayerCountdown =
        (prayer != null &&
            prayer.countdownText.value.trim().isNotEmpty &&
            !prayer.countdownText.value.startsWith('--'))
        ? prayer.countdownText.value.trim()
        : null;
    final String? scheduleSummary = _buildPrayerScheduleSummary(prayer);
    final double? qiblaDegrees =
        (prayer != null && prayer.qiblaBearing.value > 0)
        ? prayer.qiblaBearing.value
        : null;

    final int activeSosCount = haji?.activeSosCount.value ?? 0;
    final bool selfSosActive = _resolveSelfSosActive(haji);
    final int unreadNotifs = notif?.unreadCount.value ?? 0;
    final String? latestNotif = _buildLatestNotificationSummary(notif, haji);

    return SensorContext(
      isSmartbandConnected: bleConnected,
      braceletId: braceletId,
      heartRateBpm: hrBpm,
      temperatureC: tempC,
      isFallDetected: fallDetected,
      spo2Percent: spo2,
      stepCount: steps,
      batteryPercent: battery,
      latitude: effectiveLat,
      longitude: effectiveLng,
      smartbandLatitude: sbLat,
      smartbandLongitude: sbLng,
      isSmartbandGpsFix: sbGpsFix,
      phoneLatitude: phoneLat,
      phoneLongitude: phoneLng,
      isPhoneGpsActive: phoneGpsActive,
      locationCityName: cityName,
      hijriDateText: hijriDate,
      userName: userName,
      userRole: userRole,
      hasActiveRoom: hasRoom,
      roomName: roomName,
      roomCode: roomCode,
      kloter: kloter,
      maktab: maktab,
      companionName: companionName,
      isCompanionGpsActive: companionGpsActive,
      companionLatitude: companionLat,
      companionLongitude: companionLng,
      distanceToCompanionMeters: realDistance,
      safeRadiusMeters: safeRadius,
      roomMembersCount: membersCount,
      roomMembersSummary: membersSummary,
      closestJamaahSummary: closestSummary,
      userProfileSummary: profileSummary,
      nextPrayerName: nextPrayerName,
      nextPrayerTime: nextPrayerTime,
      nextPrayerCountdown: nextPrayerCountdown,
      todayPrayerScheduleSummary: scheduleSummary,
      qiblaBearingDegrees: qiblaDegrees,
      activeSosCount: activeSosCount,
      isSelfSosActive: selfSosActive,
      unreadNotificationsCount: unreadNotifs,
      latestNotificationSummary: latestNotif,
      source: bleConnected
          ? SensorDataSource.live
          : SensorDataSource.disconnected,
      capturedAt: DateTime.now(),
    );
  }

  String _resolveUserName(HajiCareController? haji) {
    if (Get.isRegistered<ProfileController>()) {
      final pCtrl = Get.find<ProfileController>();
      final dName = pCtrl.displayName.value.trim();
      if (dName.isNotEmpty && dName != 'Pengguna') return dName;
    }
    if (haji == null) return 'Pengguna HajiCare';
    try {
      if (haji.role == UserRole.pendamping) {
        final pName = haji.pendampingName.value.trim();
        if (pName.isNotEmpty && pName != 'Pendamping Anda') return pName;
        return 'Pendamping HajiCare';
      }
      final uid = haji.currentUid;
      if (uid != null) {
        final match = haji.jamaahList.firstWhereOrNull((j) => j.id == uid);
        if (match != null && match.name.trim().isNotEmpty) {
          return match.name.trim();
        }
        final roomMatch =
            haji.activeRoomMembers.firstWhereOrNull((m) => m.uid == uid);
        if (roomMatch != null && roomMatch.name.trim().isNotEmpty) {
          return roomMatch.name.trim();
        }
      }
      if (haji.jamaahList.isNotEmpty &&
          haji.jamaahList.first.name.trim().isNotEmpty) {
        return haji.jamaahList.first.name.trim();
      }
    } catch (_) {}
    return 'Jamaah HajiCare';
  }

  bool _resolveSelfSosActive(HajiCareController? haji) {
    if (haji == null) return false;
    try {
      final uid = haji.currentUid;
      if (uid != null) {
        final match = haji.jamaahList.firstWhereOrNull((j) => j.id == uid);
        if (match != null) return match.sosActive;
        final roomMatch =
            haji.activeRoomMembers.firstWhereOrNull((m) => m.uid == uid);
        if (roomMatch != null) return roomMatch.sosActive;
      }
    } catch (_) {}
    return false;
  }

  /// Hitung jarak permukaan bumi (Haversine) dalam satuan meter.
  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000.0;
    final double dLat = (lat2 - lat1) * (math.pi / 180.0);
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Bangun daftar lengkap seluruh anggota di Room (baik untuk Jamaah maupun Pendamping)
  /// beserta urutan jarak nyata dari yang paling dekat hingga paling jauh.
  (String?, String?) _buildRoomMembersAndClosestSummary({
    required HajiCareController? haji,
    required double? myLat,
    required double? myLng,
    required double safeRadius,
    required double? realDistanceToCompanion,
    required String? companionName,
  }) {
    if (haji == null) return (null, null);
    final roomId = haji.activeRoomId.value?.trim();
    if (roomId == null || roomId.isEmpty) return (null, null);

    final currentUid = haji.currentUid;
    final members = haji.activeRoomMembers.toList();

    // Gabungkan data dari activeRoomMembers dan jamaahList agar tidak ada anggota yang terlewat
    final Map<String, ({
      String uid,
      String name,
      String role,
      double? lat,
      double? lng,
      double? distanceMeters,
      bool sosActive,
      bool smartbandConnected,
      bool isSelf,
    })> resolvedMap = {};

    for (final m in members) {
      final isSelf = currentUid != null && m.uid == currentUid;
      double? dist;
      if (!isSelf &&
          myLat != null &&
          myLng != null &&
          m.latitude != null &&
          m.longitude != null) {
        dist = _haversineMeters(myLat, myLng, m.latitude!, m.longitude!);
      }
      resolvedMap[m.uid] = (
        uid: m.uid,
        name: m.name,
        role: m.role,
        lat: m.latitude,
        lng: m.longitude,
        distanceMeters: dist,
        sosActive: m.sosActive,
        smartbandConnected: m.isSmartbandConnected,
        isSelf: isSelf,
      );
    }

    for (final j in haji.jamaahList) {
      final isSelf = currentUid != null && j.id == currentUid;
      final existing = resolvedMap[j.id];
      final lat = existing?.lat ?? j.currentLocation?.latitude;
      final lng = existing?.lng ?? j.currentLocation?.longitude;
      double? dist = existing?.distanceMeters;
      if (dist == null && !isSelf) {
        if (myLat != null && myLng != null && lat != null && lng != null) {
          dist = _haversineMeters(myLat, myLng, lat, lng);
        } else if (haji.role == UserRole.pendamping && j.distance > 0) {
          dist = j.distance;
        }
      }
      resolvedMap[j.id] = (
        uid: j.id,
        name: existing?.name ?? j.name,
        role: existing?.role ?? (j.role ?? 'jamaah'),
        lat: lat,
        lng: lng,
        distanceMeters: dist,
        sosActive: (existing?.sosActive ?? false) || j.sosActive,
        smartbandConnected:
            (existing?.smartbandConnected ?? false) || j.isSmartbandConnected,
        isSelf: isSelf,
      );
    }

    if (resolvedMap.isEmpty) return (null, null);

    final allEntries = resolvedMap.values.toList();
    final otherEntries = allEntries.where((e) => !e.isSelf).toList()
      ..sort((a, b) {
        final da = a.distanceMeters ?? double.infinity;
        final db = b.distanceMeters ?? double.infinity;
        return da.compareTo(db);
      });

    final otherJamaahWithDist = otherEntries
        .where((e) => e.role == 'jamaah' && e.distanceMeters != null)
        .toList();
    final otherJamaahNoDist = otherEntries
        .where((e) => e.role == 'jamaah' && e.distanceMeters == null)
        .toList();
    final otherPendampingWithDist = otherEntries
        .where((e) => e.role == 'pendamping' && e.distanceMeters != null)
        .toList();

    // 1. Ringkasan Jamaah Terdekat, Terjauh, & Pendamping Terdekat
    final closestParts = <String>[];
    if (otherJamaahWithDist.isNotEmpty) {
      final closestJ = otherJamaahWithDist.first;
      final d = closestJ.distanceMeters!.round();
      final status = d <= safeRadius ? 'Aman' : 'Di luar radius aman';
      closestParts.add(
        'Jamaah paling dekat (terdekat) dengan Anda: ${closestJ.name} (${d}m, $status)',
      );
      if (otherJamaahWithDist.length > 1) {
        final farthestJ = otherJamaahWithDist.last;
        final df = farthestJ.distanceMeters!.round();
        closestParts.add(
          'Jamaah paling jauh (terjauh) dari Anda: ${farthestJ.name} (${df}m)',
        );
      }
    } else if (otherJamaahNoDist.isNotEmpty) {
      final names = otherJamaahNoDist.map((e) => e.name).join(', ');
      closestParts.add(
        'Jamaah lain di room Anda (${otherJamaahNoDist.length} orang): $names (saat ini lokasi GPS HP mereka belum aktif sehingga jarak ke sesama jamaah belum dapat diukur)',
      );
    } else {
      closestParts.add(
        'Belum ada jamaah lain selain Anda di dalam room ini',
      );
    }

    if (otherPendampingWithDist.isNotEmpty) {
      final cp = otherPendampingWithDist.first;
      closestParts.add(
        'Pendamping terdekat: ${cp.name} (${cp.distanceMeters!.round()}m)',
      );
    } else if (realDistanceToCompanion != null) {
      closestParts.add(
        'Pendamping terdekat: ${companionName ?? "Pendamping"} (${realDistanceToCompanion.round()}m)',
      );
    }

    final closestSummary = closestParts.join('. ');

    // 2. Daftar Lengkap Seluruh Anggota Room (diurutkan dari yang terdekat)
    final pendampingCount =
        allEntries.where((e) => e.role == 'pendamping').length;
    final jamaahCount = allEntries.where((e) => e.role == 'jamaah').length;

    final memberDescriptions = <String>[];
    for (final e in allEntries) {
      final roleLabel = e.role == 'pendamping' ? 'Pendamping' : 'Jamaah';
      final String distLabel;
      if (e.isSelf) {
        distLabel = 'Anda sendiri';
      } else if (e.distanceMeters != null) {
        final d = e.distanceMeters!.round();
        final safety = d <= safeRadius ? 'Aman' : 'Di luar radius';
        distLabel = '${d}m ($safety)';
      } else {
        distLabel = 'GPS belum aktif';
      }
      final sosTag = e.sosActive ? ', DARURAT SOS AKTIF' : '';
      final bandTag = e.smartbandConnected ? ', Gelang BLE Aktif' : '';
      memberDescriptions.add(
        '${e.name} ($roleLabel, $distLabel$sosTag$bandTag)',
      );
    }

    final membersSummary =
        'Total anggota room: ${allEntries.length} orang ($pendampingCount pendamping, $jamaahCount jamaah). '
        'Daftar lengkap anggota: ${memberDescriptions.join("; ")}';

    return (membersSummary, closestSummary);
  }

  /// Bangun ringkasan profil, dokumen haji, dan rekam medis pengguna dari aplikasi.
  String? _buildUserProfileSummary(HajiCareController? haji) {
    final parts = <String>[];
    String? porsi;
    String? passport;
    String? nik;
    String? blood;
    String? allergy;
    String? condition;
    String? emergency;
    String? email;

    if (Get.isRegistered<ProfileController>()) {
      final p = Get.find<ProfileController>();
      if (p.nomorPorsi.value.trim().isNotEmpty) porsi = p.nomorPorsi.value.trim();
      if (p.passportNumber.value.trim().isNotEmpty) {
        passport = p.passportNumber.value.trim();
      }
      if (p.nik.value.trim().isNotEmpty) nik = p.nik.value.trim();
      if (p.bloodType.value.trim().isNotEmpty) blood = p.bloodType.value.trim();
      if (p.allergies.value.trim().isNotEmpty) allergy = p.allergies.value.trim();
      if (p.conditions.value.trim().isNotEmpty) {
        condition = p.conditions.value.trim();
      }
      if (p.emergencyContact.value.trim().isNotEmpty) {
        emergency = p.emergencyContact.value.trim();
      }
      if (p.safeEmail.isNotEmpty) email = p.safeEmail;
    }

    if (haji != null) {
      final uid = haji.currentUid;
      final selfData = uid != null
          ? haji.jamaahList.firstWhereOrNull((j) => j.id == uid)
          : (haji.jamaahList.isNotEmpty ? haji.jamaahList.first : null);
      if (selfData != null) {
        porsi ??= selfData.porsi;
        passport ??= selfData.passportNumber;
        nik ??= selfData.nik;
        blood ??= selfData.bloodType;
        allergy ??= selfData.allergies;
        condition ??= selfData.conditions;
        emergency ??= selfData.emergencyContact;
        email ??= selfData.email;
      }
    }

    if (email != null && email.isNotEmpty) parts.add('Email=$email');
    if (porsi != null && porsi.isNotEmpty) parts.add('Nomor Porsi=$porsi');
    if (passport != null && passport.isNotEmpty) {
      parts.add('No Paspor=$passport');
    }
    if (nik != null && nik.isNotEmpty) parts.add('NIK=$nik');
    if (blood != null && blood.isNotEmpty) parts.add('Golongan Darah=$blood');
    if (allergy != null && allergy.isNotEmpty) parts.add('Alergi=$allergy');
    if (condition != null && condition.isNotEmpty) {
      parts.add('Kondisi Medis=$condition');
    }
    if (emergency != null && emergency.isNotEmpty) {
      parts.add('Kontak Darurat=$emergency');
    }

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String? _buildPrayerScheduleSummary(PrayerTimesController? prayer) {
    if (prayer == null || prayer.prayers.isEmpty) return null;
    return prayer.prayers
        .map((p) => '${p.name} ${p.formattedTime}')
        .join(', ');
  }

  String? _buildLatestNotificationSummary(
    NotificationController? notif,
    HajiCareController? haji,
  ) {
    final parts = <String>[];
    if (haji != null && haji.activeSosEvents.isNotEmpty) {
      final sosNames = haji.activeSosEvents
          .take(4)
          .map(
            (e) =>
                (e['userName'] ?? e['name'] ?? e['jamaahName'] ?? 'Anggota')
                    .toString(),
          )
          .join(', ');
      parts.add('Peringatan SOS Aktif dari: $sosNames');
    }

    if (notif != null && notif.notifications.isNotEmpty) {
      final items = notif.notifications.take(3).map((n) {
        final t = n.title.trim();
        final m = n.message.trim();
        return t.isNotEmpty ? '$t ($m)' : m;
      }).join(' | ');
      if (items.isNotEmpty) {
        parts.add(items);
      }
    }
    return parts.isEmpty ? null : parts.join('; ');
  }

  /// Kirim ringkasan OLED ke gelang pintar melalui BLE RX Characteristic
  /// (`6e400002-b5a3-f393-e0a9-e50e24dcca9e`) dengan format `"AI:<teks>"`
  /// (dipotong aman maksimal 55 karakter ASCII, bersih dari newline & emoji).
  ///
  /// Jika BLE belum terhubung, mengembalikan [OledDeliveryStatus.previewOnly]
  /// tanpa berpura-pura gelang terhubung.
  Future<OledDisplayState> sendOledToSmartband(String rawOledText) async {
    final sanitizedText = OledTextFormatter.sanitize(rawOledText);
    final effectiveText = sanitizedText.isNotEmpty
        ? sanitizedText
        : 'Siap bantu jamaah HajiCare';
    final payload = OledTextFormatter.buildPayload(effectiveText);

    final ble = _bleService;
    if (ble != null && ble.isConnected && ble.canWriteCommand) {
      final ldr = _ldrCtrl;
      if (ldr != null) {
        final wrapped = OledTextFormatter.wrap(effectiveText, width: 16);
        if (wrapped.isNotEmpty) {
          ldr.lcdLine1.value = wrapped.first.padRight(16).substring(0, 16);
        }
        if (wrapped.length > 1) {
          ldr.lcdLine2.value = wrapped[1].padRight(16).substring(0, 16);
        }
      }

      final ok = await ble.sendAiOledPayload(payload);
      return OledDisplayState(
        text: effectiveText,
        payload: payload,
        status: ok
            ? OledDeliveryStatus.deliveredBle
            : OledDeliveryStatus.failed,
        updatedAt: DateTime.now(),
      );
    }

    return OledDisplayState(
      text: effectiveText,
      payload: payload,
      status: OledDeliveryStatus.previewOnly,
      updatedAt: DateTime.now(),
    );
  }

  /// Pindai & hubungkan gelang BLE fisik.
  Future<void> connectSmartband() async {
    final ldr = _ldrCtrl;
    if (ldr != null) {
      await ldr.connectSmartband();
      return;
    }
    final ble = _bleService;
    if (ble != null) {
      await ble.scanSmartband(autoConnect: true);
    }
  }
}

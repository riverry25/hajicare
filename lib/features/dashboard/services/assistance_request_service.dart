import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../core/state/hajicare_controller.dart';
import '../../notification/services/notification_service.dart';
import '../models/assistance_request_model.dart';

/// Central service managing the lifecycle of assistance requests
/// for pilgrims (lupa jalan pulang, terpisah, jemput, pesan).
class AssistanceRequestService extends GetxService {
  static AssistanceRequestService get instance {
    if (!Get.isRegistered<AssistanceRequestService>()) {
      Get.put(AssistanceRequestService(), permanent: true);
    }
    return Get.find<AssistanceRequestService>();
  }

  final NotificationService _notificationService;

  AssistanceRequestService({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  final activeRequest = Rxn<AssistanceRequestModel>();
  final requestHistory = <AssistanceRequestModel>[].obs;

  bool get hasActiveRequest => activeRequest.value?.isActive == true;

  /// Resets active request and history (useful for testing or session cleanup).
  void reset() {
    activeRequest.value = null;
    requestHistory.clear();
  }

  /// Creates and submits a new assistance request.
  Future<AssistanceRequestModel> submitRequest({
    required String roomId,
    String? roomName,
    required String jamaahId,
    required String jamaahName,
    required AssistanceType type,
    required String message,
    Position? currentPosition,
    String? customHumanLocation,
    required String targetHotel,
    String? targetRoom,
    int sharingDurationMinutes = 30,
    String? selectedPendampingUid,
    String? selectedPendampingName,
    bool sendToAll = false,
  }) async {
    final humanLocation =
        customHumanLocation ??
        resolveHumanReadableLocation(currentPosition, targetHotel: targetHotel);

    final double? distanceMeters = currentPosition != null
        ? estimateDistanceToHotel(currentPosition)
        : null;

    final request = AssistanceRequestModel(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      roomName: roomName,
      jamaahId: jamaahId,
      jamaahName: jamaahName,
      type: type,
      status: AssistanceStatus.sent,
      message: message.trim().isNotEmpty
          ? message.trim()
          : type.defaultQuickMessage,
      latitude: currentPosition?.latitude,
      longitude: currentPosition?.longitude,
      humanReadableLocation: humanLocation,
      targetHotel: targetHotel,
      targetRoom: targetRoom,
      hotelDistanceMeters: distanceMeters,
      sharingDurationMinutes: sharingDurationMinutes,
      createdAt: DateTime.now(),
      assignedPendampingUid: sendToAll ? null : selectedPendampingUid,
      assignedPendampingName: sendToAll
          ? 'Semua Pendamping'
          : (selectedPendampingName ?? 'Pendamping'),
      sendToAll: sendToAll,
    );

    activeRequest.value = request;
    requestHistory.insert(0, request);

    // Kirim notifikasi nyata ke Firebase via NotificationService
    try {
      final notifTitle = '[${type.title}] dari $jamaahName';
      final notifMessage =
          '$notifTitle\n${request.message}\n📍 Lokasi: $humanLocation\n🏨 Tujuan: $targetHotel';

      await _notificationService.sendCompanionMessage(
        roomId: roomId,
        message: notifMessage,
        sendToAll: sendToAll,
        kind: type == AssistanceType.message ? 'message' : 'info',
        pendampingUid: sendToAll ? null : selectedPendampingUid,
        latitude: currentPosition?.latitude,
        longitude: currentPosition?.longitude,
      );
    } catch (e) {
      debugPrint(
        '[AssistanceRequestService] Realtime notification warning (handled): $e',
      );
    }

    return request;
  }

  /// Pendamping accepts / acknowledges the assistance request.
  AssistanceRequestModel? acknowledgeRequest({
    String? pendampingName,
    String? pendampingUid,
    String? companionName,
    String? companionUid,
  }) {
    final current = activeRequest.value;
    if (current == null || !current.isActive) return null;

    final updated = current.copyWith(
      status: AssistanceStatus.acknowledged,
      acknowledgedAt: DateTime.now(),
      assignedPendampingName:
          companionName ?? pendampingName ?? current.assignedPendampingName,
      assignedPendampingUid:
          companionUid ?? pendampingUid ?? current.assignedPendampingUid,
    );
    activeRequest.value = updated;
    _updateHistory(updated);
    return updated;
  }

  /// Pendamping starts heading to the pilgrim's location.
  AssistanceRequestModel? dispatchCompanionToLocation({
    String? pendampingName,
    String? pendampingUid,
    String? companionName,
    String? companionUid,
  }) {
    final current = activeRequest.value;
    if (current == null || !current.isActive) return null;

    final updated = current.copyWith(
      status: AssistanceStatus.onTheWay,
      onTheWayAt: DateTime.now(),
      assignedPendampingName:
          companionName ?? pendampingName ?? current.assignedPendampingName,
      assignedPendampingUid:
          companionUid ?? pendampingUid ?? current.assignedPendampingUid,
    );
    activeRequest.value = updated;
    _updateHistory(updated);
    return updated;
  }

  /// Pilgrim confirms: "Saya sudah ditemukan" / assistance completed.
  AssistanceRequestModel? completeRequest() {
    final current = activeRequest.value;
    if (current == null) return null;

    final updated = current.copyWith(
      status: AssistanceStatus.completed,
      completedAt: DateTime.now(),
    );
    activeRequest.value = updated;
    _updateHistory(updated);
    return updated;
  }

  /// Clear or close active request session.
  void clearActiveRequest() {
    activeRequest.value = null;
  }

  /// Cancel ongoing assistance request.
  void cancelRequest() {
    final current = activeRequest.value;
    if (current == null) return;

    final updated = current.copyWith(status: AssistanceStatus.cancelled);
    activeRequest.value = null;
    _updateHistory(updated);
  }

  void _updateHistory(AssistanceRequestModel updated) {
    final index = requestHistory.indexWhere((r) => r.id == updated.id);
    if (index >= 0) {
      requestHistory[index] = updated;
    } else {
      requestHistory.insert(0, updated);
    }
  }

  /// Resolves an accessible, human-readable description of current position.
  /// Hindari menampilkan latitude/longitude mentah ke jamaah lansia!
  String resolveHumanReadableLocation(
    Position? position, {
    String? targetHotel,
  }) {
    if (position == null) {
      return 'Lokasi belum tersedia';
    }

    // Hitung jarak estimasi ke titik tujuan jika koordinat tersedia
    final distanceMeters = estimateDistanceToHotel(position);
    if (distanceMeters != null) {
      if (distanceMeters < 1000) {
        return '${distanceMeters.round()} m dari ${targetHotel ?? "Hotel / Pemondokan"}';
      } else {
        final km = (distanceMeters / 1000).toStringAsFixed(1);
        return '$km km dari ${targetHotel ?? "Hotel / Pemondokan"}';
      }
    }

    return 'Dekat area Masjid / Pos Pantau Rombongan';
  }

  /// Estimasi jarak kasar jika koordinat referensi diketahui.
  double? estimateDistanceToHotel(Position position) {
    // Estimasi jarak realistis untuk area Masjidil Haram / Nabawi (~350m - 1.2km)
    // Berdasarkan jarak koordinat ke landmark tengah
    const double refLat = 24.4672;
    const double refLng = 39.6109;

    final double dLat = (position.latitude - refLat) * 111000;
    final double dLng =
        (position.longitude - refLng) *
        111000 *
        math.cos(position.latitude * 0.01745);
    final double dist = math.sqrt(dLat * dLat + dLng * dLng);

    if (dist.isNaN || dist <= 0) return 350.0;
    return dist.clamp(150.0, 3500.0);
  }

  /// Mengambil nama Maktab / Hotel dari state HajiCare.
  String resolveTargetHotel(HajiCareController state) {
    final maktab = state.effectiveMaktab;
    if (maktab != null && maktab.trim().isNotEmpty) {
      final clean = maktab.trim();
      return clean.toLowerCase().startsWith('maktab') ? clean : 'Maktab $clean';
    }

    final roomName = state.activeRoom.value?.name;
    if (roomName != null && roomName.trim().isNotEmpty) {
      return roomName.trim();
    }

    return 'Hotel Al Madinah';
  }

  /// Mengambil nomor kamar dari profil jamaah jika tersedia.
  String resolveTargetRoom(HajiCareController state) {
    final room = state.activeRoom.value;
    if (room != null && room.code.isNotEmpty) {
      return 'Kamar ${room.code}';
    }
    return 'Room 304';
  }
}

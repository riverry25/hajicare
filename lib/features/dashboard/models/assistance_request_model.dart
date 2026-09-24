import 'package:flutter/material.dart';

enum AssistanceType { lostWay, separated, pickup, message }

extension AssistanceTypeExtension on AssistanceType {
  String get title {
    switch (this) {
      case AssistanceType.lostWay:
        return 'Saya tidak tahu jalan pulang';
      case AssistanceType.separated:
        return 'Saya terpisah dari rombongan';
      case AssistanceType.pickup:
        return 'Saya membutuhkan penjemputan';
      case AssistanceType.message:
        return 'Saya ingin mengirim pesan';
    }
  }

  String get description {
    switch (this) {
      case AssistanceType.lostWay:
        return 'Bantu saya menemukan jalan kembali ke hotel';
      case AssistanceType.separated:
        return 'Kirim lokasi saya kepada pendamping';
      case AssistanceType.pickup:
        return 'Minta pendamping datang ke lokasi saya';
      case AssistanceType.message:
        return 'Kirim informasi kepada pendamping';
    }
  }

  IconData get icon {
    switch (this) {
      case AssistanceType.lostWay:
        return Icons.explore_rounded;
      case AssistanceType.separated:
        return Icons.groups_rounded;
      case AssistanceType.pickup:
        return Icons.directions_car_rounded;
      case AssistanceType.message:
        return Icons.chat_bubble_rounded;
    }
  }

  String get ctaLabel {
    switch (this) {
      case AssistanceType.lostWay:
        return 'Minta Bantuan';
      case AssistanceType.separated:
        return 'Minta Bantuan';
      case AssistanceType.pickup:
        return 'Minta Penjemputan';
      case AssistanceType.message:
        return 'Kirim Pesan';
    }
  }

  String get defaultQuickMessage {
    switch (this) {
      case AssistanceType.lostWay:
        return 'Saya tidak tahu jalan pulang, mohon panduan arah ke hotel.';
      case AssistanceType.separated:
        return 'Saya terpisah dari rombongan dan menunggu di lokasi ini.';
      case AssistanceType.pickup:
        return 'Mohon bantuan penjemputan di lokasi saya saat ini.';
      case AssistanceType.message:
        return 'Mohon hubungi saya.';
    }
  }

  bool get requiresLocation {
    switch (this) {
      case AssistanceType.lostWay:
      case AssistanceType.separated:
      case AssistanceType.pickup:
        return true;
      case AssistanceType.message:
        return false;
    }
  }
}

enum AssistanceStatus { sent, acknowledged, onTheWay, completed, cancelled }

extension AssistanceStatusExtension on AssistanceStatus {
  String get label {
    switch (this) {
      case AssistanceStatus.sent:
        return 'Permintaan Terkirim';
      case AssistanceStatus.acknowledged:
        return 'Diterima Pendamping';
      case AssistanceStatus.onTheWay:
        return 'Pendamping Menuju Lokasi';
      case AssistanceStatus.completed:
        return 'Bantuan Selesai';
      case AssistanceStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String get description {
    switch (this) {
      case AssistanceStatus.sent:
        return 'Pendamping Anda telah diberi tahu. Mohon tunggu sejenak.';
      case AssistanceStatus.acknowledged:
        return 'Pendamping telah menerima permintaan dan sedang bersiap.';
      case AssistanceStatus.onTheWay:
        return 'Pendamping sedang bergerak menuju lokasi Anda. Tetap di posisi.';
      case AssistanceStatus.completed:
        return 'Anda telah bertemu pendamping. Bantuan selesai.';
      case AssistanceStatus.cancelled:
        return 'Permintaan bantuan telah dibatalkan.';
    }
  }

  Color get color {
    switch (this) {
      case AssistanceStatus.sent:
        return const Color(0xFFE64A19);
      case AssistanceStatus.acknowledged:
        return const Color(0xFFD97706);
      case AssistanceStatus.onTheWay:
        return const Color(0xFF0284C7);
      case AssistanceStatus.completed:
        return const Color(0xFF16A34A);
      case AssistanceStatus.cancelled:
        return const Color(0xFF6B7280);
    }
  }

  Color get badgeColor => color;
}

class AssistanceRequestModel {
  final String id;
  final String roomId;
  final String? roomName;
  final String jamaahId;
  final String jamaahName;
  final AssistanceType type;
  final AssistanceStatus status;
  final String message;
  final double? latitude;
  final double? longitude;
  final String humanReadableLocation;
  final String targetHotel;
  final String? targetRoom;
  final double? hotelDistanceMeters;
  final int sharingDurationMinutes;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? onTheWayAt;
  final DateTime? completedAt;
  final String? assignedPendampingName;
  final String? assignedPendampingUid;
  final bool sendToAll;

  const AssistanceRequestModel({
    required this.id,
    required this.roomId,
    this.roomName,
    required this.jamaahId,
    required this.jamaahName,
    required this.type,
    this.status = AssistanceStatus.sent,
    required this.message,
    this.latitude,
    this.longitude,
    required this.humanReadableLocation,
    required this.targetHotel,
    this.targetRoom,
    this.hotelDistanceMeters,
    this.sharingDurationMinutes = 30,
    required this.createdAt,
    this.acknowledgedAt,
    this.onTheWayAt,
    this.completedAt,
    this.assignedPendampingName,
    this.assignedPendampingUid,
    this.sendToAll = false,
  });

  bool get isActive =>
      status == AssistanceStatus.sent ||
      status == AssistanceStatus.acknowledged ||
      status == AssistanceStatus.onTheWay;

  bool get isCompleted => status == AssistanceStatus.completed;

  String get humanLocation => humanReadableLocation;

  String? get assignedCompanionName => assignedPendampingName;

  String get timeFormatted {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  AssistanceRequestModel copyWith({
    String? id,
    String? roomId,
    String? roomName,
    String? jamaahId,
    String? jamaahName,
    AssistanceType? type,
    AssistanceStatus? status,
    String? message,
    double? latitude,
    double? longitude,
    String? humanReadableLocation,
    String? targetHotel,
    String? targetRoom,
    double? hotelDistanceMeters,
    int? sharingDurationMinutes,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    DateTime? onTheWayAt,
    DateTime? completedAt,
    String? assignedPendampingName,
    String? assignedPendampingUid,
    bool? sendToAll,
  }) {
    return AssistanceRequestModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      jamaahId: jamaahId ?? this.jamaahId,
      jamaahName: jamaahName ?? this.jamaahName,
      type: type ?? this.type,
      status: status ?? this.status,
      message: message ?? this.message,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      humanReadableLocation:
          humanReadableLocation ?? this.humanReadableLocation,
      targetHotel: targetHotel ?? this.targetHotel,
      targetRoom: targetRoom ?? this.targetRoom,
      hotelDistanceMeters: hotelDistanceMeters ?? this.hotelDistanceMeters,
      sharingDurationMinutes:
          sharingDurationMinutes ?? this.sharingDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      onTheWayAt: onTheWayAt ?? this.onTheWayAt,
      completedAt: completedAt ?? this.completedAt,
      assignedPendampingName:
          assignedPendampingName ?? this.assignedPendampingName,
      assignedPendampingUid:
          assignedPendampingUid ?? this.assignedPendampingUid,
      sendToAll: sendToAll ?? this.sendToAll,
    );
  }
}

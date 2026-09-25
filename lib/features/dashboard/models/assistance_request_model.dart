import 'package:flutter/material.dart';
import 'package:hajicare/core/locales/app_translations.dart';

enum AssistanceType { lostWay, separated, pickup, message }

extension AssistanceTypeExtension on AssistanceType {
  String get title {
    switch (this) {
      case AssistanceType.lostWay:
        return AppTranslations.tr('assistanceTypeLostWayTitle');
      case AssistanceType.separated:
        return AppTranslations.tr('assistanceTypeSeparatedTitle');
      case AssistanceType.pickup:
        return AppTranslations.tr('assistanceTypePickupTitle');
      case AssistanceType.message:
        return AppTranslations.tr('assistanceTypeMessageTitle');
    }
  }

  String get description {
    switch (this) {
      case AssistanceType.lostWay:
        return AppTranslations.tr('assistanceTypeLostWayDesc');
      case AssistanceType.separated:
        return AppTranslations.tr('assistanceTypeSeparatedDesc');
      case AssistanceType.pickup:
        return AppTranslations.tr('assistanceTypePickupDesc');
      case AssistanceType.message:
        return AppTranslations.tr('assistanceTypeMessageDesc');
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
        return AppTranslations.tr('assistanceCtaRequestHelp');
      case AssistanceType.separated:
        return AppTranslations.tr('assistanceCtaRequestHelp');
      case AssistanceType.pickup:
        return AppTranslations.tr('assistanceCtaRequestPickup');
      case AssistanceType.message:
        return AppTranslations.tr('assistanceCtaSendMessage');
    }
  }

  String get defaultQuickMessage {
    switch (this) {
      case AssistanceType.lostWay:
        return AppTranslations.tr('assistanceTypeLostWayTitle');
      case AssistanceType.separated:
        return AppTranslations.tr('assistanceTypeSeparatedTitle');
      case AssistanceType.pickup:
        return AppTranslations.tr('assistanceTypePickupTitle');
      case AssistanceType.message:
        return AppTranslations.tr('assistanceTypeMessageTitle');
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
        return AppTranslations.tr('assistanceStatusSent');
      case AssistanceStatus.acknowledged:
        return AppTranslations.tr('assistanceStatusAcknowledged');
      case AssistanceStatus.onTheWay:
        return AppTranslations.tr('assistanceStatusOnTheWay');
      case AssistanceStatus.completed:
        return AppTranslations.tr('assistanceStatusCompleted');
      case AssistanceStatus.cancelled:
        return AppTranslations.tr('assistanceStatusCancelled');
    }
  }

  String get description {
    switch (this) {
      case AssistanceStatus.sent:
        return AppTranslations.tr('assistanceStatusSentDesc');
      case AssistanceStatus.acknowledged:
        return AppTranslations.tr('assistanceStatusAcknowledgedDesc');
      case AssistanceStatus.onTheWay:
        return AppTranslations.tr('assistanceStatusOnTheWayDesc');
      case AssistanceStatus.completed:
        return AppTranslations.tr('assistanceStatusCompletedDesc');
      case AssistanceStatus.cancelled:
        return AppTranslations.tr('assistanceStatusCancelledDesc');
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

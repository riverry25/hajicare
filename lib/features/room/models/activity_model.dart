import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/haji_colors.dart';

enum ActivityType {
  roomCreated,
  roomActivated,
  roomDeactivated,
  roomUpdated,
  memberJoined,
  memberLeft,
  sosActive,
  unknown,
}

class ActivityModel {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String? roomId;
  final String? roomName;
  final String? userId;
  final String? userName;
  final String? role;
  final DateTime timestamp;

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.roomId,
    this.roomName,
    this.userId,
    this.userName,
    this.role,
    required this.timestamp,
  });

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawType = data['type'] as String? ?? '';
    final ActivityType type;
    switch (rawType) {
      case 'room_created':
        type = ActivityType.roomCreated;
        break;
      case 'room_activated':
        type = ActivityType.roomActivated;
        break;
      case 'room_deactivated':
        type = ActivityType.roomDeactivated;
        break;
      case 'room_updated':
        type = ActivityType.roomUpdated;
        break;
      case 'member_joined':
        type = ActivityType.memberJoined;
        break;
      case 'member_left':
        type = ActivityType.memberLeft;
        break;
      case 'sos_active':
        type = ActivityType.sosActive;
        break;
      default:
        type = ActivityType.unknown;
    }

    DateTime time = DateTime.now();
    if (data['timestamp'] != null) {
      if (data['timestamp'] is Timestamp) {
        time = (data['timestamp'] as Timestamp).toDate();
      } else if (data['timestamp'] is String) {
        time = DateTime.tryParse(data['timestamp']) ?? DateTime.now();
      }
    }

    return ActivityModel(
      id: doc.id,
      type: type,
      title: data['title'] as String? ?? 'Aktivitas Operasional',
      description: data['description'] as String? ?? '',
      roomId: data['roomId'] as String?,
      roomName: data['roomName'] as String?,
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      role: data['role'] as String?,
      timestamp: time,
    );
  }

  Map<String, dynamic> toFirestore() {
    String rawType;
    switch (type) {
      case ActivityType.roomCreated:
        rawType = 'room_created';
        break;
      case ActivityType.roomActivated:
        rawType = 'room_activated';
        break;
      case ActivityType.roomDeactivated:
        rawType = 'room_deactivated';
        break;
      case ActivityType.roomUpdated:
        rawType = 'room_updated';
        break;
      case ActivityType.memberJoined:
        rawType = 'member_joined';
        break;
      case ActivityType.memberLeft:
        rawType = 'member_left';
        break;
      case ActivityType.sosActive:
        rawType = 'sos_active';
        break;
      case ActivityType.unknown:
        rawType = 'unknown';
        break;
    }

    return {
      'type': rawType,
      'title': title,
      'description': description,
      'roomId': roomId,
      'roomName': roomName,
      'userId': userId,
      'userName': userName,
      'role': role,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  IconData get icon {
    switch (type) {
      case ActivityType.roomCreated:
        return Icons.add_business_rounded;
      case ActivityType.roomActivated:
        return Icons.check_circle_rounded;
      case ActivityType.roomDeactivated:
        return Icons.pause_circle_filled_rounded;
      case ActivityType.roomUpdated:
        return Icons.edit_note_rounded;
      case ActivityType.memberJoined:
        return role?.toLowerCase() == 'pendamping'
            ? Icons.health_and_safety_rounded
            : Icons.person_add_alt_1_rounded;
      case ActivityType.memberLeft:
        return Icons.person_remove_rounded;
      case ActivityType.sosActive:
        return Icons.warning_rounded;
      case ActivityType.unknown:
        return Icons.notifications_active_rounded;
    }
  }

  StatusTone get tone {
    switch (type) {
      case ActivityType.roomCreated:
        return StatusTone.islamic;
      case ActivityType.roomActivated:
        return StatusTone.success;
      case ActivityType.roomDeactivated:
        return StatusTone.neutral;
      case ActivityType.roomUpdated:
        return StatusTone.islamic;
      case ActivityType.memberJoined:
        return role?.toLowerCase() == 'pendamping'
            ? StatusTone.islamic
            : StatusTone.success;
      case ActivityType.memberLeft:
        return StatusTone.danger;
      case ActivityType.sosActive:
        return StatusTone.danger;
      case ActivityType.unknown:
        return StatusTone.neutral;
    }
  }

  /// Resolve color using current theme context tokens
  Color resolveColor(HajiColors colors) => colors.tone(tone);

  /// Default color using light palette
  Color get color => HajiColors.light.tone(tone);

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

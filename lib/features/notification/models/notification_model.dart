import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String recipientId;
  final String
  type; // 'room_invitation', 'room_removed', 'announcement', 'system', 'sos_alert'
  final String title;
  final String message;
  final String? relatedId; // e.g. invitationId, roomId, or sosEventId
  final String? senderId;
  final String? senderRole; // 'admin', 'pendamping', 'system'
  final String? senderName;
  final String? scope; // 'global', 'maktab', 'kloter', 'room', 'user'
  final String? targetUserId;
  final String? targetRoomId;
  final String? targetMaktab;
  final String? targetKloter;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  const AppNotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.senderId,
    this.senderRole,
    this.senderName,
    this.scope,
    this.targetUserId,
    this.targetRoomId,
    this.targetMaktab,
    this.targetKloter,
    this.isRead = false,
    this.createdAt,
    this.metadata,
  });

  bool get isRoomInvitation => type == 'room_invitation';
  bool get isRoomJoined => type == 'room_joined';
  bool get isRoomRemoved => type == 'room_removed';
  bool get isAnnouncement => type == 'announcement';
  bool get isSosAlert => type == 'sos_alert';

  factory AppNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    return AppNotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      relatedId: data['relatedId'] as String?,
      senderId: data['senderId'] as String?,
      senderRole: data['senderRole'] as String?,
      senderName: data['senderName'] as String?,
      scope: data['scope'] as String?,
      targetUserId: data['targetUserId'] as String?,
      targetRoomId: data['targetRoomId'] as String?,
      targetMaktab: data['targetMaktab'] as String?,
      targetKloter: data['targetKloter'] as String?,
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: createdAt,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'message': message,
      if (relatedId != null) 'relatedId': relatedId,
      if (senderId != null) 'senderId': senderId,
      if (senderRole != null) 'senderRole': senderRole,
      if (senderName != null) 'senderName': senderName,
      if (scope != null) 'scope': scope,
      if (targetUserId != null) 'targetUserId': targetUserId,
      if (targetRoomId != null) 'targetRoomId': targetRoomId,
      if (targetMaktab != null) 'targetMaktab': targetMaktab,
      if (targetKloter != null) 'targetKloter': targetKloter,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}
